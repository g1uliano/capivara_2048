import 'package:flutter/widgets.dart';
import '../data/animals_data.dart';

/// Lista ordenada de assets críticos para precache no startup.
///
/// **Ordem importa:** o primeiro item é decodificado primeiro (splashscreen),
/// para aparecer imediatamente. Os demais são carregados em paralelo.
///
/// Assets aqui devem estar prontos antes da Home ser mostrada para evitar
/// o efeito de "ícones aparecendo um por um" em emuladores lentos.
List<String> criticalAssetPaths() {
  return <String>[
    // 1) Splashscreen — DEVE ser o primeiro (aparece antes de tudo)
    'assets/images/splash/splashscreen.png',

    // 2) Logo do jogo (uma das duas é sorteada na Home)
    'assets/images/title/title_brown.png',
    'assets/images/title/title_orange.png',

    // 3) Fundo da tela de jogo
    'assets/images/fundo.png',

    // 4) Ícones da Home
    'assets/images/home/Colecao.png',
    'assets/images/home/ComoJogar.png',
    'assets/images/home/Configuracao.png',
    'assets/images/home/IconeLoja.png',
    'assets/images/home/Ranking.png',
    'assets/images/home/Recompensas.png',

    // 5) Ícones do inventário
    'assets/images/inventory/bomb_2.png',
    'assets/images/inventory/bomb_3.png',
    'assets/images/inventory/undo_1.png',
    'assets/images/inventory/undo_3.png',

    // 6) Tiles e hosts dos animais (aparecem no jogo)
    for (final animal in animals) animal.tilePngPath,
    for (final animal in animals) animal.hostPngPath,
  ];
}

/// Precache os assets críticos. Splashscreen é decodificada primeiro
/// (aguardada antes dos demais) para aparecer imediatamente; o resto carrega
/// em paralelo. Retorna quando tudo terminou de decodificar.
///
/// Use com timeout pelo chamador para evitar bloqueio infinito caso um asset
/// falhe (ex: `await precacheCriticalAssets(ctx).timeout(Duration(seconds: 4))`).
Future<void> precacheCriticalAssets(BuildContext context) async {
  final paths = criticalAssetPaths();
  if (paths.isEmpty) return;

  // Splashscreen primeiro — bloqueia até decodificar
  await precacheImage(AssetImage(paths.first), context);

  // Demais em paralelo
  if (!context.mounted) return;
  final rest = paths.skip(1).map((p) {
    // Para tiles/hosts dos animais usa ResizeImage para economizar memória.
    if (p.contains('/animals/tile/')) {
      return precacheImage(
        ResizeImage(AssetImage(p), width: 144, height: 144),
        context,
      );
    }
    if (p.contains('/animals/host/')) {
      return precacheImage(
        ResizeImage(AssetImage(p), width: 304, height: 304),
        context,
      );
    }
    return precacheImage(AssetImage(p), context);
  });
  await Future.wait(rest);
}
