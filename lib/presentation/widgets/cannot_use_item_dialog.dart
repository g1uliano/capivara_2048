import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showCannotUseItemDialog({
  required BuildContext context,
  required String message,
  String? pngPath,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _CannotUseItemDialog(message: message, pngPath: pngPath),
  );
}

class _CannotUseItemDialog extends StatelessWidget {
  final String message;
  final String? pngPath;

  const _CannotUseItemDialog({required this.message, this.pngPath});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFFF9800), width: 3),
      ),
      title: Row(
        children: [
          if (pngPath != null) ...[
            ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0,      0,      0,      1, 0,
              ]),
              child: Image.asset(pngPath!, width: 40, height: 40),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              'Ops! 🙈',
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFFE65100),
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: GoogleFonts.nunito(fontSize: 16),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF9800),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Entendi!',
            style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
