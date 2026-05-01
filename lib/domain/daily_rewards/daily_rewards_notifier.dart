import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/daily_rewards_state.dart';
import '../../data/models/item_type.dart';
import '../../data/repositories/daily_rewards_repository.dart';
import '../inventory/inventory_notifier.dart';
import '../lives/lives_notifier.dart';
import 'daily_rewards_engine.dart';

class DailyRewardsNotifier extends StateNotifier<DailyRewardsState> {
  DailyRewardsNotifier(this._repo, this._ref) : super(DailyRewardsState.initial());

  final DailyRewardsRepository _repo;
  final Ref _ref;

  Future<void> load() async {
    state = await _repo.load();
  }

  DailyRewardStatus get status => computeDailyRewardStatus(DateTime.now(), state);

  Future<void> claim(DateTime now) async {
    final s = computeDailyRewardStatus(now, state);
    final claimable = s == DailyRewardStatus.available ||
        s == DailyRewardStatus.streakBroken ||
        s == DailyRewardStatus.cycleCompleted;
    if (!claimable) return;

    var current = state;
    if (s == DailyRewardStatus.streakBroken || s == DailyRewardStatus.cycleCompleted) {
      current = applyStreakReset(current);
    }

    final reward = rewardForDay(current.currentDay);

    if (reward.lives > 0) await _ref.read(livesProvider.notifier).addEarned(reward.lives);
    if (reward.undo1 > 0) await _ref.read(inventoryProvider.notifier).add(ItemType.undo1, reward.undo1);
    if (reward.bomb2 > 0) await _ref.read(inventoryProvider.notifier).add(ItemType.bomb2, reward.bomb2);

    final next = applyClaim(now, current);
    state = next;
    await _repo.save(state);
  }

  Future<void> claimDouble(DailyReward original) async {
    if (original.lives > 0) await _ref.read(livesProvider.notifier).addEarned(original.lives);
    if (original.undo1 > 0) await _ref.read(inventoryProvider.notifier).add(ItemType.undo1, original.undo1);
    if (original.bomb2 > 0) await _ref.read(inventoryProvider.notifier).add(ItemType.bomb2, original.bomb2);
  }

  void debugSetState(DailyRewardsState s) => state = s;
}

final dailyRewardsRepositoryProvider = Provider<DailyRewardsRepository>(
  (_) => DailyRewardsRepository(),
);

final dailyRewardsProvider = StateNotifierProvider<DailyRewardsNotifier, DailyRewardsState>(
  (ref) => DailyRewardsNotifier(ref.read(dailyRewardsRepositoryProvider), ref),
);
