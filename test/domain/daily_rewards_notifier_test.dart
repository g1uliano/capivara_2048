import 'package:capivara_2048/data/models/daily_rewards_state.dart';
import 'package:capivara_2048/data/models/daily_rewards_state_adapter.dart';
import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/item_type.dart';
import 'package:capivara_2048/data/models/lives_state.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/data/repositories/daily_rewards_repository.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/data/repositories/lives_repository.dart';
import 'package:capivara_2048/domain/daily_rewards/daily_rewards_engine.dart';
import 'package:capivara_2048/domain/daily_rewards/daily_rewards_notifier.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

DateTime day(int d) => DateTime(2026, 5, d);

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_notifier_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LivesStateAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DailyRewardsStateAdapter());

    container = ProviderContainer(overrides: [
      livesRepositoryProvider.overrideWithValue(LivesRepository()),
      inventoryRepositoryProvider.overrideWithValue(InventoryRepository()),
      dailyRewardsRepositoryProvider.overrideWithValue(DailyRewardsRepository()),
    ]);
    await container.read(livesProvider.notifier).addEarned(0);
    await container.read(inventoryProvider.notifier).load();
    await container.read(dailyRewardsProvider.notifier).load();
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('1: Dia 3 (+1 vida): lives=14 → lives=15 após claim', () async {
    final livesNotifier = container.read(livesProvider.notifier);
    await livesNotifier.addEarned(9); // initial=5, +9=14
    expect(container.read(livesProvider).lives, 14);

    final notifier = container.read(dailyRewardsProvider.notifier);
    notifier.debugSetState(DailyRewardsState(
      currentDay: 3,
      lastClaimedDate: day(1),
      claimedThisCycle: true,
    ));

    await notifier.claim(day(2));
    expect(container.read(livesProvider).lives, 15);
  });

  test('2: Dia 2 (+1 bomba): bomb2 aumenta em 1', () async {
    final notifier = container.read(dailyRewardsProvider.notifier);
    notifier.debugSetState(DailyRewardsState(
      currentDay: 2,
      lastClaimedDate: day(1),
      claimedThisCycle: true,
    ));

    await notifier.claim(day(2));
    expect(container.read(inventoryProvider).bomb2, 1);
  });

  test('3: Dia 7 (combo): lives+2, undo1+2, bomb2+2', () async {
    final notifier = container.read(dailyRewardsProvider.notifier);
    notifier.debugSetState(DailyRewardsState(
      currentDay: 7,
      lastClaimedDate: day(1),
      claimedThisCycle: false,
    ));

    await notifier.claim(day(2));
    expect(container.read(livesProvider).lives, 7); // 5 inicial + 2
    expect(container.read(inventoryProvider).undo1, 2);
    expect(container.read(inventoryProvider).bomb2, 2);
  });

  test('4: claimDouble Dia 2 entrega delta (+1 bomba extra)', () async {
    final notifier = container.read(dailyRewardsProvider.notifier);
    notifier.debugSetState(DailyRewardsState(
      currentDay: 2,
      lastClaimedDate: day(1),
      claimedThisCycle: true,
    ));

    await notifier.claim(day(2)); // entrega base: +1 bomb2
    expect(container.read(inventoryProvider).bomb2, 1);

    await notifier.claimDouble(rewardForDay(2)); // entrega delta: +1 bomb2
    expect(container.read(inventoryProvider).bomb2, 2);

    expect(container.read(dailyRewardsProvider).claimedThisCycle, false); // advanced to day 3
  });

  test('5: streakBroken → claim reseta para Dia 1 e entrega undo1', () async {
    final notifier = container.read(dailyRewardsProvider.notifier);
    notifier.debugSetState(DailyRewardsState(
      currentDay: 5,
      lastClaimedDate: day(1),
      claimedThisCycle: true,
    ));

    // gap=3 → streakBroken
    await notifier.claim(day(4));
    expect(container.read(dailyRewardsProvider).currentDay, 2); // após claim Dia 1, avança para 2
    expect(container.read(inventoryProvider).undo1, 1); // recompensa do Dia 1
  });

  test('6: cycleCompleted → claim entrega Dia 1 do novo ciclo', () async {
    final notifier = container.read(dailyRewardsProvider.notifier);
    notifier.debugSetState(DailyRewardsState(
      currentDay: 7,
      lastClaimedDate: day(7),
      claimedThisCycle: true,
    ));

    await notifier.claim(day(8)); // cycleCompleted → reset para Dia 1 → claim
    expect(container.read(inventoryProvider).undo1, 1); // recompensa do Dia 1
    expect(container.read(dailyRewardsProvider).currentDay, 2); // avança para 2
  });
}
