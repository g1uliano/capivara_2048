import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/animals_data.dart';
import '../../data/models/tile.dart';

class TileWidget extends StatelessWidget {
  final Tile? tile;
  final double size;

  const TileWidget({super.key, required this.tile, required this.size});

  @override
  Widget build(BuildContext context) {
    if (tile == null) {
      return _EmptyCell(size: size);
    }
    return _FilledTile(tile: tile!, size: size);
  }
}

class _EmptyCell extends StatelessWidget {
  final double size;
  const _EmptyCell({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFC9B79C),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _FilledTile extends StatelessWidget {
  final Tile tile;
  final double size;
  const _FilledTile({required this.tile, required this.size});

  @override
  Widget build(BuildContext context) {
    final animal = animalForLevel(tile.level);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: animal.borderColor, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(size * 0.08),
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
              '${1 << tile.level}',
              style: GoogleFonts.fredoka(
                fontSize: size * 0.35,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3E2723),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
