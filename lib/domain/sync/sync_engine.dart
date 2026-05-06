// lib/domain/sync/sync_engine.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/pending_event.dart';

enum SyncStatus { idle, syncing, error }

abstract class SyncEngine {
  Future<void> init(String userId);
  Future<void> dispose();
  Future<void> syncProfile();
  Future<void> drainPendingEvents();
  Future<void> enqueuePendingEvent(PendingEvent event);
  Stream<SyncStatus> get statusStream;
}

class FakeSyncEngine implements SyncEngine {
  bool initCalled = false;
  bool disposeCalled = false;
  final List<PendingEvent> drained = [];
  final List<PendingEvent> enqueued = [];

  @override
  Future<void> init(String userId) async => initCalled = true;

  @override
  Future<void> dispose() async => disposeCalled = true;

  @override
  Future<void> syncProfile() async {}

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
  Stream<SyncStatus> get statusStream => Stream.value(SyncStatus.idle);
}

final syncEngineProvider = Provider<SyncEngine>((_) => FakeSyncEngine());
