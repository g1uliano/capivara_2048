import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../data/models/inventory.dart';
import '../../data/models/lives_state.dart';
import '../../data/models/shop_package.dart';
import '../../domain/shop/iap_service.dart';

class IAPServiceImpl implements IAPService {
  final String userId;
  final FirebaseFirestore _firestore;

  IAPServiceImpl({required this.userId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  bool get isAvailable => true;

  @override
  Future<PurchaseResult> buyPackage(ShopPackage package) async {
    final iap = InAppPurchase.instance;
    if (!await iap.isAvailable()) {
      return const PurchaseResult.failed('Loja não disponível no momento.');
    }

    // Load product details
    final response = await iap.queryProductDetails({
      'bichim_pack_${package.id}',
    });
    if (response.productDetails.isEmpty) {
      return const PurchaseResult.failed('Produto não encontrado na loja.');
    }

    final completer = Completer<PurchaseResult>();
    late StreamSubscription<List<PurchaseDetails>> sub;

    sub = iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.productID != 'bichim_pack_${package.id}') continue;
        switch (purchase.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            // restored: Firestore idempotency prevents duplicate delivery
            final result = await _deliverAndRecord(purchase, package);
            await iap.completePurchase(purchase);
            if (!completer.isCompleted) completer.complete(result);
            await sub.cancel();
          case PurchaseStatus.pending:
            // Pending payment (boleto, Google Pay, carrier billing)
            // Do NOT close subscription — wait for final status
            // Do NOT call completePurchase here
            break;
          case PurchaseStatus.error:
            await iap.completePurchase(purchase);
            if (!completer.isCompleted) {
              completer.complete(PurchaseResult.failed(
                  purchase.error?.message ?? 'Erro desconhecido'));
            }
            await sub.cancel();
          case PurchaseStatus.canceled:
            if (!completer.isCompleted) {
              completer.complete(const PurchaseResult.cancelled());
            }
            await sub.cancel();
        }
      }
    });

    final param = PurchaseParam(productDetails: response.productDetails.first);
    await iap.buyConsumable(purchaseParam: param);

    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        sub.cancel();
        return const PurchaseResult.failed('Tempo esgotado.');
      },
    );
  }

  @override
  Future<void> restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
  }

  Future<PurchaseResult> _deliverAndRecord(
    PurchaseDetails purchase,
    ShopPackage package,
  ) async {
    final purchaseId =
        purchase.purchaseID ?? purchase.verificationData.serverVerificationData;
    final docRef = _firestore
        .collection('purchases')
        .doc(userId)
        .collection('items')
        .doc(purchaseId);

    // Idempotency check
    final existing = await docRef.get();
    if (existing.exists && existing.data()?['status'] == 'delivered') {
      return PurchaseResult.succeeded(
        shareCode: existing.data()?['shareCode'] as String? ?? '',
      );
    }

    await docRef.set({
      'status': 'pending',
      'packageId': package.id,
      'purchasedAt': FieldValue.serverTimestamp(),
    });

    await _deliverToHive(package.contents);

    final code = _generateShareCode();
    await _firestore.collection('shareCodes').doc(code).set({
      'code': code,
      'packageId': package.id,
      'giftContents': {
        'lives': package.giftContents.lives,
        'bomb2': package.giftContents.bomb2,
        'bomb3': package.giftContents.bomb3,
        'undo1': package.giftContents.undo1,
        'undo3': package.giftContents.undo3,
      },
      'status': 'pending',
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)),
      ),
    });

    await docRef.update({
      'status': 'delivered',
      'shareCode': code,
      'deliveredAt': FieldValue.serverTimestamp(),
    });

    return PurchaseResult.succeeded(shareCode: code);
  }

  Future<void> _deliverToHive(RewardBundle contents) async {
    final invBox = await Hive.openBox<Inventory>('inventory');
    final inv = invBox.get('data') ?? Inventory.empty();
    await invBox.put(
      'data',
      Inventory(
        bomb2: inv.bomb2 + contents.bomb2,
        bomb3: inv.bomb3 + contents.bomb3,
        undo1: inv.undo1 + contents.undo1,
        undo3: inv.undo3 + contents.undo3,
      ),
    );
    if (contents.lives > 0) {
      final livesBox = await Hive.openBox<LivesState>('lives');
      final ls = livesBox.get('state') ?? LivesState.initial();
      await livesBox.put(
        'state',
        ls.copyWith(lives: (ls.lives + contents.lives).clamp(0, 15)),
      );
    }
  }

  String _generateShareCode() {
    const animals = [
      'CAPIVARA',
      'ONCA',
      'BOTO',
      'SUCURI',
      'TUCANO',
      'PREGUICA',
    ];
    final animal = animals[Random().nextInt(animals.length)];
    final digits = (1000 + Random().nextInt(9000)).toString();
    final letters = String.fromCharCodes(
      List.generate(2, (_) => 65 + Random().nextInt(26)),
    );
    return '$animal-$digits-$letters';
  }
}
