import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'test_harness.dart';

enum SwipeDirection { up, down, left, right }

extension E2EHelpers on WidgetTester {
  /// Tap a widget identified by a string [Key] and call [pumpAndSettle].
  Future<void> tapByKey(String key) async {
    await tap(find.byKey(Key(key)));
    await pumpAndSettle();
  }

  /// Swipe the game board widget (found by Key 'game_board') in [dir].
  /// Falls back to screen center if the board is not in the tree.
  Future<void> swipeBoard(SwipeDirection dir) async {
    const swipeDistance = 200.0;
    final boardFinder = find.byKey(const Key('game_board'));
    final start = boardFinder.evaluate().isNotEmpty
        ? getCenter(boardFinder)
        : Offset(
            view.physicalSize.width / view.devicePixelRatio / 2,
            view.physicalSize.height / view.devicePixelRatio / 2,
          );

    final delta = switch (dir) {
      SwipeDirection.up    => const Offset(0, -swipeDistance),
      SwipeDirection.down  => const Offset(0, swipeDistance),
      SwipeDirection.left  => const Offset(-swipeDistance, 0),
      SwipeDirection.right => const Offset(swipeDistance, 0),
    };

    await flingFrom(start, delta, 800.0);
    await pumpAndSettle();
  }

  /// Lê o GameState atual do container.
  GameState readGame(GameTestHarness harness) =>
      harness.container.read(gameProvider);

  /// Define um estado de jogo com dois tiles de [level-1] prontos para fundir.
  /// Após swipeBoard(SwipeDirection.left), o merge produz tile de [level],
  /// disparando pendingMilestone = [level] (se level >= 11).
  void setupNearWin(GameTestHarness harness, {int level = 11}) {
    final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
    board[0][0] = Tile(id: 'near_win_a', level: level - 1, row: 0, col: 0);
    board[0][1] = Tile(id: 'near_win_b', level: level - 1, row: 0, col: 1);
    harness.container.read(gameProvider.notifier).debugSetState(
      GameState(
        board: board,
        score: 100,
        highScore: 0,
        isGameOver: false,
        hasWon: false,
        maxLevel: level - 1,
      ),
    );
  }

  /// Define estado de game over aguardando resolução (mostra GameOverItemOverlay
  /// ou GameOverNoItemsOverlay dependendo do inventário).
  void setupAwaitingResolution(GameTestHarness harness) {
    harness.container.read(gameProvider.notifier).debugSetState(
      GameState(
        board: List.generate(4, (_) => List<Tile?>.filled(4, null)),
        score: 100,
        highScore: 0,
        isGameOver: true,
        hasWon: false,
        maxLevel: 1, // level 1 (Tanajura) is valid for animalForLevel()
        isAwaitingGameOverResolution: true,
      ),
    );
  }

  /// Define estado de game over final (mostra GameOverModal com 'Game Over!').
  void setupGameOverModal(GameTestHarness harness) {
    harness.container.read(gameProvider.notifier).debugSetState(
      GameState(
        board: List.generate(4, (_) => List<Tile?>.filled(4, null)),
        score: 100,
        highScore: 0,
        isGameOver: true,
        hasWon: false,
        maxLevel: 1, // level 1 (Tanajura) is valid for animalForLevel()
        isAwaitingGameOverResolution: false,
      ),
    );
  }

  /// Navega da Home para a GameScreen via "Novo jogo".
  /// Pré-condição: tester já fez boot() e pumpAndSettle da splash.
  Future<void> gotoGame(GameTestHarness harness) async {
    await tap(find.text('Novo jogo'));
    await pumpAndSettle();
  }
}
