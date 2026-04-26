import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/animals_data.dart';

void main() {
  group('GameBackground colors', () {
    testWidgets('Boto background is pink, not beige', (tester) async {
      final boto = animalForLevel(8);
      expect(boto.backgroundBaseColor, const Color(0xFFFBD0DD));
    });

    testWidgets('Tucano background is yellow pastel', (tester) async {
      final tucano = animalForLevel(4);
      expect(tucano.backgroundBaseColor, const Color(0xFFFFE9A8));
    });

    testWidgets('Capivara background differs from Tucano and Onca', (tester) async {
      final capivara = animalForLevel(11);
      final tucano = animalForLevel(4);
      final onca = animalForLevel(9);
      expect(capivara.backgroundBaseColor, isNot(equals(tucano.backgroundBaseColor)));
      expect(capivara.backgroundBaseColor, isNot(equals(onca.backgroundBaseColor)));
    });
  });
}
