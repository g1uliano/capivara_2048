import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/game_engine/direction.dart';
import '../../controllers/game_notifier.dart';
import '../../widgets/board_widget.dart';
import '../../widgets/score_panel.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF3FA968),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanEnd: (details) {
            final v = details.velocity.pixelsPerSecond;
            const threshold = 100.0;
            if (v.dx.abs() > v.dy.abs()) {
              if (v.dx > threshold) {
                ref.read(gameProvider.notifier).onSwipe(Direction.right);
              } else if (v.dx < -threshold) {
                ref.read(gameProvider.notifier).onSwipe(Direction.left);
              }
            } else {
              if (v.dy > threshold) {
                ref.read(gameProvider.notifier).onSwipe(Direction.down);
              } else if (v.dy < -threshold) {
                ref.read(gameProvider.notifier).onSwipe(Direction.up);
              }
            }
          },
          child: Column(
            children: [
              const ScorePanel(),
              const Spacer(),
              const BoardWidget(),
              const Spacer(),
              if (state.isGameOver)
                _buildOverlay('Game Over!', ref),
              if (state.hasWon && !state.isGameOver)
                _buildOverlay('Capivara Lendária! 🎉', ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(String message, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(message,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ref.read(gameProvider.notifier).restart(),
            child: const Text('Jogar de novo'),
          ),
        ],
      ),
    );
  }
}
