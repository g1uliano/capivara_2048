import 'dart:math';
import 'package:flutter/material.dart';

/// Full-screen VHS rewind effect overlay.
/// A CustomPainter animates scanlines, glitch bands, a rewind line,
/// and a brief white flash — all drawn on top of the game content below.
class VhsRewindOverlay extends StatefulWidget {
  const VhsRewindOverlay({
    super.key,
    required this.isUndo3,
    required this.onComplete,
  });

  final bool isUndo3;
  final VoidCallback onComplete;

  @override
  State<VhsRewindOverlay> createState() => _VhsRewindOverlayState();
}

class _VhsRewindOverlayState extends State<VhsRewindOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final duration = widget.isUndo3
        ? const Duration(milliseconds: 750)
        : const Duration(milliseconds: 500);
    _controller = AnimationController(vsync: this, duration: duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          widget.onComplete();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _VhsPainter(
          progress: _controller.value,
          isUndo3: widget.isUndo3,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _VhsPainter extends CustomPainter {
  const _VhsPainter({required this.progress, required this.isUndo3});

  final double progress;
  final bool isUndo3;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark translucent overlay
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0x88000000),
    );

    // 2. Horizontal scanlines
    final scanPaint = Paint()..color = const Color(0x26000000);
    for (double y = 0; y < size.height; y += 6) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), scanPaint);
    }

    // 3. White flash at the beginning (first 25% of animation)
    if (progress < 0.25) {
      final flashOpacity = (1.0 - progress / 0.25) * 0.55;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Color.fromRGBO(255, 255, 255, flashOpacity),
      );
    }

    // 4. Rewind line (bright horizontal bar moving bottom to top)
    final lineY = size.height * (1.0 - progress);
    canvas.drawRect(
      Rect.fromLTWH(0, lineY - 1, size.width, 4),
      Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, lineY, size.width, 2),
      Paint()..color = Colors.white,
    );

    // 5. Glitch bands (random horizontal offsets, seeded by frame)
    final rng = Random((progress * 1000).toInt());
    final bandCount = isUndo3 ? 10 : 6;
    final glitchPaint = Paint();
    for (int i = 0; i < bandCount; i++) {
      final y = rng.nextDouble() * size.height;
      final h = rng.nextDouble() * 3 + 1;
      final xOff = (rng.nextDouble() - 0.5) * 16;
      final opacity = rng.nextDouble() * 0.25 + 0.08;
      glitchPaint.color = Color.fromRGBO(255, 255, 255, opacity);
      canvas.drawRect(Rect.fromLTWH(xOff, y, size.width, h), glitchPaint);
    }
  }

  @override
  bool shouldRepaint(_VhsPainter old) => old.progress != progress;
}
