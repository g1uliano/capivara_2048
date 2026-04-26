import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/animals_data.dart';
import '../../../data/models/game_state.dart';
import '../../../domain/game_engine/direction.dart';
import '../../../domain/lives/lives_notifier.dart';
import '../../controllers/game_notifier.dart';
import '../../widgets/board_widget.dart';
import '../../widgets/bomb_selection_overlay.dart';
import '../../widgets/game_background.dart';
import '../../widgets/game_over_modal.dart';
import '../../widgets/host_banner.dart';
import '../../widgets/inventory_bar.dart';
import '../../widgets/lives_indicator.dart';
import '../../widgets/pause_overlay.dart';
import '../../widgets/status_panel.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final GlobalKey _headerKey = GlobalKey();
  double _pauseTop = 80;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePausePosition());
  }

  void _updatePausePosition() {
    final renderBox =
        _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final headerBottom =
        renderBox.localToGlobal(Offset.zero).dy + renderBox.size.height;
    if (mounted) {
      setState(() => _pauseTop = headerBottom + 12);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameProvider);
    final isGameOver = state.isGameOver;
    final hasWon = state.hasWon;
    final notifier = ref.read(gameProvider.notifier);
    final hostAnimal =
        state.maxLevel > 0 ? animalForLevel(state.maxLevel) : null;

    ref.listen<GameState>(gameProvider, (prev, next) {
      if (prev != null && !prev.isGameOver && next.isGameOver && !next.hasWon) {
        ref.read(livesProvider.notifier).consume();
      }
    });

    return Scaffold(
      body: GameBackground(
        animal: hostAnimal,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    key: _headerKey,
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
                      if (state.isPaused || isGameOver || hasWon || state.bombMode != null) return;
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: LivesIndicator(),
                  ),
                ],
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
              if (!isGameOver && !hasWon)
                Positioned(
                  top: _pauseTop,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      state.isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      color: Colors.white,
                    ),
                    iconSize: 32,
                    onPressed:
                        state.isPaused ? notifier.resume : notifier.pause,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
