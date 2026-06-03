import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/widgets/vhs_rewind_overlay.dart';

void main() {
  group('VhsRewindOverlay', () {
    testWidgets('renderiza sem crash — undo1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VhsRewindOverlay(
              isUndo3: false,
              onComplete: () {},
            ),
          ),
        ),
      );
      expect(find.byType(VhsRewindOverlay), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('renderiza sem crash — undo3', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VhsRewindOverlay(
              isUndo3: true,
              onComplete: () {},
            ),
          ),
        ),
      );
      expect(find.byType(VhsRewindOverlay), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 850));
    });

    testWidgets('onComplete é chamado ao terminar', (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VhsRewindOverlay(
              isUndo3: false,
              onComplete: () => completed = true,
            ),
          ),
        ),
      );
      // Undo1 = 500ms; avançar além disso
      await tester.pump(const Duration(milliseconds: 600));
      expect(completed, isTrue);
    });

    testWidgets('undo3 dura mais que undo1', (tester) async {
      // Undo1: completa em 500ms. Verificar que undo3 NÃO completa em 500ms.
      bool completed3 = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VhsRewindOverlay(
              isUndo3: true,
              onComplete: () => completed3 = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(completed3, isFalse);
      // Avançar além de 750ms — agora deve completar
      await tester.pump(const Duration(milliseconds: 300));
      expect(completed3, isTrue);
    });
  });
}
