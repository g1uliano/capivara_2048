import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mascote da Capivara que se posiciona ao lado do dia atual na trilha de
/// recompensa diária. Tem animação sutil de "bobbing" (flutua pra cima e pra
/// baixo) para parecer viva.
///
/// O posicionamento é controlado pelo widget pai (via AnimatedPositioned ou
/// AnimatedAlign) — este widget só renderiza o sprite + balão "Você está aqui!".
class CapivaraMascot extends StatelessWidget {
  final double size;
  final bool showHint;

  const CapivaraMascot({super.key, this.size = 64, this.showHint = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHint)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.brown.shade700, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Aqui!',
              style: GoogleFonts.fredoka(
                color: const Color(0xFF3E2723),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Image.asset(
              'assets/images/animals/tile/Capivara.webp',
              width: size,
              height: size,
              fit: BoxFit.contain,
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              duration: 1100.ms,
              begin: 0,
              end: -6,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }
}
