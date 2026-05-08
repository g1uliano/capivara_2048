import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:capivara_2048/presentation/controllers/post_game_controller.dart';
import 'package:capivara_2048/presentation/controllers/personal_records_notifier.dart';
import 'package:capivara_2048/data/models/personal_records.dart';
import 'package:capivara_2048/data/models/personal_records_hive_adapter.dart';
import 'package:capivara_2048/domain/sync/sync_engine.dart';
import 'package:capivara_2048/domain/auth/auth_service.dart';
import 'package:capivara_2048/core/providers/ranking_provider.dart';
import 'package:capivara_2048/data/repositories/iap_startup_service.dart';
import 'package:capivara_2048/data/repositories/fake_ranking_service.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/data/models/lives_state.dart';
import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/data/models/item_type.dart';

void main() {
  setUpAll(() async {
    final testDir =
        '/tmp/capivara_postgame_test_${DateTime.now().millisecondsSinceEpoch}';
    Hive.init(testDir);
    if (!Hive.isAdapterRegistered(PersonalRecords.hiveTypeId)) {
      Hive.registerAdapter(PersonalRecordsHiveAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
  });

  ProviderContainer makeContainer({bool loggedIn = false}) {
    final fakeAuth = FakeAuthService(initialProfile: null);

    return ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(fakeAuth),
        syncEngineProvider.overrideWithValue(FakeSyncEngine()),
        rankingRepositoryProvider.overrideWithValue(FakeRankingService()),
        iapStartupServiceProvider.overrideWithValue(FakeIAPStartupService()),
        livesProvider.overrideWith(() => _FakeLivesNotifier()),
        inventoryProvider.overrideWith(() => _FakeInventoryNotifier()),
      ],
    );
  }

  group('PostGameController — initial state', () {
    test('build() returns null', () {
      final c = makeContainer();
      addTearDown(c.dispose);
      expect(c.read(postGameControllerProvider), isNull);
    });
  });

  group('PostGameController — milestone 11 (2048)', () {
    test('first 2048 (bestTimeMs2048 == 0) → earnedCombo true', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(personalRecordsProvider.notifier).load();

      await c.read(postGameControllerProvider.notifier).onMilestone(
        milestone: 11,
        timeMs: 27000,
        maxLevel: 11,
        timesReached8192: 0,
      );

      final summary = c.read(postGameControllerProvider);
      expect(summary, isNotNull);
      expect(summary!.milestone, 11);
      expect(summary.timeMs, 27000);
      expect(summary.earnedCombo, true);
    });

    test('better time → earnedCombo true', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(personalRecordsProvider.notifier).load();
      // Set a previous record
      await c.read(personalRecordsProvider.notifier).updateBestTime2048(30000);

      await c.read(postGameControllerProvider.notifier).onMilestone(
        milestone: 11,
        timeMs: 25000, // better than 30000
        maxLevel: 11,
        timesReached8192: 0,
      );

      final summary = c.read(postGameControllerProvider);
      expect(summary!.earnedCombo, true);
    });

    test('worse time → earnedCombo false (no new tile record)', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(personalRecordsProvider.notifier).load();
      await c.read(personalRecordsProvider.notifier).updateBestTime2048(20000);
      await c.read(personalRecordsProvider.notifier).updateHighestLevel(11);

      await c.read(postGameControllerProvider.notifier).onMilestone(
        milestone: 11,
        timeMs: 25000, // worse than 20000
        maxLevel: 11, // same as highestLevelEver → no tile record
        timesReached8192: 0,
      );

      final summary = c.read(postGameControllerProvider);
      expect(summary!.earnedCombo, false);
    });
  });

  group('PostGameController — milestone 12 (4096)', () {
    test('first 4096 (new tile record) → earnedCombo true', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(personalRecordsProvider.notifier).load();
      await c
          .read(personalRecordsProvider.notifier)
          .updateHighestLevel(11); // previously 2048

      await c.read(postGameControllerProvider.notifier).onMilestone(
        milestone: 12,
        timeMs: 50000,
        maxLevel: 12, // higher than highestLevelEver (11) → tile record
        timesReached8192: 0,
      );

      final summary = c.read(postGameControllerProvider);
      expect(summary!.milestone, 12);
      expect(summary.earnedCombo, true);
    });

    test('repeat 4096 (no new tile record) → earnedCombo false', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(personalRecordsProvider.notifier).load();
      await c
          .read(personalRecordsProvider.notifier)
          .updateHighestLevel(12); // already at 4096

      await c.read(postGameControllerProvider.notifier).onMilestone(
        milestone: 12,
        timeMs: 50000,
        maxLevel: 12, // same as highestLevelEver → no tile record
        timesReached8192: 0,
      );

      final summary = c.read(postGameControllerProvider);
      expect(summary!.earnedCombo, false);
    });
  });

  group('PostGameController — milestone 13 (8192)', () {
    test('emits correct timesReached8192', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(personalRecordsProvider.notifier).load();
      await c.read(personalRecordsProvider.notifier).updateHighestLevel(12);

      await c.read(postGameControllerProvider.notifier).onMilestone(
        milestone: 13,
        timeMs: 90000,
        maxLevel: 13, // new tile record
        timesReached8192: 3,
      );

      final summary = c.read(postGameControllerProvider);
      expect(summary!.milestone, 13);
      expect(summary.timesReached8192, 3);
      expect(summary.earnedCombo, true); // first 8192
    });
  });

  group('PostGameController — dismiss', () {
    test('dismiss() sets state to null', () async {
      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(personalRecordsProvider.notifier).load();

      await c.read(postGameControllerProvider.notifier).onMilestone(
        milestone: 11,
        timeMs: 27000,
        maxLevel: 11,
        timesReached8192: 0,
      );
      expect(c.read(postGameControllerProvider), isNotNull);

      c.read(postGameControllerProvider.notifier).dismiss();
      expect(c.read(postGameControllerProvider), isNull);
    });
  });
}

// ---------------------------------------------------------------------------
// Minimal fake notifiers — avoid Hive dependency for lives and inventory.
// ---------------------------------------------------------------------------

/// Extends [LivesNotifier] so that [livesProvider.overrideWith] type-checks.
/// Overrides [build] to skip Hive/_init, and [addEarned] to skip _ready.future.
class _FakeLivesNotifier extends LivesNotifier {
  @override
  LivesState build() => LivesState.initial();

  @override
  Future<void> addEarned(int amount) async {
    state = LivesNotifier.applyAddEarned(state, amount);
  }

  @override
  Future<void> consume() async {}

  @override
  Future<void> addPurchased(int amount) async {}

  @override
  Future<void> rewardFromAd() async {}

  @override
  Future<void> recordAdWatched() async {}
}

/// Extends [InventoryNotifier] so that [inventoryProvider.overrideWith] type-checks.
/// Overrides [build] and [add] to skip Hive.
class _FakeInventoryNotifier extends InventoryNotifier {
  @override
  Inventory build() => Inventory.empty();

  @override
  Future<void> add(ItemType type, int amount) async {
    state = state.add(type, amount);
  }

  @override
  Future<void> consume(ItemType type) async {}

  @override
  Future<void> load() async {}
}
