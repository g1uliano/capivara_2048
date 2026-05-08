// lib/data/repositories/firebase_sync_engine.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/game_record.dart';
import '../../data/models/pending_event.dart';
import '../../data/models/personal_records.dart';
import '../../data/models/inventory.dart';
import '../../data/models/lives_state.dart';
import '../../data/models/game_record_hive_adapter.dart';
import '../../domain/sync/sync_engine.dart';
import '../../domain/sync/sync_conflict_resolver.dart';

class FirebaseSyncEngine implements SyncEngine {
  static const _pendingEventsBox = 'pending_events';
  static const _personalRecordsBox = 'personal_records';
  static const _personalRecordsKey = 'records';

  String? displayName;

  FirebaseSyncEngine({this.displayName});

  String? _userId;
  StreamSubscription<DocumentSnapshot>? _profileListener;
  StreamSubscription<List<ConnectivityResult>>? _connectivityListener;
  StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  final _firestore = FirebaseFirestore.instance;
  String? _remoteAvatarUrl;
  String? _remoteDisplayName;

  @override
  Stream<SyncStatus> get statusStream => _statusController.stream;

  @override
  Future<void> init(String userId, {String? displayName}) async {
    // Recriar controller se foi fechado por dispose() (re-login após signOut)
    if (_statusController.isClosed) {
      _statusController = StreamController<SyncStatus>.broadcast();
    }
    _userId = userId;
    if (displayName != null) this.displayName = displayName;
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
        final data = doc.data()!;
        // Avatar (para contas e-mail com tile animal)
        _remoteAvatarUrl = data['avatarUrl'] as String?;
        // displayName canônico do Firestore (mais confiável que o cache do Firebase Auth)
        _remoteDisplayName = data['displayName'] as String?;
        // Creditar vidas pendentes (reward de convite para o convidador)
        final pendingLives = (data['pendingLives'] as num?)?.toInt() ?? 0;
        if (pendingLives > 0) {
          await _creditPendingLives(pendingLives);
        }
        await _mergeRemotePersonalRecords(
          data['personalRecords'] as Map<String, dynamic>?,
        );
        await _mergeRemoteInventory(data['inventory'] as Map<String, dynamic>?);
        await _mergeRemoteGameRecords(
          (data['gameRecords'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList(),
        );
      } else {
        await _writeLocalProfileToFirestore();
      }
      _statusController.add(SyncStatus.idle);
    } catch (_) {
      _statusController.add(SyncStatus.error);
    }
  }

