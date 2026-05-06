import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/widgets/purchase_success_sheet.dart';

Widget _wrap({VoidCallback? onDismiss}) => MaterialApp(
      home: Scaffold(
        body: PurchaseSuccessSheet(
            shareCode: 'BOTO-1234-XK', onDismiss: onDismiss),
      ),
    );

void main() {
  testWidgets('exibe shareCode', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.text('BOTO-1234-XK'), findsOneWidget);
  });

  testWidgets('botão Copiar presente', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.textContaining('Copiar'), findsOneWidget);
  });

  testWidgets('botão Compartilhar presente', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.textContaining('Compartilhar'), findsOneWidget);
  });

  testWidgets('botão Continuar chama onDismiss', (tester) async {
    bool called = false;
    await tester.pumpWidget(_wrap(onDismiss: () => called = true));
    await tester.tap(find.textContaining('Continuar'));
    await tester.pump();
    expect(called, isTrue);
  });
}
