import '../../data/models/daily_rewards_state.dart';

enum DailyRewardStatus {
  available,
  alreadyClaimed,
  streakBroken,
  cycleCompleted,
}

class DailyReward {
  final int lives;
  final int undo1;
  final int bomb2;

  const DailyReward({
    required this.lives,
    required this.undo1,
    required this.bomb2,
  });
}

const List<DailyReward> kDailyRewards = [
  DailyReward(lives: 0, undo1: 1, bomb2: 0), // Dia 1
  DailyReward(lives: 0, undo1: 0, bomb2: 1), // Dia 2
  DailyReward(lives: 1, undo1: 0, bomb2: 0), // Dia 3
  DailyReward(lives: 0, undo1: 2, bomb2: 0), // Dia 4
  DailyReward(lives: 0, undo1: 0, bomb2: 2), // Dia 5
  DailyReward(lives: 2, undo1: 0, bomb2: 0), // Dia 6
  DailyReward(lives: 2, undo1: 2, bomb2: 2), // Dia 7
];

DailyReward rewardForDay(int day) {
  assert(day >= 1 && day <= kDailyRewards.length, 'day must be 1–${kDailyRewards.length}');
  return kDailyRewards[day - 1];
}

DailyRewardStatus computeDailyRewardStatus(DateTime now, DailyRewardsState state) {
  final today = DateTime(now.year, now.month, now.day);
  final last = state.lastClaimedDate;

  if (today.isBefore(last)) return DailyRewardStatus.alreadyClaimed;

  final gap = today.difference(last).inDays;

  if (gap == 0) return DailyRewardStatus.alreadyClaimed;

  // gap >= 1
  if (!state.claimedThisCycle) return DailyRewardStatus.available;

  // claimedThisCycle == true
  if (gap >= 2) return DailyRewardStatus.streakBroken;

  // gap == 1 AND claimedThisCycle == true
  if (state.currentDay == 7) return DailyRewardStatus.cycleCompleted;
  return DailyRewardStatus.available;
}

DailyRewardsState applyStreakReset(DailyRewardsState state) {
  return state.copyWith(currentDay: 1, claimedThisCycle: false);
}

DailyRewardsState applyClaim(DateTime now, DailyRewardsState state) {
  final today = DateTime(now.year, now.month, now.day);
  final nextDay = state.currentDay < 7 ? state.currentDay + 1 : 7;
  // claimedThisCycle=true only when currentDay stays at 7 (Day 7 was claimed).
  // When advancing to a new day, claimedThisCycle=false (new slot not yet claimed).
  return state.copyWith(
    claimedThisCycle: nextDay == state.currentDay,
    lastClaimedDate: today,
    currentDay: nextDay,
  );
}
