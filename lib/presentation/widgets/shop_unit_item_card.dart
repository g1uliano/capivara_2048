import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/item_type.dart';
import '../../data/shop_data.dart';
import '../../domain/inventory/inventory_notifier.dart';

class ShopUnitItemCard extends ConsumerWidget {
  final ItemType item;
  const ShopUnitItemCard({super.key, required this.item});

  String get _png => switch (item) {
        ItemType.bomb2 => 'assets/icons/inventory/bomb_2.png',
        ItemType.bomb3 => 'assets/icons/inventory/bomb_3.png',
        ItemType.undo1 => 'assets/icons/inventory/undo_1.png',
        ItemType.undo3 => 'assets/icons/inventory/undo_3.png',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar compra'),
        content: Text('Você receberá 1× $_name por $_price'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(inventoryProvider.notifier).add(item, 1);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_name adicionado! 🎉')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Image.asset(_png, width: 40, height: 40),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_name, style: const TextStyle(fontSize: 16)),
            ),
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
