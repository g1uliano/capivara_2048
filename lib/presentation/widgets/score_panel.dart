import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/game_notifier.dart';

class ScorePanel extends ConsumerWidget {
  const ScorePanel({super.key});

  String _formatTime(int elapsedMs) {
    if (elapsedMs == 0) return '--:--';
    final totalSeconds = elapsedMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pontuação: ${state.score}',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Recorde: ${state.highScore}',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          Text(
            _formatTime(state.elapsedMs),
            style: GoogleFonts.fredoka(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.pause_rounded, color: Colors.white),
            iconSize: 32,
            onPressed: state.isGameOver ? null : notifier.pause,
          ),
        ],
      ),
    );
  }
}
