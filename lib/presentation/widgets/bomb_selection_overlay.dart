import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/game_engine/bomb_mode.dart';
import '../controllers/game_notifier.dart';

/// Full-screen dim + label + cancel button.
/// The dim background is IgnorePointer so taps pass through to BombGridOverlay.
/// Only the cancel button absorbs pointer events.
class BombDimOverlay extends ConsumerWidget {
  const BombDimOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final state = ref.watch(gameProvider);
    final mode = state.bombMode;
    if (mode == null) return const SizedBox.shrink();

    final maxTiles = mode == BombMode.bomb2 ? 2 : 3;

    return Stack(
      children: [
        // Dim background — passes all taps through to BombGridOverlay below
        IgnorePointer(
          child: Container(color: const Color(0x60000000)),
        ),
        // Label at the top — display only, no interaction needed
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    'Selecione $maxTiles tiles para destruir',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Cancel button — interactive
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: TextButton(
                  onPressed: notifier.cancelBomb,
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
