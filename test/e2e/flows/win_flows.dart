import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/data/models/tile.dart';
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

/// Force [pendingMilestone] via debugSetState using a clean board.
/// maxLevel: 1 avoids level-0 crash in animalForLevel().
void _setMilestone(GameTestHarness harness, int milestone) {
  harness.container.read(gameProvider.notifier).debugSetState(
    GameState(
      board: List.generate(4, (_) => List<Tile?>.filled(4, null)),
      score: 100,
      highScore: 0,
      maxLevel: 1,
      isGameOver: false,
      hasWon: false,
      pendingMilestone: milestone,
    ),
  );
}

// ─── flow.win_2048_first_time ─────────────────────────────────────────────────

final win2048FirstTimeScenario = E2EScenario(
  id: 'flow.win_2048_first_time',
  title: 'milestone 11 → VictoryChoiceDialog mostra título + "Você chegou ao 2048!"',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);
    _setMilestone(harness, 11);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // _title (OutlinedText) for milestone 11
    expect(find.text('Capivara Lendária! 🎉'), findsOneWidget);
    // _subtitle (Text) for milestone 11
    expect(find.text('Você chegou ao 2048!'), findsOneWidget);
    // Botão "Continuar" deve existir (milestone != 13)
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Encerrar'), findsOneWidget);
  },
);

// ─── flow.win_4096_first_time ─────────────────────────────────────────────────

final win4096FirstTimeScenario = E2EScenario(
  id: 'flow.win_4096_first_time',
  title: 'milestone 12 → VictoryChoiceDialog mostra "Peixe-boi! Incrível! 🌊" + "Você chegou ao 4096!"',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);
    _setMilestone(harness, 12);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Peixe-boi! Incrível! 🌊'), findsOneWidget);
    expect(find.text('Você chegou ao 4096!'), findsOneWidget);
    // milestone 12 também tem "Continuar"
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Encerrar'), findsOneWidget);
  },
);

// ─── flow.win_8192_first_time ─────────────────────────────────────────────────

final win8192FirstTimeScenario = E2EScenario(
  id: 'flow.win_8192_first_time',
  title: 'milestone 13 → VictoryChoiceDialog mostra "Jacaré!" + SEM botão "Continuar"',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);
    _setMilestone(harness, 13);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Jacaré! Lendário! 🐊'), findsOneWidget);
    expect(find.text('Você chegou ao 8192!'), findsOneWidget);
    // milestone 13: SEM botão "Continuar" (condição `if (milestone != 13)`)
    expect(find.text('Continuar'), findsNothing);
    expect(find.text('Encerrar'), findsOneWidget);
  },
);

// ─── flow.continue_after_win ─────────────────────────────────────────────────

final continueAfterWinScenario = E2EScenario(
  id: 'flow.continue_after_win',
  title: 'vitória 2048 → tap "Encerrar" → GameOverModal "Capivara Lendária! 🎉"',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);
    _setMilestone(harness, 11);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Você chegou ao 2048!'), findsOneWidget);

    // Tap "Encerrar" → chama async endGame() → hasWon: true, pendingMilestone: null
    await tester.tap(find.text('Encerrar'));
    // endGame() é async; runAsync drena microtasks + futures pendentes
    await tester.runAsync(() async {});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // hasWon && !isGameOver → GameOverModal(message: 'Capivara Lendária! 🎉')
    expect(find.text('Capivara Lendária! 🎉'), findsOneWidget,
        reason: 'endGame() deve setar hasWon:true → GameOverModal deve aparecer');
    expect(find.text('Jogar de novo'), findsOneWidget);
  },
);
