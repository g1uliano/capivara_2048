import 'package:flutter/material.dart';
import '../../data/animals_data.dart';
import '../../data/models/tile.dart';

class TileWidget extends StatelessWidget {
  final Tile? tile;
  final double size;

  const TileWidget({super.key, required this.tile, required this.size});

  @override
  Widget build(BuildContext context) {
    if (tile == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFC9B79C),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    final animal = animalForLevel(tile!.level);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: animal.borderColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Center(
        child: Text(
          '${1 << tile!.level}',
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [Shadow(color: Colors.black38, blurRadius: 2)],
          ),
        ),
      ),
    );
  }
}
