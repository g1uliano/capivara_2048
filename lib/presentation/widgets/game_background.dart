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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: animal == null
          ? ColoredBox(
              key: const ValueKey('no-animal'),
              color: AppColors.primary,
              child: SizedBox.expand(child: child),
            )
          : _Background(
              key: ValueKey(animal!.level),
              animal: animal!,
              child: child,
            ),
    );
  }
}

class _Background extends StatelessWidget {
  final Animal animal;
  final Widget child;

  const _Background({super.key, required this.animal, required this.child});

  Color get _bgColor =>
      Color.lerp(animal.borderColor, AppColors.mint, 0.65) ?? AppColors.mint;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: _bgColor),
        Opacity(
          opacity: 0.12,
          child: RepaintBoundary(
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
        ),
        child,
      ],
    );
  }
}
