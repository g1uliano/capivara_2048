import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/animal.dart';
import 'texture_painter.dart';

class GameBackground extends StatelessWidget {
  final Animal? animal;
  final Widget child;

  const GameBackground({super.key, required this.animal, required this.child});

  @override
  Widget build(BuildContext context) {
    final targetColor = animal?.backgroundBaseColor ?? AppColors.primary;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: null, end: targetColor),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      child: child,
      builder: (context, color, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: color ?? AppColors.primary),
            if (animal != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _TextureLayer(
                  key: ValueKey(animal!.level),
                  animal: animal!,
                ),
              ),
            if (child != null) child,
          ],
        );
      },
    );
  }
}

class _TextureLayer extends StatelessWidget {
  final Animal animal;
  const _TextureLayer({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Opacity(
        opacity: 0.12,
        child: animal.backgroundTexturePath != null
            ? Image.asset(
                animal.backgroundTexturePath!,
                repeat: ImageRepeat.repeat,
                fit: BoxFit.none,
                errorBuilder: (_, __, ___) => CustomPaint(
                  painter: TexturePainter(
                    pattern: animal.texturePattern,
                    color: animal.borderColor,
                  ),
                  size: Size.infinite,
                ),
              )
            : CustomPaint(
                painter: TexturePainter(
                  pattern: animal.texturePattern,
                  color: animal.borderColor,
                ),
                size: Size.infinite,
              ),
      ),
    );
  }
}
