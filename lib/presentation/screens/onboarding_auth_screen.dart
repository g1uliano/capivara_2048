import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/home_constants.dart';
import '../../core/theme/text_styles.dart';
import '../controllers/auth_controller.dart';
import '../widgets/game_background.dart';
import '../widgets/game_title_image.dart';
import 'email_auth_screen.dart';
import 'home_screen.dart';

class OnboardingAuthScreen extends ConsumerStatefulWidget {
  const OnboardingAuthScreen({super.key});

  @override
  ConsumerState<OnboardingAuthScreen> createState() =>
      _OnboardingAuthScreenState();
}

class _OnboardingAuthScreenState extends ConsumerState<OnboardingAuthScreen> {
  bool _loading = false;

  Future<void> _handleSignIn(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) _navigateHome();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao entrar: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(authControllerProvider.notifier);

    final size = MediaQuery.of(context).size;
    final scale = min(size.width / 390.0, size.height / 844.0).clamp(0.1, 1.0);

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GameTitleImage(
                  asset: GameTitleImage.pickAsset(),
                  height: HomeConstants.titleHeight(scale),
                ),
                const SizedBox(height: 8),
                Text(
                  'Salve seu progresso e dispute o ranking global.',
                  textAlign: TextAlign.center,
                  style: outlinedWhiteTextStyle(
                    GoogleFonts.nunito(fontSize: 15),
                  ),
                ),
                const SizedBox(height: 48),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else ...[
                  _AuthButton(
                    label: 'Entrar com Google',
                    icon: Icons.g_mobiledata,
                    onPressed: () => _handleSignIn(controller.signInWithGoogle),
                  ),
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 12),
                    _AuthButton(
                      label: 'Entrar com Apple',
                      icon: Icons.apple,
                      onPressed: () =>
                          _handleSignIn(controller.signInWithApple),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _AuthButton(
                    label: 'Entrar com Email',
                    icon: Icons.email_outlined,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EmailAuthScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: _navigateHome,
                    child: Text(
                      'Jogar sem conta →',
                      style: outlinedWhiteTextStyle(
                        GoogleFonts.nunito(
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, style: GoogleFonts.fredoka(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
