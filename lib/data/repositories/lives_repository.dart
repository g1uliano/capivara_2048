import 'package:hive_flutter/hive_flutter.dart';
import '../models/lives_state.dart';

class LivesRepository {
  static const _boxName = 'lives';
  static const _key = 'state';
  static const _prefsBox = 'prefs';

  Future<LivesState> load() async {
    final box = await Hive.openBox<LivesState>(_boxName);
    return box.get(_key) ?? LivesState.initial();
  }

  Future<void> save(LivesState state) async {
    final box = await Hive.openBox<LivesState>(_boxName);
    await box.put(_key, state);
  }

  Future<bool> getMigrationFlag(String key) async {
    final box = await Hive.openBox<bool>(_prefsBox);
    return box.get(key, defaultValue: false) ?? false;
  }

  Future<void> setMigrationFlag(String key) async {
    final box = await Hive.openBox<bool>(_prefsBox);
    await box.put(key, true);
  }
}
