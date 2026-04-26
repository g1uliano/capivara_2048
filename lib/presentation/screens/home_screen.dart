import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/lives/lives_notifier.dart';
import '../controllers/game_notifier.dart';
import '../widgets/lives_indicator.dart';
import 'game/game_screen.dart';
import 'no_lives_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final hasSave = gameState.score > 0 || gameState.maxLevel > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF3FA968),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: LivesIndicator(),
              ),
              const Spacer(),
              SvgPicture.asset(
                'assets/images/home_ensemble.svg',
                height: 220,
              ),
              const SizedBox(height: 32),
              _HomeButton(
                label: 'Novo Jogo',
                onPressed: () => _startNew(context, ref),
              ),
              const SizedBox(height: 12),
              _HomeButton(
                label: 'Continuar',
                onPressed: hasSave ? () => _continue(context) : null,
              ),
              const SizedBox(height: 12),
              const _RankingButton(),
              const SizedBox(height: 12),
              _HomeButton(
                label: 'Sair',
                onPressed: () => SystemNavigator.pop(),
                secondary: true,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _startNew(BuildContext context, WidgetRef ref) {
    final lives = ref.read(livesProvider).lives;
    if (lives <= 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NoLivesScreen(midGame: false)),
      );
      return;
    }
    ref.read(livesProvider.notifier).consume();
    ref.read(gameProvider.notifier).restart();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  void _continue(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
  }
}

class _HomeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;

  const _HomeButton({
    required this.label,
    this.onPressed,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary ? Colors.white24 : Colors.white,
          foregroundColor: secondary ? Colors.white : const Color(0xFF3FA968),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _RankingButton extends StatelessWidget {
  const _RankingButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null, // Fase 3
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white38,
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Ranking',
                style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Positioned(
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Em breve',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
