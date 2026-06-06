import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/performance_settings_notifier.dart';

Future<void> showPerformanceSuggestionDialog(
  BuildContext context,
  WidgetRef ref,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PerformanceSuggestionDialog(ref: ref),
  );
}

class _PerformanceSuggestionDialog extends StatelessWidget {
  final WidgetRef ref;
  const _PerformanceSuggestionDialog({required this.ref});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFFF9800), width: 3),
      ),
      title: Text(
        'Modo de Desempenho 🐢',
        style: GoogleFonts.fredoka(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: const Color(0xFFE65100),
        ),
      ),
      content: Text(
        'Detectamos que seu dispositivo pode estar com dificuldades para rodar o jogo suavemente. Quer ativar o Modo de Desempenho?',
        style: GoogleFonts.nunito(fontSize: 16),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () {
            ref.read(performanceSettingsProvider.notifier).markDialogShown();
            Navigator.of(context).pop();
          },
          child: Text(
            'Agora não',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              color: const Color(0xFFE65100),
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF9800),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
          onPressed: () {
            ref.read(performanceSettingsProvider.notifier).enable();
            Navigator.of(context).pop();
          },
          child: Text(
            'Ativar',
            style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
