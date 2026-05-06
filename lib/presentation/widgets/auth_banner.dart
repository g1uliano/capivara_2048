import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../screens/onboarding_auth_screen.dart';

class AuthBanner extends ConsumerWidget {
  const AuthBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider);
    if (profile != null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppColors.primary.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Faça login para salvar seu progresso e acessar o ranking.',
              style: GoogleFonts.nunito(color: Colors.white, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OnboardingAuthScreen()),
            ),
            child: Text(
              'Entrar',
              style: GoogleFonts.fredoka(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
