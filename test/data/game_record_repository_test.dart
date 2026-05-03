import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:capivara_2048/data/models/game_record.dart';
import 'package:capivara_2048/data/models/game_record_hive_adapter.dart';
import 'package:capivara_2048/data/repositories/game_record_repository.dart';

void main() {
  late Directory tempDir;
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(GameRecord.hiveTypeId)) {
      Hive.registerAdapter(GameRecordHiveAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('GameRecordRepository', () {
    test('adicionar e recuperar records', () async {
      final repo = GameRecordRepository();
      await repo.load();
      final record = GameRecord(
        playedAt: DateTime(2026, 5, 3),
        elapsedMs: 120000,
        score: 5000,
        maxLevel: 11,
      );
      await repo.add(record);
      final all = repo.all;
      expect(all.length, 1);
      expect(all.first.score, 5000);
    });

    test('lista limitada a 20 entradas (FIFO)', () async {
      final repo = GameRecordRepository();
      await repo.load();
      for (int i = 0; i < 21; i++) {
        await repo.add(GameRecord(
          playedAt: DateTime(2026, 5, 3, i),
          elapsedMs: (i + 1) * 1000,
          score: i * 100,
          maxLevel: 11,
        ));
      }
      expect(repo.all.length, 20);
      // A primeira entrada (i=0, score=0) foi removida
      expect(repo.all.first.score, 100);
    });

    test('topByTime ordena por menor elapsedMs', () async {
      final repo = GameRecordRepository();
      await repo.load();
      await repo.add(GameRecord(playedAt: DateTime(2026, 5, 3), elapsedMs: 200000, score: 3000, maxLevel: 11));
      await repo.add(GameRecord(playedAt: DateTime(2026, 5, 3), elapsedMs: 100000, score: 2000, maxLevel: 11));
      await repo.add(GameRecord(playedAt: DateTime(2026, 5, 3), elapsedMs: 150000, score: 4000, maxLevel: 11));
      final top = repo.topByTime;
      expect(top.first.elapsedMs, 100000);
      expect(top.last.elapsedMs, 200000);
    });

    test('topByTime não inclui partidas com maxLevel < 11', () async {
      final repo = GameRecordRepository();
      await repo.load();
      await repo.add(GameRecord(playedAt: DateTime(2026, 5, 3), elapsedMs: 50000, score: 100, maxLevel: 8));
      await repo.add(GameRecord(playedAt: DateTime(2026, 5, 3), elapsedMs: 200000, score: 5000, maxLevel: 11));
      expect(repo.topByTime.length, 1);
      expect(repo.topByTime.first.maxLevel, 11);
    });

    test('topByScore ordena por maior score', () async {
      final repo = GameRecordRepository();
      await repo.load();
      await repo.add(GameRecord(playedAt: DateTime(2026, 5, 3), elapsedMs: 100000, score: 2000, maxLevel: 9));
      await repo.add(GameRecord(playedAt: DateTime(2026, 5, 3), elapsedMs: 200000, score: 8000, maxLevel: 11));
      await repo.add(GameRecord(playedAt: DateTime(2026, 5, 3), elapsedMs: 150000, score: 5000, maxLevel: 10));
      final top = repo.topByScore;
      expect(top.first.score, 8000);
      expect(top.last.score, 2000);
    });
  });
}
