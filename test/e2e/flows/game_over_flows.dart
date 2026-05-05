import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';
import '../_harness/tester_extensions.dart';

Future<void> _bootToGame(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
  await tester.gotoGame(harness);
}

// flutter_animate creates a Future.delayed(0) timer per widget in initState.
// First pump() builds the overlay (creates timers).
// Second pump(500ms) fires those zero-duration timers AND drains finite animations.
// Repeating AnimationControllers use tickers (not Timer) so they don't appear
// in timersPending — only Future.delayed timers do.
const _drainOverlay = Duration(milliseconds: 500);

// ─── flow.game_over_no_items ─────────────────────────────────────────────────

final gameOverNoItemsScenario = E2EScenario(
  id: 'flow.game_over_no_items',
  title: 'game over sem itens → GameOverNoItemsOverlay ("Você não possui mais itens!")',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    harness.container
        .read(inventoryProvider.notifier)
        .debugSetState(Inventory.empty());

    tester.setupAwaitingResolution(harness);
    await tester.pump();              // builds overlay; creates flutter_animate timers
    await tester.pump(_drainOverlay); // fires zero-duration timers + drains finite animations

    expect(find.textContaining('Você não possui mais itens!'), findsOneWidget);
    expect(find.textContaining('Ver anúncio'), findsOneWidget);
    expect(find.textContaining('Encerrar partida'), findsOneWidget);
  },
);

// ─── flow.game_over_with_items ───────────────────────────────────────────────

final gameOverWithItemsScenario = E2EScenario(
  id: 'flow.game_over_with_items',
  title: 'game over com itens → GameOverItemOverlay (oferta de item)',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    harness.container
        .read(inventoryProvider.notifier)
        .debugSetState(const Inventory(bomb2: 1, bomb3: 0, undo1: 0, undo3: 0));

    tester.setupAwaitingResolution(harness);
    await tester.pump();              // builds overlay; creates flutter_animate timers
    await tester.pump(_drainOverlay); // fires zero-duration timers (repeating tickers stay but are not Timer)

    expect(find.textContaining('Bomba 2'), findsOneWidget);
    expect(find.textContaining('Você não possui mais itens!'), findsNothing);
  },
);
