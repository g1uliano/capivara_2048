import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/iap_delivery.dart';
import '../../data/models/item_type.dart';
import '../../data/shop_data.dart';
import '../../domain/shop/iap_service.dart';
import 'iap_confirmation_sheet.dart';
import 'purchase_success_sheet.dart';

class ShopUnitItemCard extends ConsumerWidget {
  final ItemType item;
  final bool highlighted;
  const ShopUnitItemCard({
    super.key,
    required this.item,
    this.highlighted = false,
  });

  String get _png => switch (item) {
    ItemType.bomb2 => 'assets/images/inventory/bomb_2.webp',
    ItemType.bomb3 => 'assets/images/inventory/bomb_3.webp',
    ItemType.undo1 => 'assets/images/inventory/undo_1.webp',
    ItemType.undo3 => 'assets/images/inventory/undo_3.webp',
  };

  String get _name => switch (item) {
    ItemType.bomb2 => 'Bomba 2',
    ItemType.bomb3 => 'Bomba 3',
    ItemType.undo1 => 'Desfazer 1',
    ItemType.undo3 => 'Desfazer 3',
  };

  String get _price {
    final p = kItemUnitPrices[item] ?? 0.0;
    return 'R\$ ${p.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Future<void> _buy(BuildContext context, WidgetRef ref) async {
    final package = kUnitPackageByType[item]!;

    // 1. Confirmation sheet (same as main shop)
    final confirmed = await IAPConfirmationSheet.show(context, package);
    if (!confirmed || !context.mounted) return;

    // 2. Call IAP service (IAPServiceImpl in dev/prd; FakeIAPService in tst)
    final iapService = ref.read(iapServiceProvider);
    final result = await iapService.buyPackage(package);
    if (!context.mounted) return;

    if (result.success) {
      deliverIAPItems(ref, package);
      if (result.shareCode != null && context.mounted) {
        await PurchaseSuccessSheet.show(context, result.shareCode!);
      }
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na compra: ${result.error}')),
      );
    }
    // cancelled (error == null && !success) → do nothing
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highlighted
            ? const BorderSide(color: Color(0xFFFF8C42), width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Image.asset(_png, width: 40, height: 40),
            const SizedBox(width: 8),
            Expanded(child: Text(_name, style: const TextStyle(fontSize: 16))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C42),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () => _buy(context, ref),
              child: Text(
                _price,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
