import 'dart:math' as math;
import 'package:flutter/material.dart';

enum TexturePattern { dots, diagonal, grid, waves, blobs, scales, radial }

class TexturePainter extends CustomPainter {
  final TexturePattern pattern;
  final Color color;

  const TexturePainter({required this.pattern, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    switch (pattern) {
      case TexturePattern.dots:
        _drawDots(canvas, size, paint);
      case TexturePattern.diagonal:
        _drawDiagonal(canvas, size, paint);
      case TexturePattern.grid:
        _drawGrid(canvas, size, paint);
      case TexturePattern.waves:
        _drawWaves(canvas, size, paint);
      case TexturePattern.blobs:
        _drawBlobs(canvas, size, paint);
      case TexturePattern.scales:
        _drawScales(canvas, size, paint);
      case TexturePattern.radial:
        _drawRadial(canvas, size, paint);
    }
  }

  void _drawDots(Canvas canvas, Size size, Paint paint) {
    const spacing = 20.0;
    final dotPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2, dotPaint);
      }
    }
  }

  void _drawDiagonal(Canvas canvas, Size size, Paint paint) {
    const spacing = 18.0;
    for (double d = -size.height; d < size.width + size.height; d += spacing) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), paint);
    }
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    const spacing = 22.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawWaves(Canvas canvas, Size size, Paint paint) {
    const spacing = 20.0;
    const amplitude = 6.0;
    const freq = 0.04;
    for (double y = spacing; y < size.height; y += spacing) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x < size.width; x++) {
        path.lineTo(x, y + amplitude * math.sin(x * freq * math.pi));
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawBlobs(Canvas canvas, Size size, Paint paint) {
    const spacing = 32.0;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x + (y % 20 - 10), y), width: 14, height: 10),
          paint,
        );
      }
    }
  }

  void _drawScales(Canvas canvas, Size size, Paint paint) {
    const w = 20.0;
    const h = 12.0;
    for (double row = 0; row < size.height / h; row++) {
      final offset = (row % 2) * (w / 2);
      for (double col = -1; col < size.width / w + 1; col++) {
        final x = col * w + offset;
        final y = row * h;
        final path = Path()
          ..moveTo(x, y + h)
          ..quadraticBezierTo(x + w / 2, y, x + w, y + h);
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawRadial(Canvas canvas, Size size, Paint paint) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const lines = 16;
    final maxR = size.longestSide;
    for (int i = 0; i < lines; i++) {
      final angle = (i / lines) * 2 * math.pi;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + maxR * math.cos(angle), cy + maxR * math.sin(angle)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(TexturePainter old) =>
      old.pattern != pattern || old.color != color;
}
