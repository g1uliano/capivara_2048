import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/game_constants.dart';
import '../../data/animals_data.dart';
import '../controllers/game_notifier.dart';
import 'host_artwork.dart';

class HostBanner extends ConsumerWidget {
  const HostBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxLevel = ref.watch(gameProvider.select((s) => s.maxLevel));
    // Width = 2 tiles + 1 inner gap
    final bannerWidth = GameConstants.tileSize * 2 + GameConstants.tileSpacing;

    return SizedBox(
      width: bannerWidth,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: maxLevel == 0
            ? _Placeholder(key: const ValueKey('ph'), width: bannerWidth)
            : _AnimalHost(key: ValueKey(maxLevel), level: maxLevel),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double width;
  const _Placeholder({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 64,
          height: 64,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFC9B79C),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Comece a jogar!',
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AnimalHost extends StatelessWidget {
  final int level;
  const _AnimalHost({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final animal = animalForLevel(level);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HostArtwork(animal: animal, size: 64),
        const SizedBox(height: 4),
        Text(
          animal.name,
          style: GoogleFonts.nunito(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
