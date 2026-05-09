import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/iap_delivery.dart';
import '../../data/models/item_type.dart';
import '../../data/models/shop_package.dart';
import '../../data/shop_data.dart';
import '../../domain/shop/iap_service.dart';
import '../widgets/outlined_text.dart';
import 'auth_gate_overlay.dart';
import 'iap_confirmation_sheet.dart';
import 'purchase_success_sheet.dart';
import 'shop_package_card.dart';
import 'shop_unit_item_card.dart';

class ShopOverlay extends ConsumerStatefulWidget {
  const ShopOverlay({
    super.key,
    required this.itemType,
    required this.onClose,
    required this.onItemPurchased,
  });

  final ItemType itemType;
  final VoidCallback onClose;
  final void Function(ItemType) onItemPurchased;

  @override
  ConsumerState<ShopOverlay> createState() => _ShopOverlayState();
}

class _ShopOverlayState extends ConsumerState<ShopOverlay> {
  late final List<String> _relevantIds;

  @override
  void initState() {
    super.initState();
    _relevantIds = packageIdsContaining(widget.itemType);
  }

  Future<void> _onBuy(ShopPackage package) async {
    // 1. Confirmation sheet (same as main shop)
    final confirmed = await IAPConfirmationSheet.show(context, package);
    if (!confirmed || !mounted) return;

    // 2. Call IAP service (IAPServiceImpl in dev/prd; FakeIAPService in tst)
    final iapService = ref.read(iapServiceProvider);
    final result = await iapService.buyPackage(package);
    if (!mounted) return;

    if (result.success) {
      deliverIAPItems(ref, package);
      if (result.shareCode != null && mounted) {
        await PurchaseSuccessSheet.show(context, result.shareCode!);
      }
      widget.onItemPurchased(widget.itemType);
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na compra: ${result.error}')),
      );
    }
    // cancelled → do nothing
  }

  @override
  Widget build(BuildContext context) {
    return AuthGateOverlay(
      reason: 'Para acessar a Loja você precisa estar conectado.',
      onClose: widget.onClose,
      child: _buildShopContent(context),
    );
  }

  Widget _buildShopContent(BuildContext context) {
    final packages = ref.watch(shopPackagesProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) widget.onClose();
      },
      child: Stack(
        children: [
          AbsorbPointer(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.75),
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const OutlinedText(
                        text: 'Loja',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Fredoka',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white30),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (final pkg in packages)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ShopPackageCard(
                              package: pkg,
                              onBuy: () => _onBuy(pkg),
                              highlighted: _relevantIds.contains(pkg.id),
                            ),
                          ),
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedText(
                            text: 'Itens avulsos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Fredoka',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final item in const [
                          ItemType.bomb3,
                          ItemType.undo3,
                          ItemType.bomb2,
                          ItemType.undo1,
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: ShopUnitItemCard(
                              item: item,
                              highlighted: item == widget.itemType,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
