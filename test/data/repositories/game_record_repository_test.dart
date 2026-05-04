import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:capivara_2048/data/models/game_record.dart';
import 'package:capivara_2048/data/repositories/game_record_repository.dart';

void main() {
  setUpAll(() async {
    await Hive.initFlutter();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('GameRecordRepository - Ranking pessoal por pontos', () {
    late GameRecordRepository repo;

    setUp(() async {
      await Hive.deleteBoxFromDisk('game_records');
      repo = GameRecordRepository();
      await repo.load();
    });

    test('topByScore não deve ter pontuações duplicadas', () async {
      // Arrange: Adicionar múltiplos recordes com pontuações repetidas
      final records = [
        GameRecord(
          playedAt: DateTime(2024, 1, 1),
          elapsedMs: 60000,
          score: 1000,
          maxLevel: 11,
        ),
        GameRecord(
          playedAt: DateTime(2024, 1, 2),
          elapsedMs: 70000,
          score: 2000,
          maxLevel: 11,
        ),
        GameRecord(
          playedAt: DateTime(2024, 1, 3),
          elapsedMs: 80000,
          score: 1000, // pontuação repetida
          maxLevel: 11,
        ),
        GameRecord(
          playedAt: DateTime(2024, 1, 4),
          elapsedMs: 90000,
          score: 3000,
          maxLevel: 11,
        ),
        GameRecord(
          playedAt: DateTime(2024, 1, 5),
          elapsedMs: 100000,
          score: 2000, // pontuação repetida
          maxLevel: 11,
        ),
      ];

      for (final record in records) {
        await repo.add(record);
      }

      // Act
      final topByScore = repo.topByScore;

      // Assert: Deve ter apenas pontuações únicas
      final scores = topByScore.map((r) => r.score).toList();
      final uniqueScores = scores.toSet().toList();
      
      expect(scores.length, equals(uniqueScores.length),
          reason: 'topByScore deve conter apenas pontuações únicas');
      
      // Deve estar ordenado do maior para o menor
      expect(scores, equals([3000, 2000, 1000]));
    });

    test('topByScore deve limitar a 15 entradas', () async {
      // Arrange: Adicionar 20 recordes com pontuações diferentes
      for (int i = 0; i < 20; i++) {
        await repo.add(GameRecord(
          playedAt: DateTime(2024, 1, i + 1),
          elapsedMs: 60000 + (i * 1000),
          score: 1000 + (i * 100), // pontuações diferentes
          maxLevel: 11,
        ));
      }

      // Act
      final topByScore = repo.topByScore;

      // Assert: Deve ter no máximo 15 entradas
      expect(topByScore.length, lessThanOrEqualTo(15),
          reason: 'topByScore deve limitar a 15 entradas');
    });

    test('quando há pontuações duplicadas, deve manter a mais recente', () async {
      // Arrange
      final older = GameRecord(
        playedAt: DateTime(2024, 1, 1),
        elapsedMs: 60000,
        score: 1000,
        maxLevel: 11,
      );
      final newer = GameRecord(
        playedAt: DateTime(2024, 1, 2),
        elapsedMs: 50000,
        score: 1000, // mesma pontuação
        maxLevel: 11,
      );

      await repo.add(older);
      await repo.add(newer);

      // Act
      final topByScore = repo.topByScore;

      // Assert: Deve ter apenas 1 entrada com pontuação 1000
      final score1000Entries = topByScore.where((r) => r.score == 1000).toList();
      expect(score1000Entries.length, equals(1));
      
      // Deve ser a entrada mais recente
      expect(score1000Entries.first.playedAt, equals(DateTime(2024, 1, 2)));
    });
  });
}
