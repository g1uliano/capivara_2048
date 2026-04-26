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
}
