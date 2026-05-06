// lib/presentation/screens/shop_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/item_type.dart';
import '../../data/models/share_code.dart';
import '../../data/shop_data.dart';
import '../../data/models/shop_package.dart';
import '../../domain/inventory/inventory_notifier.dart';
import '../../domain/lives/lives_notifier.dart';
import '../../domain/shop/iap_service.dart';
import '../../domain/shop/share_codes_notifier.dart';
import '../widgets/game_background.dart';
import '../widgets/iap_confirmation_sheet.dart';
import '../widgets/outlined_text.dart';
import '../widgets/purchase_success_sheet.dart';
import '../widgets/shop_package_card.dart';
import '../widgets/shop_unit_item_card.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packages = ref.watch(shopPackagesProvider);

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Loja',
            style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            ...packages.map(
              (pkg) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ShopPackageCard(
                  highlighted: false,
                  package: pkg,
                  onBuy: () => _onBuy(context, ref, pkg),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: OutlinedText(
                text: 'Itens avulsos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Fredoka',
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 12),
            ...const [ItemType.bomb3, ItemType.undo3, ItemType.bomb2, ItemType.undo1]
                .map((item) => Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: ShopUnitItemCard(item: item),
                    )),
          ],
        ),
      ),
    );
  }

  Future<void> _onBuy(
    BuildContext context,
    WidgetRef ref,
    ShopPackage package,
  ) async {
    // Step 1: Show confirmation sheet
    final confirmed = await IAPConfirmationSheet.show(context, package);
    if (!confirmed || !context.mounted) return;

    // Step 2: Call IAPService (FakeIAPService in dev)
    final iapService = ref.read(iapServiceProvider);
    final result = await iapService.buyPackage(package);

    if (!context.mounted) return;

    if (result.success && result.shareCode != null) {
      // In dev/fake: deliver items to Riverpod state manually
      const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
      if (flavor != 'prd') {
        _deliverItemsLocally(ref, package);
      }
      if (context.mounted) {
        await PurchaseSuccessSheet.show(context, result.shareCode!);
      }
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na compra: ${result.error}')));
    }
    // cancelled → do nothing
  }

  void _deliverItemsLocally(WidgetRef ref, ShopPackage package) {
    final c = package.contents;
    if (c.lives > 0) {
      unawaited(ref.read(livesProvider.notifier).addPurchased(c.lives));
    }
    if (c.bomb2 > 0) unawaited(ref.read(inventoryProvider.notifier).add(ItemType.bomb2, c.bomb2));
    if (c.bomb3 > 0) unawaited(ref.read(inventoryProvider.notifier).add(ItemType.bomb3, c.bomb3));
    if (c.undo1 > 0) unawaited(ref.read(inventoryProvider.notifier).add(ItemType.undo1, c.undo1));
    if (c.undo3 > 0) unawaited(ref.read(inventoryProvider.notifier).add(ItemType.undo3, c.undo3));
    // Generate fake share code for dev
    unawaited(ref.read(shareCodesProvider.notifier).add(ShareCode(
      code: 'DEV-${DateTime.now().millisecondsSinceEpoch % 10000}-AB',
      packageId: package.id,
      giftContents: package.giftContents,
      status: ShareCodeStatus.pending,
      createdAt: DateTime.now(),
    )));
  }
}
