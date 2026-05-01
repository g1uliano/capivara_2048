import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/settings_notifier.dart';
import '../widgets/game_background.dart';

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
            _SettingsSection('Geral'),
            SwitchListTile(
              title: Text('Vibração', style: GoogleFonts.nunito(fontSize: 16)),
              value: settings.hapticEnabled,
              onChanged: notifier.setHaptic,
              activeColor: AppColors.primary,
            ),
            ListTile(
              title: Text('Idioma', style: GoogleFonts.nunito(fontSize: 16)),
              trailing: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'pt', label: Text('PT-BR')),
                  ButtonSegment(value: 'en', label: Text('EN')),
                ],
                selected: {settings.locale},
                onSelectionChanged: (s) => notifier.setLocale(s.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected) ? AppColors.primary : null),
                ),
              ),
            ),
            const Divider(),
            _SettingsSection('Áudio'),
            ListTile(
              title: Text(
                'Disponível na Fase 5',
                style: GoogleFonts.nunito(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
            Opacity(
              opacity: 0.4,
              child: ListTile(
                title: Text('Volume SFX', style: GoogleFonts.nunito(fontSize: 16)),
                subtitle: Slider(value: 1.0, onChanged: null),
              ),
            ),
            Opacity(
              opacity: 0.4,
              child: ListTile(
                title: Text('Volume Música', style: GoogleFonts.nunito(fontSize: 16)),
                subtitle: Slider(value: 1.0, onChanged: null),
              ),
            ),
            const Divider(),
            _SettingsSection('Sobre'),
            if (_version.isNotEmpty)
              ListTile(
                title: Text('Versão', style: GoogleFonts.nunito(fontSize: 16)),
                trailing: Text(_version, style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey)),
              ),
            ListTile(
              title: Text('Olha o Bichim! © Catraia Aplicativos',
                  style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey)),
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
      child: Text(
        title,
        style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
