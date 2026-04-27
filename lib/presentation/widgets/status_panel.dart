import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/text_styles.dart';
import '../controllers/game_notifier.dart';

class StatusPanel extends ConsumerWidget {
  const StatusPanel({super.key});

  String _formatTime(int elapsedMs) {
    if (elapsedMs == 0) return '--:--:--';
    final total = elapsedMs ~/ 1000;
    final hh = (total ~/ 3600).toString().padLeft(2, '0');
    final mm = ((total % 3600) ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(gameProvider.select((s) => s.score));
    final highScore = ref.watch(gameProvider.select((s) => s.highScore));
    final elapsedMs = ref.watch(gameProvider.select((s) => s.elapsedMs));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(elapsedMs),
          style: outlinedWhiteTextStyle(
            GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$score',
          style: outlinedWhiteTextStyle(
            GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          'Recorde: $highScore',
          style: outlinedWhiteTextStyle(
            GoogleFonts.nunito(fontSize: 11),
          ),
        ),
      ],
    );
  }
}