  @override
  Future<void> updateAvatar(String? avatarUrl) async {
    if (_userId == null) return;
    await _firestore.collection('users').doc(_userId).set({
      'avatarUrl': avatarUrl,
    }, SetOptions(merge: true));
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
            data['personalRecords'] as Map<String, dynamic>?,
          );
          await _mergeRemoteInventory(
            data['inventory'] as Map<String, dynamic>?,
          );
        });
  }

  void _startConnectivityListener() {
    _connectivityListener = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
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
          final ref = _firestore.collection(collectionPath).doc(_userId);
          final snap = await tx.get(ref);
          if (snap.exists) {
            tx.update(ref, {'timesReached': FieldValue.increment(1)});
          } else {
            tx.set(ref, {
              'userId': _userId,
              'displayName': displayName ?? 'Jogador',
              'timesReached': 1,
              'firstReachedAt': Timestamp.fromDate(event.occurredAt),
            });
          }
        });
        final field = switch (level) {
          2048 => 'personalRecords.timesReached2048',
          4096 => 'personalRecords.timesReached4096',
          _ => 'personalRecords.timesReached8192',
        };
        await _firestore.collection('users').doc(_userId).update({
          field: FieldValue.increment(1),
        });
      case PendingEventType.inventoryConsume:
        // Handled by direct transaction at purchase time — not via queue
        break;
    }
  }

  Future<void> _mergeRemotePersonalRecords(
    Map<String, dynamic>? remoteData,
  ) async {
    if (remoteData == null) return;
    final box = await Hive.openBox<PersonalRecords>(_personalRecordsBox);
    final local = box.get(_personalRecordsKey) ?? const PersonalRecords();
    final remote = _personalRecordsFromMap(remoteData);
    final merged = SyncConflictResolver.mergePersonalRecords(local, remote);
    await box.put(_personalRecordsKey, merged);
  }

  Future<void> _creditPendingLives(int amount) async {
    if (_userId == null || amount <= 0) return;
    try {
      // 1. Zerar no Firestore ANTES de creditar localmente — evita duplo crédito em crash
      await _firestore.collection('users').doc(_userId).update({
        'pendingLives': 0,
      });
      // 2. Creditar localmente via Hive
      final livesBox = await Hive.openBox<LivesState>('lives');
      final ls = livesBox.get('state') ?? LivesState.initial();
      await livesBox.put(
        'state',
        ls.copyWith(lives: (ls.lives + amount).clamp(0, 15)),
      );
    } catch (_) {
      // Non-fatal — pendingLives remains > 0 in Firestore for next sync
    }
  }

  Future<void> _mergeRemoteInventory(Map<String, dynamic>? remoteData) async {
    if (remoteData == null) return;
    final box = await Hive.openBox<Inventory>('inventory');
    final local = box.get('data') ?? Inventory.empty();
    final remote = Inventory(
      bomb2: (remoteData['bomb2'] as int?) ?? 0,
      bomb3: (remoteData['bomb3'] as int?) ?? 0,
      undo1: (remoteData['undo1'] as int?) ?? 0,
      undo3: (remoteData['undo3'] as int?) ?? 0,
    );
    final merged = SyncConflictResolver.mergeInventory(local, remote);
    await box.put('data', merged);
  }

  Future<void> _writeLocalProfileToFirestore() async {
    if (_userId == null) return;
    final prBox = await Hive.openBox<PersonalRecords>(_personalRecordsBox);
    final pr = prBox.get(_personalRecordsKey) ?? const PersonalRecords();
    await _firestore.collection('users').doc(_userId).set({
      'userId': _userId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
      'personalRecords': {
        'timesReached2048': pr.timesReached2048,
        'timesReached4096': pr.timesReached4096,
        'timesReached8192': pr.timesReached8192,
        'highestLevelEver': pr.highestLevelEver,
        'rewardCollected4096': pr.rewardCollected4096,
        'rewardCollected8192': pr.rewardCollected8192,
        if (pr.firstReached2048At != null)
          'firstReached2048At': Timestamp.fromDate(pr.firstReached2048At!),
        if (pr.firstReached4096At != null)
          'firstReached4096At': Timestamp.fromDate(pr.firstReached4096At!),
        if (pr.firstReached8192At != null)
          'firstReached8192At': Timestamp.fromDate(pr.firstReached8192At!),
      },
    }, SetOptions(merge: true));
  }

  PersonalRecords _personalRecordsFromMap(Map<String, dynamic> m) {
    final ts2048 = m['firstReached2048At'] as Timestamp?;
    final ts4096 = m['firstReached4096At'] as Timestamp?;
    final ts8192 = m['firstReached8192At'] as Timestamp?;
    return PersonalRecords(
      timesReached2048: (m['timesReached2048'] as int?) ?? 0,
      timesReached4096: (m['timesReached4096'] as int?) ?? 0,
      timesReached8192: (m['timesReached8192'] as int?) ?? 0,
      highestLevelEver: (m['highestLevelEver'] as int?) ?? 0,
      rewardCollected4096: (m['rewardCollected4096'] as bool?) ?? false,
      rewardCollected8192: (m['rewardCollected8192'] as bool?) ?? false,
      firstReached2048At: ts2048?.toDate(),
      firstReached4096At: ts4096?.toDate(),
      firstReached8192At: ts8192?.toDate(),
    );
  }

  @override
  String? get remoteAvatarUrl => _remoteAvatarUrl;

  @override
  String? get remoteDisplayName => _remoteDisplayName;

  @override
  Future<void> updateDisplayName(String name) async {
    if (_userId == null) return;
    await _firestore.collection('users').doc(_userId).set({
      'displayName': name,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteUserData() async {
    if (_userId == null) return;
    await _firestore.collection('users').doc(_userId).delete();
  }

  @override
  Future<void> syncGameRecord(GameRecord record) async {
    if (_userId == null) return;
    final docRef = _firestore.collection('users').doc(_userId);
    final doc = await docRef.get();
    final existing = ((doc.data()?['gameRecords'] as List<dynamic>?) ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
    existing.add(record.toJson());
    existing.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    final top20 = existing.take(20).toList();
    await docRef.set({'gameRecords': top20}, SetOptions(merge: true));
  }

  Future<void> _mergeRemoteGameRecords(
    List<Map<String, dynamic>>? remoteData,
  ) async {
    if (remoteData == null || remoteData.isEmpty) return;
    if (!Hive.isAdapterRegistered(GameRecord.hiveTypeId)) {
      Hive.registerAdapter(GameRecordHiveAdapter());
    }
    final box = await Hive.openBox<GameRecord>('game_records');
    final local = box.values.toList();

    final Map<String, GameRecord> byKey = {};
    for (final r in local) {
      byKey['\${r.playedAt.toIso8601String()}_\${r.score}'] = r;
    }
    for (final json in remoteData) {
      try {
        final r = GameRecord.fromJson(json);
        byKey['\${r.playedAt.toIso8601String()}_\${r.score}'] = r;
      } catch (_) {}
    }
    final merged = byKey.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final top20 = merged.take(20).toList();

    await box.clear();
    for (final r in top20) {
      await box.add(r);
    }
  }
}
