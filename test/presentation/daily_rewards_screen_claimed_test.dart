import 'package:capivara_2048/data/models/daily_rewards_state.dart';
import 'package:capivara_2048/data/models/daily_rewards_state_adapter.dart';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/data/repositories/daily_rewards_repository.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/data/repositories/lives_repository.dart';
import 'package:capivara_2048/domain/daily_rewards/ad_service.dart';
import 'package:capivara_2048/domain/daily_rewards/daily_rewards_notifier.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/presentation/screens/daily_rewards/daily_rewards_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_claimed_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LivesStateAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DailyRewardsStateAdapter());
  });

  tearDown(() async { await Hive.close(); await tempDir.delete(recursive: true); });

  testWidgets('estado alreadyClaimed: mostra "Volte amanhã" e sem botão Coletar', (tester) async {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        livesRepositoryProvider.overrideWithValue(LivesRepository()),
        inventoryRepositoryProvider.overrideWithValue(InventoryRepository()),
        dailyRewardsRepositoryProvider.overrideWithValue(DailyRewardsRepository()),
        adServiceProvider.overrideWithValue(FakeAdService()),
        dailyRewardsProvider.overrideWith(
          (ref) => DailyRewardsNotifier(ref.read(dailyRewardsRepositoryProvider), ref)
            ..debugSetState(DailyRewardsState(
              currentDay: 2,
              lastClaimedDate: normalizedToday,
              claimedThisCycle: true,
            )),
        ),
      ],
      child: const MaterialApp(home: DailyRewardsScreen()),
    ));
    await tester.pump();

    expect(find.text('Volte amanhã'), findsOneWidget);
    expect(find.text('Coletar'), findsNothing);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(seconds: 2));
  });
}
