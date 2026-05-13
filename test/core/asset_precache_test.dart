import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/core/asset_precache.dart';

void main() {
  group('criticalAssetPaths', () {
    final paths = criticalAssetPaths();

    test('inclui a splashscreen (deve aparecer imediatamente)', () {
      expect(paths, contains('assets/images/splash/splashscreen.png'));
    });

    test('inclui ambos os títulos do jogo (a logo carrega por último era bug)', () {
      expect(paths, contains('assets/images/title/title_brown.webp'));
      expect(paths, contains('assets/images/title/title_orange.webp'));
    });

    test('inclui o fundo da game screen', () {
      expect(paths, contains('assets/images/fundo.webp'));
    });

    test('inclui os 6 ícones da Home', () {
      expect(paths, containsAll([
        'assets/images/home/Colecao.webp',
        'assets/images/home/ComoJogar.webp',
        'assets/images/home/Configuracao.webp',
        'assets/images/home/IconeLoja.webp',
        'assets/images/home/Ranking.webp',
        'assets/images/home/Recompensas.webp',
      ]));
    });

    test('inclui os ícones do inventário', () {
      expect(paths, containsAll([
        'assets/images/inventory/bomb_2.webp',
        'assets/images/inventory/bomb_3.webp',
        'assets/images/inventory/undo_1.webp',
        'assets/images/inventory/undo_3.webp',
      ]));
    });

    test('splashscreen é o primeiro path da lista (deve ser decodificado primeiro)', () {
      expect(paths.first, 'assets/images/splash/splashscreen.png');
    });
  });
}
