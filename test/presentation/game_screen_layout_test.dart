import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pause button layout', () {
    testWidgets('pause button has minimum touch area 48x48', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              icon: const Icon(Icons.pause_rounded, color: Colors.white),
              iconSize: 32,
              onPressed: () {},
            ),
          ),
        ),
      );
      final button = tester.getSize(find.byType(IconButton));
      expect(button.width, greaterThanOrEqualTo(48));
      expect(button.height, greaterThanOrEqualTo(48));
    });
  });
}
