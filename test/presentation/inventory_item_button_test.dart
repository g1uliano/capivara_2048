import 'package:capivara_2048/presentation/widgets/inventory_item_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InventoryItemButton', () {
    testWidgets('renders Icon when pngPath is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InventoryItemButton(
              icon: Icons.dangerous,
              label: 'Bomba',
              count: 2,
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renders Image when pngPath is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InventoryItemButton(
              icon: Icons.dangerous,
              label: 'Bomba',
              count: 2,
              pngPath: 'assets/icons/inventory/bomb_2.png',
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('shows count badge when count > 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InventoryItemButton(
              icon: Icons.dangerous,
              label: 'Bomba',
              count: 3,
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('hides count badge when count is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InventoryItemButton(
              icon: Icons.dangerous,
              label: 'Bomba',
              count: 0,
            ),
          ),
        ),
      );

      expect(find.text('0'), findsNothing);
    });

    testWidgets('applies grayscale ColorFilter when count is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InventoryItemButton(
              icon: Icons.dangerous,
              label: 'Bomba',
              count: 0,
            ),
          ),
        ),
      );

      final colorFilteredFinder = find.byWidgetPredicate((w) {
        if (w is! ColorFiltered) return false;
        return w.colorFilter !=
            const ColorFilter.mode(Colors.transparent, BlendMode.dst);
      });
      expect(colorFilteredFinder, findsOneWidget);
    });
  });
}
