import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/core/theme/text_styles.dart';
import 'package:capivara_2048/presentation/widgets/outlined_text.dart';

void main() {
  group('outlinedWhiteTextStyle', () {
    test('returns TextStyle with white color', () {
      const base = TextStyle(fontSize: 16);
      final result = outlinedWhiteTextStyle(base);
      expect(result.color, Colors.white);
    });

    test('applies 4 shadows for outline effect', () {
      const base = TextStyle(fontSize: 16);
      final result = outlinedWhiteTextStyle(base);
      expect(result.shadows, isNotNull);
      expect(result.shadows!.length, 4);
    });

    test('all shadows are black', () {
      const base = TextStyle(fontSize: 16);
      final result = outlinedWhiteTextStyle(base);
      for (final shadow in result.shadows!) {
        expect(shadow.color, Colors.black);
      }
    });
  });

  group('OutlinedText widget', () {
    testWidgets('renders text content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OutlinedText(
              text: 'Tucano',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
      expect(find.text('Tucano'), findsWidgets); // two Text widgets in the Stack
    });

    testWidgets('renders with colored base style without asserting', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OutlinedText(
              text: 'Test',
              style: TextStyle(fontSize: 16, color: Colors.amber),
            ),
          ),
        ),
      );
      expect(find.text('Test'), findsWidgets);
    });
  });
}
