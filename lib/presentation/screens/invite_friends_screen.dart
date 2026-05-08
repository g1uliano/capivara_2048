import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../controllers/invite_controller.dart';
import '../widgets/auth_banner.dart';
import '../widgets/game_background.dart';

class InviteFriendsScreen extends ConsumerWidget {
  const InviteFriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider);
    final inviteState = ref.watch(inviteControllerProvider);

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Convidar Amigos',
            style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            if (profile == null) const AuthBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  children: [
                    const _HeroCard(),
                    const SizedBox(height: 20),
                    if (profile == null)
                      const _LoginPrompt()
                    else
                      inviteState.when(
                        data: (link) => link == null
                            ? _GenerateButton(
                                onPressed: () => ref
                                    .read(inviteControllerProvider.notifier)
                                    .generateLink(),
                              )
                            : _LinkSection(link: link),
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        error: (e, _) => _GlassPanel(
                          child: Text(
                            'Erro ao gerar link: $e',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────── Hero card com Capivara + recompensas ──────────
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          // Capivara com glow dourado
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFFD54F), Color(0x00FFD54F)],
                stops: [0.0, 0.75],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.55),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/images/animals/tile/Capivara.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Convide e ganhem juntos!',
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quando seu amigo entrar pelo seu link e jogar a primeira partida, vocês dois recebem:',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          // Recompensas
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RewardChip(
                icon: Icon(Icons.favorite, color: Color(0xFFE53935), size: 32),
                quantity: '2',
                label: 'Vidas',
              ),
              SizedBox(width: 14),
              _RewardChip(
                imageAsset: 'assets/images/inventory/bomb_2.png',
                quantity: '1',
                label: 'Bomba',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    this.icon,
    this.imageAsset,
    required this.quantity,
    required this.label,
  });

  final Widget? icon;
  final String? imageAsset;
  final String quantity;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: icon ?? Image.asset(imageAsset!, fit: BoxFit.contain),
          ),
          const SizedBox(height: 8),
          Text(
            '+$quantity',
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────── Link section: card + botões ──────────
class _LinkSection extends StatelessWidget {
  const _LinkSection({required this.link});
  final String link;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GlassPanel(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SEU LINK DE CONVITE',
                style: GoogleFonts.fredoka(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: const Color(0xFFFFD54F),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  link,
                  style: GoogleFonts.robotoMono(
                    fontSize: 12.5,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Botão primário: Compartilhar
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                text: 'Jogue Olha o Bichim! comigo! $link',
                subject: 'Convite para Olha o Bichim!',
              ),
            ),
            icon: const Icon(Icons.share, size: 22),
            label: Text(
              'Compartilhar convite',
              style: GoogleFonts.fredoka(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5A623),
              foregroundColor: const Color(0xFF4A2400),
              elevation: 6,
              shadowColor: const Color(0xFFF5A623).withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Botão secundário: Copiar
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Link copiado!'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 18, color: Color(0xFF4A2400)),
            label: Text(
              'Copiar link',
              style: GoogleFonts.fredoka(
                fontSize: 14,
                color: const Color(0xFF4A2400),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ────────── Botão para gerar link ──────────
class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.link, size: 22),
        label: Text(
          'Gerar meu link',
          style: GoogleFonts.fredoka(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF5A623),
          foregroundColor: const Color(0xFF4A2400),
          elevation: 6,
          shadowColor: const Color(0xFFF5A623).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ────────── Mensagem para usuário não logado ──────────
class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.white70, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Faça login para gerar seu link de convite.',
              style: GoogleFonts.fredoka(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────── Glass panel reutilizável ──────────
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF0A1F0D).withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
