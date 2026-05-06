import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/shop_package.dart';

class PurchaseResult {
  final bool success;
  final String? error;
  final String? shareCode;

  const PurchaseResult({required this.success, this.error, this.shareCode});

  const PurchaseResult.succeeded({required String shareCode})
      : success = true,
        error = null,
        shareCode = shareCode;

  const PurchaseResult.failed(String error)
      : success = false,
        error = error,
        shareCode = null;

  const PurchaseResult.cancelled()
      : success = false,
        error = null,
        shareCode = null;

  bool get isCancelled => !success && error == null;
}

abstract class IAPService {
  Future<PurchaseResult> buyPackage(ShopPackage package);
  Future<void> restorePurchases();
  bool get isAvailable;
}

class FakeIAPService implements IAPService {
  @override
  bool get isAvailable => true;

  @override
  Future<PurchaseResult> buyPackage(ShopPackage package) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const PurchaseResult.succeeded(shareCode: 'CAPIVARA-1234-AB');
  }

  @override
  Future<void> restorePurchases() async {}
}

final iapServiceProvider = Provider<IAPService>((_) => FakeIAPService());
