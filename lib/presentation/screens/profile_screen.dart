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
import '../../domain/auth/auth_service.dart';
import 'home_screen.dart';

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
              style: outlinedWhiteTextStyle(
                GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
              ),
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

class _LoggedIn extends ConsumerStatefulWidget {
  const _LoggedIn({required this.profile, required this.onSignOut});
  final PlayerProfile profile;
  final VoidCallback onSignOut;

  @override
  ConsumerState<_LoggedIn> createState() => _LoggedInState();
}

class _LoggedInState extends ConsumerState<_LoggedIn> {
  bool _deletingAccount = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final onSignOut = widget.onSignOut;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarWidget(radius: 40, profile: profile),
              if (profile.provider == AuthProvider.email)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AvatarPickerScreen(
                          onDone: (ctx) => Navigator.of(ctx).pop(),
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
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 14,
                      ),
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
              GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (profile.email != null) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              profile.email!,
              style: outlinedWhiteTextStyle(GoogleFonts.fredoka(fontSize: 14)),
            ),
          ),
        ],
        const SizedBox(height: 24),
        // Ações principais — card branco semi-transparente (mesmo padrão das settings)
        Card(
          margin: EdgeInsets.zero,
          color: Colors.white.withValues(alpha: 0.88),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_add, color: AppColors.primary),
                title: Text(
                  'Convidar Amigos',
                  style: GoogleFonts.nunito(fontSize: 16),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InviteFriendsScreen(),
                  ),
                ),
              ),
              if (profile.provider == AuthProvider.email) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.edit,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Editar nome',
                    style: GoogleFonts.nunito(fontSize: 16),
                  ),
                  onTap: () => _editName(context, profile),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.lock_reset,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Trocar senha',
                    style: GoogleFonts.nunito(fontSize: 16),
                  ),
                  onTap: () => _sendPasswordReset(context, profile),
                ),
              ],
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restore, color: AppColors.primary),
                title: Text(
                  'Restaurar compras',
                  style: GoogleFonts.nunito(fontSize: 16),
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
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Zona de perigo
        Card(
          margin: EdgeInsets.zero,
          color: Colors.white.withValues(alpha: 0.88),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  'Excluir conta',
                  style: GoogleFonts.nunito(fontSize: 16, color: Colors.red),
                ),
                onTap: _deletingAccount
                    ? null
                    : () => _confirmDeleteAccount(context, profile),
              ),
              const Divider(height: 1, color: Colors.red),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: Text(
                  'Sair',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: Colors.redAccent,
                  ),
                ),
                onTap: onSignOut,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editName(BuildContext context, PlayerProfile profile) async {
    final ctrl = TextEditingController(text: profile.displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Editar nome',
          style: GoogleFonts.fredoka(
            fontSize: 20,
            color: const Color(0xFF3E2723),
          ),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.length >= 2) Navigator.pop(ctx, v);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      await ref.read(authControllerProvider.notifier).updateDisplayName(result);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nome atualizado!')));
      }
    }
  }

  Future<void> _sendPasswordReset(
    BuildContext context,
    PlayerProfile profile,
  ) async {
    if (profile.email == null) return;
    try {
      await ref.read(authServiceProvider).sendPasswordReset(profile.email!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'E-mail de redefinição enviado para ${profile.email}',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao enviar e-mail. Tente novamente.'),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    PlayerProfile profile,
  ) async {
    // Dialog 1: general warning
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Excluir conta?',
          style: GoogleFonts.fredoka(
            fontSize: 20,
            color: const Color(0xFF3E2723),
          ),
        ),
        content: Text(
          'Todos os seus dados serão apagados permanentemente: '
          'progresso, inventário, histórico e ranking.',
          style: GoogleFonts.nunito(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Continuar →',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return;

    // Dialog 2: type EXCLUIR + password for email accounts
    String? senha;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDeleteDialog(
        isEmail: profile.provider == AuthProvider.email,
        onConfirm: (s) {
          senha = s;
          Navigator.pop(ctx, true);
        },
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    setState(() => _deletingAccount = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .deleteAccount(senha: senha);
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao excluir conta: $e')));
      }
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }
}

class _ConfirmDeleteDialog extends StatefulWidget {
  const _ConfirmDeleteDialog({
    required this.isEmail,
    required this.onConfirm,
    required this.onCancel,
  });
  final bool isEmail;
  final void Function(String? senha) onConfirm;
  final VoidCallback onCancel;

  @override
  State<_ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<_ConfirmDeleteDialog> {
  final _confirmCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _canDelete = false;
  bool _showSenha = false;

  @override
  void dispose() {
    _confirmCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Confirmar exclusão',
        style: GoogleFonts.fredoka(
          fontSize: 20,
          color: const Color(0xFF3E2723),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Digite EXCLUIR para confirmar:',
            style: GoogleFonts.nunito(fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmCtrl,
            decoration: const InputDecoration(labelText: 'EXCLUIR'),
            onChanged: (v) => setState(() => _canDelete = v == 'EXCLUIR'),
          ),
          if (widget.isEmail) ...[
            const SizedBox(height: 16),
            Text(
              'Confirme sua senha:',
              style: GoogleFonts.nunito(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _senhaCtrl,
              obscureText: !_showSenha,
              decoration: InputDecoration(
                labelText: 'Senha atual',
                suffixIcon: IconButton(
                  icon: Icon(
                    _showSenha ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _showSenha = !_showSenha),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _canDelete
              ? () => widget.onConfirm(widget.isEmail ? _senhaCtrl.text : null)
              : null,
          child: const Text(
            'Excluir conta',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
