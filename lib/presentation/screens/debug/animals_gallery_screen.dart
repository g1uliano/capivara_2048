import 'package:flutter/material.dart';
import '../../../core/constants/game_constants.dart';
import '../../../data/animals_data.dart';
import '../../../data/models/animal.dart';
import '../../widgets/host_artwork.dart';

class AnimalsGalleryScreen extends StatelessWidget {
  const AnimalsGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galeria de Animais')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: animals.length,
        separatorBuilder: (_, __) => const Divider(height: 32),
        itemBuilder: (context, index) {
          final animal = animals[index];
          return _AnimalRow(animal: animal);
        },
      ),
    );
  }
}

class _AnimalRow extends StatelessWidget {
  final Animal animal;
  const _AnimalRow({required this.animal});

  @override
  Widget build(BuildContext context) {
    const slot2x = GameConstants.twoCellWidth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nível ${animal.level} — ${animal.name} — ${animal.value}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                const Text('Tile', style: TextStyle(fontSize: 10)),
                const SizedBox(height: 4),
                _TilePreview(animal: animal),
              ],
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                const Text('Host 1×1', style: TextStyle(fontSize: 10)),
                const SizedBox(height: 4),
                HostArtwork(animal: animal),
              ],
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                const Text('Host 2×2', style: TextStyle(fontSize: 10)),
                const SizedBox(height: 4),
                HostArtwork(animal: animal, size: slot2x),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _ColorChip(label: 'Border', color: animal.borderColor),
            const SizedBox(width: 8),
            _ColorChip(label: 'Bg', color: animal.backgroundBaseColor),
          ],
        ),
      ],
    );
  }
}

class _TilePreview extends StatelessWidget {
  final Animal animal;
  const _TilePreview({required this.animal});

  @override
  Widget build(BuildContext context) {
    const size = 80.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: animal.borderColor, width: 3),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(size * 0.08),
              child: Opacity(
                opacity: 0.27,
                child: Image.asset(
                  animal.tilePngPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              '${animal.value}',
              style: const TextStyle(
                fontSize: size * 0.35,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E2723),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final String label;
  final Color color;
  const _ColorChip({required this.label, required this.color});

  String _toHex(Color c) =>
      '#${c.value.toRadixString(16).substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text('$label ${_toHex(color)}',
            style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
