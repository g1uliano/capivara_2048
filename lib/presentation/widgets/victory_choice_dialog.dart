import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/item_type.dart';
import '../../domain/inventory/inventory_notifier.dart';
import '../../domain/lives/lives_notifier.dart';
import '../controllers/game_notifier.dart';
import '../controllers/personal_records_notifier.dart';
import 'outlined_text.dart';

class VictoryChoiceDialog extends ConsumerWidget {
  final int milestone;
  const VictoryChoiceDialog({super.key, required this.milestone});

  String get _title => switch (milestone) {
    12 => 'Peixe-boi! Incrível! 🌊',
    13 => 'Jacaré! Lendário! 🐊',
    _ => 'Capivara Lendária! 🎉',
  };

  String get _subtitle => switch (milestone) {
    12 => 'Você chegou ao 4096!',
    13 => 'Você chegou ao 8192!',
    _ => 'Você chegou ao 2048!',
  };

  Future<void> _deliverReward(WidgetRef ref) async {
    final records = ref.read(personalRecordsProvider);
    if (milestone == 12 && !records.rewardCollected4096) {
      await ref.read(livesProvider.notifier).addEarned(5);
      await ref.read(inventoryProvider.notifier).add(ItemType.bomb2, 2);
      await ref.read(inventoryProvider.notifier).add(ItemType.bomb3, 1);
      await ref.read(inventoryProvider.notifier).add(ItemType.undo1, 2);
      await ref.read(inventoryProvider.notifier).add(ItemType.undo3, 1);
      await ref.read(personalRecordsProvider.notifier).markRewardCollected(12);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);

    return PopScope(
      canPop: false,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedText(
                  text: _title,
                  style: GoogleFonts.fredoka(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_subtitle, style: GoogleFonts.nunito(fontSize: 16)),
                const SizedBox(height: 24),
                if (milestone != 13)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        if (milestone == 12) await _deliverReward(ref);
                        notifier.dismissMilestone();
                      },
                      child: Text('Continuar', style: GoogleFonts.fredoka(fontSize: 18)),
                    ),
                  ),
                if (milestone != 13) const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await notifier.endGame();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: Text('Encerrar', style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
