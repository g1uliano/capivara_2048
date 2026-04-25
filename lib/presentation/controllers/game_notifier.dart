// lib/presentation/controllers/game_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_state.dart';
import '../../domain/game_engine/direction.dart';
import '../../domain/game_engine/game_engine.dart';

class GameNotifier extends StateNotifier<GameState> {
  final GameEngine _engine;

  GameNotifier(this._engine) : super(_engine.newGame());

  void onSwipe(Direction dir) {
    if (state.isGameOver) return;
    state = _engine.move(state, dir);
  }

  void restart() {
    state = _engine.newGame();
  }
}

final gameEngineProvider = Provider<GameEngine>((ref) => GameEngine());

final gameProvider = StateNotifierProvider<GameNotifier, GameState>(
  (ref) => GameNotifier(ref.read(gameEngineProvider)),
);
