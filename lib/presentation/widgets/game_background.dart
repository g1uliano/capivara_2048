import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/animal.dart';

class GameBackground extends StatelessWidget {
  final Animal? animal;
  final Widget child;

  const GameBackground({super.key, required this.animal, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.gameBackground,
          image: DecorationImage(
            image: AssetImage('assets/images/fundo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: child,
      ),
    );
  }
}
