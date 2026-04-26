import 'package:capivara_2048/presentation/widgets/outlined_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('OutlinedText renders a single Text widget with white color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OutlinedText(text: 'Hello'),
        ),
      ),
    );

    final textFinders = find.byType(Text);
    expect(textFinders, findsOneWidget);

    final textWidget = tester.widget<Text>(textFinders);
    expect(textWidget.style?.color, Colors.white);
  });

  testWidgets('OutlinedText has no Stack widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OutlinedText(text: 'Hello'),
        ),
      ),
    );

    final stackInsideOutlinedText = find.descendant(
      of: find.byType(OutlinedText),
      matching: find.byType(Stack),
    );
    expect(stackInsideOutlinedText, findsNothing);
  });
}
