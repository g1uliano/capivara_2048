import 'package:capivara_2048/presentation/widgets/inventory_item_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('count > 0: tap chama onPressed, não onTapWhenEmpty', (tester) async {
    var pressedCalled = false;
    var emptyTapCalled = false;
    await tester.pumpWidget(_wrap(
      InventoryItemButton(
        label: 'Bomba 2',
        count: 2,
        icon: Icons.bolt,
        onPressed: () => pressedCalled = true,
        onTapWhenEmpty: () => emptyTapCalled = true,
      ),
    ));
    await tester.tap(find.byType(GestureDetector).first);
    expect(pressedCalled, isTrue);
    expect(emptyTapCalled, isFalse);
  });

  testWidgets('count == 0: tap chama onTapWhenEmpty', (tester) async {
    var called = false;
    await tester.pumpWidget(_wrap(
      InventoryItemButton(
        label: 'Bomba 2',
        count: 0,
        icon: Icons.bolt,
        onTapWhenEmpty: () => called = true,
      ),
    ));
    await tester.tap(find.byType(GestureDetector).first);
    expect(called, isTrue);
  });

  testWidgets('count == 0 e onTapWhenEmpty null → sem erro', (tester) async {
    await tester.pumpWidget(_wrap(
      const InventoryItemButton(
        label: 'Bomba 2',
        count: 0,
        icon: Icons.bolt,
      ),
    ));
    await tester.tap(find.byType(GestureDetector).first);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shouldPulse: true → widget anima (Animate presente)', (tester) async {
    await tester.pumpWidget(_wrap(
      InventoryItemButton(
        label: 'Bomba 2',
        count: 1,
        icon: Icons.bolt,
        shouldPulse: true,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(Animate), findsWidgets);
  });
}
