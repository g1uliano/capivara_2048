import 'tile.dart';

class GameState {
  final List<List<Tile?>> board;
  final int score;
  final int highScore;
  final bool isGameOver;
  final bool hasWon;

  const GameState({
    required this.board,
    required this.score,
    required this.highScore,
    required this.isGameOver,
    required this.hasWon,
  });

  GameState copyWith({
    List<List<Tile?>>? board,
    int? score,
    int? highScore,
    bool? isGameOver,
    bool? hasWon,
  }) {
    return GameState(
      board: board ?? this.board,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      isGameOver: isGameOver ?? this.isGameOver,
      hasWon: hasWon ?? this.hasWon,
    );
  }
}
