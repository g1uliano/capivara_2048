import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../controllers/auth_controller.dart';
import '../widgets/avatar_widget.dart';
import 'avatar_picker_screen.dart';
import '../widgets/game_background.dart';
import '../../data/models/player_profile.dart';
import 'onboarding_auth_screen.dart';
import 'invite_friends_screen.dart';
import '../../domain/shop/iap_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider);

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Perfil',
            style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: profile == null
            ? _NotLoggedIn(
                onLogin: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OnboardingAuthScreen(),
                  ),
                ),
              )
            : _LoggedIn(
                profile: profile,
                onSignOut: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
      ),
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  const _NotLoggedIn({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.person_outline,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Você não está conectado.',
              style: outlinedWhiteTextStyle(GoogleFonts.nunito(fontSize: 16)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C42),
                minimumSize: const Size(200, 48),
              ),
              child: Text(
                'Entrar',
                style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoggedIn extends ConsumerWidget {
  const _LoggedIn({required this.profile, required this.onSignOut});
  final PlayerProfile profile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarWidget(radius: 40, profile: profile),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AvatarPickerScreen(
                        onDone: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D52),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            profile.displayName,
            style: outlinedWhiteTextStyle(
              GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        if (profile.email != null) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              profile.email!,
              style: outlinedWhiteTextStyle(GoogleFonts.nunito(fontSize: 14)),
            ),
          ),
        ],
        const SizedBox(height: 32),
        const Divider(color: Colors.white24),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.person_add, color: Colors.white),
          title: Text(
            'Convidar Amigos',
            style: outlinedWhiteTextStyle(GoogleFonts.nunito()),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const InviteFriendsScreen()),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.restore, color: Colors.white),
          title: Text(
            'Restaurar compras',
            style: outlinedWhiteTextStyle(GoogleFonts.nunito()),
          ),
          onTap: () async {
            final iapService = ref.read(iapServiceProvider);
            await iapService.restorePurchases();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compras restauradas!')),
              );
            }
          },
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: Text(
            'Sair',
            style: outlinedWhiteTextStyle(
              GoogleFonts.nunito(),
            ).copyWith(color: Colors.redAccent),
          ),
          onTap: onSignOut,
        ),
      ],
    );
  }
}
