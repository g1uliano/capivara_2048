import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/animals_data.dart';
import '../../data/models/tile.dart';
import '../../domain/performance/performance_settings.dart';
import '../controllers/performance_settings_notifier.dart';

class TileWidget extends ConsumerWidget {
  final Tile? tile;
  final double size;

  const TileWidget({super.key, required this.tile, required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tile == null) return _EmptyCell(size: size);
    final quality = ref.watch(
      performanceSettingsProvider.select((s) => s.tileQuality),
    );
    return switch (quality) {
      TileQuality.full => _FilledTileFull(tile: tile!, size: size),
      TileQuality.fullOpacity => _FilledTileFullOpacity(tile: tile!, size: size),
      TileQuality.simple => _FilledTileSimple(tile: tile!, size: size),
    };
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

class _FilledTileFull extends StatelessWidget {
  final Tile tile;
  final double size;
  const _FilledTileFull({required this.tile, required this.size});

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
          BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
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
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
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

class _FilledTileFullOpacity extends StatelessWidget {
  final Tile tile;
  final double size;
  const _FilledTileFullOpacity({required this.tile, required this.size});

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
          BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(size * 0.08),
              child: Image.asset(
                animal.tilePngPath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
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

class _FilledTileSimple extends StatelessWidget {
  final Tile tile;
  final double size;
  const _FilledTileSimple({required this.tile, required this.size});

  @override
  Widget build(BuildContext context) {
    final animal = animalForLevel(tile.level);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: animal.backgroundBaseColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: animal.borderColor, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            animal.name,
            style: GoogleFonts.fredoka(
              fontSize: size * 0.18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3E2723),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${1 << tile.level}',
            style: GoogleFonts.fredoka(
              fontSize: size * 0.30,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3E2723),
            ),
          ),
        ],
      ),
    );
  }
}
