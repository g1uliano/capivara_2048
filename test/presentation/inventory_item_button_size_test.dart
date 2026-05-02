import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/widgets/inventory_item_button.dart';
import 'package:capivara_2048/core/constants/game_constants.dart';

void main() {
  testWidgets('InventoryItemButton root SizedBox is 72dp', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InventoryItemButton(
            label: 'Bomba 2',
            icon: Icons.bolt,
            count: 1,
          ),
        ),
      ),
    );
    final sizedBoxes = tester.widgetList<SizedBox>(
      find.descendant(
        of: find.byType(InventoryItemButton),
        matching: find.byType(SizedBox),
      ),
    ).toList();
    // The root SizedBox (first one) should be 72dp
    expect(sizedBoxes.first.width, GameConstants.inventoryIconSize);
    expect(sizedBoxes.first.height, GameConstants.inventoryIconSize);
  });
}
