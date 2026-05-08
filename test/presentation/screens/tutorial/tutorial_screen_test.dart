import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capivara_2048/presentation/screens/tutorial/tutorial_screen.dart';
import 'package:capivara_2048/domain/sync/sync_engine.dart';
import 'package:capivara_2048/presentation/controllers/auth_controller.dart';
import 'package:capivara_2048/data/models/player_profile.dart';

Widget _makeApp() => ProviderScope(
      overrides: [
        syncEngineProvider.overrideWithValue(FakeSyncEngine()),
        authControllerProvider.overrideWith(() => _FakeAuth()),
      ],
      child: const MaterialApp(home: TutorialScreen()),
    );

class _FakeAuth extends AuthController {
  @override
  PlayerProfile? build() => null; // anonymous
}

// Pumps enough frames to settle flutter_animate without timing out.
Future<void> _settle(WidgetTester tester, {int frames = 5}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows welcome page (page 1) on open', (tester) async {
    await tester.pumpWidget(_makeApp());
    await _settle(tester);
    expect(find.text('Bem-vindo à floresta amazônica!'), findsOneWidget);
  });

  testWidgets('Próximo button advances from page 1 to page 2', (tester) async {
    await tester.pumpWidget(_makeApp());
    await _settle(tester);
    await tester.tap(find.text('Próximo →'));
    await _settle(tester);
    expect(find.text('Deslize pra mover'), findsOneWidget);
  });

  testWidgets('Próximo is disabled on interactive page before completing', (tester) async {
    await tester.pumpWidget(_makeApp());
    await _settle(tester);
    // Navigate to page 2 (movement, interactive)
    await tester.tap(find.text('Próximo →'));
    await _settle(tester);
    // Find the Próximo button — should be disabled (onPressed == null)
    final btns = tester.widgetList<TextButton>(find.byType(TextButton)).toList();
    final nextBtn = btns.firstWhere(
      (b) => b.onPressed == null,
      orElse: () => throw StateError('No disabled button found'),
    );
    expect(nextBtn.onPressed, isNull);
  });

  testWidgets('Pular closes the screen', (tester) async {
    // Use a wrapper with a route so Navigator.pop works
    await tester.pumpWidget(ProviderScope(
      overrides: [
        syncEngineProvider.overrideWithValue(FakeSyncEngine()),
        authControllerProvider.overrideWith(() => _FakeAuth()),
      ],
      child: MaterialApp(
        home: Builder(builder: (ctx) => ElevatedButton(
          onPressed: () => Navigator.of(ctx).push(
            MaterialPageRoute(builder: (_) => const TutorialScreen()),
          ),
          child: const Text('Open'),
        )),
      ),
    ));
    await tester.tap(find.text('Open'));
    await _settle(tester);
    expect(find.text('Tutorial'), findsOneWidget);
    await tester.tap(find.text('Pular'));
    // Extra frames for async markCompleted + Navigator.pop
    await _settle(tester, frames: 15);
    expect(find.text('Tutorial'), findsNothing);
  });
}
