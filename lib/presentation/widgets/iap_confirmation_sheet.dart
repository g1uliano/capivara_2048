import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/shop_package.dart';

class IAPConfirmationSheet extends StatelessWidget {
  const IAPConfirmationSheet({
    super.key,
    required this.package,
    this.onConfirm,
    this.onCancel,
  });

  final ShopPackage package;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  /// Shows the bottom sheet and returns true if the user confirmed.
  static Future<bool> show(BuildContext context, ShopPackage package) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => IAPConfirmationSheet(
        package: package,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final price =
        'R\$ ${package.currentPrice.toStringAsFixed(2).replaceAll('.', ',')}';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '📦 ${package.name}',
              style: GoogleFonts.fredoka(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            Text('Conteúdo:',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            _BundleItems(bundle: package.contents),
            if (_hasGift(package.giftContents)) ...[
              const Divider(height: 24),
              Text('🎁 Presente para um amigo:',
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              _BundleItems(bundle: package.giftContents),
            ],
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Confirmar — $price',
                    style: GoogleFonts.fredoka(fontSize: 17)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onCancel,
                child:
                    Text('Cancelar', style: GoogleFonts.nunito(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasGift(RewardBundle gift) =>
      gift.lives > 0 ||
      gift.bomb2 > 0 ||
      gift.bomb3 > 0 ||
      gift.undo1 > 0 ||
      gift.undo3 > 0;
}

class _BundleItems extends StatelessWidget {
  const _BundleItems({required this.bundle});
  final RewardBundle bundle;

  @override
  Widget build(BuildContext context) {
    final items = <String>[];
    if (bundle.lives > 0) items.add('❤️ ${bundle.lives} Vida${bundle.lives > 1 ? 's' : ''}');
    if (bundle.bomb3 > 0) items.add('🧨 ${bundle.bomb3}× Bomba 3');
    if (bundle.bomb2 > 0) items.add('💣 ${bundle.bomb2}× Bomba 2');
    if (bundle.undo3 > 0) items.add('↩️ ${bundle.undo3}× Desfazer 3');
    if (bundle.undo1 > 0) items.add('↩️ ${bundle.undo1}× Desfazer 1');
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: items
          .map((t) => Text(t, style: GoogleFonts.nunito(fontSize: 14)))
          .toList(),
    );
  }
}
