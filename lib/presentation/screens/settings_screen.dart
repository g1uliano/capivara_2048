import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/performance/performance_settings.dart';
import '../controllers/performance_settings_notifier.dart';
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
    final perf = ref.watch(performanceSettingsProvider);

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
                ],
              ),
            ),
            _SettingsSection('Performance'),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: Colors.white.withValues(alpha: 0.88),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    tileColor: Colors.transparent,
                    title: Text('Modo de Performance', style: GoogleFonts.nunito(fontSize: 16)),
                    value: perf.enabled,
                    onChanged: (v) => v
                        ? ref.read(performanceSettingsProvider.notifier).enable()
                        : ref.read(performanceSettingsProvider.notifier).disable(),
                    activeThumbColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    tileColor: Colors.transparent,
                    title: Text('Detecção automática', style: GoogleFonts.nunito(fontSize: 16)),
                    subtitle: Text(
                      'Sugere ativar quando o jogo tiver lentidão',
                      style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey),
                    ),
                    value: perf.autoDetectEnabled,
                    onChanged: (v) => ref.read(performanceSettingsProvider.notifier).setAutoDetect(v),
                    activeThumbColor: AppColors.primary,
                  ),
                  Opacity(
                    opacity: perf.enabled ? 1.0 : 0.4,
                    child: IgnorePointer(
                      ignoring: !perf.enabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Text(
                              'Qualidade dos tiles',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: SegmentedButton<TileQuality>(
                              segments: const [
                                ButtonSegment(
                                  value: TileQuality.full,
                                  label: Text('Completo'),
                                ),
                                ButtonSegment(
                                  value: TileQuality.fullOpacity,
                                  label: Text('Sem opacidade'),
                                ),
                                ButtonSegment(
                                  value: TileQuality.simple,
                                  label: Text('Simples'),
                                ),
                              ],
                              selected: {perf.tileQuality},
                              onSelectionChanged: (s) => ref.read(performanceSettingsProvider.notifier).setTileQuality(s.first),
                              style: ButtonStyle(
                                textStyle: WidgetStateProperty.all(
                                  GoogleFonts.nunito(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                          SwitchListTile(
                            tileColor: Colors.transparent,
                            title: Text('Efeitos de blur', style: GoogleFonts.nunito(fontSize: 16)),
                            value: perf.blurEffectsEnabled,
                            onChanged: (v) => ref.read(performanceSettingsProvider.notifier).setBlurEffects(v),
                            activeThumbColor: AppColors.primary,
                          ),
                          SwitchListTile(
                            tileColor: Colors.transparent,
                            title: Text('Animações', style: GoogleFonts.nunito(fontSize: 16)),
                            value: perf.animationsEnabled,
                            onChanged: (v) => ref.read(performanceSettingsProvider.notifier).setAnimations(v),
                            activeThumbColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
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
                  SwitchListTile(
                    tileColor: Colors.transparent,
                    title: Text('Efeitos sonoros', style: GoogleFonts.nunito(fontSize: 16)),
                    value: settings.sfxEnabled,
                    onChanged: notifier.setSfxEnabled,
                    activeThumbColor: AppColors.primary,
                  ),
                  if (settings.sfxEnabled)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.volume_up, size: 18),
                          Expanded(
                            child: Slider(
                              value: settings.sfxVolume,
                              onChanged: notifier.setSfxVolume,
                              activeColor: AppColors.primary,
                            ),
                          ),
                        ],
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
