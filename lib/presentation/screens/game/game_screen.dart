import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/animals_data.dart';
import '../../../domain/game_engine/direction.dart';
import '../../controllers/game_notifier.dart';
import '../../widgets/board_widget.dart';
import '../../widgets/game_background.dart';
import '../../widgets/host_banner.dart';
import '../../widgets/lives_indicator.dart';
import '../../widgets/pause_overlay.dart';
import '../../widgets/status_panel.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final isGameOver = state.isGameOver;
    final hasWon = state.hasWon;
    final notifier = ref.read(gameProvider.notifier);
    final hostAnimal = state.maxLevel > 0 ? animalForLevel(state.maxLevel) : null;

    return Scaffold(
      body: GameBackground(
        animal: hostAnimal,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const HostBanner(),
                        const Spacer(),
                        const StatusPanel(),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanEnd: (details) {
                      if (state.isPaused || isGameOver) return;
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
                    child: Stack(
                      children: [
                        const RepaintBoundary(child: BoardWidget()),
                        if (state.isPaused) const PauseOverlay(),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: LivesIndicator(),
                  ),
                  if (isGameOver) _buildOverlay('Game Over!', notifier),
                  if (hasWon && !isGameOver)
                    _buildOverlay('Capivara Lendária! 🎉', notifier),
                ],
              ),
              // Floating pause button — positioned below the header row
              if (!isGameOver && !hasWon)
                Positioned(
                  top: 72,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      state.isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      color: Colors.white,
                    ),
                    iconSize: 32,
                    onPressed: state.isPaused ? notifier.resume : notifier.pause,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(String message, GameNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(message,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => notifier.restart(),
            child: const Text('Jogar de novo'),
          ),
        ],
      ),
    );
  }
}
