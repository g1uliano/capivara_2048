import 'package:flutter/material.dart';

enum TexturePattern { dots, diagonal, grid, waves, blobs, scales, radial }

class Animal {
  final int level;
  final int value;
  final String name;
  final Color borderColor;
  final String assetPath;
  final String? hostSvgPath;
  final double? hostAspectRatio;
  final String? backgroundTexturePath;
  final TexturePattern texturePattern;

  const Animal({
    required this.level,
    required this.value,
    required this.name,
    required this.borderColor,
    required this.assetPath,
    required this.texturePattern,
    this.hostSvgPath,
    this.hostAspectRatio,
    this.backgroundTexturePath,
  });
}
