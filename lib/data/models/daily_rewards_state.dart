// lib/data/models/daily_rewards_state.dart

class DailyRewardsState {
  final int currentDay;
  final DateTime lastClaimedDate;
  final bool claimedThisCycle;

  const DailyRewardsState({
    required this.currentDay,
    required this.lastClaimedDate,
    required this.claimedThisCycle,
  });

  factory DailyRewardsState.initial() => DailyRewardsState(
        currentDay: 1,
        lastClaimedDate: DateTime(1970),
        claimedThisCycle: false,
      );

  DailyRewardsState copyWith({
    int? currentDay,
    DateTime? lastClaimedDate,
    bool? claimedThisCycle,
  }) {
    return DailyRewardsState(
      currentDay: currentDay ?? this.currentDay,
      lastClaimedDate: lastClaimedDate ?? this.lastClaimedDate,
      claimedThisCycle: claimedThisCycle ?? this.claimedThisCycle,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DailyRewardsState &&
      other.currentDay == currentDay &&
      other.lastClaimedDate == lastClaimedDate &&
      other.claimedThisCycle == claimedThisCycle;

  @override
  int get hashCode => Object.hash(currentDay, lastClaimedDate, claimedThisCycle);
}
