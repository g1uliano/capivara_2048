import 'package:flutter/material.dart';

TextStyle outlinedWhiteTextStyle(TextStyle base) {
  const offset = 1.5;
  return base.copyWith(
    color: Colors.white,
    shadows: const [
      Shadow(color: Colors.black, offset: Offset(offset, offset)),
      Shadow(color: Colors.black, offset: Offset(-offset, offset)),
      Shadow(color: Colors.black, offset: Offset(offset, -offset)),
      Shadow(color: Colors.black, offset: Offset(-offset, -offset)),
    ],
  );
}
