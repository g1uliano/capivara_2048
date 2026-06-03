import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/game_constants.dart';
import '../../data/models/item_type.dart';
import '../../data/models/tile.dart';
import '../../domain/game_engine/bomb_mode.dart';
import '../../domain/inventory/inventory_notifier.dart';
import '../controllers/game_notifier.dart';
import 'cannot_use_item_dialog.dart';
import 'confirm_use_dialog.dart';
import 'inventory_item_button.dart';

class InventoryBar extends ConsumerWidget {
  const InventoryBar({
    super.key,
    this.onTapWhenEmpty,
    this.pulsingItems = const {},
    this.iconSize = GameConstants.inventoryIconSize,
    this.onUndoUsed,
  });

  final void Function(ItemType)? onTapWhenEmpty;
  final Set<ItemType> pulsingItems;
  final double iconSize;
  final void Function(bool isUndo3)? onUndoUsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);
    final undoStackLen = ref.watch(
      gameProvider.select((s) => s.undoStack.length),
    );
    final tileCount = ref.watch(
      gameProvider.select(
        (s) => s.board.expand((row) => row).whereType<Tile>().length,
      ),
    );

    Future<void> useBomb2() async {
      final ok = await showConfirmUseDialog(
        context: context,
        itemName: 'Bomba 2',
        description: 'Selecione 2 peças para remover do tabuleiro.',
        pngPath: 'assets/images/inventory/bomb_2.webp',
      );
      if (!ok) return;
      ref
          .read(gameProvider.notifier)
          .enterBombMode(BombMode.bomb2, ItemType.bomb2);
    }

    Future<void> useBomb3() async {
      final ok = await showConfirmUseDialog(
        context: context,
        itemName: 'Bomba 3',
        description: 'Selecione 3 peças para remover do tabuleiro.',
        pngPath: 'assets/images/inventory/bomb_3.webp',
      );
      if (!ok) return;
      ref
          .read(gameProvider.notifier)
          .enterBombMode(BombMode.bomb3, ItemType.bomb3);
    }

    Future<void> useUndo1() async {
      final ok = await showConfirmUseDialog(
        context: context,
        itemName: 'Desfazer 1',
        description: 'Desfaz o último movimento.',
        pngPath: 'assets/images/inventory/undo_1.webp',
      );
      if (!ok) return;
      final undone = ref.read(gameProvider.notifier).undo(1);
      if (undone) {
        ref.read(inventoryProvider.notifier).consume(ItemType.undo1);
        onUndoUsed?.call(false);
      }
    }

    Future<void> useUndo3() async {
      final ok = await showConfirmUseDialog(
        context: context,
        itemName: 'Desfazer 3',
        description: 'Desfaz os últimos 3 movimentos.',
        pngPath: 'assets/images/inventory/undo_3.webp',
      );
      if (!ok) return;
      final undone = ref.read(gameProvider.notifier).undo(3);
      if (undone) {
        ref.read(inventoryProvider.notifier).consume(ItemType.undo3);
        onUndoUsed?.call(true);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InventoryItemButton(
            key: const Key('inventory_bomb2'),
            label: 'Bomba 2',
            icon: Icons.bolt,
            pngPath: 'assets/images/inventory/bomb_2.webp',
            count: inventory.bomb2,
            size: iconSize,
            onPressed: inventory.bomb2 > 0 ? useBomb2 : null,
            onTapWhenEmpty: inventory.bomb2 == 0 && onTapWhenEmpty != null
                ? () => onTapWhenEmpty!(ItemType.bomb2)
                : null,
            shouldPulse: pulsingItems.contains(ItemType.bomb2),
          ),
          InventoryItemButton(
            key: const Key('inventory_bomb3'),
            label: 'Bomba 3',
            icon: Icons.auto_fix_high,
            pngPath: 'assets/images/inventory/bomb_3.webp',
            count: inventory.bomb3,
            size: iconSize,
            onPressed: inventory.bomb3 > 0 && tileCount >= 5 ? useBomb3 : null,
            forceDisabled: inventory.bomb3 > 0 && tileCount < 5,
            onTapWhenDisabled: () => showCannotUseItemDialog(
              context: context,
              message:
                  'São necessárias pelo menos 5 peças no tabuleiro para usar a Bomba 3.',
              pngPath: 'assets/images/inventory/bomb_3.webp',
            ),
            onTapWhenEmpty: inventory.bomb3 == 0 && onTapWhenEmpty != null
                ? () => onTapWhenEmpty!(ItemType.bomb3)
                : null,
            shouldPulse: pulsingItems.contains(ItemType.bomb3),
          ),
          InventoryItemButton(
            key: const Key('inventory_undo1'),
            label: 'Desfazer 1',
            icon: Icons.undo,
            pngPath: 'assets/images/inventory/undo_1.webp',
            count: inventory.undo1,
            size: iconSize,
            onPressed: inventory.undo1 > 0 && undoStackLen >= 1
                ? useUndo1
                : null,
            forceDisabled: inventory.undo1 > 0 && undoStackLen < 1,
            onTapWhenDisabled: () => showCannotUseItemDialog(
              context: context,
              message: 'Não há jogadas para desfazer.',
              pngPath: 'assets/images/inventory/undo_1.webp',
            ),
            onTapWhenEmpty: inventory.undo1 == 0 && onTapWhenEmpty != null
                ? () => onTapWhenEmpty!(ItemType.undo1)
                : null,
            shouldPulse: pulsingItems.contains(ItemType.undo1),
          ),
          InventoryItemButton(
            key: const Key('inventory_undo3'),
            label: 'Desfazer 3',
            icon: Icons.fast_rewind,
            pngPath: 'assets/images/inventory/undo_3.webp',
            count: inventory.undo3,
            size: iconSize,
            onPressed: inventory.undo3 > 0 && undoStackLen >= 3
                ? useUndo3
                : null,
            forceDisabled: inventory.undo3 > 0 && undoStackLen < 3,
            onTapWhenDisabled: () => showCannotUseItemDialog(
              context: context,
              message:
                  'São necessárias pelo menos 3 jogadas para usar o Desfazer 3.',
              pngPath: 'assets/images/inventory/undo_3.webp',
            ),
            onTapWhenEmpty: inventory.undo3 == 0 && onTapWhenEmpty != null
                ? () => onTapWhenEmpty!(ItemType.undo3)
                : null,
            shouldPulse: pulsingItems.contains(ItemType.undo3),
          ),
        ],
      ),
    );
  }
}
