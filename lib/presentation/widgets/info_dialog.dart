import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showInfoDialog({
  required BuildContext context,
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _InfoDialog(title: title, message: message),
  );
}

class _InfoDialog extends StatelessWidget {
  final String title;
  final String message;

  const _InfoDialog({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFFF9800), width: 3),
      ),
      title: Text(
        title,
        style: GoogleFonts.fredoka(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: const Color(0xFFE65100),
        ),
        textAlign: TextAlign.center,
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
