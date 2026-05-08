import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/outlined_text.dart';
import '../../../widgets/game_title_image.dart';

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
          OutlinedText(
            text: 'Bem-vindo à floresta amazônica!',
            style: GoogleFonts.fredoka(
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: OutlinedText(
              text:
                  'Aqui moram bichos de todo tipo — e cabe a você ajudá-los a evoluir até descobrir a lendária Capivara. Bora aprender?',
              style: GoogleFonts.fredoka(fontSize: 16, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ).animate().fade(duration: 300.ms).slideY(begin: 0.1, end: 0, duration: 300.ms),
    );
  }
}
