import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../../domain/ranking/ranking_repository.dart';
import '../../domain/ranking/week_id.dart';
import '../../domain/ranking/weekly_reward_result.dart';
import '../models/inventory.dart';
import '../models/lives_state.dart';

class FirestoreRankingRepository implements RankingRepository {
  final String userId;
  final FirebaseFirestore _firestore;

  FirestoreRankingRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Collection references ─────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _weeklyCollection(
    String weekId,
    RankingType type,
  ) {
    assert(
      type == RankingType.globalTime || type == RankingType.globalScore,
      '_weeklyCollection called with legends type: $type',
    );
    final sub = type == RankingType.globalScore ? 'globalScore' : 'globalTime';
    return _firestore.collection('rankings').doc(weekId).collection(sub);
  }

  CollectionReference<Map<String, dynamic>> _legendsCollection(
    RankingType type,
  ) {
    final tier = type == RankingType.legends8192Count ? '8192' : '4096';
    return _firestore
        .collection('legendsRankings')
        .doc(tier)
        .collection('entries');
  }

  // ── Query helpers ─────────────────────────────────────────────────────────

  Query<Map<String, dynamic>> _buildQuery(RankingType type) {
    final weekId = WeekId.fromUtc(DateTime.now().toUtc());
    switch (type) {
      case RankingType.globalTime:
        return _weeklyCollection(
          weekId,
          type,
        ).orderBy('bestTimeMs', descending: false).limit(50);
      case RankingType.globalScore:
        return _weeklyCollection(
          weekId,
          type,
        ).orderBy('value', descending: true).limit(50);
      case RankingType.legends4096Time:
        return _legendsCollection(
          type,
        ).orderBy('timesReached', descending: true).limit(50);
      case RankingType.legends8192Count:
        return _legendsCollection(type)
            .orderBy('timesReached', descending: true)
            .orderBy('firstReachedAt', descending: false)
            .limit(50);
    }
  }

  // ── Conversion ────────────────────────────────────────────────────────────

  List<RankingEntry> _docsToEntries(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    RankingType type,
  ) {
    if (docs.isEmpty) return [];

    final entries = <RankingEntry>[];
    int rank = 1;

    for (int i = 0; i < docs.length; i++) {
      final data = docs[i].data();
      final entryUserId = data['userId'] as String? ?? docs[i].id;
      final displayName = data['displayName'] as String? ?? entryUserId;

      final int value;
      if (type == RankingType.globalTime) {
        value = (data['bestTimeMs'] as num?)?.toInt() ?? 0;
      } else if (type == RankingType.globalScore) {
        value = (data['value'] as num?)?.toInt() ?? 0;
      } else {
        // legends
        value = (data['timesReached'] as num?)?.toInt() ?? 0;
      }

      // Compute rank considering ties
      if (i > 0) {
        final prevData = docs[i - 1].data();
        final int prevValue;
        if (type == RankingType.globalTime) {
          prevValue = (prevData['bestTimeMs'] as num?)?.toInt() ?? 0;
        } else if (type == RankingType.globalScore) {
          prevValue = (prevData['value'] as num?)?.toInt() ?? 0;
        } else {
          prevValue = (prevData['timesReached'] as num?)?.toInt() ?? 0;
        }
        if (value != prevValue) {
          rank = i + 1;
        }
        // else rank stays the same (tie)
      }

      entries.add(
        RankingEntry(
          rank: rank,
          playerName: displayName,
          userId: entryUserId,
          value: value,
          isLocalPlayer: entryUserId == userId,
        ),
      );
    }

    return entries;
  }

  // ── Interface implementation ──────────────────────────────────────────────

  @override
  Future<List<RankingEntry>> getWeeklyTop(RankingType type) async {
    final snap = await _buildQuery(type).get();
    return _docsToEntries(snap.docs, type);
  }

  @override
  Stream<List<RankingEntry>> watchWeeklyTop(RankingType type) {
    return _buildQuery(
      type,
    ).snapshots().map((snap) => _docsToEntries(snap.docs, type));
  }

  @override
  Future<RankingEntry?> getPlayerEntry(RankingType type) async {
    final CollectionReference<Map<String, dynamic>> col;
    if (type == RankingType.globalTime || type == RankingType.globalScore) {
      final weekId = WeekId.fromUtc(DateTime.now().toUtc());
      col = _weeklyCollection(weekId, type);
    } else {
      col = _legendsCollection(type);
    }

    final docSnap = await col.doc(userId).get();
    if (!docSnap.exists) return null;

    final data = docSnap.data()!;
    final displayName = data['displayName'] as String? ?? userId;

    final int playerValue;
    final int rank;

    if (type == RankingType.globalTime) {
      playerValue = (data['bestTimeMs'] as num?)?.toInt() ?? 0;
      final countSnap =
          await col.where('bestTimeMs', isLessThan: playerValue).count().get();
      rank = (countSnap.count ?? 0) + 1;
    } else if (type == RankingType.globalScore) {
      playerValue = (data['value'] as num?)?.toInt() ?? 0;
      final countSnap =
          await col.where('value', isGreaterThan: playerValue).count().get();
      rank = (countSnap.count ?? 0) + 1;
    } else {
      // legends
      playerValue = (data['timesReached'] as num?)?.toInt() ?? 0;
      final countSnap = await col
          .where('timesReached', isGreaterThan: playerValue)
          .count()
          .get();
      rank = (countSnap.count ?? 0) + 1;
    }

    return RankingEntry(
      rank: rank,
      playerName: displayName,
      userId: userId,
      value: playerValue,
      isLocalPlayer: true,
    );
  }

