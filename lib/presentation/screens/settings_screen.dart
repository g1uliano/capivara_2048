import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/reduce_effects_provider.dart';
import '../controllers/settings_notifier.dart';
import '../widgets/game_background.dart';
import '../widgets/outlined_text.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version}+${info.buildNumber}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Configurações', style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _SettingsSection('Gameplay'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: Colors.white.withValues(alpha: 0.88),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Column(
                children: [
                  SwitchListTile(
                    tileColor: Colors.transparent,
                    title: Text('Vibração', style: GoogleFonts.nunito(fontSize: 16)),
                    value: settings.hapticEnabled,
                    onChanged: notifier.setHaptic,
                    activeThumbColor: AppColors.primary,
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final reduceEffects = ref.watch(reduceEffectsProvider);
                      return SwitchListTile(
                        tileColor: Colors.transparent,
                        title: Text('Reduzir Efeitos Visuais', style: GoogleFonts.nunito(fontSize: 16)),
                        value: reduceEffects,
                        onChanged: (_) => ref.read(reduceEffectsProvider.notifier).toggle(),
                        activeThumbColor: AppColors.primary,
                      );
                    },
                  ),
                ],
              ),
            ),
            _SettingsSection('Áudio'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: Colors.white.withValues(alpha: 0.88),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Column(
                children: [
                  ListTile(
                    tileColor: Colors.transparent,
                    title: Text(
                      'Disponível na Fase 5',
                      style: GoogleFonts.nunito(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ),
                  Opacity(
                    opacity: 0.4,
                    child: ListTile(
                      tileColor: Colors.transparent,
                      title: Text('Volume SFX', style: GoogleFonts.nunito(fontSize: 16)),
                      subtitle: Slider(value: 1.0, onChanged: null),
                    ),
                  ),
                  Opacity(
                    opacity: 0.4,
                    child: ListTile(
                      tileColor: Colors.transparent,
                      title: Text('Volume Música', style: GoogleFonts.nunito(fontSize: 16)),
                      subtitle: Slider(value: 1.0, onChanged: null),
                    ),
                  ),
                ],
              ),
            ),
            _SettingsSection('Sobre'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: Colors.white.withValues(alpha: 0.88),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Column(
                children: [
                  if (_version.isNotEmpty)
                    ListTile(
                      tileColor: Colors.transparent,
                      title: Text('Versão', style: GoogleFonts.nunito(fontSize: 16)),
                      trailing: Text(_version, style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey)),
                    ),
                  ListTile(
                    tileColor: Colors.transparent,
                    title: Text('Olha o Bichim! © Catraia Aplicativos',
                        style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: OutlinedText(
        text: title,
        style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
