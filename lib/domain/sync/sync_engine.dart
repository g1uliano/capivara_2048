// lib/domain/sync/sync_engine.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pending_event.dart';
import '../../data/repositories/firebase_sync_engine.dart';

enum SyncStatus { idle, syncing, error }

abstract class SyncEngine {
  Future<void> init(String userId, {String? displayName});
  Future<void> dispose();
  Future<void> syncProfile();
  Future<void> updateAvatar(String? avatarUrl);
  Future<void> drainPendingEvents();
  Future<void> enqueuePendingEvent(PendingEvent event);
  Stream<SyncStatus> get statusStream;
}

class FakeSyncEngine implements SyncEngine {
  bool initCalled = false;
  bool disposeCalled = false;
  final List<PendingEvent> drained = [];
  final List<PendingEvent> enqueued = [];
  String? lastAvatarUrl = _sentinel;
  static const _sentinel = '__not_set__';

  @override
  Future<void> init(String userId, {String? displayName}) async => initCalled = true;

  @override
  Future<void> dispose() async => disposeCalled = true;

  @override
  Future<void> syncProfile() async {}

  @override
  Future<void> updateAvatar(String? avatarUrl) async {
    lastAvatarUrl = avatarUrl;
  }

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

// TODO(fase4b): Replace FakeSyncEngine with FirebaseSyncEngine for prd flavor.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  if (flavor == 'prd') return FirebaseSyncEngine();
  return FakeSyncEngine();
});
