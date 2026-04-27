import 'package:capivara_2048/data/animals_data.dart';
import 'package:capivara_2048/data/models/animal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Animal model', () {
    test('supports scientificName and funFact nullable fields', () {
      const a = Animal(
        level: 1, value: 2, name: 'Test',
        borderColor: Color(0xFF000000),
        backgroundBaseColor: Color(0xFFFFFFFF),
        tilePngPath: 'assets/images/animals/tile/Tanajura.png',
        hostPngPath: 'assets/images/animals/host/Tanajura.png',
        scientificName: 'Atta sexdens',
        funFact: 'Some fact.',
      );
      expect(a.scientificName, 'Atta sexdens');
      expect(a.funFact, 'Some fact.');
    });

    test('scientificName and funFact default to null', () {
      const a = Animal(
        level: 1, value: 2, name: 'Test',
        borderColor: Color(0xFF000000),
        backgroundBaseColor: Color(0xFFFFFFFF),
        tilePngPath: 'assets/images/animals/tile/Tanajura.png',
        hostPngPath: 'assets/images/animals/host/Tanajura.png',
      );
      expect(a.scientificName, isNull);
      expect(a.funFact, isNull);
    });
  });

  group('animals list', () {
    test('has exactly 11 animals', () {
      expect(animals.length, 11);
    });

    test('level 5 is Sagui, not Arara-azul', () {
      final level5 = animals.firstWhere((a) => a.level == 5);
      expect(level5.name, 'Sagui');
      expect(level5.scientificName, 'Callithrix penicillata');
      expect(level5.borderColor.value, const Color(0xFFA0826D).value);
      expect(level5.backgroundBaseColor.value, const Color(0xFFE0D2C5).value);
    });

    test('level 5 Sagui has fun fact', () {
      final level5 = animals.firstWhere((a) => a.level == 5);
      expect(level5.funFact, isNotNull);
      expect(level5.funFact!.isNotEmpty, isTrue);
    });

    test('all animals have tilePngPath pointing to .png files', () {
      for (final animal in animals) {
        expect(
          animal.tilePngPath.endsWith('.png'),
          isTrue,
          reason: '${animal.name} tilePngPath should end in .png',
        );
      }
    });

    test('all animals have hostPngPath set', () {
      for (final animal in animals) {
        expect(
          animal.hostPngPath,
          isNotNull,
          reason: '${animal.name} hostPngPath should not be null',
        );
      }
    });

    test('no animal has hostSvgPath or assetPath field (old API gone)', () {
      for (final animal in animals) {
        expect(animal.tilePngPath, isNotEmpty);
      }
    });

    test('no animal is named Arara-azul', () {
      final names = animals.map((a) => a.name).toList();
      expect(names, isNot(contains('Arara-azul')));
    });
  });
}
