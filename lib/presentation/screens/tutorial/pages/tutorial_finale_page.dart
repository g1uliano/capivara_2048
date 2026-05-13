import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/glass_panel.dart';

class TutorialFinalePage extends StatelessWidget {
  const TutorialFinalePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
                'assets/images/animals/tile/Capivara.webp',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(
                begin: 1.0,
                end: 1.03,
                duration: 2000.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 24),
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                Text(
                  'A Capivara Lendária te espera',
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Funda animais, explore os biomas brasileiros e chegue até ela. Boa sorte, explorador!',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
