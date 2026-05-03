class PersonalRecords {
  static const int hiveTypeId = 10;

  final int timesReached2048;
  final int timesReached4096;
  final int timesReached8192;
  final DateTime? firstReached2048At;
  final DateTime? firstReached4096At;
  final DateTime? firstReached8192At;
  final bool rewardCollected4096;
  final bool rewardCollected8192;

  const PersonalRecords({
    this.timesReached2048 = 0,
    this.timesReached4096 = 0,
    this.timesReached8192 = 0,
    this.firstReached2048At,
    this.firstReached4096At,
    this.firstReached8192At,
    this.rewardCollected4096 = false,
    this.rewardCollected8192 = false,
  });

  static const _sentinel = Object();

  PersonalRecords copyWith({
    int? timesReached2048,
    int? timesReached4096,
    int? timesReached8192,
    Object? firstReached2048At = _sentinel,
    Object? firstReached4096At = _sentinel,
    Object? firstReached8192At = _sentinel,
    bool? rewardCollected4096,
    bool? rewardCollected8192,
  }) {
    return PersonalRecords(
      timesReached2048: timesReached2048 ?? this.timesReached2048,
      timesReached4096: timesReached4096 ?? this.timesReached4096,
      timesReached8192: timesReached8192 ?? this.timesReached8192,
      firstReached2048At: firstReached2048At == _sentinel
          ? this.firstReached2048At
          : firstReached2048At as DateTime?,
      firstReached4096At: firstReached4096At == _sentinel
          ? this.firstReached4096At
          : firstReached4096At as DateTime?,
      firstReached8192At: firstReached8192At == _sentinel
          ? this.firstReached8192At
          : firstReached8192At as DateTime?,
      rewardCollected4096: rewardCollected4096 ?? this.rewardCollected4096,
      rewardCollected8192: rewardCollected8192 ?? this.rewardCollected8192,
    );
  }
}
