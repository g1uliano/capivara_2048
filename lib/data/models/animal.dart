import 'package:flutter/material.dart';

class Animal {
  final int level;
  final int value;
  final String name;
  final Color borderColor;
  final String assetPath;

  const Animal({
    required this.level,
    required this.value,
    required this.name,
    required this.borderColor,
    required this.assetPath,
  });
}
