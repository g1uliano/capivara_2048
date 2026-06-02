import 'dart:math' show pi;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/audio/audio_service.dart';
import '../../data/models/item_type.dart';
import '../../domain/inventory/inventory_notifier.dart';
import '../../domain/lives/lives_notifier.dart';
import '../controllers/game_notifier.dart';
import '../controllers/personal_records_notifier.dart';
import '../controllers/post_game_controller.dart';
import '../screens/ranking_screen.dart';
import 'outlined_text.dart';

class VictoryChoiceDialog extends ConsumerStatefulWidget {
  final int milestone;
  const VictoryChoiceDialog({super.key, required this.milestone});

  @override
  ConsumerState<VictoryChoiceDialog> createState() =>
      _VictoryChoiceDialogState();
}

class _VictoryChoiceDialogState extends ConsumerState<VictoryChoiceDialog> {
  late ConfettiController _confettiController;

  String get _title => switch (widget.milestone) {
    12 => 'Peixe-boi! Incrível! 🌊',
    13 => 'Jacaré! Lendário! 🐊',
    _ => 'Capivara Lendária! 🎉',
  };

  String get _subtitle => switch (widget.milestone) {
    12 => 'Você chegou ao 4096!',
    13 => 'Você chegou ao 8192!',
    _ => 'Você chegou ao 2048!',
  };

  List<Color> _confettiColors() => switch (widget.milestone) {
    11 => [AppColors.primary, const Color(0xFFFFD700), Colors.white],
    12 => [Colors.blue, Colors.cyan, Colors.lightBlue],
    13 => [Colors.orange, Colors.yellow, Colors.amber],
    _ => [AppColors.primary, Colors.yellow, Colors.white],
  };

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    _confettiController.play();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioServiceProvider).playEffect(const VictoryReached());
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _deliverReward() async {
    final records = ref.read(personalRecordsProvider);
    if (widget.milestone == 12 && !records.rewardCollected4096) {
      await ref.read(livesProvider.notifier).addEarned(5);
      await ref.read(inventoryProvider.notifier).add(ItemType.bomb2, 2);
      await ref.read(inventoryProvider.notifier).add(ItemType.bomb3, 1);
      await ref.read(inventoryProvider.notifier).add(ItemType.undo1, 2);
      await ref.read(inventoryProvider.notifier).add(ItemType.undo3, 1);
      await ref
          .read(personalRecordsProvider.notifier)
          .markRewardCollected(12);
    }
  }

  static String _formatMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  void _dismissSummary() {
    if (widget.milestone == 11) {
      ref.read(postGameControllerProvider.notifier).dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(gameProvider.notifier);

    final timesReached8192 = widget.milestone == 13
        ? ref.watch(personalRecordsProvider.select((r) => r.timesReached8192))
        : 0;
    final bestTimeMs4096 = widget.milestone == 12
        ? ref.read(gameProvider.select((s) => s.bestTimeMs4096))
        : null;

    // Milestone 11: dados de ranking chegam de forma reativa (fetch async).
    final summary = widget.milestone == 11
        ? ref.watch(postGameControllerProvider)
        : null;
    final bestTimeMs2048 = widget.milestone == 11
        ? ref.read(gameProvider.select((s) => s.bestTimeMs2048))
        : null;

    return PopScope(
      canPop: false,
      child: Stack(
        children: [
          Center(
            child: Card(
              margin: const EdgeInsets.all(32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
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

                    // Milestone 11: tempo + posição no ranking + combo
                    if (widget.milestone == 11) ...[
                      if (bestTimeMs2048 != null && bestTimeMs2048 > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tempo: ${_formatMs(bestTimeMs2048)}',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (summary == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: SizedBox(
                            height: 2,
                            child: LinearProgressIndicator(),
                          ),
                        )
                      else ...[
                        if (summary.rankingPosition != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Você está em ${summary.rankingPosition}º lugar no ranking global!',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                        if (summary.earnedCombo) ...[
                          const Divider(height: 20),
                          Text(
                            '🎁 Recorde pessoal!',
                            style: GoogleFonts.fredoka(
                              fontSize: 15,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '+1 vida  •  +1 bomba  •  +1 desfazer',
                            style: GoogleFonts.nunito(fontSize: 13),
                          ),
                        ],
                      ],
                    ],

                    // Milestone 12: tempo
                    if (widget.milestone == 12 && bestTimeMs4096 != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Seu tempo: ${_formatMs(bestTimeMs4096)}',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],

                    // Milestone 13: vezes que chegou
                    if (widget.milestone == 13) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Você chegou aqui $timesReached8192 '
                        '${timesReached8192 == 1 ? 'vez' : 'vezes'}!',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Ver Ranking (só milestone 11)
                    if (widget.milestone == 11) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            // Submit ranking before navigating so the ranking
                            // screen shows fresh data. Do NOT call endGame() —
                            // the dialog must remain alive when the player
                            // returns so they can still choose Continuar/Encerrar.
                            final nav = Navigator.of(context);
                            await notifier.submitForRanking();
                            nav.push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const RankingScreen(initialTab: 1),
                              ),
                            );
                          },
                          child: Text(
                            'Ver Ranking',
                            style: GoogleFonts.fredoka(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Ver Ranking (milestone 12 → aba Lendas)
                    if (widget.milestone == 12) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            final nav = Navigator.of(context);
                            await _deliverReward();
                            await notifier.submitForRanking();
                            nav.push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const RankingScreen(initialTab: 2),
                              ),
                            );
                          },
                          child: Text(
                            'Ver Ranking',
                            style: GoogleFonts.fredoka(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Ver Ranking (milestone 13 → aba Lendas)
                    if (widget.milestone == 13) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            final nav = Navigator.of(context);
                            await notifier.submitForRanking();
                            nav.push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const RankingScreen(initialTab: 2),
                              ),
                            );
                          },
                          child: Text(
                            'Ver Ranking',
                            style: GoogleFonts.fredoka(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (widget.milestone != 13)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () async {
                            if (widget.milestone == 12) await _deliverReward();
                            _dismissSummary();
                            notifier.dismissMilestone();
                          },
                          child: Text(
                            'Continuar',
                            style: GoogleFonts.fredoka(fontSize: 18),
                          ),
                        ),
                      ),
                    if (widget.milestone != 13) const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          _dismissSummary();
                          await notifier.endGame();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: Text(
                          'Encerrar',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.05,
              colors: _confettiColors(),
            ),
          ),
        ],
      ),
    );
  }
}
