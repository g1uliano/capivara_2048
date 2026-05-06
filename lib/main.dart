import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Gerados pelo FlutterFire CLI — executar FIREBASE.md §5.1 e §5.2 antes do build
import 'firebase_options_dev.dart' as dev_options;
import 'firebase_options_prd.dart' as prd_options;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/models/lives_state_adapter.dart';
import 'data/models/inventory_hive_adapter.dart';
import 'data/models/daily_rewards_state_adapter.dart';
import 'data/models/personal_records_hive_adapter.dart';
import 'data/models/game_record_hive_adapter.dart';
import 'data/models/pending_event_hive_adapter.dart';
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

  // Firebase — flavor selecionado via --dart-define=FLAVOR=dev|prd
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  final firebaseOptions = flavor == 'prd'
      ? prd_options.DefaultFirebaseOptions.currentPlatform
      : dev_options.DefaultFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(options: firebaseOptions);

  // Emulador local — ativo apenas no flavor dev
  // Host configurável via --dart-define=EMULATOR_HOST=...
  // Padrões: 'localhost' (USB + adb reverse), '10.0.3.2' (Genymotion), IP fixo da rede (WiFi)
  const emulatorHost =
      String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');
  if (flavor == 'dev') {
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  }

  await Hive.initFlutter();
  Hive.registerAdapter(LivesStateAdapter());
  Hive.registerAdapter(InventoryHiveAdapter());
  Hive.registerAdapter(DailyRewardsStateAdapter());
  Hive.registerAdapter(PersonalRecordsHiveAdapter());
  Hive.registerAdapter(GameRecordHiveAdapter());
  Hive.registerAdapter(PendingEventHiveAdapter());
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
  runApp(
    UncontrolledProviderScope(container: container, child: const CapivaraApp()),
  );
}
