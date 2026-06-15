import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/item_type.dart';
import 'package:capivara_2048/presentation/widgets/game_over_no_items_overlay.dart';

void main() {
  group('offerableItems', () {
    test('sem histórico de jogadas: oferece apenas bombas', () {
      expect(offerableItems(0), [ItemType.bomb2, ItemType.bomb3]);
    });

    test('1 jogada: inclui Desfazer 1, exclui Desfazer 3', () {
      final items = offerableItems(1);
      expect(items.contains(ItemType.undo1), true);
      expect(items.contains(ItemType.undo3), false);
    });

    test('2 jogadas: inclui Desfazer 1, ainda exclui Desfazer 3', () {
      final items = offerableItems(2);
      expect(items.contains(ItemType.undo1), true);
      expect(items.contains(ItemType.undo3), false);
    });

    test('3+ jogadas: inclui Desfazer 1 e Desfazer 3', () {
      final items = offerableItems(3);
      expect(items.contains(ItemType.undo1), true);
      expect(items.contains(ItemType.undo3), true);
    });

    test('nunca retorna lista vazia', () {
      expect(offerableItems(0), isNotEmpty);
    });
  });
}
