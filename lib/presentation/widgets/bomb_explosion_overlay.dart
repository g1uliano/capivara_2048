import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/game_constants.dart';

/// Shows explosion particles over each selected bomb tile.
/// Uses the same grid layout as BombGridOverlay for pixel-perfect alignment.
class BombExplosionOverlay extends StatefulWidget {
  const BombExplosionOverlay({
    super.key,
    required this.positions,
    required this.isBomb3,
    required this.onComplete,
  });

  final List<(int, int)> positions;
  final bool isBomb3;
  final VoidCallback onComplete;

  static const _duration = Duration(milliseconds: 350);

  @override
  State<BombExplosionOverlay> createState() => _BombExplosionOverlayState();
}

class _BombExplosionOverlayState extends State<BombExplosionOverlay> {
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(BombExplosionOverlay._duration, () {
      if (mounted && !_completed) {
        _completed = true;
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(GameConstants.tileSpacing),
      child: Column(
        children: List.generate(
          GameConstants.boardSize,
          (r) => Expanded(
            child: Row(
              children: List.generate(
                GameConstants.boardSize,
                (c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(
                      GameConstants.tileSpacing / 2,
                    ),
                    child: widget.positions.contains((r, c))
                        ? _ExplosionCell(isBomb3: widget.isBomb3)
                        : const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplosionCell extends StatelessWidget {
  const _ExplosionCell({required this.isBomb3});
  final bool isBomb3;

  @override
  Widget build(BuildContext context) {
    final color = isBomb3 ? Colors.red.shade600 : Colors.orange.shade500;
    final scale = isBomb3 ? 1.6 : 1.3;
    return Center(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.85),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 12,
              spreadRadius: 4,
            ),
          ],
        ),
      )
          .animate()
          .scale(
            begin: const Offset(0.2, 0.2),
            end: Offset(scale, scale),
            duration: BombExplosionOverlay._duration,
            curve: Curves.easeOutCubic,
          )
          .fadeOut(
            delay: const Duration(milliseconds: 150),
            duration: const Duration(milliseconds: 200),
          ),
    );
  }
}
