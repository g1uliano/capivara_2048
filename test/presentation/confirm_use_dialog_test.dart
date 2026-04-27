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
}
