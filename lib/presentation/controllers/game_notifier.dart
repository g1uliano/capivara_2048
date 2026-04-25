// lib/presentation/controllers/game_notifier.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_state.dart';
import '../../domain/game_engine/direction.dart';
import '../../domain/game_engine/game_engine.dart';

class GameNotifier extends StateNotifier<GameState> {
  final GameEngine _engine;
  Timer? _timer;
  bool _timerStarted = false;

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
    if (state.isGameOver) return;
    _stopTimer();
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    if (!state.isPaused) return;
    state = state.copyWith(isPaused: false);
    if (_timerStarted) _startTimer();
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

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

final gameEngineProvider = Provider<GameEngine>((ref) => GameEngine());

final gameProvider = StateNotifierProvider<GameNotifier, GameState>(
  (ref) => GameNotifier(ref.read(gameEngineProvider)),
);
