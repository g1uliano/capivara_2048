import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/inventory.dart';
import '../../data/models/lives_state.dart';
import '../../domain/invites/invite_service.dart';

class FirestoreInviteRepository implements InviteService {
  final String userId;
  final String? displayName;
  final FirebaseFirestore _firestore;

  static const _inviteRefsBox = 'invite_refs';
  static const _pendingRefKey = 'pending_ref';
  static const _maxInvites = 20;

  FirestoreInviteRepository({
    required this.userId,
    this.displayName,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> generateInviteLink(String userId) async {
    await _firestore.collection('invites').doc(userId).set({
      'inviterDisplayName': displayName ?? 'Jogador',
      'invites': [],
      'totalRewardsClaimed': 0,
    }, SetOptions(merge: true));
    return 'https://bichim-prd.web.app/invite?ref=$userId';
  }

  @override
  Future<void> registerInvite({
    required String inviterId,
    required String inviteeId,
    required String inviteeDisplayName,
  }) async {
    await _firestore.runTransaction((tx) async {
      final ref = _firestore.collection('invites').doc(inviterId);
      final snap = await tx.get(ref);
      if (!snap.exists) {
        // Inviter doc doesn't exist yet — create it
        tx.set(ref, {
          'inviterDisplayName': 'Jogador',
          'invites': [
            {
              'inviteeId': inviteeId,
              'inviteeDisplayName': inviteeDisplayName,
              'status': 'pending',
            },
          ],
          'totalRewardsClaimed': 0,
        });
        return;
      }
      final invites = List<Map<String, dynamic>>.from(
        snap.data()?['invites'] as List? ?? [],
      );
      // No-op if already registered
      if (invites.any((i) => i['inviteeId'] == inviteeId)) return;
      // Max 20 active invites
      if (invites.length >= _maxInvites) return;
      invites.add({
        'inviteeId': inviteeId,
        'inviteeDisplayName': inviteeDisplayName,
        'status': 'pending',
      });
      tx.update(ref, {'invites': invites});
    });
    // Save pending ref to Hive (this device is the invitee)
    final box = await Hive.openBox<String>(_inviteRefsBox);
    await box.put(_pendingRefKey, inviterId);
  }

  @override
  Future<bool> completeInviteReward({
    required String inviteeId,
    required String inviteeDisplayName,
  }) async {
    // Check for pending invite ref
    final box = await Hive.openBox<String>(_inviteRefsBox);
    final inviterId = box.get(_pendingRefKey);
    if (inviterId == null) return false;

    bool completed = false;
    await _firestore.runTransaction((tx) async {
      final ref = _firestore.collection('invites').doc(inviterId);
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final invites = List<Map<String, dynamic>>.from(
        snap.data()?['invites'] as List? ?? [],
      );
      final idx = invites.indexWhere(
        (i) => i['inviteeId'] == inviteeId && i['status'] == 'pending',
      );
      if (idx == -1) return;

      invites[idx] = {
        ...invites[idx],
        'status': 'completed',
        'completedAt': Timestamp.now(),
      };

      // Deliver reward to inviter: 1 combo (1 vida + 1 bomb3 + 1 undo1) via Firestore
      // - inventory items synced by _mergeRemoteInventory on next login
      // - lives delivered via pendingLives field claimed in syncProfile()
      final inviterRef = _firestore.collection('users').doc(inviterId);
      tx.set(inviterRef, {
        'inventory': {
          'bomb3': FieldValue.increment(1),
          'undo1': FieldValue.increment(1),
        },
        'pendingLives': FieldValue.increment(1),
      }, SetOptions(merge: true));

      tx.update(ref, {
        'invites': invites,
        'totalRewardsClaimed': FieldValue.increment(1),
      });
      completed = true;
    });

    if (!completed) return false;

    // Deliver reward to invitee (local Hive)
    await _deliverLocalReward();

    // Clear pending ref
    await box.delete(_pendingRefKey);

    return true;
  }

  Future<void> _deliverLocalReward() async {
    // 2 lives
    final livesBox = await Hive.openBox<LivesState>('lives');
    final ls = livesBox.get('state') ?? LivesState.initial();
    await livesBox.put(
      'state',
      ls.copyWith(lives: (ls.lives + 2).clamp(0, 15)),
    );
    // 1× Bomb2
    final invBox = await Hive.openBox<Inventory>('inventory');
    final inv = invBox.get('data') ?? Inventory.empty();
    await invBox.put(
      'data',
      Inventory(
        bomb2: inv.bomb2 + 1,
        bomb3: inv.bomb3,
        undo1: inv.undo1,
        undo3: inv.undo3,
      ),
    );
  }
}
