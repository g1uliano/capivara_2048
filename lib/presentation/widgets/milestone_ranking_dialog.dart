import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/post_game_controller.dart';

class MilestoneRankingDialog extends StatelessWidget {
  const MilestoneRankingDialog({
    super.key,
    required this.summary,
    this.onViewRanking,
    this.onDismiss,
  });

  final PostGameSummary summary;
  final VoidCallback? onViewRanking;
  final VoidCallback? onDismiss;

  static Future<void> show(
    BuildContext context,
    PostGameSummary summary, {
    VoidCallback? onViewRanking,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MilestoneRankingDialog(
        summary: summary,
        onViewRanking: onViewRanking,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  String _formatMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rem = s % 60;
    return '${m.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitle(),
            const SizedBox(height: 8),
            _buildBody(),
            if (summary.earnedCombo) ...[
              const Divider(height: 24),
              _buildComboReward(),
            ],
            const SizedBox(height: 20),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final (emoji, text) = switch (summary.milestone) {
      11 => ('🏆', 'Ranking Global'),
      12 => ('🌊', 'Peixe-boi atingido!'),
      13 => ('🐊', 'Jacaré atingido!'),
      _ => ('🎯', 'Marco atingido!'),
    };
    return Text(
      '$emoji $text',
      style: GoogleFonts.fredoka(
        fontSize: 22,
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBody() {
    if (summary.milestone == 11) {
      return Column(
        children: [
          if (summary.rankingPosition != null)
            Text(
              'Você está em ${summary.rankingPosition}º lugar!',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          Text(
            'Tempo: ${_formatMs(summary.timeMs)}',
            style: GoogleFonts.nunito(fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (summary.milestone == 12) {
      return Text(
        'Seu tempo: ${_formatMs(summary.timeMs)}',
        style: GoogleFonts.nunito(fontSize: 15),
        textAlign: TextAlign.center,
      );
    } else {
      return Text(
        'Você chegou aqui ${summary.timesReached8192} '
        '${summary.timesReached8192 == 1 ? 'vez' : 'vezes'}!',
        style: GoogleFonts.nunito(fontSize: 15),
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _buildComboReward() {
    return Column(
      children: [
        Text(
          '🎁 Recorde pessoal!',
          style: GoogleFonts.fredoka(
            fontSize: 16,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '+1 vida  •  +1 bomba  •  +1 desfazer',
          style: GoogleFonts.nunito(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final dismiss = onDismiss ?? () => Navigator.of(context).pop();
    if (summary.milestone == 11) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onViewRanking?.call();
              },
              child: Text(
                'Ver Ranking',
                style: GoogleFonts.fredoka(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: dismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Continuar',
                style: GoogleFonts.fredoka(fontSize: 16),
              ),
            ),
          ),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: dismiss,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text('Continuar', style: GoogleFonts.fredoka(fontSize: 18)),
      ),
    );
  }
}
