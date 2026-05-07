import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../controllers/auth_controller.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/game_background.dart';

/// Tela de seleção de avatar com tiles do jogo.
///
/// [onDone] é chamado após salvar ou pular — permite ao chamador
/// decidir a navegação (ex: ir para HomeScreen ou voltar).
class AvatarPickerScreen extends ConsumerStatefulWidget {
  const AvatarPickerScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends ConsumerState<AvatarPickerScreen> {
  String? _selected;
  bool _saving = false;

  Future<void> _confirm() async {
    if (_selected == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateAvatar('tile:$_selected');
      if (mounted) widget.onDone();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar avatar: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _skip() => widget.onDone();

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Escolha seu avatar',
            style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'Qual animal vai te representar?',
                style: outlinedWhiteTextStyle(
                  GoogleFonts.fredoka(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: kAvatarAnimals.length,
                  itemBuilder: (context, index) {
                    final animal = kAvatarAnimals[index];
                    final isSelected = _selected == animal;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = animal),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ]
                              : [],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            kAnimalTileAssets[animal]!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: (_selected != null && !_saving)
                          ? _confirm
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Confirmar',
                              style: GoogleFonts.fredoka(fontSize: 18),
                            ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _saving ? null : _skip,
                      child: Text(
                        'Pular por agora',
                        style: outlinedWhiteTextStyle(
                          GoogleFonts.fredoka(
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
