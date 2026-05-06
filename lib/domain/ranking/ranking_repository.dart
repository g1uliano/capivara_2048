import 'weekly_reward_result.dart';

enum RankingType { globalTime, globalScore, legends4096Time, legends8192Count }

class RankingEntry {
  final int rank;
  final String playerName;
  final String? userId;
  final int value;
  final bool isLocalPlayer;

  const RankingEntry({
    required this.rank,
    required this.playerName,
    this.userId,
    required this.value,
    this.isLocalPlayer = false,
  });
}

abstract class RankingRepository {
  Future<List<RankingEntry>> getWeeklyTop(RankingType type);
  Future<RankingEntry?> getPlayerEntry(RankingType type);
  Future<void> submitScore(RankingType type, int value, {String? displayName});
  Future<WeeklyRewardResult?> checkAndClaimWeeklyReward(String weekId);
  Stream<List<RankingEntry>> watchWeeklyTop(RankingType type);
}
