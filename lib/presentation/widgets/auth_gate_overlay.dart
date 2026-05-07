// lib/presentation/widgets/auth_gate_overlay.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/text_styles.dart';
import '../controllers/auth_controller.dart';
import '../screens/onboarding_auth_screen.dart';
import 'game_title_image.dart';

class AuthGateOverlay extends ConsumerWidget {
  const AuthGateOverlay({
    super.key,
    required this.child,
    required this.reason,
    required this.onClose,
  });

  final Widget child;
  final String reason;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authControllerProvider) != null;
    if (isLoggedIn) return child;

    return Container(
      color: Colors.black.withOpacity(0.85),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GameTitleImage(asset: GameTitleImage.pickAsset(), height: 80),
              const SizedBox(height: 24),
              Text(
                reason,
                textAlign: TextAlign.center,
                style: outlinedWhiteTextStyle(
                  GoogleFonts.fredoka(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),
              ..._buildBenefits(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OnboardingAuthScreen(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C42),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Fazer login',
                    style: GoogleFonts.fredoka(
                        fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onClose,
                child: Text(
                  'Agora não',
                  style: outlinedWhiteTextStyle(
                      GoogleFonts.fredoka(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBenefits() {
    const items = [
      (Icons.sync_alt, 'Progresso salvo em todos os dispositivos'),
      (Icons.emoji_events, 'Ranking global semanal'),
      (Icons.card_giftcard, 'Recompensas diárias com itens'),
      (Icons.shopping_bag, 'Acesso à loja de itens'),
    ];
    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(item.$1, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.$2,
                    style: outlinedWhiteTextStyle(
                        GoogleFonts.fredoka(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}
