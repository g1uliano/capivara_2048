import 'package:capivara_2048/core/providers/reduce_effects_provider.dart';
import 'package:capivara_2048/presentation/widgets/pause_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PauseOverlay uses BackdropFilter when reduceEffects is false',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(
          home: Scaffold(body: PauseOverlay()),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('PauseOverlay has no BackdropFilter when reduceEffects is true',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reduceEffectsProvider.overrideWith((ref) {
            final notifier = ReduceEffectsNotifier();
            notifier.state = true;
            return notifier;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PauseOverlay()),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);
  });
}
