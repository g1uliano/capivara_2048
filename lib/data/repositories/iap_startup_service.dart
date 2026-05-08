// lib/data/repositories/iap_startup_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

abstract class IAPStartupService {
  /// Opens a permanent subscription on purchaseStream.
  /// Must be called after login with the logged-in userId.
  Future<void> initialize(String userId);

  /// Cancels the subscription. Called on logout.
  Future<void> dispose();
}

/// Real implementation — used in prd and tst with USE_REAL_IAP=true.
class IAPStartupServiceImpl implements IAPStartupService {
  final FirebaseFirestore _firestore;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  String? _userId;

  IAPStartupServiceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> initialize(String userId) async {
    _userId = userId;
    await _sub?.cancel();
    _sub = InAppPurchase.instance.purchaseStream.listen(
      _handlePurchases,
      onError: (_) {},
    );
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _userId = null;
  }

  void _handlePurchases(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (_userId != null) unawaited(_deliverAndComplete(p));
        case PurchaseStatus.pending:
          debugPrint('[IAPStartup] pending: ${p.productID}');
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          unawaited(InAppPurchase.instance.completePurchase(p));
      }
    }
  }

  Future<void> _deliverAndComplete(PurchaseDetails p) async {
    try {
      final purchaseId =
          p.purchaseID ?? p.verificationData.serverVerificationData;
      final docRef = _firestore
          .collection('purchases')
          .doc(_userId)
          .collection('items')
          .doc(purchaseId);

      final existing = await docRef.get();
      if (existing.exists && existing.data()?['status'] == 'delivered') {
        await InAppPurchase.instance.completePurchase(p);
        return;
      }

      await docRef.set({
        'status': 'pending_orphan',
        'productId': p.productID,
        'platform': p.verificationData.source,
        'processedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await InAppPurchase.instance.completePurchase(p);
      debugPrint('[IAPStartup] pending_orphan: ${p.productID}');
    } catch (e) {
      debugPrint('[IAPStartup] error: $e');
    }
  }
}

/// No-op fake for tests and dev flavor.
class FakeIAPStartupService implements IAPStartupService {
  bool initializeCalled = false;
  bool disposeCalled = false;
  String? lastUserId;

  @override
  Future<void> initialize(String userId) async {
    initializeCalled = true;
    lastUserId = userId;
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
  }
}

final iapStartupServiceProvider = Provider<IAPStartupService>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  const useRealIap = bool.fromEnvironment('USE_REAL_IAP', defaultValue: false);
  if (flavor == 'prd' || flavor == 'dev' || (flavor == 'tst' && useRealIap)) {
    return IAPStartupServiceImpl();
  }
  return FakeIAPStartupService();
});
