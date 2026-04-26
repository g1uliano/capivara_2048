import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/animals_data.dart';
import 'package:capivara_2048/presentation/widgets/game_background.dart';

void main() {
  group('GameBackground colors', () {
    test('Boto background is pink, not beige', () {
      final boto = animalForLevel(8);
      expect(boto.backgroundBaseColor, const Color(0xFFFBD0DD));
    });

    test('Tucano background is yellow pastel', () {
      final tucano = animalForLevel(4);
      expect(tucano.backgroundBaseColor, const Color(0xFFFFE9A8));
    });

    test('Capivara background differs from Tucano and Onca', () {
      final capivara = animalForLevel(11);
      final tucano = animalForLevel(4);
      final onca = animalForLevel(9);
      expect(capivara.backgroundBaseColor, isNot(equals(tucano.backgroundBaseColor)));
      expect(capivara.backgroundBaseColor, isNot(equals(onca.backgroundBaseColor)));
    });
  });

  group('GameBackground widget', () {
    testWidgets('renders background color for animal', (tester) async {
      final boto = animalForLevel(8);
      await tester.pumpWidget(
        MaterialApp(
          home: Stack(
            children: [
              GameBackground(animal: boto, child: const SizedBox()),
            ],
          ),
        ),
      );
      await tester.pump(); // let TweenAnimationBuilder settle
      expect(find.byType(GameBackground), findsOneWidget);
    });
  });
}
