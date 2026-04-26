import 'package:flutter/material.dart';
import '../../core/theme/text_styles.dart';

class OutlinedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const OutlinedText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: outlinedWhiteTextStyle(style ?? const TextStyle()),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
