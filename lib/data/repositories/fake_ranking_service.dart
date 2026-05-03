import '../../domain/ranking/ranking_repository.dart';

class FakeRankingService implements RankingRepository {
  @override
  Future<List<RankingEntry>> getWeeklyTop(RankingType type) async {
    await Future.delayed(const Duration(milliseconds: 50));
    switch (type) {
      case RankingType.globalTime:
      case RankingType.legends4096Time:
        return [
          const RankingEntry(rank: 1, playerName: 'Marcos A.', value: 62000, isLocalPlayer: false),
          const RankingEntry(rank: 2, playerName: 'Julia B.', value: 88000, isLocalPlayer: false),
          const RankingEntry(rank: 2, playerName: 'Pedro C.', value: 88000, isLocalPlayer: false),
          const RankingEntry(rank: 4, playerName: 'Ana D.', value: 102000, isLocalPlayer: false),
          const RankingEntry(rank: 5, playerName: 'Carlos E.', value: 115000, isLocalPlayer: false),
          const RankingEntry(rank: 6, playerName: 'Bia F.', value: 130000, isLocalPlayer: false),
          const RankingEntry(rank: 7, playerName: 'Você', value: 145000, isLocalPlayer: true),
        ];
      case RankingType.globalScore:
        return [
          const RankingEntry(rank: 1, playerName: 'Marcos A.', value: 98000, isLocalPlayer: false),
          const RankingEntry(rank: 2, playerName: 'Julia B.', value: 75000, isLocalPlayer: false),
          const RankingEntry(rank: 2, playerName: 'Pedro C.', value: 75000, isLocalPlayer: false),
          const RankingEntry(rank: 4, playerName: 'Ana D.', value: 60000, isLocalPlayer: false),
          const RankingEntry(rank: 5, playerName: 'Carlos E.', value: 52000, isLocalPlayer: false),
          const RankingEntry(rank: 6, playerName: 'Bia F.', value: 45000, isLocalPlayer: false),
          const RankingEntry(rank: 7, playerName: 'Você', value: 38000, isLocalPlayer: true),
        ];
      case RankingType.legends8192Count:
        return [
          const RankingEntry(rank: 1, playerName: 'Marcos A.', value: 3, isLocalPlayer: false),
          const RankingEntry(rank: 2, playerName: 'Julia B.', value: 2, isLocalPlayer: false),
          const RankingEntry(rank: 2, playerName: 'Pedro C.', value: 2, isLocalPlayer: false),
        ];
    }
  }

  @override
  Future<RankingEntry?> getPlayerEntry(RankingType type) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (type == RankingType.legends8192Count) return null;
    return const RankingEntry(rank: 7, playerName: 'Você', value: 145000, isLocalPlayer: true);
  }

  @override
  Future<void> submitScore(RankingType type, int value) async {}
}
