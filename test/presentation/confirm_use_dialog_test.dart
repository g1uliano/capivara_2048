import 'package:capivara_2048/presentation/widgets/confirm_use_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConfirmUseDialog', () {
    testWidgets('shows item name and description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                await showConfirmUseDialog(
                  context: context,
                  itemName: 'Bomba 2',
                  description: 'Remove os 2 tiles de menor valor.',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Usar Bomba 2?'), findsOneWidget);
      expect(find.text('Remove os 2 tiles de menor valor.'), findsOneWidget);
    });

    testWidgets('Confirmar returns true', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showConfirmUseDialog(
                  context: context,
                  itemName: 'Bomba 2',
                  description: 'Remove os 2 tiles de menor valor.',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('Cancelar returns false', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showConfirmUseDialog(
                  context: context,
                  itemName: 'Bomba 2',
                  description: 'Remove os 2 tiles de menor valor.',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });

  group('ConfirmUseDialog com pngPath', () {
    testWidgets('exibe Image.asset no título quando pngPath fornecido', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showConfirmUseDialog(
                context: ctx,
                itemName: 'Bomba 2',
                description: 'Remove tiles.',
                pngPath: 'assets/icons/inventory/bomb_2.png',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Usar Bomba 2?'), findsOneWidget);
    });

    testWidgets('sem Image quando pngPath é null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showConfirmUseDialog(
                context: ctx,
                itemName: 'Bomba 2',
                description: 'Remove tiles.',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);
      expect(find.text('Usar Bomba 2?'), findsOneWidget);
    });
  });
}
