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

  Map<String, dynamic> toJson() => {
    'playedAt': playedAt.toIso8601String(),
    'elapsedMs': elapsedMs,
    'score': score,
    'maxLevel': maxLevel,
  };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
    playedAt: DateTime.parse(json['playedAt'] as String),
    elapsedMs: json['elapsedMs'] as int,
    score: json['score'] as int,
    maxLevel: json['maxLevel'] as int,
  );
}
