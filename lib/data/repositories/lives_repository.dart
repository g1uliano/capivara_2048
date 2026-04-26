import 'package:hive_flutter/hive_flutter.dart';
import '../models/lives_state.dart';

class LivesRepository {
  static const _boxName = 'lives';
  static const _key = 'state';

  Future<LivesState> load() async {
    final box = await Hive.openBox<LivesState>(_boxName);
    return box.get(_key) ?? LivesState.initial();
  }

  Future<void> save(LivesState state) async {
    final box = await Hive.openBox<LivesState>(_boxName);
    await box.put(_key, state);
  }
}
