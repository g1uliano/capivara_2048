// lib/presentation/screens/shop_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../../data/repositories/gift_code_repository.dart';
import 'redeem_code_screen.dart';
import '../../core/utils/iap_delivery.dart';
import '../../data/models/item_type.dart';
import '../../data/models/share_code.dart';
import '../../data/shop_data.dart';
import '../../data/models/shop_package.dart';
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
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RedeemCodeScreen(),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C42),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.card_giftcard_outlined, size: 20),
                label: Text(
                  'Resgatar código de presente',
                  style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: OutlinedText(
                text: 'Itens avulsos',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 12),
            ...const [
              ItemType.bomb3,
              ItemType.undo3,
              ItemType.bomb2,
              ItemType.undo1,
            ].map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: ShopUnitItemCard(item: item),
              ),
            ),
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
      // Deliver items locally (needed in dev/tst; in prd server-side webhook does it too)
      deliverIAPItems(ref, package);
      final userId = ref.read(authControllerProvider)?.userId;
      if (userId != null) {
        unawaited(
          ref
              .read(giftCodeRepositoryProvider)
              .writeToFirestore(
                ShareCode(
                  code: result.shareCode!,
                  packageId: package.id,
                  giftContents: package.giftContents,
                  status: ShareCodeStatus.pending,
                  createdAt: DateTime.now(),
                ),
                userId,
              ),
        );
      }
      // In dev: also generate a local share code for testing the gift flow
      const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
      if (flavor != 'prd') {
        unawaited(
          ref
              .read(shareCodesProvider.notifier)
              .add(
                ShareCode(
                  code:
                      'DEV-${DateTime.now().millisecondsSinceEpoch % 10000}-AB',
                  packageId: package.id,
                  giftContents: package.giftContents,
                  status: ShareCodeStatus.pending,
                  createdAt: DateTime.now(),
                ),
              ),
        );
      }
      if (context.mounted) {
        await PurchaseSuccessSheet.show(context, result.shareCode!);
      }
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na compra: ${result.error}')),
      );
    }
    // cancelled → do nothing
  }
}
