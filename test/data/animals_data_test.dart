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
        assetPath: 'assets/images/animals/tile/Tanajura.svg',
        texturePattern: TexturePattern.dots,
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
        assetPath: 'assets/images/animals/tile/Tanajura.svg',
        texturePattern: TexturePattern.dots,
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

    test('all animals have assetPath pointing to .svg files', () {
      for (final animal in animals) {
        expect(
          animal.assetPath.endsWith('.svg'),
          isTrue,
          reason: '${animal.name} assetPath should end in .svg',
        );
      }
    });

    test('all animals have hostSvgPath set', () {
      for (final animal in animals) {
        expect(
          animal.hostSvgPath,
          isNotNull,
          reason: '${animal.name} hostSvgPath should not be null',
        );
      }
    });

    test('all animals have hostAspectRatio set to 1.0', () {
      for (final animal in animals) {
        expect(
          animal.hostAspectRatio,
          1.0,
          reason: '${animal.name} hostAspectRatio should be 1.0',
        );
      }
    });

    test('no animal is named Arara-azul', () {
      final names = animals.map((a) => a.name).toList();
      expect(names, isNot(contains('Arara-azul')));
    });
  });
}
