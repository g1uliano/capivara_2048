import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/screens/game/game_screen.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';
import '../_harness/tester_extensions.dart';

Future<void> _bootToGame(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
  await tester.gotoGame(harness);
}

// ─── flow.continue_after_pause ───────────────────────────────────────────────

final continueAfterPauseScenario = E2EScenario(
  id: 'flow.continue_after_pause',
  title: 'pausar → tap "Continuar" → jogo retoma (sem PauseOverlay)',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Pausa via notifier (mais confiável em headless do que tapping no botão).
    harness.container.read(gameProvider.notifier).pause();
    await tester.pump();

    expect(find.text('Pausado'), findsOneWidget);
    expect(tester.readGame(harness).isPaused, isTrue);

    await tester.tap(find.text('Continuar'));
    // pumpAndSettle() hangs aqui porque o board tem animações contínuas.
    // Pump bounded de 500 ms é suficiente para a AnimatedOpacity terminar.
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Pausado'), findsNothing);
    expect(tester.readGame(harness).isPaused, isFalse);
    expect(find.byType(GameScreen), findsOneWidget);
  },
);

// ─── flow.continue_after_back_button ─────────────────────────────────────────

final continueAfterBackButtonScenario = E2EScenario(
  id: 'flow.continue_after_back_button',
  title: 'pause → Menu → home → "Continuar Jogo" → SEM PauseOverlay (regressão v1.2.9)',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Garantir score > 0 para que _hasSavedGame() mostre 'Continuar Jogo' na Home.
    final currentState = tester.readGame(harness);
    harness.container.read(gameProvider.notifier).debugSetState(
      currentState.copyWith(score: 100),
    );

    // Pausa e volta ao menu via overlay.
    harness.container.read(gameProvider.notifier).pause();
    await tester.pump();
    expect(find.text('Pausado'), findsOneWidget);

    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();

    // Deve estar na Home com 'Continuar Jogo' visível.
    expect(find.text('Continuar Jogo'), findsOneWidget);

    // Toca em 'Continuar Jogo'.
    await tester.tap(find.text('Continuar Jogo'));
    // pumpAndSettle é seguro aqui: vidas em máximo não disparam rebuild da timer.
    await tester.pumpAndSettle();

    // Regressão v1.2.9: PauseOverlay NÃO deve aparecer.
    expect(find.text('Pausado'), findsNothing,
        reason: 'regressão v1.2.9 — _continueGame deve chamar resume()');
    expect(find.byType(GameScreen), findsOneWidget);
  },
);
