import 'package:capivara_2048/domain/game_engine/direction.dart';
import 'package:capivara_2048/domain/game_engine/game_engine.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GameEngine engine;

  setUp(() {
    engine = GameEngine();
  });

  GameState _stateWithBoard(List<List<int?>> levels) {
    final board = List.generate(4, (r) =>
      List.generate(4, (c) {
        final lv = levels[r][c];
        if (lv == null) return null;
        return Tile(id: '$r$c', level: lv, row: r, col: c);
      })
    );
    return GameState(
      board: board,
      score: 0,
      highScore: 0,
      isGameOver: false,
      hasWon: false,
    );
  }

  int? _level(GameState s, int r, int c) => s.board[r][c]?.level;

  group('newGame', () {
    test('starts with exactly 2 tiles on board', () {
      final state = engine.newGame();
      final filled = state.board.expand((r) => r).where((t) => t != null).length;
      expect(filled, 2);
    });

    test('initial tiles are level 1 or 2', () {
      final state = engine.newGame();
      for (final tile in state.board.expand((r) => r).whereType<Tile>()) {
        expect(tile.level, anyOf(1, 2));
      }
    });

    test('starts with score 0', () {
      expect(engine.newGame().score, 0);
    });
  });

  group('compactAndMerge — move left', () {
    test('two equal tiles merge into one of next level', () {
      final state = _stateWithBoard([
        [1, 1, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.left);
      expect(_level(next, 0, 0), 2);
      // board[0][1] may hold the spawned tile — only check merge result
    });

    test('different tiles do not merge', () {
      final state = _stateWithBoard([
        [1, 2, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.left);
      expect(_level(next, 0, 0), 1);
      expect(_level(next, 0, 1), 2);
    });

    test('three equal tiles: first two merge, third stays', () {
      final state = _stateWithBoard([
        [1, 1, 1, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.left);
      expect(_level(next, 0, 0), 2);
      expect(_level(next, 0, 1), 1);
      // board[0][2] may hold the spawned tile — only check merge result
    });

    test('four equal tiles: two pairs merge', () {
      final state = _stateWithBoard([
        [1, 1, 1, 1],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.left);
      expect(_level(next, 0, 0), 2);
      expect(_level(next, 0, 1), 2);
      // board[0][2] and [0][3] may hold the spawned tile — only check merge result
    });

    test('tiles slide left filling gaps', () {
      final state = _stateWithBoard([
        [null, null, 1, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.left);
      expect(_level(next, 0, 0), 1);
      // board[0][1] may hold the spawned tile — only check that tile slid to col 0
    });
  });

  group('score', () {
    test('merge adds value of resulting tile to score', () {
      final state = _stateWithBoard([
        [1, 1, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.left);
      // level 2 = value 4
      expect(next.score, 4);
    });

    test('multiple merges in one move accumulate score', () {
      final state = _stateWithBoard([
        [1, 1, 1, 1],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.left);
      // two merges of level 2 = 4 + 4 = 8
      expect(next.score, 8);
    });

    test('highScore updates when score exceeds it', () {
      final state = _stateWithBoard([
        [1, 1, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]).copyWith(highScore: 2);
      final next = engine.move(state, Direction.left);
      expect(next.highScore, 4);
    });
  });

  group('directions', () {
    test('move right slides tiles to the right', () {
      final state = _stateWithBoard([
        [1, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.right);
      expect(_level(next, 0, 3), 1);
      // A new tile spawns after the move, so we only assert the tile reached col 3
    });

    test('move up slides tiles to the top', () {
      final state = _stateWithBoard([
        [null, null, null, null],
        [1,    null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.up);
      expect(_level(next, 0, 0), 1);
      // A new tile spawns after the move, so we only assert the tile reached row 0
    });

    test('move down slides tiles to the bottom', () {
      final state = _stateWithBoard([
        [1,    null, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.down);
      expect(_level(next, 3, 0), 1);
      // A new tile spawns after the move, so we only assert the tile reached row 3
    });

    test('move up merges equal tiles in same column', () {
      final state = _stateWithBoard([
        [1,    null, null, null],
        [1,    null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.up);
      expect(_level(next, 0, 0), 2);
    });
  });

  group('spawn', () {
    test('a new tile appears after a valid move', () {
      final state = _stateWithBoard([
        [1, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.right);
      final filled = next.board.expand((r) => r).where((t) => t != null).length;
      expect(filled, 2); // original tile moved + 1 new
    });

    test('no new tile spawns when move has no effect', () {
      final state = _stateWithBoard([
        [1, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.left); // already leftmost
      // tile still at 0,0 — board unchanged
      final filled = next.board.expand((r) => r).where((t) => t != null).length;
      expect(filled, 1);
    });
  });

  group('game over', () {
    test('isGameOver is true when board is full with no merges possible', () {
      // Checkerboard: no two adjacent tiles are equal
      final state = _stateWithBoard([
        [1, 2, 1, 2],
        [2, 1, 2, 1],
        [1, 2, 1, 2],
        [2, 1, 2, 1],
      ]);
      // Force isGameOver check by moving in any direction (board won't change)
      final next = engine.move(state, Direction.left);
      expect(next.isGameOver, isTrue);
    });

    test('isGameOver is false when empty cells exist', () {
      final state = _stateWithBoard([
        [1, 2, 1, 2],
        [2, 1, 2, 1],
        [1, 2, 1, 2],
        [2, 1, 2, null],
      ]);
      final next = engine.move(state, Direction.left);
      expect(next.isGameOver, isFalse);
    });
  });

  group('win condition', () {
    test('hasWon is true when a tile reaches level 11', () {
      final state = _stateWithBoard([
        [10, 10, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.left);
      expect(next.hasWon, isTrue);
    });

    test('hasWon stays false when max level not reached', () {
      final state = _stateWithBoard([
        [9, 9, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.left);
      expect(next.hasWon, isFalse);
    });
  });
}
