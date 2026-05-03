import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/repositories/fake_ranking_service.dart';
import 'package:capivara_2048/domain/ranking/ranking_repository.dart';

void main() {
  group('FakeRankingService', () {
    late FakeRankingService service;

    setUp(() {
      service = FakeRankingService();
    });

    test('getWeeklyTop retorna pelo menos 3 entradas para globalTime', () async {
      final entries = await service.getWeeklyTop(RankingType.globalTime);
      expect(entries.length, greaterThanOrEqualTo(3));
    });

    test('ranks estão em ordem crescente', () async {
      final entries = await service.getWeeklyTop(RankingType.globalTime);
      for (int i = 0; i < entries.length - 1; i++) {
        expect(entries[i].rank, lessThanOrEqualTo(entries[i + 1].rank));
      }
    });

    test('empate no 2º lugar: dois entries com rank == 2', () async {
      final entries = await service.getWeeklyTop(RankingType.globalTime);
      final rank2 = entries.where((e) => e.rank == 2).toList();
      expect(rank2.length, 2);
    });

    test('getPlayerEntry retorna isLocalPlayer=true para globalTime', () async {
      final entry = await service.getPlayerEntry(RankingType.globalTime);
      expect(entry, isNotNull);
      expect(entry!.isLocalPlayer, true);
    });

    test('getPlayerEntry retorna null para legends8192Count (não atingido)', () async {
      final entry = await service.getPlayerEntry(RankingType.legends8192Count);
      expect(entry, null);
    });

    test('entry do jogador local tem rank > 3 em globalTime', () async {
      final entry = await service.getPlayerEntry(RankingType.globalTime);
      expect(entry!.rank, greaterThan(3));
    });
  });
}
