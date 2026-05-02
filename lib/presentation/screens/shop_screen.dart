// lib/presentation/screens/shop_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/item_type.dart';
import '../../data/models/share_code.dart';
import '../../data/shop_data.dart';
import '../../data/models/shop_package.dart';
import '../../domain/inventory/inventory_notifier.dart';
import '../../domain/lives/lives_notifier.dart';
import '../../domain/shop/share_codes_notifier.dart';
import '../widgets/game_background.dart';

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
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: packages.length,
          itemBuilder: (context, index) {
            final pkg = packages[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShopPackageCard(
                package: pkg,
                onBuy: () => _onBuy(context, ref, pkg),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onBuy(
    BuildContext context,
    WidgetRef ref,
    ShopPackage package,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar compra'),
        content: Text(
          'Comprar ${package.name} por R\$ ${package.currentPrice.toStringAsFixed(2).replaceAll('.', ',')}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Generate share code synchronously so we can show the sheet immediately
    final rawCode = const Uuid().v4().replaceAll('-', '');
    final truncated =
        '${rawCode.substring(0, 4)}-${rawCode.substring(4, 8)}-${rawCode.substring(8, 12)}';

    final shareCode = ShareCode(
      code: truncated,
      packageId: package.id,
      giftContents: package.giftContents,
      status: ShareCodeStatus.pending,
      createdAt: DateTime.now(),
    );

    // Apply state updates synchronously (Riverpod state update is sync;
    // Hive persistence is fire-and-forget — UI does not need to await it).
    final c = package.contents;
    if (c.lives > 0) {
      _fireAndLog(ref.read(livesProvider.notifier).addPurchased(c.lives));
    }
    if (c.bomb2 > 0) {
      _fireAndLog(ref.read(inventoryProvider.notifier).add(ItemType.bomb2, c.bomb2));
    }
    if (c.bomb3 > 0) {
      _fireAndLog(ref.read(inventoryProvider.notifier).add(ItemType.bomb3, c.bomb3));
    }
    if (c.undo1 > 0) {
      _fireAndLog(ref.read(inventoryProvider.notifier).add(ItemType.undo1, c.undo1));
    }
    if (c.undo3 > 0) {
      _fireAndLog(ref.read(inventoryProvider.notifier).add(ItemType.undo3, c.undo3));
    }
    _fireAndLog(ref.read(shareCodesProvider.notifier).add(shareCode));

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _GiftCodeSheet(code: shareCode),
      );
    }
  }
}

class _ShopPackageCard extends StatelessWidget {
  const _ShopPackageCard({
    required this.package,
    required this.onBuy,
  });

  final ShopPackage package;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black26,
      color: Colors.white.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    package.name,
                    style: GoogleFonts.fredoka(fontSize: 18),
                  ),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFFF8C42),
                  child: Text(
                    '${package.discountPercent}%',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              package.description,
              style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'De R\$ ${package.originalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: const Color(0xFF9E9E9E),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Por R\$ ${package.currentPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Comprar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _fireAndLog(Future<void> future) {
  unawaited(future.catchError(
    (Object e) => debugPrint('[ShopScreen] purchase side-effect error: $e'),
  ));
}

class _GiftCodeSheet extends StatelessWidget {
  const _GiftCodeSheet({required this.code});

  final ShareCode code;

  String _describeBundle(RewardBundle b) {
    final parts = <String>[];
    if (b.lives > 0) parts.add('${b.lives} vida${b.lives > 1 ? 's' : ''}');
    if (b.bomb2 > 0) parts.add('${b.bomb2} Bomba 2');
    if (b.bomb3 > 0) parts.add('${b.bomb3} Bomba 3');
    if (b.undo1 > 0) parts.add('${b.undo1} Desfazer 1');
    if (b.undo3 > 0) parts.add('${b.undo3} Desfazer 3');
    return parts.join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Presente gerado!',
                style: GoogleFonts.fredoka(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Compartilhe este código com um amigo:',
                style: GoogleFonts.nunito(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Text(
                  code.code,
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copiado!')),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Seu amigo recebe: ${_describeBundle(code.giftContents)}',
                style: GoogleFonts.nunito(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
