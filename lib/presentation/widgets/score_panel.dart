import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/game_notifier.dart';

/// Minimal score display — used outside game screen if needed.
/// In GameScreen, use StatusPanel instead.
class ScorePanel extends ConsumerWidget {
  const ScorePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(gameProvider.select((s) => s.score));
    final highScore = ref.watch(gameProvider.select((s) => s.highScore));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Pontuação: $score',
              style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text('Recorde: $highScore',
              style: GoogleFonts.nunito(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }
}
