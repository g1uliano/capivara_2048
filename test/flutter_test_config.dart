// test/flutter_test_config.dart
import 'dart:async';
import 'dart:io';
import 'package:alchemist/alchemist.dart';
import 'package:google_fonts/google_fonts.dart';
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
/// Os hashes vêm de google_fonts-8.1.0/lib/src/google_fonts_parts/*.dart.
Future<void> _seedFontCache(Directory cacheDir) async {
  // Caminho base dos TTFs do Roboto (gerados pelo alchemist no build).
  final roboto = Directory(
    'build/unit_test_assets/packages/alchemist/assets/fonts/Roboto',
  );
  if (!roboto.existsSync()) return; // build ainda não rodou; skip seguro

  final Map<String, String> mappings = {
    // Fredoka — hashes de google_fonts-8.1.0
    'Fredoka_regular_2a5db7832feb3b8261603fc01e4411601c9b08d4107d3ddacc6b1a1b24a98078':
        '${roboto.path}/Roboto-Regular.ttf',
    'Fredoka_500_f33d2fcedde5d0920682170e6088df9501bab260f84d94213b0e0388d5586fa6':
        '${roboto.path}/Roboto-Medium.ttf',
    'Fredoka_600_241f09c2822f1cde8677dc18da3fc2b9f35e87926f3fe4fd687538098f5d55fa':
        '${roboto.path}/Roboto-Medium.ttf',
    'Fredoka_700_fb87f9cd22fc2af57c25c381f17d470f7d7ab40e19f51975b6c5b069051718d3':
        '${roboto.path}/Roboto-Bold.ttf',
    // Nunito — hashes de google_fonts-8.1.0
    'Nunito_regular_33383e64e1f3603142b718d1854778a9c9c5e2744b5aafdac2b66fedde54a98d':
        '${roboto.path}/Roboto-Regular.ttf',
    'Nunito_italic_3ea474b0be3d68d751c274c95dbfe0d7215091f388aec3e41fea8ce02e64bcc7':
        '${roboto.path}/Roboto-Regular.ttf',
    'Nunito_500_578b7f3f76615d258788124d9299d5fcef1711101cee45c494cc985a9d736c4e':
        '${roboto.path}/Roboto-Medium.ttf',
    'Nunito_600_da0d941aa9dda69a63c9d611ba4dbdb490ea43a61edc611f0e66cdbfc2ac0a18':
        '${roboto.path}/Roboto-Medium.ttf',
    'Nunito_700_c4ee3c72ba7b147e5386f71fe18f7c076016c947b8956a7affcd338101f9ddcd':
        '${roboto.path}/Roboto-Bold.ttf',
    'Nunito_800_89122aad8fac58cb57e90b1560e0de7bcf458341752f4f1bf7e6c27578e22b1e':
        '${roboto.path}/Roboto-Black.ttf',
    'Nunito_900_8d18d333bff5d00f5094d887290556281a163ca2375d920df2527c7dc2e00e3b':
        '${roboto.path}/Roboto-Black.ttf',
    'Nunito_200_a699f7f28981eea3c9beb5b01129f0d5a745c613376350ea01d599fc3aeab432':
        '${roboto.path}/Roboto-Light.ttf',
    'Nunito_300_689cc9cc60675d7d9efa0b4fd7492045c8bac6bb73569a4dbbd5ef2ebabdc309':
        '${roboto.path}/Roboto-Light.ttf',
    'Nunito_600italic_72106e753bb7e88c2b99e5cff9bda977be76d25cf5395a1e61fd24b83f17f981':
        '${roboto.path}/Roboto-Medium.ttf',
    'Nunito_700italic_371e6cfbed5ed0e3f6b8bb8843de51378e72b8b7237c0e609282cde18dd509e4':
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
  // Prevent google_fonts from making HTTP requests during tests.
  // Without this, tests fail with "Failed to load font" network errors.
  GoogleFonts.config.allowRuntimeFetching = false;

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
