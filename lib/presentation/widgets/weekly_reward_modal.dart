import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/ranking/weekly_reward_result.dart';

class WeeklyRewardModal extends StatelessWidget {
  const WeeklyRewardModal({
    super.key,
    required this.reward,
    this.onDismiss,
  });

  final WeeklyRewardResult reward;
  final VoidCallback? onDismiss;

  static Future<void> show(BuildContext context, WeeklyRewardResult reward) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WeeklyRewardModal(
        reward: reward,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
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
            Text(
              '🏆 Recompensa Semanal!',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Parabéns! Você ficou em ${reward.position}º lugar!',
              style: GoogleFonts.nunito(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _RewardItems(reward: reward),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Continuar',
                  style: GoogleFonts.fredoka(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardItems extends StatelessWidget {
  const _RewardItems({required this.reward});
  final WeeklyRewardResult reward;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (reward.lives > 0) {
      items.add(_Item(
          emoji: '❤️',
          label: '${reward.lives} Vida${reward.lives > 1 ? 's' : ''}'));
    }
    if (reward.bomb3 > 0) {
      items.add(_Item(emoji: '🧨', label: '${reward.bomb3}× Bomba 3'));
    }
    if (reward.bomb2 > 0) {
      items.add(_Item(emoji: '💣', label: '${reward.bomb2}× Bomba 2'));
    }
    if (reward.undo1 > 0) {
      items.add(_Item(emoji: '↩️', label: '${reward.undo1}× Desfazer'));
    }
    if (items.isEmpty) {
      items.add(Text('Nenhum item desta vez.',
          style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey)));
    }
    return Column(children: items);
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.emoji, required this.label});
  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
