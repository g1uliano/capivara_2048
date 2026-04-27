import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/widgets/game_background.dart';

void main() {
  group('GameBackground', () {
    testWidgets('renders fixed background color D4F1DE', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameBackground(animal: null, child: SizedBox()),
        ),
      );
      await tester.pump();

      final container = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(GameBackground),
          matching: find.byType(ColoredBox),
        ).first,
      );
      expect(container.color, const Color(0xFFD4F1DE));
    });

    testWidgets('renders same fixed color regardless of animal', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameBackground(animal: null, child: SizedBox()),
        ),
      );
      await tester.pump();
      final box1 = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(GameBackground),
          matching: find.byType(ColoredBox),
        ).first,
      );

      expect(box1.color, const Color(0xFFD4F1DE));
    });

    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameBackground(
            animal: null,
            child: Text('hello'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('hello'), findsOneWidget);
    });
  });
}
