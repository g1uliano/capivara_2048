import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/lives_state_adapter.dart';
import 'data/models/inventory_hive_adapter.dart';
import 'data/models/daily_rewards_state_adapter.dart';
import 'core/providers/reduce_effects_provider.dart';
import 'domain/inventory/inventory_notifier.dart';
import 'domain/daily_rewards/daily_rewards_notifier.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(LivesStateAdapter());
  Hive.registerAdapter(InventoryHiveAdapter());
  Hive.registerAdapter(DailyRewardsStateAdapter());
  final container = ProviderContainer();
  await container.read(reduceEffectsProvider.notifier).load();
  await container.read(inventoryProvider.notifier).load();
  await container.read(dailyRewardsProvider.notifier).load();
  runApp(UncontrolledProviderScope(container: container, child: const CapivaraApp()));
}

