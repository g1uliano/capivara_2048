// lib/presentation/controllers/game_notifier.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_record.dart';
import '../../data/models/game_state.dart';
import '../../data/models/item_type.dart';
import '../../data/repositories/game_record_repository.dart';
import '../../domain/game_engine/bomb_mode.dart';
import '../../domain/game_engine/direction.dart';
import '../../domain/game_engine/game_engine.dart';
import '../../domain/inventory/inventory_notifier.dart';
import '../controllers/personal_records_notifier.dart';

class GameNotifier extends StateNotifier<GameState> {
  final GameEngine _engine;
  final Ref _ref;
  Timer? _timer;
  bool _timerStarted = false;
  List<(int, int)> _bombSelection = [];
  ItemType? _pendingBombItem;
  // Called on confirm to deduct the item; null-safe so tests don't need Hive.
  void Function(ItemType)? _consumeItem;
  final Set<int> _reachedMilestones = {};

  GameNotifier(this._engine, this._ref) : super(_engine.newGame());

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
    // Set isAwaitingGameOverResolution only on first transition to game-over
    final justLost = !before.isGameOver && after.isGameOver && !after.hasWon;
    state = justLost
        ? after.copyWith(isAwaitingGameOverResolution: true)
        : after.isGameOver
            ? after
            : after.copyWith(isContinuingWithItem: false);

    if (justLost) {
      unawaited(_saveGameRecord()); // fire-and-forget
    }

    // Detectar novos marcos
    for (final milestone in [11, 12, 13]) {
      if (!_reachedMilestones.contains(milestone) &&
          state.maxLevel >= milestone &&
          !state.hasWon &&
          state.pendingMilestone == null) {
        _reachedMilestones.add(milestone);
        final captured = state.elapsedMs;
        GameState updated = state;
        if (milestone == 11) {
          updated = updated.copyWith(
            pendingMilestone: milestone,
            bestTimeMs2048: captured,
          );
        } else if (milestone == 12) {
          updated = updated.copyWith(
            pendingMilestone: milestone,
            bestTimeMs4096: captured,
          );
        } else {
          updated = updated.copyWith(pendingMilestone: milestone);
        }
        state = updated;
        unawaited(_ref
            .read(personalRecordsProvider.notifier)
            .recordMilestone(milestone, DateTime.now()));
        break; // Apenas um marco por vez
      }
    }

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
    if (state.isGameOver || state.hasWon || state.pendingMilestone != null) return;
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
    _reachedMilestones.clear();
    _stopTimer();
    _timerStarted = false;
    final fresh = _engine.newGame();
    state = fresh.copyWith(
      elapsedMs: 0,
      isPaused: false,
    );
  }

  void setAwaitingResolution(bool value) {
    state = state.copyWith(isAwaitingGameOverResolution: value);
  }

  void startContinueWithItem() {
    state = state.copyWith(
      isAwaitingGameOverResolution: false,
      isContinuingWithItem: true,
    );
  }

  void cancelContinueWithItem() {
    state = state.copyWith(
      isContinuingWithItem: false,
      isAwaitingGameOverResolution: false,
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
    if (item != null) _consumeItem?.call(item);
    state = newState.copyWith(
      bombMode: null,
      selectedBombTiles: const [],
      isContinuingWithItem: false,
      isAwaitingGameOverResolution: false,
    );
  }

  void cancelBomb() {
    final wasContinuing = state.isContinuingWithItem;
    _bombSelection = [];
    _pendingBombItem = null;
    if (wasContinuing) {
      // Return to the "use item?" overlay so the player can pick a different item.
      state = state.copyWith(
        bombMode: null,
        selectedBombTiles: const [],
        isContinuingWithItem: false,
        isAwaitingGameOverResolution: true,
      );
    } else {
      state = state.copyWith(bombMode: null, selectedBombTiles: const []);
    }
  }

  List<(int, int)> get bombSelection => List.unmodifiable(_bombSelection);

  /// Wired up by the provider factory; not called in unit tests.
  void setConsumeCallback(void Function(ItemType) callback) {
    _consumeItem = callback;
  }

  void dismissMilestone() {
    state = state.copyWith(pendingMilestone: null);
  }

  Future<void> endGame() async {
    _stopTimer();
    state = state.copyWith(hasWon: true, pendingMilestone: null);
    await _saveGameRecord();
  }

  Future<void> _saveGameRecord() async {
    try {
      final record = GameRecord(
        playedAt: DateTime.now(),
        elapsedMs: state.elapsedMs,
        score: state.score,
        maxLevel: state.maxLevel,
      );
      await _ref.read(gameRecordRepositoryProvider).add(record);
    } catch (_) {
      // Não bloquear o jogo se o save falhar
    }
  }

  @visibleForTesting
  void setStateForTest(GameState s) => state = s;

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

final gameEngineProvider = Provider<GameEngine>((ref) => GameEngine());

final gameProvider = StateNotifierProvider<GameNotifier, GameState>(
  (ref) {
    final notifier = GameNotifier(ref.read(gameEngineProvider), ref);
    notifier.setConsumeCallback(
      (type) => ref.read(inventoryProvider.notifier).consume(type),
    );
    return notifier;
  },
);
