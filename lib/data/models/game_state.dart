import 'tile.dart';
import '../../domain/game_engine/bomb_mode.dart';

class GameState {
  final List<List<Tile?>> board;
  final int score;
  final int highScore;
  final bool isGameOver;
  final bool hasWon;
  final int maxLevel;
  final int elapsedMs;
  final bool isPaused;
  final List<GameState> undoStack;
  final BombMode? bombMode;
  // Transient — excluded from ==/hashCode; reset whenever bomb mode exits.
  final List<(int, int)> selectedBombTiles;

  static const _bombSentinel = Object();

  GameState({
    required this.board,
    required this.score,
    required this.highScore,
    required this.isGameOver,
    required this.hasWon,
    this.maxLevel = 0,
    this.elapsedMs = 0,
    this.isPaused = false,
    List<GameState>? undoStack,
    this.bombMode,
    this.selectedBombTiles = const [],
  }) : undoStack = List.unmodifiable(undoStack ?? const []);

  GameState copyWith({
    List<List<Tile?>>? board,
    int? score,
    int? highScore,
    bool? isGameOver,
    bool? hasWon,
    int? maxLevel,
    int? elapsedMs,
    bool? isPaused,
    List<GameState>? undoStack,
    Object? bombMode = _bombSentinel,
    List<(int, int)>? selectedBombTiles,
  }) {
    return GameState(
      board: board ?? this.board,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      isGameOver: isGameOver ?? this.isGameOver,
      hasWon: hasWon ?? this.hasWon,
      maxLevel: maxLevel ?? this.maxLevel,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      isPaused: isPaused ?? this.isPaused,
      undoStack: undoStack ?? this.undoStack,
      bombMode: bombMode == _bombSentinel ? this.bombMode : bombMode as BombMode?,
      selectedBombTiles: selectedBombTiles ?? this.selectedBombTiles,
    );
  }
}
