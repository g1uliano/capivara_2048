import 'package:capivara_2048/data/models/daily_rewards_state.dart';
import 'package:capivara_2048/data/models/daily_rewards_state_adapter.dart';
import 'package:capivara_2048/data/repositories/daily_rewards_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_daily_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(DailyRewardsStateAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('load returns initial when box is empty', () async {
    final repo = DailyRewardsRepository();
    final state = await repo.load();
    expect(state, DailyRewardsState.initial());
  });

  test('save and load round-trips correctly', () async {
    final repo = DailyRewardsRepository();
    final saved = DailyRewardsState(
      currentDay: 3,
      lastClaimedDate: DateTime(2026, 5, 1),
      claimedThisCycle: true,
    );
    await repo.save(saved);
    final loaded = await repo.load();
    expect(loaded.currentDay, 3);
    expect(loaded.lastClaimedDate, DateTime(2026, 5, 1));
    expect(loaded.claimedThisCycle, true);
  });

  test('reset returns state to initial', () async {
    final repo = DailyRewardsRepository();
    await repo.save(DailyRewardsState(
      currentDay: 5,
      lastClaimedDate: DateTime(2026, 5, 3),
      claimedThisCycle: true,
    ));
    await repo.reset();
    final loaded = await repo.load();
    expect(loaded, DailyRewardsState.initial());
  });
}
