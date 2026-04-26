import 'package:flutter/material.dart';

enum TexturePattern { dots, diagonal, grid, waves, blobs, scales, radial }

class Animal {
  final int level;
  final int value;
  final String name;
  final Color borderColor;
  final Color backgroundBaseColor;
  final String assetPath;
  final TexturePattern texturePattern;
  final String? hostSvgPath;
  final double? hostAspectRatio;
  final String? backgroundTexturePath;

  const Animal({
    required this.level,
    required this.value,
    required this.name,
    required this.borderColor,
    required this.backgroundBaseColor,
    required this.assetPath,
    required this.texturePattern,
    this.hostSvgPath,
    this.hostAspectRatio,
    this.backgroundTexturePath,
  });
}
