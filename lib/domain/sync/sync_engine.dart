// lib/domain/sync/sync_engine.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/daily_rewards_state.dart';
import '../../data/models/game_record.dart';
import '../../data/models/game_state.dart';
import '../../data/models/inventory.dart';
import '../../data/models/pending_event.dart';
import '../../data/models/personal_records.dart';
import '../../data/repositories/firebase_sync_engine.dart';

enum SyncStatus { idle, syncing, error }

abstract class SyncEngine {
  Future<void> init(String userId, {String? displayName});
  Future<void> dispose();
  Future<void> syncProfile();
  Future<void> updateAvatar(String? avatarUrl);
  Future<void> updateTutorialCompleted(bool completed);
  Future<void> updateDisplayName(String name);
  Future<void> deleteUserData();
  Future<void> syncGameRecord(GameRecord record);
  Future<void> syncCurrentGame(GameState? state);
  Future<void> syncInventory(Inventory inventory);
  Future<void> syncPersonalRecords(PersonalRecords records);
  Future<void> syncDailyRewards(DailyRewardsState state);
  Future<void> drainPendingEvents();
  Future<void> enqueuePendingEvent(PendingEvent event);
  Stream<SyncStatus> get statusStream;
  String? get remoteAvatarUrl;
  String? get remoteDisplayName;
}

class FakeSyncEngine implements SyncEngine {
  bool initCalled = false;
  bool disposeCalled = false;
  final List<PendingEvent> drained = [];
  final List<PendingEvent> enqueued = [];
  String? lastAvatarUrl = _sentinel;
  static const _sentinel = '__not_set__';

  @override
  String? remoteAvatarUrl;

  @override
  String? remoteDisplayName;

  @override
  Future<void> init(String userId, {String? displayName}) async =>
      initCalled = true;

  @override
  Future<void> dispose() async => disposeCalled = true;

  @override
  Future<void> syncProfile() async {}

  @override
  Future<void> updateAvatar(String? avatarUrl) async {
    lastAvatarUrl = avatarUrl;
  }

  bool tutorialCompleted = false;

  @override
  Future<void> updateTutorialCompleted(bool completed) async {
    tutorialCompleted = completed;
  }

  @override
  Future<void> updateDisplayName(String name) async {}

  @override
  Future<void> deleteUserData() async {}

  @override
  Future<void> syncGameRecord(GameRecord record) async {}

  GameState? lastSyncedGame;

  @override
  Future<void> syncCurrentGame(GameState? state) async {
    lastSyncedGame = state;
  }

  @override
  Future<void> syncInventory(Inventory inventory) async {}

  @override
  Future<void> syncPersonalRecords(PersonalRecords records) async {}

  @override
  Future<void> syncDailyRewards(DailyRewardsState state) async {}

  @override
  Future<void> drainPendingEvents() async {
    drained.addAll(enqueued);
    enqueued.clear();
  }

  @override
  Future<void> enqueuePendingEvent(PendingEvent event) async {
    enqueued.add(event);
  }

  @override
  // Emits a single idle event. Real implementation uses a broadcast StreamController.
  Stream<SyncStatus> get statusStream => Stream.value(SyncStatus.idle);
}

final syncEngineProvider = Provider<SyncEngine>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  if (flavor == 'prd' || flavor == 'dev') {
    return FirebaseSyncEngine();
  }
  return FakeSyncEngine();
});
