import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/item_type.dart';
import '../../domain/game_engine/bomb_mode.dart';
import '../../domain/inventory/inventory_notifier.dart';
import '../controllers/game_notifier.dart';
import 'inventory_item_button.dart';

class InventoryBar extends ConsumerWidget {
  const InventoryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InventoryItemButton(
            label: 'Bomba 2',
            icon: Icons.bolt,
            count: inventory.bomb2,
            onPressed: inventory.bomb2 > 0
                ? () {
                    ref.read(gameProvider.notifier).enterBombMode(BombMode.bomb2);
                    ref.read(inventoryProvider.notifier).consume(ItemType.bomb2);
                  }
                : null,
          ),
          InventoryItemButton(
            label: 'Bomba 3',
            icon: Icons.auto_fix_high,
            count: inventory.bomb3,
            onPressed: inventory.bomb3 > 0
                ? () {
                    ref.read(gameProvider.notifier).enterBombMode(BombMode.bomb3);
                    ref.read(inventoryProvider.notifier).consume(ItemType.bomb3);
                  }
                : null,
          ),
          InventoryItemButton(
            label: 'Desfazer 1',
            icon: Icons.undo,
            count: inventory.undo1,
            onPressed: inventory.undo1 > 0
                ? () {
                    ref.read(gameProvider.notifier).undo(1);
                    ref.read(inventoryProvider.notifier).consume(ItemType.undo1);
                  }
                : null,
          ),
          InventoryItemButton(
            label: 'Desfazer 3',
            icon: Icons.fast_rewind,
            count: inventory.undo3,
            onPressed: inventory.undo3 > 0
                ? () {
                    ref.read(gameProvider.notifier).undo(3);
                    ref.read(inventoryProvider.notifier).consume(ItemType.undo3);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
