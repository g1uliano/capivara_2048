import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ranking_provider.dart';
import '../../domain/ranking/ranking_repository.dart';
import '../../domain/ranking/week_id.dart';
import '../../domain/ranking/weekly_reward_result.dart';

class RankingController extends StateNotifier<AsyncValue<WeeklyRewardResult?>> {
  RankingController(this._repository) : super(const AsyncValue.data(null));

  final RankingRepository _repository;

  /// Called on app startup to check and claim any pending weekly reward.
  Future<WeeklyRewardResult?> checkWeeklyReward() async {
    state = const AsyncValue.loading();
    try {
      final currentWeekId = WeekId.fromUtc(DateTime.now().toUtc());
      final reward = await _repository.checkAndClaimWeeklyReward(currentWeekId);
      state = AsyncValue.data(reward);
      return reward;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void clearReward() => state = const AsyncValue.data(null);
}

final rankingControllerProvider =
    StateNotifierProvider<RankingController, AsyncValue<WeeklyRewardResult?>>(
  (ref) => RankingController(ref.watch(rankingRepositoryProvider)),
);
