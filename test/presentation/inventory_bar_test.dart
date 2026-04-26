import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/presentation/widgets/inventory_bar.dart';
import 'package:capivara_2048/presentation/widgets/inventory_item_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildSubject({Inventory? inventory}) {
  return ProviderScope(
    overrides: [
      if (inventory != null)
        inventoryProvider.overrideWith((ref) {
          final notifier =
              InventoryNotifier(ref.read(inventoryRepositoryProvider));
          notifier.state = inventory;
          return notifier;
        }),
    ],
    child: const MaterialApp(
      home: Scaffold(body: InventoryBar()),
    ),
  );
}

void main() {
  testWidgets('InventoryBar shows 4 InventoryItemButton widgets',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    expect(find.byType(InventoryItemButton), findsNWidgets(4));
  });

  testWidgets('bomb2 button is disabled when count is 0', (tester) async {
    await tester.pumpWidget(buildSubject(inventory: Inventory.empty()));
    final buttons = tester
        .widgetList<InventoryItemButton>(find.byType(InventoryItemButton))
        .toList();
    // bomb2 is the first button
    expect(buttons[0].onPressed, isNull);
  });

  testWidgets('bomb2 button is enabled when count > 0', (tester) async {
    await tester.pumpWidget(buildSubject(
      inventory: const Inventory(bomb2: 1, bomb3: 0, undo1: 0, undo3: 0),
    ));
    final buttons = tester
        .widgetList<InventoryItemButton>(find.byType(InventoryItemButton))
        .toList();
    expect(buttons[0].onPressed, isNotNull);
  });
}
