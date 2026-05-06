// lib/data/repositories/firebase_sync_engine.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/pending_event.dart';
import '../../data/models/personal_records.dart';
import '../../data/models/inventory.dart';
import '../../domain/sync/sync_engine.dart';
import '../../domain/sync/sync_conflict_resolver.dart';

class FirebaseSyncEngine implements SyncEngine {
  static const _pendingEventsBox = 'pending_events';
  static const _personalRecordsBox = 'personal_records';
  static const _personalRecordsKey = 'records';

  String? _userId;
  StreamSubscription<DocumentSnapshot>? _profileListener;
  StreamSubscription<List<ConnectivityResult>>? _connectivityListener;
  final _statusController = StreamController<SyncStatus>.broadcast();
  final _firestore = FirebaseFirestore.instance;

  @override
  Stream<SyncStatus> get statusStream => _statusController.stream;

  @override
  Future<void> init(String userId) async {
    _userId = userId;
    _startSnapshotListener();
    _startConnectivityListener();
    await drainPendingEvents();
  }

  @override
  Future<void> dispose() async {
    await _profileListener?.cancel();
    await _connectivityListener?.cancel();
    if (!_statusController.isClosed) await _statusController.close();
    _userId = null;
  }

  @override
  Future<void> syncProfile() async {
    if (_userId == null) return;
    _statusController.add(SyncStatus.syncing);
    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists) {
        await _mergeRemotePersonalRecords(
            doc.data()?['personalRecords'] as Map<String, dynamic>?);
        await _mergeRemoteInventory(
            doc.data()?['inventory'] as Map<String, dynamic>?);
      } else {
        await _writeLocalProfileToFirestore();
      }
      _statusController.add(SyncStatus.idle);
    } catch (_) {
      _statusController.add(SyncStatus.error);
    }
  }

  @override
  Future<void> drainPendingEvents() async {
    final box = await Hive.openBox<PendingEvent>(_pendingEventsBox);
    final events = box.values.toList();
    if (events.isEmpty) return;
    for (final event in events) {
      try {
        await _applyEvent(event);
        await box.delete(event.id);
      } catch (_) {
        // Keep in queue if failed — will retry on next drain
      }
    }
  }

  @override
  Future<void> enqueuePendingEvent(PendingEvent event) async {
    final box = await Hive.openBox<PendingEvent>(_pendingEventsBox);
    await box.put(event.id, event);
    await drainPendingEvents();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _startSnapshotListener() {
    if (_userId == null) return;
    _profileListener = _firestore
        .collection('users')
        .doc(_userId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      await _mergeRemotePersonalRecords(
          data['personalRecords'] as Map<String, dynamic>?);
      await _mergeRemoteInventory(
          data['inventory'] as Map<String, dynamic>?);
    });
  }

  void _startConnectivityListener() {
    _connectivityListener =
        Connectivity().onConnectivityChanged.listen((results) async {
      if (results.any((r) => r != ConnectivityResult.none)) {
        await drainPendingEvents();
      }
    });
  }

  Future<void> _applyEvent(PendingEvent event) async {
    if (_userId == null) return;
    switch (event.type) {
      case PendingEventType.legendReached:
        final level = event.payload['level'] as int;
        final collectionPath = 'legendsRankings/$level/entries';
        await _firestore.runTransaction((tx) async {
          final ref =
              _firestore.collection(collectionPath).doc(_userId);
          final snap = await tx.get(ref);
          if (snap.exists) {
            tx.update(ref, {'timesReached': FieldValue.increment(1)});
          } else {
            tx.set(ref, {
              'userId': _userId,
              'displayName': 'Jogador',
              'timesReached': 1,
              'firstReachedAt': Timestamp.fromDate(event.occurredAt),
            });
          }
        });
        final field = level == 4096
            ? 'personalRecords.timesReached4096'
            : 'personalRecords.timesReached8192';
        await _firestore
            .collection('users')
            .doc(_userId)
            .update({field: FieldValue.increment(1)});
      case PendingEventType.inventoryConsume:
        // Handled by direct transaction at purchase time — not via queue
        break;
    }
  }

  Future<void> _mergeRemotePersonalRecords(
      Map<String, dynamic>? remoteData) async {
    if (remoteData == null) return;
    final box = await Hive.openBox<PersonalRecords>(_personalRecordsBox);
    final local =
        box.get(_personalRecordsKey) ?? const PersonalRecords();
    final remote = _personalRecordsFromMap(remoteData);
    final merged =
        SyncConflictResolver.mergePersonalRecords(local, remote);
    await box.put(_personalRecordsKey, merged);
  }

  Future<void> _mergeRemoteInventory(
      Map<String, dynamic>? remoteData) async {
    if (remoteData == null) return;
    final box = await Hive.openBox<Inventory>('inventory');
    final local = box.get('inventory') ?? Inventory.empty();
    final remote = Inventory(
      bomb2: (remoteData['bomb2'] as int?) ?? 0,
      bomb3: (remoteData['bomb3'] as int?) ?? 0,
      undo1: (remoteData['undo1'] as int?) ?? 0,
      undo3: (remoteData['undo3'] as int?) ?? 0,
    );
    final merged = SyncConflictResolver.mergeInventory(local, remote);
    await box.put('inventory', merged);
  }

  Future<void> _writeLocalProfileToFirestore() async {
    if (_userId == null) return;
    final prBox =
        await Hive.openBox<PersonalRecords>(_personalRecordsBox);
    final pr =
        prBox.get(_personalRecordsKey) ?? const PersonalRecords();
    await _firestore.collection('users').doc(_userId).set(
      {
        'userId': _userId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'personalRecords': {
          'timesReached2048': pr.timesReached2048,
          'timesReached4096': pr.timesReached4096,
          'timesReached8192': pr.timesReached8192,
          'highestLevelEver': pr.highestLevelEver,
          if (pr.firstReached4096At != null)
            'firstReached4096At':
                Timestamp.fromDate(pr.firstReached4096At!),
          if (pr.firstReached8192At != null)
            'firstReached8192At':
                Timestamp.fromDate(pr.firstReached8192At!),
        },
      },
      SetOptions(merge: true),
    );
  }

  PersonalRecords _personalRecordsFromMap(Map<String, dynamic> m) {
    final ts4096 = m['firstReached4096At'] as Timestamp?;
    final ts8192 = m['firstReached8192At'] as Timestamp?;
    return PersonalRecords(
      timesReached2048: (m['timesReached2048'] as int?) ?? 0,
      timesReached4096: (m['timesReached4096'] as int?) ?? 0,
      timesReached8192: (m['timesReached8192'] as int?) ?? 0,
      highestLevelEver: (m['highestLevelEver'] as int?) ?? 0,
      firstReached4096At: ts4096?.toDate(),
      firstReached8192At: ts8192?.toDate(),
    );
  }
}
