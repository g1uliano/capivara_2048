// test/flutter_test_config.dart
import 'dart:async';
import 'dart:io';
import 'package:alchemist/alchemist.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// ---------------------------------------------------------------------------
// Fake PathProvider
// ---------------------------------------------------------------------------

/// Aponta getApplicationSupportPath para [_dir], onde pré-populamos os
/// arquivos de fonte que o google_fonts espera encontrar no cache do
/// dispositivo. Isso evita que o google_fonts tente fazer download de fontes
/// durante os testes, eliminando exceções de rede.
class _FontCachePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FontCachePathProvider(this._dir);
  final String _dir;

  @override
  Future<String?> getApplicationSupportPath() async => _dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => _dir;

  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

// ---------------------------------------------------------------------------
// Font-cache bootstrap
// ---------------------------------------------------------------------------

/// google_fonts espera encontrar o arquivo em:
///   {applicationSupportDir}/{familyVariant}_{fileHash}.ttf
///
/// Com obscureText:true o alchemist substitui texto por blocos Ahem, portanto
/// qualquer TTF válido serve como placeholder (usamos Roboto do alchemist).
///
/// Fontes usadas pelo app:
///   • Fredoka regular (w400), semibold (w600), bold (w700)
///   • Nunito  regular (w400), italic (w400i), semibold (w600), bold (w700)
///
/// Os hashes vêm de google_fonts-6.2.1/lib/src/google_fonts_parts/*.dart.
Future<void> _seedFontCache(Directory cacheDir) async {
  // Caminho base dos TTFs do Roboto (gerados pelo alchemist no build).
  final roboto = Directory(
    'build/unit_test_assets/packages/alchemist/assets/fonts/Roboto',
  );
  if (!roboto.existsSync()) return; // build ainda não rodou; skip seguro

  final Map<String, String> mappings = {
    'Fredoka_regular_125cc34039587d0926961da82659002e686518af02c0771f7224c40a63f2c144':
        '${roboto.path}/Roboto-Regular.ttf',
    'Fredoka_600_70d1c0745883e965e3ae80c61a32ee2e547f444e0804649d673a700989447a29':
        '${roboto.path}/Roboto-Medium.ttf',
    'Fredoka_700_e646f1ecd8e27d6468396ddecc96774207d41706edee7fd82d1a1385ba98d29f':
        '${roboto.path}/Roboto-Bold.ttf',
    'Nunito_regular_6f96017e762896b4cf3c2db345d41d7a72a3720a95698c3cd47020bf433db435':
        '${roboto.path}/Roboto-Regular.ttf',
    'Nunito_italic_df3c491d67e881e1b0c6265a7a8364f07e38d7a25893e9b2beac1439e1c2efd9':
        '${roboto.path}/Roboto-Regular.ttf',
    'Nunito_600_f165190d31319dc6384c83fdd014ed983630541b21d005b5caadf1d74fbd513d':
        '${roboto.path}/Roboto-Medium.ttf',
    'Nunito_700_8148a236e4127dad38346ce596c544389aa2fdaaa9f311e589741de30d25ddb8':
        '${roboto.path}/Roboto-Bold.ttf',
  };

  for (final entry in mappings.entries) {
    final src = File(entry.value);
    if (!src.existsSync()) continue;
    final dest = File('${cacheDir.path}/${entry.key}.ttf');
    await dest.writeAsBytes(await src.readAsBytes());
  }
}

// ---------------------------------------------------------------------------
// testExecutable — ponto de entrada do flutter_test_config
// ---------------------------------------------------------------------------

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Cria dir temporário e popula com fontes placeholder.
  final cacheDir = await Directory.systemTemp.createTemp('gf_font_cache_');
  await _seedFontCache(cacheDir);

  // Redireciona path_provider para o cache dir acima. O google_fonts
  // encontrará os arquivos .ttf antes de tentar download HTTP.
  PathProviderPlatform.instance = _FontCachePathProvider(cacheDir.path);

  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      // Apenas CI goldens: texto vira blocos coloridos (Ahem font) — output
      // idêntico em qualquer plataforma/CI. Platform goldens desabilitados.
      ciGoldensConfig: CiGoldensConfig(
        enabled: true,
        obscureText: true,
        renderShadows: false,
      ),
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
    ),
    run: testMain,
  );
}
