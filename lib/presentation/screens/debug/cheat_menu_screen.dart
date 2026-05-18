import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/animals_data.dart';
import '../../../data/models/item_type.dart';
import '../../../domain/inventory/inventory_notifier.dart';
import '../../../domain/lives/lives_notifier.dart';
import '../../controllers/game_notifier.dart';

class CheatMenuScreen extends ConsumerStatefulWidget {
  const CheatMenuScreen({super.key});

  @override
  ConsumerState<CheatMenuScreen> createState() => _CheatMenuScreenState();
}

class _CheatMenuScreenState extends ConsumerState<CheatMenuScreen> {
  late int _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = ref.read(gameProvider).maxLevel.clamp(1, 13);
  }

  @override
  Widget build(BuildContext context) {
    final lives = ref.watch(livesProvider).lives;
    final inventory = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('🧪 Cheat Menu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Vidas'),
          _CounterRow(
            label: 'Vidas',
            count: lives,
            onIncrement: () =>
                ref.read(livesProvider.notifier).addPurchased(1),
            onDecrement: lives > 0
                ? () => ref
                    .read(livesProvider.notifier)
                    // ignore: invalid_use_of_visible_for_testing_member
                    .debugSetLives(lives - 1)
                : null,
          ),
          const Divider(height: 32),
          _SectionHeader('Itens'),
          for (final type in ItemType.values)
            _CounterRow(
              label: _itemLabel(type),
              count: inventory.count(type),
              onIncrement: () =>
                  ref.read(inventoryProvider.notifier).add(type, 1),
              onDecrement: inventory.count(type) > 0
                  ? () =>
                      ref.read(inventoryProvider.notifier).consume(type)
                  : null,
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () =>
                ref.read(inventoryProvider.notifier).addDebugItems(),
            child: const Text('Dar 5 de cada'),
          ),
          const Divider(height: 32),
          _SectionHeader('Pular para Nível'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final animal in animals)
                ChoiceChip(
                  label: Text(
                    '${animal.level} ${animal.name}',
                    style: GoogleFonts.fredoka(fontSize: 13),
                  ),
                  selected: _selectedLevel == animal.level,
                  onSelected: (_) =>
                      setState(() => _selectedLevel = animal.level),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(gameProvider.notifier)
                  // ignore: invalid_use_of_visible_for_testing_member
                  .debugJumpToLevel(_selectedLevel);
              Navigator.of(context).pop();
            },
            child: Text(
              '▶ Ir para Nível $_selectedLevel — ${animals[_selectedLevel - 1].name}',
            ),
          ),
        ],
      ),
    );
  }

  String _itemLabel(ItemType type) => switch (type) {
        ItemType.bomb2 => 'Bomba 2×2',
        ItemType.bomb3 => 'Bomba 3×3',
        ItemType.undo1 => 'Desfazer ×1',
        ItemType.undo3 => 'Desfazer ×3',
      };
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.fredoka(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;

  const _CounterRow({
    required this.label,
    required this.count,
    required this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: onDecrement,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}
