import 'package:flutter/material.dart';
import '../../data/models/animal.dart';
import '../../core/constants/game_constants.dart';

class HostArtwork extends StatelessWidget {
  final Animal animal;

  const HostArtwork({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    final slotSize = GameConstants.twoCellWidth;
    return SizedBox(
      width: slotSize,
      height: slotSize,
      child: Image.asset(
        animal.hostPngPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
