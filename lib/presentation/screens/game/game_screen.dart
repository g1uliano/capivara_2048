import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/game_state.dart';
import '../../../domain/game_engine/direction.dart';
import '../../../domain/lives/lives_notifier.dart';
import '../../controllers/game_notifier.dart';
import '../../widgets/board_widget.dart';
import '../../widgets/bomb_selection_overlay.dart';
import '../../widgets/game_background.dart';
import '../../widgets/game_header.dart';
import '../../widgets/game_over_modal.dart';
import '../../widgets/inventory_bar.dart';
import '../../widgets/pause_overlay.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final isGameOver = state.isGameOver;
    final hasWon = state.hasWon;
    final notifier = ref.read(gameProvider.notifier);
    ref.listen<GameState>(gameProvider, (prev, next) {
      if (prev != null && !prev.isGameOver && next.isGameOver && !next.hasWon) {
        ref.read(livesProvider.notifier).consume();
      }
    });

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    GameHeader(
                      onPauseTap: state.isPaused
                          ? notifier.resume
                          : notifier.pause,
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanEnd: (details) {
                        if (state.isPaused ||
                            isGameOver ||
                            hasWon ||
                            state.bombMode != null) return;
                        final v = details.velocity.pixelsPerSecond;
                        const threshold = 100.0;
                        if (v.dx.abs() > v.dy.abs()) {
                          if (v.dx > threshold) {
                            notifier.onSwipe(Direction.right);
                          } else if (v.dx < -threshold) {
                            notifier.onSwipe(Direction.left);
                          }
                        } else {
                          if (v.dy > threshold) {
                            notifier.onSwipe(Direction.down);
                          } else if (v.dy < -threshold) {
                            notifier.onSwipe(Direction.up);
                          }
                        }
                      },
                      child: const RepaintBoundary(child: BoardWidget()),
                    ),
                    const Spacer(),
                    const InventoryBar(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              if (state.isPaused) const Positioned.fill(child: PauseOverlay()),
              if (state.bombMode != null)
                const Positioned.fill(child: BombSelectionOverlay()),
              if (isGameOver)
                const Positioned.fill(
                    child: GameOverModal(message: 'Game Over!')),
              if (hasWon && !isGameOver)
                const Positioned.fill(
                    child: GameOverModal(message: 'Capivara Lendária! 🎉')),
            ],
          ),
        ),
      ),
    );
  }
}
