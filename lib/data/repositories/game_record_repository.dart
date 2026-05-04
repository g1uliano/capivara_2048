import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_record.dart';
import '../models/game_record_hive_adapter.dart';

class GameRecordRepository {
  static const _boxName = 'game_records';
  static const _maxEntries = 20;

  List<GameRecord> _records = [];

  List<GameRecord> get all => List.unmodifiable(_records);

  List<GameRecord> get topByTime {
    final filtered = _records.where((r) => r.maxLevel >= 11).toList();
    if (filtered.isEmpty) return [];

    // Agrupar por tempo e manter apenas o mais recente de cada grupo
    final Map<int, GameRecord> uniqueByTime = {};
    for (final record in filtered) {
      final existing = uniqueByTime[record.elapsedMs];
      if (existing == null || record.playedAt.isAfter(existing.playedAt)) {
        uniqueByTime[record.elapsedMs] = record;
      }
    }

    // Ordenar por tempo (menor primeiro) e limitar a 15
    final sorted = uniqueByTime.values.toList()
      ..sort((a, b) => a.elapsedMs.compareTo(b.elapsedMs));
    return sorted.take(15).toList();
  }

  List<GameRecord> get topByScore {
    if (_records.isEmpty) return [];

    // Agrupar por score e manter apenas o mais recente de cada grupo
    final Map<int, GameRecord> uniqueByScore = {};
    for (final record in _records) {
      final existing = uniqueByScore[record.score];
      if (existing == null || record.playedAt.isAfter(existing.playedAt)) {
        uniqueByScore[record.score] = record;
      }
    }

    // Ordenar por score (maior primeiro) e limitar a 15
    final sorted = uniqueByScore.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return sorted.take(15).toList();
  }

  Future<void> load() async {
    if (!Hive.isAdapterRegistered(GameRecord.hiveTypeId)) {
      Hive.registerAdapter(GameRecordHiveAdapter());
    }
    final box = await Hive.openBox<GameRecord>(_boxName);
    _records = box.values.toList();
  }

  Future<void> add(GameRecord record) async {
    final box = await Hive.openBox<GameRecord>(_boxName);
    await box.add(record);
    _records = box.values.toList();
    if (_records.length > _maxEntries) {
      final keys = box.keys.toList();
      final toRemove = keys.sublist(0, _records.length - _maxEntries);
      await box.deleteAll(toRemove);
      _records = box.values.toList();
    }
  }
}

final gameRecordRepositoryProvider = Provider<GameRecordRepository>((ref) {
  throw UnimplementedError('Inicializar em main via override');
});
