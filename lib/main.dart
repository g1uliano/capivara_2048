import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/models/lives_state_adapter.dart';
import 'data/models/inventory_hive_adapter.dart';
import 'data/models/daily_rewards_state_adapter.dart';
import 'data/models/personal_records_hive_adapter.dart';
import 'data/models/game_record_hive_adapter.dart';
import 'data/repositories/game_record_repository.dart';
import 'core/providers/reduce_effects_provider.dart';
import 'domain/inventory/inventory_notifier.dart';
import 'domain/daily_rewards/daily_rewards_notifier.dart';
import 'presentation/controllers/settings_notifier.dart';
import 'presentation/controllers/personal_records_notifier.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Hive.initFlutter();
  Hive.registerAdapter(LivesStateAdapter());
  Hive.registerAdapter(InventoryHiveAdapter());
  Hive.registerAdapter(DailyRewardsStateAdapter());
  Hive.registerAdapter(PersonalRecordsHiveAdapter());
  Hive.registerAdapter(GameRecordHiveAdapter());
  final gameRecordRepo = GameRecordRepository();
  await gameRecordRepo.load();
  final sharedPrefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      settingsProvider.overrideWith((ref) => SettingsNotifier(sharedPrefs)),
      gameRecordRepositoryProvider.overrideWithValue(gameRecordRepo),
    ],
  );
  await container.read(reduceEffectsProvider.notifier).load();
  await container.read(inventoryProvider.notifier).load();
  await container.read(dailyRewardsProvider.notifier).load();
  await container.read(personalRecordsProvider.notifier).load();
  runApp(UncontrolledProviderScope(container: container, child: const CapivaraApp()));
}

