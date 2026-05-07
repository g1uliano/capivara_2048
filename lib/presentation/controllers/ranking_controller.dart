import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ranking_provider.dart';
import '../../domain/ranking/week_id.dart';
import '../../domain/ranking/weekly_reward_result.dart';

class RankingController extends AsyncNotifier<WeeklyRewardResult?> {
  @override
  Future<WeeklyRewardResult?> build() async => null;

  Future<WeeklyRewardResult?> checkWeeklyReward() async {
    state = const AsyncLoading();
    try {
      final currentWeekId = WeekId.fromUtc(DateTime.now().toUtc());
      final reward = await ref
          .read(rankingRepositoryProvider)
          .checkAndClaimWeeklyReward(currentWeekId);
      state = AsyncData(reward);
      return reward;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  void clearReward() => state = const AsyncData(null);
}

final rankingControllerProvider =
    AsyncNotifierProvider<RankingController, WeeklyRewardResult?>(
  RankingController.new,
);
