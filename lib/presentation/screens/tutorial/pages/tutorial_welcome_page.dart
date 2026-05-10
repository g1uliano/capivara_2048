import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/game_title_image.dart';
import '../../../widgets/glass_panel.dart';

class TutorialWelcomePage extends StatefulWidget {
  const TutorialWelcomePage({super.key});

  @override
  State<TutorialWelcomePage> createState() => _TutorialWelcomePageState();
}

class _TutorialWelcomePageState extends State<TutorialWelcomePage> {
  late final String _titleAsset;

  @override
  void initState() {
    super.initState();
    _titleAsset = GameTitleImage.pickAsset();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GameTitleImage(asset: _titleAsset, height: 120),
          const SizedBox(height: 24),
          GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                Text(
                  'Bem-vindo à fauna do Brasil!',
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Do Cerrado à Amazônia, do Pantanal à Mata Atlântica — aqui vivem os bichos mais incríveis do Brasil. Ajude-os a evoluir e encontre a lendária Capivara!',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bora aprender? 🌿',
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ).animate().fade(duration: 300.ms).slideY(begin: 0.1, end: 0, duration: 300.ms),
    );
  }
}
