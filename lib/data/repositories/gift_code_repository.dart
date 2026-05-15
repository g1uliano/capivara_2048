// lib/data/repositories/gift_code_repository.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/share_code.dart';
import '../models/shop_package.dart';

enum RedeemError { notFound, alreadyRedeemed, expired, ownCode, offline }

class RedeemException implements Exception {
  final RedeemError error;
  const RedeemException(this.error);
}

/// Pure validation — no Firestore dependency, fully unit-testable.
RedeemError? validateGiftCode({
  required String status,
  required String createdBy,
  required DateTime createdAt,
  required String userId,
  required DateTime now,
}) {
  if (status == 'redeemed') return RedeemError.alreadyRedeemed;
  if (createdBy == userId) return RedeemError.ownCode;
  if (now.difference(createdAt).inDays > 30) return RedeemError.expired;
  return null;
}

class GiftCodeRepository {
  final FirebaseFirestore _db;

  GiftCodeRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<void> writeToFirestore(ShareCode code, String userId) async {
    await _db.collection('shareCodes').doc(code.code).set({
      'code': code.code,
      'packageId': code.packageId,
      'giftContents': {
        'lives': code.giftContents.lives,
        'bomb2': code.giftContents.bomb2,
        'bomb3': code.giftContents.bomb3,
        'undo1': code.giftContents.undo1,
        'undo3': code.giftContents.undo3,
      },
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': userId,
      'redeemedBy': null,
      'redeemedAt': null,
    });
  }

  /// Atomically redeems a gift code and returns the reward bundle.
  /// Throws [RedeemException] for all validation failures.
  Future<RewardBundle> redeemCode(String code, String userId) async {
    final docRef = _db.collection('shareCodes').doc(code.trim());
    RewardBundle? result;
    try {
      await _db.runTransaction((txn) async {
        final snap = await txn.get(docRef);
        if (!snap.exists) throw const RedeemException(RedeemError.notFound);
        final data = snap.data()!;
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final validationError = validateGiftCode(
          status: data['status'] as String,
          createdBy: data['createdBy'] as String,
          createdAt: createdAt,
          userId: userId,
          now: DateTime.now(),
        );
        if (validationError != null) throw RedeemException(validationError);
        final g = data['giftContents'] as Map<String, dynamic>;
        result = RewardBundle(
          lives: g['lives'] as int,
          bomb2: g['bomb2'] as int,
          bomb3: g['bomb3'] as int,
          undo1: g['undo1'] as int,
          undo3: g['undo3'] as int,
        );
        txn.update(docRef, {
          'status': 'redeemed',
          'redeemedBy': userId,
          'redeemedAt': FieldValue.serverTimestamp(),
        });
      });
    } on RedeemException {
      rethrow;
    } on FirebaseException {
      throw const RedeemException(RedeemError.offline);
    } catch (_) {
      throw const RedeemException(RedeemError.offline);
    }
    return result!;
  }
}

final giftCodeRepositoryProvider = Provider<GiftCodeRepository>(
  (ref) => GiftCodeRepository(),
);
