import 'dart:math' show pi;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../controllers/post_game_controller.dart';

class MilestoneRankingDialog extends StatefulWidget {
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

  @override
  State<MilestoneRankingDialog> createState() =>
      _MilestoneRankingDialogState();
}

class _MilestoneRankingDialogState extends State<MilestoneRankingDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  List<Color> _confettiColors() => switch (widget.summary.milestone) {
        11 => [AppColors.primary, const Color(0xFFFFD700), Colors.white],
        12 => [Colors.blue, Colors.cyan, Colors.lightBlue],
        13 => [Colors.orange, Colors.yellow, Colors.amber],
        _ => [AppColors.primary, Colors.yellow, Colors.white],
      };

  String _formatMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rem = s % 60;
    return '${m.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitle(),
                const SizedBox(height: 8),
                _buildBody(),
                if (widget.summary.earnedCombo) ...[
                  const Divider(height: 24),
                  _buildComboReward(),
                ],
                const SizedBox(height: 20),
                _buildActions(context),
              ],
            ),
          ),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: pi / 2,
          maxBlastForce: 20,
          minBlastForce: 8,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          gravity: 0.05,
          colors: _confettiColors(),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    final (emoji, text) = switch (widget.summary.milestone) {
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
    if (widget.summary.milestone == 11) {
      return Column(
        children: [
          if (widget.summary.rankingPosition != null)
            Text(
              'Você está em ${widget.summary.rankingPosition}º lugar!',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          Text(
            'Tempo: ${_formatMs(widget.summary.timeMs)}',
            style: GoogleFonts.nunito(fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (widget.summary.milestone == 12) {
      return Text(
        'Seu tempo: ${_formatMs(widget.summary.timeMs)}',
        style: GoogleFonts.nunito(fontSize: 15),
        textAlign: TextAlign.center,
      );
    } else {
      return Text(
        'Você chegou aqui ${widget.summary.timesReached8192} '
        '${widget.summary.timesReached8192 == 1 ? 'vez' : 'vezes'}!',
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
    final dismiss = widget.onDismiss ?? () => Navigator.of(context).pop();
    if (widget.summary.milestone == 11) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onViewRanking?.call();
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
