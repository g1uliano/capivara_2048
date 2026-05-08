class WeeklyRewardResult {
  final int position;
  final String weekId;
  final int lives;
  final int bomb3;
  final int bomb2;
  final int undo1;

  const WeeklyRewardResult({
    required this.position,
    required this.weekId,
    this.lives = 0,
    this.bomb3 = 0,
    this.bomb2 = 0,
    this.undo1 = 0,
  });

  bool get hasReward => lives > 0 || bomb3 > 0 || bomb2 > 0 || undo1 > 0;

  factory WeeklyRewardResult.forPosition(int position, {String weekId = 'unknown'}) {
    if (position == 1) {
      return WeeklyRewardResult(
        position: position, weekId: weekId,
        lives: 10, undo1: 10, bomb3: 10,
      );
    } else if (position == 2) {
      return WeeklyRewardResult(
        position: position, weekId: weekId,
        lives: 5, undo1: 5, bomb3: 5,
      );
    } else if (position == 3) {
      return WeeklyRewardResult(
        position: position, weekId: weekId,
        lives: 3, undo1: 3, bomb3: 3,
      );
    } else if (position >= 4 && position <= 6) {
      return WeeklyRewardResult(
        position: position, weekId: weekId,
        lives: 3, bomb3: 3,
      );
    } else if (position >= 7 && position <= 9) {
      return WeeklyRewardResult(
        position: position, weekId: weekId,
        lives: 3, undo1: 3,
      );
    } else if (position == 10) {
      return WeeklyRewardResult(
        position: position, weekId: weekId,
        lives: 3,
      );
    } else {
      return WeeklyRewardResult(position: position, weekId: weekId);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyRewardResult &&
          other.position == position &&
          other.weekId == weekId &&
          other.lives == lives &&
          other.bomb3 == bomb3 &&
          other.bomb2 == bomb2 &&
          other.undo1 == undo1;

  @override
  int get hashCode =>
      Object.hash(position, weekId, lives, bomb3, bomb2, undo1);

  WeeklyRewardResult copyWith({
    int? position,
    String? weekId,
    int? lives,
    int? bomb3,
    int? bomb2,
    int? undo1,
  }) {
    return WeeklyRewardResult(
      position: position ?? this.position,
      weekId: weekId ?? this.weekId,
      lives: lives ?? this.lives,
      bomb3: bomb3 ?? this.bomb3,
      bomb2: bomb2 ?? this.bomb2,
      undo1: undo1 ?? this.undo1,
    );
  }
}
