import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/core/providers/reduce_effects_provider.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';
import '../_harness/tester_extensions.dart';

Future<void> _bootToHome(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

Future<void> _bootToGame(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
  await tester.gotoGame(harness);
}

// ─── settings.toggle_reduce_effects_persists ─────────────────────────────────

final settingsReduceEffectsScenario = E2EScenario(
  id: 'settings.toggle_reduce_effects_persists',
  title: 'toggle Reduzir Efeitos Visuais → valor invertido + persiste após restart',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    final initialValue = harness.container.read(reduceEffectsProvider);

    // Toggle via notifier (same codepath as UI tap, avoids PackageInfo mock)
    await tester.runAsync(
        () => harness.container.read(reduceEffectsProvider.notifier).toggle());
    await tester.pump();

    expect(
      harness.container.read(reduceEffectsProvider),
      equals(!initialValue),
      reason: 'toggle deve inverter o valor de reduceEffects',
    );

    // Cold restart — SharedPreferences survives (same mock)
    final widget2 = await tester.runAsync(() => harness.restart());
    await tester.pumpWidget(widget2!);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(
      harness.container.read(reduceEffectsProvider),
      equals(!initialValue),
      reason: 'reduceEffects deve persistir após cold restart',
    );
  },
);

// ─── settings.reduce_effects_disables_blur_in_pause ──────────────────────────

final settingsReduceEffectsBlurScenario = E2EScenario(
  id: 'settings.reduce_effects_disables_blur_in_pause',
  title: 'reduceEffects=true → PauseOverlay sem BackdropFilter',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Enable reduce effects directly via notifier
    await tester.runAsync(
        () => harness.container.read(reduceEffectsProvider.notifier).toggle());
    await tester.pump();

    // Verify it's now true
    expect(harness.container.read(reduceEffectsProvider), isTrue);

    // Pause the game
    harness.container.read(gameProvider.notifier).pause();
    await tester.pump();
    // Trigger the addPostFrameCallback opacity animation
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Pausado'), findsOneWidget);
    // With reduceEffects=true, BackdropFilter should NOT be in the tree
    expect(
      find.byType(BackdropFilter),
      findsNothing,
      reason:
          'reduceEffects=true deve remover BackdropFilter (sem blur) da PauseOverlay',
    );
  },
);

// ─── settings.toggle_haptics_persists ────────────────────────────────────────

final settingsHapticsScenario = E2EScenario(
  id: 'settings.toggle_haptics_persists',
  title: 'toggle Vibração → invertido + persiste após cold restart',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    final initialHaptic = harness.container.read(settingsProvider).hapticEnabled;

    // Toggle via notifier (same codepath as UI switch, avoids PackageInfo mock)
    harness.container.read(settingsProvider.notifier).setHaptic(!initialHaptic);
    await tester.pump();

    expect(
      harness.container.read(settingsProvider).hapticEnabled,
      equals(!initialHaptic),
      reason: 'setHaptic deve inverter hapticEnabled',
    );

    // Cold restart — SharedPreferences survives
    final widget2 = await tester.runAsync(() => harness.restart());
    await tester.pumpWidget(widget2!);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(
      harness.container.read(settingsProvider).hapticEnabled,
      equals(!initialHaptic),
      reason: 'hapticEnabled deve persistir após cold restart',
    );
  },
);

// ─── settings.language_pt_br_default ─────────────────────────────────────────

final settingsLanguageScenario = E2EScenario(
  id: 'settings.language_pt_br_default',
  title: 'locale padrão é "pt" e UI exibe texto em português',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    expect(
      harness.container.read(settingsProvider).locale,
      equals('pt'),
      reason: 'locale padrão deve ser "pt"',
    );
    expect(
      find.text('Novo jogo'),
      findsOneWidget,
      reason: 'UI deve estar em português ("Novo jogo" visível na HomeScreen)',
    );
  },
);
