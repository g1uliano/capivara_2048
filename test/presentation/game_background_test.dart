import 'package:capivara_2048/presentation/widgets/game_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameBackground', () {
    testWidgets('renders DecoratedBox with DecorationImage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameBackground(
            animal: null,
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      );
      final decoratedBox = tester.widget<DecoratedBox>(
        find.byType(DecoratedBox).first,
      );
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.image, isNotNull);
      expect(decoration.image!.fit, BoxFit.cover);
    });

    testWidgets('decoration includes fallback color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameBackground(
            animal: null,
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      );
      final decoratedBox = tester.widget<DecoratedBox>(
        find.byType(DecoratedBox).first,
      );
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFD4F1DE));
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GameBackground(
            animal: null,
            child: Text('hello'),
          ),
        ),
      );
      expect(find.text('hello'), findsOneWidget);
    });
  });
}
