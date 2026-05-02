import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../data/models/inventory.dart';
import '../../../data/models/item_type.dart';
import '../../../domain/inventory/inventory_notifier.dart';
import '../../../presentation/controllers/game_notifier.dart';

String _pngFor(ItemType t) => switch (t) {
      ItemType.bomb2 => 'assets/icons/inventory/bomb_2.png',
      ItemType.bomb3 => 'assets/icons/inventory/bomb_3.png',
      ItemType.undo1 => 'assets/icons/inventory/undo_1.png',
      ItemType.undo3 => 'assets/icons/inventory/undo_3.png',
    };

String _nameFor(ItemType t) => switch (t) {
      ItemType.bomb2 => 'Bomba 2',
      ItemType.bomb3 => 'Bomba 3',
      ItemType.undo1 => 'Desfazer 1',
      ItemType.undo3 => 'Desfazer 3',
    };

String _descFor(ItemType t) => switch (t) {
      ItemType.bomb2 => 'Remove 2 casas adjacentes',
      ItemType.bomb3 => 'Remove 3 casas à sua escolha',
      ItemType.undo1 => 'Desfaz a última jogada',
      ItemType.undo3 => 'Desfaz as últimas 3 jogadas',
    };

List<ItemType> _availableItems(Inventory inv) {
  const priority = [ItemType.undo3, ItemType.undo1, ItemType.bomb3, ItemType.bomb2];
  return priority.where((t) => inv.count(t) > 0).toList();
}

class GameOverItemOverlay extends ConsumerStatefulWidget {
  const GameOverItemOverlay({super.key});

  @override
  ConsumerState<GameOverItemOverlay> createState() => _GameOverItemOverlayState();
}

class _GameOverItemOverlayState extends ConsumerState<GameOverItemOverlay>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late AnimationController _hapticController;

  @override
  void initState() {
    super.initState();
    _hapticController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) maybeHaptic(ref);
      })
      ..repeat();
  }

  @override
  void dispose() {
    _hapticController.dispose();
    super.dispose();
  }

  void _nextItem() {
    setState(() => _index++);
    _hapticController.reset();
    _hapticController.repeat();
  }

  void _useItem(ItemType type) {
    _hapticController.stop();
    ref.read(inventoryProvider.notifier).consume(type);
    ref.read(gameProvider.notifier).startContinueWithItem();
  }

  void _giveUp() {
    _hapticController.stop();
    ref.read(gameProvider.notifier).setAwaitingResolution(false);
  }

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryProvider);
    final items = _availableItems(inventory);

    if (items.isEmpty) return const SizedBox.shrink();

    final safeIndex = _index.clamp(0, items.length - 1);
    final item = items[safeIndex];
    final count = inventory.count(item);
    final isLast = safeIndex == items.length - 1;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Oh não! O tabuleiro travou!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3E2723)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Image.asset(_pngFor(item), width: 120, height: 120)
                  .animate(
                    key: ValueKey(safeIndex),
                    onPlay: (c) => c.repeat(reverse: true),
                  )
                  .fade(begin: 1.0, end: 0.4, duration: 400.ms, curve: Curves.easeInOut),
              const SizedBox(height: 12),
              Text(
                _nameFor(item),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF3E2723)),
              ),
              const SizedBox(height: 4),
              Text(
                _descFor(item),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Você tem $count deste item',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C42)),
                  onPressed: () => _useItem(item),
                  child: const Text('Usar item', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: isLast
                    ? TextButton(
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF5350)),
                        onPressed: _giveUp,
                        child: const Text('Desistir'),
                      )
                    : TextButton(
                        onPressed: _nextItem,
                        child: const Text('Próximo item →'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
