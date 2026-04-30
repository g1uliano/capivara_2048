import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<bool> showConfirmUseDialog({
  required BuildContext context,
  required String itemName,
  required String description,
  String? pngPath,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ConfirmUseDialog(
      itemName: itemName,
      description: description,
      pngPath: pngPath,
    ),
  );
  return result ?? false;
}

class _ConfirmUseDialog extends StatelessWidget {
  final String itemName;
  final String description;
  final String? pngPath;

  const _ConfirmUseDialog({
    required this.itemName,
    required this.description,
    this.pngPath,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          if (pngPath != null) ...[
            Image.asset(pngPath!, width: 40, height: 40),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              'Usar $itemName?',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ],
      ),
      content: Text(
        description,
        style: GoogleFonts.nunito(fontSize: 15),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancelar',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Confirmar',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
