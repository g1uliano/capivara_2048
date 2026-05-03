class GameRecord {
  static const int hiveTypeId = 11;

  final DateTime playedAt;
  final int elapsedMs;
  final int score;
  final int maxLevel;

  const GameRecord({
    required this.playedAt,
    required this.elapsedMs,
    required this.score,
    required this.maxLevel,
  });
}
