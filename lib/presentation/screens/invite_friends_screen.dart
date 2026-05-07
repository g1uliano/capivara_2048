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
import '../widgets/outlined_text.dart';

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
          title: OutlinedText(
            text: 'Convidar Amigos',
            style: GoogleFonts.fredoka(fontSize: 22),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            if (profile == null) const AuthBanner(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎁', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    OutlinedText(
                      text: 'Convide amigos e ganhe recompensas!',
                      style: GoogleFonts.fredoka(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Você e seu amigo recebem 2 vidas + 1× Bomba 2\nquando ele completar a primeira partida.',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (profile == null)
                      Text(
                        'Faça login para convidar amigos.',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                      )
                    else
                      inviteState.when(
                        data: (link) => link == null
                            ? _GenerateButton(
                                onPressed: () => ref
                                    .read(inviteControllerProvider.notifier)
                                    .generateLink(),
                              )
                            : _LinkCard(link: link),
                        loading: () => const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        error: (e, _) => Text(
                          'Erro: $e',
                          style: GoogleFonts.nunito(color: Colors.redAccent),
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

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.link),
      label: Text(
        'Gerar Link de Convite',
        style: GoogleFonts.fredoka(fontSize: 17),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF7A00),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.link});
  final String link;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            link,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copiado!')),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.white),
                label: Text(
                  'Copiar',
                  style: GoogleFonts.nunito(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text: 'Jogue Olha o Bichim! comigo! $link',
                    subject: 'Convite para Olha o Bichim!',
                  ),
                ),
                icon: const Icon(Icons.share),
                label: Text('Compartilhar', style: GoogleFonts.nunito()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
