import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/domain/game_engine/direction.dart' as game;
import '../../../widgets/outlined_text.dart';
import '../widgets/tutorial_mini_board.dart';

class TutorialFusionPage extends StatefulWidget {
  final VoidCallback onUserCompleted;
  const TutorialFusionPage({super.key, required this.onUserCompleted});

  @override
  State<TutorialFusionPage> createState() => _TutorialFusionPageState();
}

class _TutorialFusionPageState extends State<TutorialFusionPage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedText(
            text: 'Iguais se fundem!',
            style: GoogleFonts.fredoka(
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedText(
            text:
                'Quando dois bichos do mesmo tipo se encontram, eles se transformam num bicho mais raro. Tente fundir as duas tanajuras.',
            style: GoogleFonts.fredoka(fontSize: 16, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TutorialMiniBoard(
                initialTiles: [
                  Tile(id: 'fusion_1', level: 1, row: 0, col: 0),
                  Tile(id: 'fusion_2', level: 1, row: 0, col: 1),
                ],
                acceptedDirections: {game.Direction.left, game.Direction.right},
                mergedResult: Tile(
                  id: 'fusion_result',
                  level: 2,
                  row: 0,
                  col: 0,
                ),
                onCorrectSwipe: () {
                  setState(() => _done = true);
                  widget.onUserCompleted();
                },
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.04, duration: 1500.ms),
          const SizedBox(height: 24),
          AnimatedOpacity(
            opacity: _done ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            child: OutlinedText(
              text: '👉 Deslize em qualquer direção',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _done ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: OutlinedText(
              text: '✓ Você fez evoluir um bicho!',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
