import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/item_type.dart';
import '../../data/models/shop_package.dart';
import '../../data/shop_data.dart';
import '../../domain/inventory/inventory_notifier.dart';
import '../../domain/lives/lives_notifier.dart';
import '../widgets/outlined_text.dart';
import 'shop_package_card.dart';

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

    if (confirmed != true || !mounted) return;

    final c = package.contents;
    if (c.lives > 0) unawaited(ref.read(livesProvider.notifier).addPurchased(c.lives));
    if (c.bomb2 > 0) unawaited(ref.read(inventoryProvider.notifier).add(ItemType.bomb2, c.bomb2));
    if (c.bomb3 > 0) unawaited(ref.read(inventoryProvider.notifier).add(ItemType.bomb3, c.bomb3));
    if (c.undo1 > 0) unawaited(ref.read(inventoryProvider.notifier).add(ItemType.undo1, c.undo1));
    if (c.undo3 > 0) unawaited(ref.read(inventoryProvider.notifier).add(ItemType.undo3, c.undo3));

    widget.onItemPurchased(widget.itemType);
  }

  @override
  Widget build(BuildContext context) {
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
