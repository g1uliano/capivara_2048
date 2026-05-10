import 'dart:ui';
import 'package:flutter/material.dart';

/// Painel glass-morphism usado para envolver conteúdo de texto sobre o fundo
/// do jogo (GameBackground). Combina BackdropFilter blur com um container
/// escuro esmeralda semi-transparente e borda sutil.
///
/// Usado em: OnboardingAuthScreen (_ContentPanel), InviteFriendsScreen
/// (_GlassPanel), TutorialScreen (todas as páginas de texto).
///
/// Exemplo de uso:
/// ```dart
/// GlassPanel(
///   child: Text('Olá!', style: GoogleFonts.fredoka(color: Colors.white)),
/// )
/// ```
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.borderRadius = 20.0,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            // Esmeralda escuro translúcido — funde com a floresta sem bloquear
            color: const Color(0xFF0A1F0D).withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(borderRadius),
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
