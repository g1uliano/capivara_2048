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
      // Image.asset is rendered; Icon should not appear
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('shows exact count badge when count <= 99', (tester) async {
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
      expect(find.text('99+'), findsNothing);
    });

    testWidgets('shows 99+ badge when count > 99', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InventoryItemButton(
              icon: Icons.dangerous,
              label: 'Bomba',
              count: 150,
            ),
          ),
        ),
      );
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('150'), findsNothing);
    });

    testWidgets('hides badge when count is 0', (tester) async {
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

    testWidgets('long press shows tooltip with exact count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InventoryItemButton(
              icon: Icons.dangerous,
              label: 'Bomba',
              count: 150,
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(tester.getCenter(find.byType(InventoryItemButton)));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('150 Bomba'), findsOneWidget);
    });
  });
}