  @override
  Future<void> submitScore(
    RankingType type,
    int value, {
    String? displayName,
  }) async {
    // Legends rankings are managed by the SyncEngine via PendingEvents.
    if (type == RankingType.legends4096Time ||
        type == RankingType.legends8192Count) {
      return;
    }

    final weekId = WeekId.fromUtc(DateTime.now().toUtc());
    final col = _weeklyCollection(weekId, type);
    final docRef = col.doc(userId);
    final snap = await docRef.get();

    if (!snap.exists) {
      // Create new entry
      final data = <String, dynamic>{
        'userId': userId,
        'displayName': displayName ?? userId,
        'submittedAt': FieldValue.serverTimestamp(),
      };
      if (type == RankingType.globalTime) {
        data['bestTimeMs'] = value;
      } else {
        data['value'] = value;
      }
      await docRef.set(data);
    } else {
      // Update only if better
      final existing = snap.data()!;
      if (type == RankingType.globalTime) {
        final current = (existing['bestTimeMs'] as num?)?.toInt() ?? 0;
        if (value < current) {
          await docRef.update({
            'bestTimeMs': value,
            'submittedAt': FieldValue.serverTimestamp(),
            if (displayName != null) 'displayName': displayName,
          });
        }
      } else {
        // globalScore
        final current = (existing['value'] as num?)?.toInt() ?? 0;
        if (value > current) {
          await docRef.update({
            'value': value,
            'submittedAt': FieldValue.serverTimestamp(),
            if (displayName != null) 'displayName': displayName,
          });
        }
      }
    }
  }

  @override
  Future<WeeklyRewardResult?> checkAndClaimWeeklyReward(String weekId) async {
    // Check if already claimed
    final rewardsBox = await Hive.openBox<String>('ranking_rewards');
    if (rewardsBox.get(weekId) == 'claimed') return null;

    // Look up player in the previous week's globalTime ranking
    final previousWeekId = _previousWeekId(weekId);

    final snap = await _buildQueryForWeek(
      previousWeekId,
      RankingType.globalTime,
    ).get();
    final entries = _docsToEntries(snap.docs, RankingType.globalTime);

    RankingEntry? playerEntry;
    try {
      playerEntry = entries.firstWhere((e) => e.userId == userId);
    } catch (_) {
      playerEntry = null;
    }

    if (playerEntry == null) return null;

    final reward = WeeklyRewardResult.forPosition(
      playerEntry.rank,
      weekId: previousWeekId,
    );

    if (!reward.hasReward) return null;

    // Deliver reward
    await _deliverReward(reward);

    // Mark as claimed
    await rewardsBox.put(weekId, 'claimed');

    return reward;
  }

  /// Derives the previous week identifier from [currentWeekId].
  String _previousWeekId(String currentWeekId) {
    final currentStart = WeekId.weekStartsAt(DateTime.now().toUtc());
    final prevInstant = currentStart.subtract(const Duration(seconds: 1));
    return WeekId.fromUtc(prevInstant);
  }

  Query<Map<String, dynamic>> _buildQueryForWeek(
    String weekId,
    RankingType type,
  ) {
    return _weeklyCollection(
      weekId,
      type,
    ).orderBy('bestTimeMs', descending: false).limit(50);
  }

  Future<void> _deliverReward(WeeklyRewardResult reward) async {
    // Inventory
    final invBox = await Hive.openBox<Inventory>('inventory');
    final inv = invBox.get('inventory') ?? Inventory.empty();
    await invBox.put(
      'inventory',
      Inventory(
        bomb2: inv.bomb2 + reward.bomb2,
        bomb3: inv.bomb3 + reward.bomb3,
        undo1: inv.undo1 + reward.undo1,
        undo3: inv.undo3,
      ),
    );

    // Lives
    if (reward.lives > 0) {
      final livesBox = await Hive.openBox<LivesState>('lives');
      final ls = livesBox.get('state');
      if (ls != null) {
        final newLives = (ls.lives + reward.lives).clamp(0, 15);
        await livesBox.put('state', ls.copyWith(lives: newLives));
      }
    }
  }
}
