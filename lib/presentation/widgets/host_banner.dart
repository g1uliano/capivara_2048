import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/game_constants.dart';
import '../../core/theme/text_styles.dart';
import '../../data/animals_data.dart';
import '../controllers/game_notifier.dart';
import 'host_artwork.dart';

class HostBanner extends ConsumerWidget {
  final double tileSize;

  const HostBanner({super.key, this.tileSize = GameConstants.tileSize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxLevel = ref.watch(gameProvider.select((s) => s.maxLevel));

    return SizedBox(
      width: tileSize,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: maxLevel == 0
            ? _Placeholder(key: const ValueKey('ph'), tileSize: tileSize)
            : _AnimalHost(
                key: ValueKey(maxLevel),
                level: maxLevel,
                tileSize: tileSize,
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double tileSize;
  const _Placeholder({super.key, required this.tileSize});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tileSize,
      height: tileSize + 36,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Text(
          'Comece!',
          style: outlinedWhiteTextStyle(
            GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _AnimalHost extends StatelessWidget {
  final int level;
  final double tileSize;
  const _AnimalHost({super.key, required this.level, required this.tileSize});

  @override
  Widget build(BuildContext context) {
    final animal = animalForLevel(level);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          animal.name,
          style: outlinedWhiteTextStyle(
            GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        HostArtwork(animal: animal, size: tileSize),
      ],
    );
  }
}
