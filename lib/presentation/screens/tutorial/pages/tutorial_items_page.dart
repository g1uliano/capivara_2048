import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/outlined_text.dart';

class TutorialItemsPage extends StatelessWidget {
  const TutorialItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedText(
            text: 'Suas ferramentas',
            style: GoogleFonts.fredoka(
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.white.withValues(alpha: 0.88),
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Image.asset(
                'assets/images/inventory/bomb_3.png',
                width: 48,
                height: 48,
              ),
              title: Text(
                'Bomba',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3E2723),
                ),
              ),
              subtitle: Text(
                'Apaga uma área do tabuleiro quando você se enrosca.',
                style: GoogleFonts.nunito(fontSize: 14, color: Colors.black87),
              ),
            ),
          ).animate(delay: 0.ms).fade(duration: 300.ms).slideX(begin: 0.2),
          Card(
            color: Colors.white.withValues(alpha: 0.88),
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Image.asset(
                'assets/images/inventory/undo_1.png',
                width: 48,
                height: 48,
              ),
              title: Text(
                'Desfazer',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3E2723),
                ),
              ),
              subtitle: Text(
                'Volta a última jogada se rolou um arrependimento.',
                style: GoogleFonts.nunito(fontSize: 14, color: Colors.black87),
              ),
            ),
          ).animate(delay: 100.ms).fade(duration: 300.ms).slideX(begin: 0.2),
          Card(
            color: Colors.white.withValues(alpha: 0.88),
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red, size: 48),
              title: Text(
                'Vidas',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3E2723),
                ),
              ),
              subtitle: Text(
                'Cada partida custa uma vida. Elas se regeneram com o tempo.',
                style: GoogleFonts.nunito(fontSize: 14, color: Colors.black87),
              ),
            ),
          ).animate(delay: 200.ms).fade(duration: 300.ms).slideX(begin: 0.2),
        ],
      ),
    );
  }
}
