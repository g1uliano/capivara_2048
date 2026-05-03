import 'package:capivara_2048/core/constants/game_constants.dart';
import 'package:capivara_2048/data/animals_data.dart';
import 'package:capivara_2048/domain/game_engine/direction.dart';
import 'package:capivara_2048/domain/game_engine/game_engine.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:test/test.dart';

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

  group('undoStack', () {
    test('move pushes previous state onto undoStack', () {
      final state = _stateWithBoard([
        [1, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final after = engine.move(state, Direction.right);
      // move changed something, undoStack should have 1 entry
      expect(after.undoStack.length, 1);
      expect(after.undoStack[0].score, state.score);
    });

    test('no-op move does not push to undoStack', () {
      final state = _stateWithBoard([
        [1, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final after = engine.move(state, Direction.left); // already leftmost
      expect(after.undoStack.length, 0);
    });

    test('undoStack caps at 3', () {
      GameState state = _stateWithBoard([
        [1, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      for (int i = 0; i < 6; i++) {
        final next = engine.move(state, Direction.right);
        if (next.board != state.board) state = next;
        final next2 = engine.move(state, Direction.left);
        if (next2.board != state.board) state = next2;
      }
      expect(state.undoStack.length, lessThanOrEqualTo(3));
    });
  });

  group('removeTiles', () {
    test('removeTiles clears specified positions', () {
      final board = List.generate(
          4, (r) => List.generate(4, (c) => Tile(id: 'id_$r$c', level: 2, row: r, col: c)));
      final state = GameState(
        board: board,
        score: 0,
        highScore: 0,
        isGameOver: false,
        hasWon: false,
      );
      final result = GameEngine.removeTiles(state, [(0, 0), (1, 1)]);
      expect(result.board[0][0], isNull);
      expect(result.board[1][1], isNull);
      expect(result.board[0][1]?.level, 2); // untouched
    });

    test('removeTiles does not modify original state', () {
      final board = List.generate(
          4, (r) => List.generate(4, (c) => Tile(id: 'id_$r$c', level: 2, row: r, col: c)));
      final state = GameState(
        board: board,
        score: 0,
        highScore: 0,
        isGameOver: false,
        hasWon: false,
      );
      GameEngine.removeTiles(state, [(0, 0)]);
      expect(state.board[0][0], isNotNull); // original unchanged
    });
  });

  group('vitória múltipla — _checkWin desativado', () {
    test('merge que gera nível 11 não seta hasWon', () {
      final engine = GameEngine();
      final board = List.generate(4, (r) => List<Tile?>.filled(4, null));
      board[0][2] = const Tile(id: 'a', level: 10, row: 0, col: 2);
      board[0][3] = const Tile(id: 'b', level: 10, row: 0, col: 3);
      final state = GameState(
        board: board, score: 0, highScore: 0, isGameOver: false, hasWon: false,
      );
      final next = engine.move(state, Direction.left);
      expect(next.hasWon, false);
      expect(next.maxLevel, 11);
    });

    test('merge que gera nível 12 não seta hasWon', () {
      final engine = GameEngine();
      final board = List.generate(4, (r) => List<Tile?>.filled(4, null));
      board[0][2] = const Tile(id: 'a', level: 11, row: 0, col: 2);
      board[0][3] = const Tile(id: 'b', level: 11, row: 0, col: 3);
      final state = GameState(
        board: board, score: 0, highScore: 0, isGameOver: false, hasWon: false,
      );
      final next = engine.move(state, Direction.left);
      expect(next.hasWon, false);
      expect(next.maxLevel, 12);
    });

    test('merge que gera nível 13 não seta hasWon', () {
      final engine = GameEngine();
      final board = List.generate(4, (r) => List<Tile?>.filled(4, null));
      board[0][2] = const Tile(id: 'a', level: 12, row: 0, col: 2);
      board[0][3] = const Tile(id: 'b', level: 12, row: 0, col: 3);
      final state = GameState(
        board: board, score: 0, highScore: 0, isGameOver: false, hasWon: false,
      );
      final next = engine.move(state, Direction.left);
      expect(next.hasWon, false);
      expect(next.maxLevel, 13);
    });
  });

  group('animals nível 12 e 13', () {
    test('animalForLevel(12) retorna Peixe-boi', () {
      final animal = animalForLevel(12);
      expect(animal.name, 'Peixe-boi');
      expect(animal.value, 4096);
      expect(animal.level, 12);
    });

    test('animalForLevel(13) retorna Jacaré', () {
      final animal = animalForLevel(13);
      expect(animal.name, 'Jacaré');
      expect(animal.value, 8192);
      expect(animal.level, 13);
    });

    test('GameConstants.maxLevel é 13', () {
      expect(GameConstants.maxLevel, 13);
    });
  });

  group('maxLevel tracking', () {
    test('maxLevel starts at 1 on newGame', () {
      final state = engine.newGame();
      expect(state.maxLevel, 1);
    });

    test('maxLevel updates after merge', () {
      final state = _stateWithBoard([
        [1, 1, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.left);
      expect(next.maxLevel, greaterThanOrEqualTo(2));
    });

    test('maxLevel reflects highest tile on board', () {
      final state = _stateWithBoard([
        [3, 3, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      final next = engine.move(state, Direction.left);
      // merge produces level 4; maxLevel should be >= 4
      expect(next.maxLevel, greaterThanOrEqualTo(4));
    });

    test('maxLevel does not decrease', () {
      var state = _stateWithBoard([
        [5, 5, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);
      state = engine.move(state, Direction.left); // produces level 6
      final levelAfterFirst = state.maxLevel;
      expect(levelAfterFirst, greaterThanOrEqualTo(6));

      // subsequent moves on a board with no matching tiles won't reduce maxLevel
      final next = engine.move(state, Direction.right);
      expect(next.maxLevel, greaterThanOrEqualTo(levelAfterFirst));
    });
  });
}

