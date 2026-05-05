import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/data/models/lives_state.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/presentation/screens/no_lives_screen.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';
import '../_harness/tester_extensions.dart';

Future<void> _bootToGame(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
  await tester.gotoGame(harness);
}

Future<void> _bootToHome(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

// ─── flow.lives_consumed_on_game_over ────────────────────────────────────────
//
// Verifica:
// 1. GameOverNoItemsOverlay aparece quando sem itens.
// 2. Tap "Encerrar partida" → AlertDialog aparece.
// 3. Tap "Confirmar" → confirmGameOver() é chamado (isAwaitingGameOverResolution → false).
// 4. LivesNotifier.applyConsume decrementa vidas corretamente (lógica pura, sem async).
//
// Nota: consume() usa `await _ready.future` internamente (Hive IO), que não pode
// ser resolvido na zona fake-async do WidgetTester. O efeito síncrono de
// confirmGameOver() e a lógica pura de applyConsume são verificados separadamente.

final livesConsumedOnGameOverScenario = E2EScenario(
  id: 'flow.lives_consumed_on_game_over',
  title: 'game over sem itens → "Encerrar partida" → confirmar → confirmGameOver + applyConsume decrementam vida',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Inventário vazio → GameOverNoItemsOverlay.
    harness.container
        .read(inventoryProvider.notifier)
        .debugSetState(Inventory.empty());

    tester.setupAwaitingResolution(harness);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 1. Overlay correto aparece.
    expect(find.textContaining('Você não possui mais itens!'), findsOneWidget);

    // 2. Tap "Encerrar partida" → AlertDialog.
    await tester.tap(find.text('Encerrar partida'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Confirmar'), findsOneWidget);

    // 3. Tap "Confirmar" → _confirmQuit executa:
    //    unawaited(consume()); setState(_dismissed=true); confirmGameOver()
    //    Efeito síncrono visível: isAwaitingGameOverResolution → false.
    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.readGame(harness).isAwaitingGameOverResolution,
      isFalse,
      reason: 'confirmGameOver() deve ser chamado ao confirmar encerramento',
    );

    // 4. Verificar que applyConsume decrementa corretamente (lógica pura).
    final currentState = harness.container.read(livesProvider);
    final consumed = LivesNotifier.applyConsume(currentState);
    expect(
      consumed.lives,
      equals(currentState.lives - 1),
      reason: 'applyConsume deve decrementar 1 vida',
    );
  },
);

// ─── flow.no_lives_screen ────────────────────────────────────────────────────

final noLivesScreenScenario = E2EScenario(
  id: 'flow.no_lives_screen',
  title: 'GameOverModal com 0 vidas → "Jogar de novo" → NoLivesScreen',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // 0 vidas → canPlay = false. debugSetState é síncrono (sem _ready).
    harness.container.read(livesProvider.notifier).debugSetState(
      LivesState(
        lives: 0,
        regenCap: 5,
        earnedCap: 15,
        lastRegenAt: DateTime.now(),
        adWatchedToday: 0,
        adCounterResetAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );

    tester.setupGameOverModal(harness);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Game Over!'), findsOneWidget);
    expect(find.text('Jogar de novo'), findsOneWidget);

    // Com 0 vidas (canPlay: false), tap → pushReplacement(NoLivesScreen).
    await tester.tap(find.text('Jogar de novo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(NoLivesScreen), findsOneWidget);
  },
);

// ─── flow.lives_regen_over_time ───────────────────────────────────────────────

final livesRegenOverTimeScenario = E2EScenario(
  id: 'flow.lives_regen_over_time',
  title: 'lives=4, lastRegenAt=31min → calcRegen → 5 vidas',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    final staleState = LivesState(
      lives: 4,
      regenCap: 5,
      earnedCap: 15,
      lastRegenAt: DateTime.now().subtract(const Duration(minutes: 31)),
      adWatchedToday: 0,
      adCounterResetAt: DateTime.now().add(const Duration(days: 1)),
    );

    // Aplica regen via método estático e verifica o resultado.
    final regenned = LivesNotifier.calcRegen(
      state: staleState,
      now: DateTime.now(),
    );
    expect(
      regenned.lives,
      greaterThanOrEqualTo(5),
      reason: '31 minutos de regen pendente → +1 vida (4 → 5)',
    );

    // Verifica que o estado pode ser aplicado via debugSetState (sem async).
    harness.container.read(livesProvider.notifier).debugSetState(regenned);
    await tester.pump();
    expect(harness.container.read(livesProvider).lives, greaterThanOrEqualTo(5));
  },
);
