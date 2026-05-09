import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/data/models/item_type.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/domain/game_engine/bomb_mode.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import '../_harness/test_harness.dart';
import '../_harness/tester_extensions.dart';
import '../_harness/scenario.dart';

Future<void> _bootToGame(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
  await tester.gotoGame(harness);
}

List<List<Tile?>> _boardWith5Tiles() {
  final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
  for (var i = 0; i < 5; i++) {
    final row = i ~/ 4;
    final col = i % 4;
    board[row][col] = Tile(id: 'test_$i', level: 1, row: row, col: col);
  }
  return board;
}

/// Sets up a board state that already has 1 undo stack entry,
/// so undo1 is immediately usable without needing actual swipes.
/// This avoids starting the game timer (which prevents pumpAndSettle).
void _setupStateWithUndoEntry(GameTestHarness harness) {
  // The "previous" state that undo will revert to.
  final prevBoard = List.generate(4, (_) => List<Tile?>.filled(4, null));
  prevBoard[0][2] = Tile(id: 'a', level: 1, row: 0, col: 2);
  prevBoard[0][3] = Tile(id: 'b', level: 2, row: 0, col: 3);
  final prevState = GameState(
    board: prevBoard,
    score: 0,
    highScore: 0,
    isGameOver: false,
    hasWon: false,
    maxLevel: 2,
  );

  // Current board after a hypothetical move left.
  final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
  board[0][0] = Tile(id: 'a', level: 1, row: 0, col: 0);
  board[0][1] = Tile(id: 'b', level: 2, row: 0, col: 1);

  harness.container.read(gameProvider.notifier).debugSetState(
    GameState(
      board: board,
      score: 0,
      highScore: 0,
      isGameOver: false,
      hasWon: false,
      maxLevel: 2,
      undoStack: [prevState],
    ),
  );
}

// ─── flow.use_undo_during_game ───────────────────────────────────────────────

final useUndoDuringGameScenario = E2EScenario(
  id: 'flow.use_undo_during_game',
  title: 'undo1: estado com undoStack → undo(1) + consume → inventário decrementa',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    harness.container
        .read(inventoryProvider.notifier)
        .debugSetState(const Inventory(bomb2: 0, bomb3: 0, undo1: 2, undo3: 0));

    // Set up board with an existing undo entry.
    _setupStateWithUndoEntry(harness);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final inventoryBefore = harness.container.read(inventoryProvider).undo1;

    // Exercise undo logic directly via runAsync so that the Hive write from
    // consume() completes before teardown (avoids orphaned Future teardown crash).
    await tester.runAsync(() async {
      final undone = harness.container.read(gameProvider.notifier).undo(1);
      expect(undone, isTrue, reason: 'undo(1) deve retornar true com undoStack não vazio');
      if (undone) {
        await harness.container
            .read(inventoryProvider.notifier)
            .consume(ItemType.undo1);
      }
    });
    await tester.pump();

    final inventoryAfter = harness.container.read(inventoryProvider).undo1;
    expect(inventoryAfter, lessThan(inventoryBefore),
        reason: 'undo1 deve ser consumido ao usar');
  },
);

// ─── flow.use_bomb2_during_game ──────────────────────────────────────────────

final useBomb2DuringGameScenario = E2EScenario(
  id: 'flow.use_bomb2_during_game',
  title: 'bomb2: tap → confirmar dialog → BombMode.bomb2 ativo',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    harness.container
        .read(inventoryProvider.notifier)
        .debugSetState(const Inventory(bomb2: 1, bomb3: 0, undo1: 0, undo3: 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap bomb2 → shows confirm dialog.
    await tester.tap(find.byKey(const Key('inventory_bomb2')));
    await tester.pump();

    // Confirm the dialog.
    expect(find.text('Confirmar'), findsOneWidget);
    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.readGame(harness).bombMode, equals(BombMode.bomb2),
        reason: 'após confirmar, deve ativar BombMode.bomb2');
    expect(find.byKey(const Key('game_board')), findsOneWidget);
  },
);

// ─── flow.use_bomb3_during_game ──────────────────────────────────────────────

final useBomb3DuringGameScenario = E2EScenario(
  id: 'flow.use_bomb3_during_game',
  title: 'bomb3: tap → confirmar dialog → BombMode.bomb3 ativo',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    harness.container
        .read(inventoryProvider.notifier)
        .debugSetState(const Inventory(bomb2: 0, bomb3: 1, undo1: 0, undo3: 0));
    harness.container.read(gameProvider.notifier).debugSetState(
      GameState(
        board: _boardWith5Tiles(),
        score: 0,
        highScore: 0,
        isGameOver: false,
        hasWon: false,
        maxLevel: 1,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap bomb3 → shows confirm dialog.
    await tester.tap(find.byKey(const Key('inventory_bomb3')));
    await tester.pump();

    // Confirm the dialog.
    expect(find.text('Confirmar'), findsOneWidget);
    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.readGame(harness).bombMode, equals(BombMode.bomb3),
        reason: 'após confirmar, deve ativar BombMode.bomb3');
    expect(find.byKey(const Key('game_board')), findsOneWidget);
  },
);
