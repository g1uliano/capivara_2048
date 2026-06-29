import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/game_engine/bomb_mode.dart';
import '../controllers/game_notifier.dart';

/// Full-screen dim + label + cancel button.
/// The dim background is IgnorePointer so taps pass through to BombGridOverlay.
/// Only the cancel button absorbs pointer events.
/// When [maxTiles] and [onCancel] are provided, operates in standalone mode (tutorial).
class BombDimOverlay extends ConsumerWidget {
  // ponytail: optional params — tutorial passes local state, game uses provider default
  final int? maxTiles;
  final VoidCallback? onCancel;

  const BombDimOverlay({super.key, this.maxTiles, this.onCancel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStandalone = maxTiles != null;
    final notifier = isStandalone ? null : ref.read(gameProvider.notifier);
    final state = isStandalone ? null : ref.watch(gameProvider);

    // In global mode, hide when not in bomb mode.
    if (!isStandalone) {
      final mode = state!.bombMode;
      if (mode == null) return const SizedBox.shrink();
    }

    final effectiveMaxTiles =
        maxTiles ?? (state?.bombMode == BombMode.bomb2 ? 2 : 3);
    final effectiveOnCancel = onCancel ?? notifier!.cancelBomb;

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
                    'Selecione $effectiveMaxTiles peças para destruir',
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
                  onPressed: effectiveOnCancel,
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
