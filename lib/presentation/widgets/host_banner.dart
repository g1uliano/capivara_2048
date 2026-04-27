import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/game_constants.dart';
import '../../core/theme/text_styles.dart';
import '../../data/animals_data.dart';
import '../controllers/game_notifier.dart';
import 'host_artwork.dart';

class HostBanner extends ConsumerWidget {
  const HostBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxLevel = ref.watch(gameProvider.select((s) => s.maxLevel));
    const slotWidth = GameConstants.twoCellWidth;

    return SizedBox(
      width: slotWidth,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: maxLevel == 0
            ? _Placeholder(key: const ValueKey('ph'), slotWidth: slotWidth)
            : _AnimalHost(
                key: ValueKey(maxLevel),
                level: maxLevel,
                slotWidth: slotWidth,
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double slotWidth;
  const _Placeholder({super.key, required this.slotWidth});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Anfitrião: nenhum. Faça seu primeiro merge!',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Comece!',
            style: outlinedWhiteTextStyle(
              GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Image.asset(
            'assets/images/animals/host/Capivara.png',
            width: slotWidth,
            height: slotWidth,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _AnimalHost extends StatelessWidget {
  final int level;
  final double slotWidth;
  const _AnimalHost({super.key, required this.level, required this.slotWidth});

  @override
  Widget build(BuildContext context) {
    final animal = animalForLevel(level);
    return Semantics(
      label: 'Anfitrião: ${animal.name}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            animal.name,
            style: outlinedWhiteTextStyle(
              GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          HostArtwork(animal: animal, size: slotWidth),
        ],
      ),
    );
  }
}
