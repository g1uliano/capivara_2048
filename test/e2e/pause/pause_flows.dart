import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/domain/game_engine/direction.dart';
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

// ─── pause.tap_pause_button_shows_overlay ────────────────────────────────────

final pauseTapButtonScenario = E2EScenario(
  id: 'pause.tap_pause_button_shows_overlay',
  title: 'tap no botão Pausar → PauseOverlay aparece',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // PauseButtonTile has Semantics(label: 'Botão Pausar').
    await tester.tap(find.bySemanticsLabel('Botão Pausar'));
    // Allow the 100ms reverse animation in PauseButtonTile to finish so
    // widget.onTap() fires, then wait for the PauseOverlay AnimatedOpacity.
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Pausado'), findsOneWidget);
    expect(harness.container.read(gameProvider).isPaused, isTrue);
  },
);

// ─── pause.reiniciar_resets_game ─────────────────────────────────────────────

final pauseReiniciarScenario = E2EScenario(
  id: 'pause.reiniciar_resets_game',
  title: 'Reiniciar na PauseOverlay → jogo recomeça com score=0',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Set a non-zero score so we can verify it resets.
    final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
    board[0][0] = const Tile(id: 'a', level: 3, row: 0, col: 0);
    harness.container.read(gameProvider.notifier).debugSetState(
      GameState(
        board: board,
        score: 88,
        highScore: 88,
        maxLevel: 3,
        isGameOver: false,
        hasWon: false,
      ),
    );

    harness.container.read(gameProvider.notifier).pause();
    await tester.pump();
    expect(find.text('Pausado'), findsOneWidget);

    await tester.tap(find.text('Reiniciar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Pausado'), findsNothing,
        reason: 'PauseOverlay deve sumir após Reiniciar');
    expect(harness.container.read(gameProvider).score, equals(0),
        reason: 'Reiniciar deve resetar o score para 0');
    expect(harness.container.read(gameProvider).isPaused, isFalse,
        reason: 'jogo não deve estar pausado após Reiniciar');
  },
);

// ─── pause.system_back_keeps_paused_state ────────────────────────────────────

final pauseSystemBackScenario = E2EScenario(
  id: 'pause.system_back_keeps_paused_state',
  title: 'jogo em andamento → back via nav.pop → home mostra "Continuar Jogo"',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Set score > 0 so HomeScreen shows "Continuar Jogo".
    final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
    board[0][0] = const Tile(id: 'x', level: 2, row: 0, col: 0);
    harness.container.read(gameProvider.notifier).debugSetState(
      GameState(
        board: board,
        score: 50,
        highScore: 50,
        maxLevel: 2,
        isGameOver: false,
        hasWon: false,
      ),
    );

    harness.container.read(gameProvider.notifier).pause();
    await tester.pump();
    expect(find.text('Pausado'), findsOneWidget);

    // Simulate system back: pop the route directly without going through
    // the PauseOverlay Menu button (which also calls resume).
    final NavigatorState nav = tester.state(find.byType(Navigator).first);
    nav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // HomeScreen should display "Continuar Jogo" because the game has score > 0.
    expect(find.text('Continuar Jogo'), findsOneWidget,
        reason:
            'após pop com jogo em andamento (score>0), home deve mostrar "Continuar Jogo"');
  },
);

// ─── pause.game_doesnt_consume_time_while_paused ─────────────────────────────

final pauseTimeNotConsumedScenario = E2EScenario(
  id: 'pause.game_doesnt_consume_time_while_paused',
  title: 'elapsedMs não avança enquanto o jogo está pausado',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Make a valid swipe to start the game timer (_timerStarted=false initially).
    harness.container.read(gameProvider.notifier).onSwipe(Direction.right);
    // Advance fake clock 300ms so the Timer.periodic(100ms) fires 3 times.
    await tester.pump(const Duration(milliseconds: 300));

    // Pause — stops the timer via _stopTimer().
    harness.container.read(gameProvider.notifier).pause();
    await tester.pump();
    final elapsedAtPause = harness.container.read(gameProvider).elapsedMs;

    // Advance fake clock 1 second: timer is cancelled, so elapsedMs must not change.
    await tester.pump(const Duration(seconds: 1));

    final elapsedAfterWait = harness.container.read(gameProvider).elapsedMs;
    expect(elapsedAfterWait, equals(elapsedAtPause),
        reason: 'elapsedMs não deve avançar enquanto isPaused=true');
  },
);
