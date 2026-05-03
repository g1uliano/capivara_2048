import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/item_type.dart';
import '../../domain/game_engine/bomb_mode.dart';
import '../../domain/inventory/inventory_notifier.dart';
import '../controllers/game_notifier.dart';
import 'confirm_use_dialog.dart';
import 'inventory_item_button.dart';

class InventoryBar extends ConsumerWidget {
  const InventoryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);

    Future<void> useBomb2() async {
      final ok = await showConfirmUseDialog(
        context: context,
        itemName: 'Bomba 2',
        description: 'Selecione 2 tiles para remover do tabuleiro.',
        pngPath: 'assets/icons/inventory/bomb_2.png',
      );
      if (!ok) return;
      ref.read(gameProvider.notifier).enterBombMode(BombMode.bomb2, ItemType.bomb2);
    }

    Future<void> useBomb3() async {
      final ok = await showConfirmUseDialog(
        context: context,
        itemName: 'Bomba 3',
        description: 'Selecione 3 tiles para remover do tabuleiro.',
        pngPath: 'assets/icons/inventory/bomb_3.png',
      );
      if (!ok) return;
      ref.read(gameProvider.notifier).enterBombMode(BombMode.bomb3, ItemType.bomb3);
    }

    Future<void> useUndo1() async {
      final ok = await showConfirmUseDialog(
        context: context,
        itemName: 'Desfazer 1',
        description: 'Desfaz o último movimento.',
        pngPath: 'assets/icons/inventory/undo_1.png',
      );
      if (!ok) return;
      final undone = ref.read(gameProvider.notifier).undo(1);
      if (undone) ref.read(inventoryProvider.notifier).consume(ItemType.undo1);
    }

    Future<void> useUndo3() async {
      final ok = await showConfirmUseDialog(
        context: context,
        itemName: 'Desfazer 3',
        description: 'Desfaz os últimos 3 movimentos.',
        pngPath: 'assets/icons/inventory/undo_3.png',
      );
      if (!ok) return;
      final undone = ref.read(gameProvider.notifier).undo(3);
      if (undone) ref.read(inventoryProvider.notifier).consume(ItemType.undo3);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InventoryItemButton(
            label: 'Bomba 2',
            icon: Icons.bolt,
            pngPath: 'assets/icons/inventory/bomb_2.png',
            count: inventory.bomb2,
            onPressed: inventory.bomb2 > 0 ? useBomb2 : null,
          ),
          InventoryItemButton(
            label: 'Bomba 3',
            icon: Icons.auto_fix_high,
            pngPath: 'assets/icons/inventory/bomb_3.png',
            count: inventory.bomb3,
            onPressed: inventory.bomb3 > 0 ? useBomb3 : null,
          ),
          InventoryItemButton(
            label: 'Desfazer 1',
            icon: Icons.undo,
            pngPath: 'assets/icons/inventory/undo_1.png',
            count: inventory.undo1,
            onPressed: inventory.undo1 > 0 ? useUndo1 : null,
          ),
          InventoryItemButton(
            label: 'Desfazer 3',
            icon: Icons.fast_rewind,
            pngPath: 'assets/icons/inventory/undo_3.png',
            count: inventory.undo3,
            onPressed: inventory.undo3 > 0 ? useUndo3 : null,
          ),
        ],
      ),
    );
  }
}
