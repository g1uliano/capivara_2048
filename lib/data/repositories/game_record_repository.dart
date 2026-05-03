import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_record.dart';
import '../models/game_record_hive_adapter.dart';

class GameRecordRepository {
  static const _boxName = 'game_records';
  static const _maxEntries = 20;

  List<GameRecord> _records = [];

  List<GameRecord> get all => List.unmodifiable(_records);

  List<GameRecord> get topByTime => [..._records.where((r) => r.maxLevel >= 11)]
    ..sort((a, b) => a.elapsedMs.compareTo(b.elapsedMs));

  List<GameRecord> get topByScore => [..._records]
    ..sort((a, b) => b.score.compareTo(a.score));

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
