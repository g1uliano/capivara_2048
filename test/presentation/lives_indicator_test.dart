import 'package:capivara_2048/data/models/lives_state.dart';
import 'package:capivara_2048/data/repositories/lives_repository.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/presentation/widgets/lives_indicator.dart';
import 'package:capivara_2048/presentation/widgets/lives_status_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({required LivesState livesState}) {
  return ProviderScope(
    overrides: [
      livesProvider.overrideWith((_) => _FakeLivesNotifier(livesState)),
    ],
    child: const MaterialApp(home: Scaffold(body: LivesIndicator())),
  );
}

class _FakeLivesNotifier extends LivesNotifier {
  _FakeLivesNotifier(LivesState initial) : super(_FakeRepo(initial));
}

class _FakeRepo extends LivesRepository {
  final LivesState _state;
  _FakeRepo(this._state);
  @override
  Future<LivesState> load() async => _state;
  @override
  Future<void> save(LivesState state) async {}
  @override
  Future<bool> getMigrationFlag(String key) async => true;
  @override
  Future<void> setMigrationFlag(String key) async {}
}

LivesState _state({
  int lives = 3,
  int regenCap = 5,
  int earnedCap = 15,
  DateTime? lastRegenAt,
}) =>
    LivesState(
      lives: lives,
      regenCap: regenCap,
      earnedCap: earnedCap,
      lastRegenAt: lastRegenAt ?? DateTime.now(),
      adWatchedToday: 0,
      adCounterResetAt: DateTime.now().add(const Duration(hours: 24)),
    );

void main() {
  group('LivesIndicator', () {
    testWidgets('shows single heart icon', (tester) async {
      await tester.pumpWidget(_wrap(livesState: _state(lives: 3)));
      await tester.pump();
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('shows number overlay on heart', (tester) async {
      await tester.pumpWidget(_wrap(livesState: _state(lives: 3)));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows LivesStatusBanner widget', (tester) async {
      await tester.pumpWidget(_wrap(livesState: _state(lives: 3)));
      await tester.pump();
      expect(find.byType(LivesStatusBanner), findsOneWidget);
    });

    testWidgets('banner shows "Bônus" when lives > regenCap', (tester) async {
      await tester.pumpWidget(_wrap(livesState: _state(lives: 7, regenCap: 5)));
      await tester.pump();
      expect(find.text('Bônus'), findsOneWidget);
    });

    testWidgets('banner shows "Completo" when lives == regenCap', (tester) async {
      await tester.pumpWidget(_wrap(livesState: _state(lives: 5, regenCap: 5)));
      await tester.pump();
      expect(find.text('Completo'), findsOneWidget);
    });

    testWidgets('banner shows "Restando" when lives < regenCap', (tester) async {
      await tester.pumpWidget(_wrap(livesState: _state(lives: 3, regenCap: 5)));
      await tester.pump();
      expect(find.textContaining('Restando'), findsOneWidget);
    });

    testWidgets('banner shows "Sem vidas" when lives == 0', (tester) async {
      await tester.pumpWidget(_wrap(livesState: _state(lives: 0, regenCap: 5)));
      await tester.pump();
      expect(find.text('Sem vidas'), findsOneWidget);
    });
  });
}
