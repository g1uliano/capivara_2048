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

Future<Directory> setupHive() async {
  final dir = await Directory.systemTemp.createTemp('hive_widget_test');
  Hive.init(dir.path);
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LivesStateAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DailyRewardsStateAdapter());
  return dir;
}

Widget buildScreen(DailyRewardsState initialState) {
  return ProviderScope(
    overrides: [
      livesRepositoryProvider.overrideWithValue(LivesRepository()),
      inventoryRepositoryProvider.overrideWithValue(InventoryRepository()),
      dailyRewardsRepositoryProvider.overrideWithValue(DailyRewardsRepository()),
      adServiceProvider.overrideWithValue(FakeAdService()),
      dailyRewardsProvider.overrideWith(
        (ref) => DailyRewardsNotifier(ref.read(dailyRewardsRepositoryProvider), ref)
          ..debugSetState(initialState),
      ),
    ],
    child: const MaterialApp(home: DailyRewardsScreen()),
  );
}

void main() {
  late Directory tempDir;
  setUp(() async { tempDir = await setupHive(); });
  tearDown(() async { await Hive.close(); await tempDir.delete(recursive: true); });

  testWidgets('estado available: botão Coletar habilitado e título presente', (tester) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final normalizedYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day);

    await tester.pumpWidget(buildScreen(DailyRewardsState(
      currentDay: 3,
      lastClaimedDate: normalizedYesterday,
      claimedThisCycle: true,
    )));
    await tester.pump();

    expect(find.text('Recompensa Diária'), findsOneWidget);
    expect(find.text('Coletar'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.ancestor(of: find.text('Coletar'), matching: find.byType(ElevatedButton)),
    );
    expect(button.onPressed, isNotNull);

    // Dismiss the screen to trigger dispose() which cancels the periodic timer.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(seconds: 2));
  });
}
