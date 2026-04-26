// lib/presentation/controllers/game_notifier.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_state.dart';
import '../../data/models/item_type.dart';
import '../../domain/game_engine/bomb_mode.dart';
import '../../domain/game_engine/direction.dart';
import '../../domain/game_engine/game_engine.dart';
import '../../domain/inventory/inventory_notifier.dart';

class GameNotifier extends StateNotifier<GameState> {
  final GameEngine _engine;
  Timer? _timer;
  bool _timerStarted = false;
  List<(int, int)> _bombSelection = [];
  ItemType? _pendingBombItem;
  // Called on confirm to deduct the item; null-safe so tests don't need Hive.
  void Function(ItemType)? _consumeItem;

  GameNotifier(this._engine) : super(_engine.newGame());

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!state.isPaused && !state.isGameOver) {
        state = state.copyWith(elapsedMs: state.elapsedMs + 100);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void onSwipe(Direction dir) {
    if (state.isGameOver || state.isPaused) return;
    final before = state;
    final after = _engine.move(state, dir);
    // Detect if anything changed on the board (a valid move)
    final boardChanged = after.score != before.score ||
        after.isGameOver != before.isGameOver ||
        after.hasWon != before.hasWon ||
        _boardDiffers(before.board, after.board);
    state = after;
    if (boardChanged) {
      if (!_timerStarted) {
        _timerStarted = true;
        _startTimer();
      }
      if (state.isGameOver || state.hasWon) {
        _stopTimer();
      }
    }
  }

  bool _boardDiffers(List<List<dynamic>> a, List<List<dynamic>> b) {
    for (int r = 0; r < a.length; r++) {
      for (int c = 0; c < a[r].length; c++) {
        if (a[r][c]?.level != b[r][c]?.level) return true;
      }
    }
    return false;
  }

  void pause() {
    if (state.isGameOver || state.hasWon) return;
    _stopTimer();
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    if (!state.isPaused) return;
    state = state.copyWith(isPaused: false);
    if (_timerStarted && !state.isGameOver && !state.hasWon) _startTimer();
  }

  bool undo(int steps) {
    final stack = state.undoStack;
    if (stack.isEmpty) return false;
    final idx = (steps - 1).clamp(0, stack.length - 1);
    state = stack[idx];
    return true;
  }

  void restart() {
    _stopTimer();
    _timerStarted = false;
    final fresh = _engine.newGame();
    state = fresh.copyWith(
      elapsedMs: 0,
      isPaused: false,
      maxLevel: 0,
    );
  }

  void enterBombMode(BombMode mode, ItemType itemType) {
    _bombSelection = [];
    _pendingBombItem = itemType;
    state = state.copyWith(bombMode: mode, selectedBombTiles: const []);
  }

  void selectBombTile(int row, int col) {
    final mode = state.bombMode;
    if (mode == null) return;
    final maxTiles = mode == BombMode.bomb2 ? 2 : 3;

    final pos = (row, col);
    if (_bombSelection.contains(pos)) {
      _bombSelection = _bombSelection.where((p) => p != pos).toList();
    } else if (_bombSelection.length < maxTiles) {
      _bombSelection = [..._bombSelection, pos];
      if (_bombSelection.length == maxTiles) {
        confirmBomb();
        return;
      }
    }
    // Emit updated selection so overlay rebuilds on intermediate selections
    state = state.copyWith(
      selectedBombTiles: List.unmodifiable(_bombSelection),
    );
  }

  void confirmBomb() {
    final mode = state.bombMode;
    if (mode == null || _bombSelection.isEmpty) {
      cancelBomb();
      return;
    }
    final newState = GameEngine.removeTiles(state, _bombSelection);
    _bombSelection = [];
    final item = _pendingBombItem;
    _pendingBombItem = null;
    // Consume the item only after successful confirmation
    if (item != null) _consumeItem?.call(item);
    state = newState.copyWith(bombMode: null, selectedBombTiles: const []);
  }

  void cancelBomb() {
    _bombSelection = [];
    _pendingBombItem = null;
    state = state.copyWith(bombMode: null, selectedBombTiles: const []);
  }

  List<(int, int)> get bombSelection => List.unmodifiable(_bombSelection);

  /// Wired up by the provider factory; not called in unit tests.
  void setConsumeCallback(void Function(ItemType) callback) {
    _consumeItem = callback;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

final gameEngineProvider = Provider<GameEngine>((ref) => GameEngine());

final gameProvider = StateNotifierProvider<GameNotifier, GameState>(
  (ref) {
    final notifier = GameNotifier(ref.read(gameEngineProvider));
    notifier.setConsumeCallback(
      (type) => ref.read(inventoryProvider.notifier).consume(type),
    );
    return notifier;
  },
);
