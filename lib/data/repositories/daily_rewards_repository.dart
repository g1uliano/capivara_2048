import 'package:hive_flutter/hive_flutter.dart';
import '../models/daily_rewards_state.dart';

class DailyRewardsRepository {
  static const _boxName = 'daily_rewards';
  static const _key = 'state';

  Future<DailyRewardsState> load() async {
    final box = await Hive.openBox<DailyRewardsState>(_boxName);
    return box.get(_key) ?? DailyRewardsState.initial();
  }

  Future<void> save(DailyRewardsState state) async {
    final box = await Hive.openBox<DailyRewardsState>(_boxName);
    await box.put(_key, state);
  }

  Future<void> reset() async {
    final box = await Hive.openBox<DailyRewardsState>(_boxName);
    await box.put(_key, DailyRewardsState.initial());
  }
}
