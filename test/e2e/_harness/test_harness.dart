import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capivara_2048/app.dart';
import 'package:capivara_2048/core/providers/reduce_effects_provider.dart';
import 'package:capivara_2048/data/models/daily_rewards_state_adapter.dart';
import 'package:capivara_2048/data/models/game_record.dart';
import 'package:capivara_2048/data/models/game_record_hive_adapter.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/data/models/personal_records.dart';
import 'package:capivara_2048/data/models/personal_records_hive_adapter.dart';
import 'package:capivara_2048/data/repositories/game_record_repository.dart';
import 'package:capivara_2048/domain/daily_rewards/daily_rewards_notifier.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/controllers/personal_records_notifier.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';

/// Test harness that boots the full app inside [WidgetTester.pumpWidget]
/// with an isolated Hive directory and mocked SharedPreferences.
///
/// Usage:
/// ```dart
/// final h = GameTestHarness();
/// addTearDown(h.teardown);
/// await tester.pumpWidget(await h.boot());
/// ```
class GameTestHarness {
  late ProviderContainer container;
  late Directory tempDir;
  bool _booted = false;

  Future<Widget> boot({GameState? initialGameState}) async {
    assert(!_booted, 'GameTestHarness.boot() called twice — call teardown() first');
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tempDir = await Directory.systemTemp.createTemp('e2e_hive_');
    Hive.init(tempDir.path);
    _registerAdapters();

    final prefs = await SharedPreferences.getInstance();
    final repo = GameRecordRepository();
    await repo.load();

    container = ProviderContainer(
      overrides: [
        settingsProvider.overrideWith((ref) => SettingsNotifier(prefs)),
        gameRecordRepositoryProvider.overrideWithValue(repo),
      ],
    );

    await container.read(reduceEffectsProvider.notifier).load();
    await container.read(inventoryProvider.notifier).load();
    await container.read(dailyRewardsProvider.notifier).load();
    await container.read(personalRecordsProvider.notifier).load();

    if (initialGameState != null) {
      container.read(gameProvider.notifier).debugSetState(initialGameState);
    }

    _booted = true;
    return UncontrolledProviderScope(
      container: container,
      child: CapivaraApp(precacheFutureOverride: Future.value()),
    );
  }

  Future<void> teardown() async {
    if (!_booted) return;
    container.dispose();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
    _booted = false;
  }

  void _registerAdapters() {
    final lives = LivesStateAdapter();
    if (!Hive.isAdapterRegistered(lives.typeId)) Hive.registerAdapter(lives);

    final inv = InventoryHiveAdapter();
    if (!Hive.isAdapterRegistered(inv.typeId)) Hive.registerAdapter(inv);

    final daily = DailyRewardsStateAdapter();
    if (!Hive.isAdapterRegistered(daily.typeId)) Hive.registerAdapter(daily);

    if (!Hive.isAdapterRegistered(PersonalRecords.hiveTypeId)) {
      Hive.registerAdapter(PersonalRecordsHiveAdapter());
    }
    if (!Hive.isAdapterRegistered(GameRecord.hiveTypeId)) {
      Hive.registerAdapter(GameRecordHiveAdapter());
    }
  }
}
