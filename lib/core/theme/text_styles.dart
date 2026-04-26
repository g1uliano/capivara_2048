import 'package:flutter/material.dart';

TextStyle outlinedWhiteTextStyle(TextStyle base) {
  const d = 1.5;
  const d45 = 1.06; // d * cos(45°)
  const blur = 0.8;
  return base.copyWith(
    color: Colors.white,
    shadows: const [
      Shadow(color: Colors.black, offset: Offset(d, 0), blurRadius: blur),
      Shadow(color: Colors.black, offset: Offset(-d, 0), blurRadius: blur),
      Shadow(color: Colors.black, offset: Offset(0, d), blurRadius: blur),
      Shadow(color: Colors.black, offset: Offset(0, -d), blurRadius: blur),
      Shadow(color: Colors.black, offset: Offset(d45, d45), blurRadius: blur),
      Shadow(color: Colors.black, offset: Offset(-d45, d45), blurRadius: blur),
      Shadow(color: Colors.black, offset: Offset(d45, -d45), blurRadius: blur),
      Shadow(color: Colors.black, offset: Offset(-d45, -d45), blurRadius: blur),
    ],
  );
}
