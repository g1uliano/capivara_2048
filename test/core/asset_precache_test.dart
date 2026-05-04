import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/core/asset_precache.dart';

void main() {
  group('criticalAssetPaths', () {
    final paths = criticalAssetPaths();

    test('inclui a splashscreen (deve aparecer imediatamente)', () {
      expect(paths, contains('assets/images/splash/splashscreen.png'));
    });

    test('inclui ambos os títulos do jogo (a logo carrega por último era bug)', () {
      expect(paths, contains('assets/images/title/title_brown.png'));
      expect(paths, contains('assets/images/title/title_orange.png'));
    });

    test('inclui o fundo da game screen', () {
      expect(paths, contains('assets/images/fundo.png'));
    });

    test('inclui os 6 ícones da Home', () {
      expect(paths, containsAll([
        'assets/images/home/Colecao.png',
        'assets/images/home/ComoJogar.png',
        'assets/images/home/Configuracao.png',
        'assets/images/home/IconeLoja.png',
        'assets/images/home/Ranking.png',
        'assets/images/home/Recompensas.png',
      ]));
    });

    test('inclui os ícones do inventário', () {
      expect(paths, containsAll([
        'assets/images/inventory/bomb_2.png',
        'assets/images/inventory/bomb_3.png',
        'assets/images/inventory/undo_1.png',
        'assets/images/inventory/undo_3.png',
      ]));
    });

    test('splashscreen é o primeiro path da lista (deve ser decodificado primeiro)', () {
      expect(paths.first, 'assets/images/splash/splashscreen.png');
    });
  });
}
