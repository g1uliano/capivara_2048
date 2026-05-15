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
  // True only while the game-over item overlay is shown (set on first transition
  // to game-over; never persisted so loading a saved game-over state won't re-show).
  final bool isAwaitingGameOverResolution;
  // True when player tapped "Usar item" and is now selecting from InventoryBar.
  // Suppresses GameOverModal while keeping the board interactive.
  final bool isContinuingWithItem;
  final int? pendingMilestone;   // 11, 12 ou 13 — dispara VictoryChoiceDialog
  final int? bestTimeMs2048;     // elapsedMs capturado ao atingir nível 11
  final int? bestTimeMs4096;     // elapsedMs capturado ao atingir nível 12

  static const _bombSentinel = Object();

  Map<String, dynamic> toJson() {
    final boardJson = board
        .map((row) => row.map((tile) => tile?.toJson()).toList())
        .toList();
    return {
      'board': boardJson,
      'score': score,
      'highScore': highScore,
      'maxLevel': maxLevel,
      'elapsedMs': elapsedMs,
      'isGameOver': isGameOver,
      'hasWon': hasWon,
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    final rawBoard = json['board'] as List<dynamic>;
    final board = rawBoard.map((rawRow) {
      final row = rawRow as List<dynamic>;
      return row.map((cell) {
        if (cell == null) return null;
        return Tile.fromJson(cell as Map<String, dynamic>);
      }).toList();
    }).toList();

    return GameState(
      board: board,
      score: json['score'] as int,
      highScore: json['highScore'] as int,
      maxLevel: (json['maxLevel'] as int?) ?? 0,
      elapsedMs: (json['elapsedMs'] as int?) ?? 0,
      isGameOver: (json['isGameOver'] as bool?) ?? false,
      hasWon: (json['hasWon'] as bool?) ?? false,
      isPaused: true, // always paused on restore
    );
  }

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
    this.isAwaitingGameOverResolution = false,
    this.isContinuingWithItem = false,
    this.pendingMilestone,
    this.bestTimeMs2048,
    this.bestTimeMs4096,
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
    bool? isAwaitingGameOverResolution,
    bool? isContinuingWithItem,
    Object? pendingMilestone = _bombSentinel,
    Object? bestTimeMs2048 = _bombSentinel,
    Object? bestTimeMs4096 = _bombSentinel,
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
      isAwaitingGameOverResolution: isAwaitingGameOverResolution ?? this.isAwaitingGameOverResolution,
      isContinuingWithItem: isContinuingWithItem ?? this.isContinuingWithItem,
      pendingMilestone: pendingMilestone == _bombSentinel
          ? this.pendingMilestone
          : pendingMilestone as int?,
      bestTimeMs2048: bestTimeMs2048 == _bombSentinel
          ? this.bestTimeMs2048
          : bestTimeMs2048 as int?,
      bestTimeMs4096: bestTimeMs4096 == _bombSentinel
          ? this.bestTimeMs4096
          : bestTimeMs4096 as int?,
    );
  }
}
