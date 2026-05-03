import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../data/models/game_state.dart';
import '../../data/models/tile.dart';
import '../../core/constants/game_constants.dart';
import 'direction.dart';

class _MergeResult {
  final List<Tile?> row;
  final int gained;
  final bool changed;
  _MergeResult(this.row, this.gained, this.changed);
}

class GameEngine {
  final _uuid = const Uuid();
  final Random _random;

  // [random] is injectable for deterministic testing.
  GameEngine({Random? random}) : _random = random ?? Random();

  GameState newGame() {
    final board = List.generate(
      GameConstants.boardSize,
      (_) => List<Tile?>.filled(GameConstants.boardSize, null),
    );
    var state = GameState(
      board: board,
      score: 0,
      highScore: 0,
      isGameOver: false,
      hasWon: false,
      maxLevel: 1,
    );
    state = _spawnTile(state);
    state = _spawnTile(state);
    return state;
  }

  GameState move(GameState state, Direction dir) {
    if (state.isGameOver) return state;

    final rotated = _rotateBoard(state.board, dir);
    int totalGained = 0;
    bool anyChanged = false;

    final newBoard = rotated.map((row) {
      final result = _compactAndMerge(row);
      if (result.changed) anyChanged = true;
      totalGained += result.gained;
      return result.row;
    }).toList();

    if (!anyChanged) {
      final isOver = _checkGameOver(state.board);
      return state.copyWith(isGameOver: isOver);
    }

    final rawUnrotated = _unrotateBoard(newBoard, dir);
    final size = GameConstants.boardSize;
    final unrotated = List.generate(size, (r) =>
      List.generate(size, (c) {
        final t = rawUnrotated[r][c];
        return t != null ? t.copyWith(row: r, col: c) : null;
      })
    );
    final newScore = state.score + totalGained;
    final newHighScore = max(state.highScore, newScore);
    final hasWon = _checkWin(unrotated);

    int newMaxLevel = state.maxLevel;
    for (final row in unrotated) {
      for (final tile in row.whereType<Tile>()) {
        if (tile.level > newMaxLevel) newMaxLevel = tile.level;
      }
    }

    final newUndoStack = [state.copyWith(undoStack: []), ...state.undoStack.map((s) => s.copyWith(undoStack: []))].take(3).toList();

    var next = state.copyWith(
      board: unrotated,
      score: newScore,
      highScore: newHighScore,
      hasWon: hasWon,
      maxLevel: newMaxLevel,
      undoStack: newUndoStack,
    );

    next = _spawnTile(next);
    final isGameOver = _checkGameOver(next.board);
    return next.copyWith(isGameOver: isGameOver);
  }

  static GameState removeTiles(GameState state, List<(int, int)> positions) {
    final board = state.board.map((row) => List<Tile?>.from(row)).toList();
    for (final (r, c) in positions) {
      board[r][c] = null;
    }
    // Removing tiles always creates empty cells — the game is never over after a bomb.
    return state.copyWith(board: board, isGameOver: false);
  }

  _MergeResult _compactAndMerge(List<Tile?> row) {
    final original = List<Tile?>.from(row);
    final filtered = row.where((t) => t != null).cast<Tile>().toList();
    final merged = <Tile?>[];
    int gained = 0;
    int i = 0;

    while (i < filtered.length) {
      if (i + 1 < filtered.length &&
          filtered[i].level == filtered[i + 1].level) {
        final newLevel = filtered[i].level + 1;
        gained += _valueForLevel(newLevel);
        merged.add(Tile(
          id: _uuid.v4(),
          level: newLevel,
          row: filtered[i].row,
          col: filtered[i].col,
          justMerged: true,
        ));
        i += 2;
      } else {
        merged.add(filtered[i].copyWith(isNew: false, justMerged: false));
        i++;
      }
    }

    while (merged.length < GameConstants.boardSize) {
      merged.add(null);
    }

    final changed = !_boardRowEquals(original, merged);
    return _MergeResult(merged, gained, changed);
  }

  bool _boardRowEquals(List<Tile?> a, List<Tile?> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i]?.level != b[i]?.level) return false;
    }
    return true;
  }

  List<List<Tile?>> _rotateBoard(List<List<Tile?>> board, Direction dir) {
    switch (dir) {
      case Direction.left:
        return board;
      case Direction.right:
        return board.map((row) => row.reversed.toList()).toList();
      case Direction.up:
        return _transpose(board);
      case Direction.down:
        return _transpose(board).map((row) => row.reversed.toList()).toList();
    }
  }

  List<List<Tile?>> _unrotateBoard(List<List<Tile?>> board, Direction dir) {
    switch (dir) {
      case Direction.left:
        return board;
      case Direction.right:
        return board.map((row) => row.reversed.toList()).toList();
      case Direction.up:
        return _transpose(board);
      case Direction.down:
        return _transpose(board.map((row) => row.reversed.toList()).toList());
    }
  }

  List<List<Tile?>> _transpose(List<List<Tile?>> board) {
    final size = GameConstants.boardSize;
    return List.generate(
      size,
      (r) => List.generate(size, (c) => board[c][r]),
    );
  }

  GameState _spawnTile(GameState state) {
    final empty = <(int, int)>[];
    for (int r = 0; r < GameConstants.boardSize; r++) {
      for (int c = 0; c < GameConstants.boardSize; c++) {
        if (state.board[r][c] == null) empty.add((r, c));
      }
    }
    if (empty.isEmpty) return state;

    final pos = empty[_random.nextInt(empty.length)];
    final level = _random.nextDouble() < GameConstants.newTileLevel2Probability
        ? 2
        : 1;

    final newBoard = state.board
        .map((row) => List<Tile?>.from(row))
        .toList();
    newBoard[pos.$1][pos.$2] = Tile(
      id: _uuid.v4(),
      level: level,
      row: pos.$1,
      col: pos.$2,
      isNew: true,
    );

    return state.copyWith(board: newBoard);
  }

  bool _checkGameOver(List<List<Tile?>> board) {
    for (final row in board) {
      if (row.any((t) => t == null)) return false;
    }
    final size = GameConstants.boardSize;
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final level = board[r][c]!.level;
        if (c + 1 < size && board[r][c + 1]?.level == level) return false;
        if (r + 1 < size && board[r + 1][c]?.level == level) return false;
      }
    }
    return true;
  }

  bool _checkWin(List<List<Tile?>> board) {
    return false; // Vitória detectada pelo GameNotifier via pendingMilestone
  }

  int _valueForLevel(int level) => (1 << level);
}
