import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/controllers/personal_records_notifier.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';
import 'package:capivara_2048/data/models/player_profile.dart';
import 'package:capivara_2048/domain/auth/auth_service.dart';
import 'package:capivara_2048/domain/sync/sync_engine.dart';

/// PlayerProfile de teste: simula usuário logado no harness e2e.
final _kTestProfile = PlayerProfile(
  userId: 'test-user',
  displayName: 'Jogador Teste',
  provider: AuthProvider.email,
  createdAt: DateTime(2025),
  lastSeenAt: DateTime(2025),
);

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
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tempDir = await Directory.systemTemp.createTemp('e2e_hive_');
    Hive.init(tempDir.path);
    _registerAdapters();

    final prefs = await SharedPreferences.getInstance();
    final repo = GameRecordRepository();
    await repo.load();

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        gameRecordRepositoryProvider.overrideWithValue(repo),
        authServiceProvider.overrideWithValue(FakeAuthService(initialProfile: _kTestProfile)),
        syncEngineProvider.overrideWithValue(FakeSyncEngine()),
      ],
    );

    await container.read(reduceEffectsProvider.notifier).load();
    await container.read(inventoryProvider.notifier).load();
    await container.read(dailyRewardsProvider.notifier).load();
    await container.read(personalRecordsProvider.notifier).load();
    // Ensure LivesNotifier._init() completes here (real-async Hive I/O).
    // Without this, _init() is deferred to FakeAsync (pumpWidget) where Hive I/O
    // continuations cannot resolve, leaving an orphaned Future that races with
    // subsequent tests' Hive operations and causes non-deterministic hangs.
    await container.read(livesProvider.notifier).awaitReady();

    if (initialGameState != null) {
      container.read(gameProvider.notifier).debugSetState(initialGameState);
    }

    _booted = true;
    return UncontrolledProviderScope(
      container: container,
      child: CapivaraApp(precacheFutureOverride: Future.value()),
    );
  }

  /// Simulates a cold app restart: disposes the current [container] and
  /// provider state, but keeps Hive on disk (same [tempDir]).
  /// Call after [boot()].
  Future<Widget> restart() async {
    assert(_booted, 'GameTestHarness.restart() called before boot()');
    container.dispose();
    await Hive.close().timeout(
      const Duration(seconds: 3),
      onTimeout: () => [],
    ); // flush all boxes to disk and close them

    // Re-use same SharedPreferences mock (no reset — simulates production cold
    // restart where SharedPreferences persists on disk). Same Hive tempDir also
    // kept on purpose.
    final prefs = await SharedPreferences.getInstance();
    final repo = GameRecordRepository();
    await repo.load();

    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        gameRecordRepositoryProvider.overrideWithValue(repo),
        authServiceProvider.overrideWithValue(FakeAuthService(initialProfile: _kTestProfile)),
        syncEngineProvider.overrideWithValue(FakeSyncEngine()),
      ],
    );

    await container.read(reduceEffectsProvider.notifier).load();
    await container.read(inventoryProvider.notifier).load();
    await container.read(dailyRewardsProvider.notifier).load();
    await container.read(personalRecordsProvider.notifier).load();
    await container.read(livesProvider.notifier).awaitReady();

    return UncontrolledProviderScope(
      container: container,
      child: CapivaraApp(precacheFutureOverride: Future.value()),
    );
  }

  Future<void> teardown() async {
    if (!_booted) return;
    container.dispose();
    // Use a timeout in case there are unawaited Hive writes pending (e.g. from
    // `unawaited(notifier.add(...))` inside widget code). We're deleting the
    // temp directory anyway, so skipping the flush is safe for test isolation.
    await Hive.close().timeout(
      const Duration(seconds: 2),
      onTimeout: () => [],
    );
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
