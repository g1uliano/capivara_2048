import 'package:flutter/material.dart';
import '../../core/constants/game_constants.dart';
import '../../data/models/animal.dart';

class HostArtwork extends StatelessWidget {
  final Animal animal;
  final double size;

  const HostArtwork({
    super.key,
    required this.animal,
    this.size = GameConstants.tileSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        animal.hostPngPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
