enum RankingType { globalTime, globalScore, legends4096Time, legends8192Count }

class RankingEntry {
  final int rank;
  final String playerName;
  final int value;
  final bool isLocalPlayer;

  const RankingEntry({
    required this.rank,
    required this.playerName,
    required this.value,
    required this.isLocalPlayer,
  });
}

abstract class RankingRepository {
  Future<List<RankingEntry>> getWeeklyTop(RankingType type);
  Future<RankingEntry?> getPlayerEntry(RankingType type);
  Future<void> submitScore(RankingType type, int value);
}
