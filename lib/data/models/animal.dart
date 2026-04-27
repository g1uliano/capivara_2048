import 'package:flutter/material.dart';

class Animal {
  final int level;
  final int value;
  final String name;
  final Color borderColor;
  final Color backgroundBaseColor;
  final String tilePngPath;
  final String hostPngPath;
  final String? scientificName;
  final String? funFact;

  const Animal({
    required this.level,
    required this.value,
    required this.name,
    required this.borderColor,
    required this.backgroundBaseColor,
    required this.tilePngPath,
    required this.hostPngPath,
    this.scientificName,
    this.funFact,
  });
}
