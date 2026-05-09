import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/item_type.dart';
import 'package:capivara_2048/data/shop_data.dart';

void main() {
  group('kShopUnitPackages', () {
    test('tem exatamente 4 produtos unitários', () {
      expect(kShopUnitPackages.length, 4);
    });

    test('IDs são únicos e seguem convenção u_*', () {
      final ids = kShopUnitPackages.map((p) => p.id).toList();
      expect(ids, containsAll(['u_bomb3', 'u_undo3', 'u_bomb2', 'u_undo1']));
      expect(ids.toSet().length, 4);
    });

    test('cada produto tem exatamente 1 unidade do item correspondente', () {
      final bomb3 = kShopUnitPackages.firstWhere((p) => p.id == 'u_bomb3');
      expect(bomb3.contents.bomb3, 1);
      expect(bomb3.contents.bomb2, 0);
      expect(bomb3.contents.undo1, 0);
      expect(bomb3.contents.undo3, 0);
      expect(bomb3.contents.lives, 0);

      final undo1 = kShopUnitPackages.firstWhere((p) => p.id == 'u_undo1');
      expect(undo1.contents.undo1, 1);
    });

    test('giftContents são zeros para todos os unitários', () {
      for (final pkg in kShopUnitPackages) {
        expect(pkg.giftContents.bomb2, 0, reason: pkg.id);
        expect(pkg.giftContents.bomb3, 0, reason: pkg.id);
        expect(pkg.giftContents.undo1, 0, reason: pkg.id);
        expect(pkg.giftContents.undo3, 0, reason: pkg.id);
        expect(pkg.giftContents.lives, 0, reason: pkg.id);
      }
    });
  });

  group('kUnitPackageByType', () {
    test('mapeia todos os 4 ItemType', () {
      expect(kUnitPackageByType.keys, containsAll(ItemType.values));
    });

    test('bomb3 mapeia para pacote u_bomb3', () {
      expect(kUnitPackageByType[ItemType.bomb3]!.id, 'u_bomb3');
    });

    test('undo1 mapeia para pacote u_undo1', () {
      expect(kUnitPackageByType[ItemType.undo1]!.id, 'u_undo1');
    });
  });
}
