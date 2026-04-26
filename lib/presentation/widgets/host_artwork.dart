import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/models/animal.dart';

class HostArtwork extends StatelessWidget {
  final Animal animal;
  final double size;

  const HostArtwork({super.key, required this.animal, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final path = animal.hostSvgPath ?? animal.assetPath;
    final ratio = animal.hostAspectRatio ?? 1.0;

    final isSvg = path.endsWith('.svg');
    return SizedBox(
      width: size * ratio,
      height: size,
      child: isSvg
          ? SvgPicture.asset(
              path,
              fit: BoxFit.contain,
              placeholderBuilder: (_) => const SizedBox.shrink(),
            )
          : Image.asset(
              path,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
    );
  }
}
