import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/domain/game_engine/direction.dart' as game;
import '../../../widgets/outlined_text.dart';
import '../../../widgets/glass_panel.dart';
import '../widgets/tutorial_mini_board.dart';

class TutorialMovementPage extends StatefulWidget {
  final VoidCallback onUserCompleted;
  const TutorialMovementPage({super.key, required this.onUserCompleted});

  @override
  State<TutorialMovementPage> createState() => _TutorialMovementPageState();
}

class _TutorialMovementPageState extends State<TutorialMovementPage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Text(
                  'Deslize pra mover',
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Arraste o dedo em qualquer direção pra mover todos os bichos do tabuleiro de uma vez.',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TutorialMiniBoard(
                initialTiles: [
                  Tile(id: 'mv_1', level: 1, row: 0, col: 0),
                  null,
                ],
                acceptedDirections: {game.Direction.right},
                mergedResult: null,
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
              text: '👉 Tente deslizar pra direita',
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
              text: '✓ Boa!',
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
