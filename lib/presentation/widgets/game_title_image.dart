import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class GameTitleImage extends StatelessWidget {
  const GameTitleImage({super.key, required this.asset, this.height});

  final String asset;
  final double? height;

  @visibleForTesting
  static String pickAsset({Random? random}) {
    final r = random ?? Random();
    return r.nextInt(2) == 0
        ? 'assets/images/title/title_brown.png'
        : 'assets/images/title/title_orange.png';
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Olha o Bichim!',
    );
  }
}
