import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/shop_package.dart';
import 'package:capivara_2048/presentation/widgets/iap_confirmation_sheet.dart';

const _pkg = ShopPackage(
  id: 'p1',
  name: 'Pacote Teste',
  description: 'Desc',
  originalPrice: 9.99,
  currentPrice: 4.99,
  discountPercent: 50,
  contents: RewardBundle(lives: 3, bomb2: 1, bomb3: 0, undo1: 0, undo3: 0),
  giftContents: RewardBundle(lives: 1, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0),
);

Widget _wrap(ShopPackage pkg, {VoidCallback? onConfirm, VoidCallback? onCancel}) =>
    MaterialApp(
      home: Scaffold(
        body: IAPConfirmationSheet(
            package: pkg, onConfirm: onConfirm, onCancel: onCancel),
      ),
    );

void main() {
  testWidgets('exibe nome do pacote', (tester) async {
    await tester.pumpWidget(_wrap(_pkg));
    expect(find.textContaining('Pacote Teste'), findsOneWidget);
  });

  testWidgets('exibe conteúdo com emoji de vidas', (tester) async {
    await tester.pumpWidget(_wrap(_pkg));
    expect(find.textContaining('❤️'), findsWidgets);
    expect(find.textContaining('3'), findsWidgets);
  });

  testWidgets('exibe seção de presente quando giftContents não vazio', (tester) async {
    await tester.pumpWidget(_wrap(_pkg));
    expect(find.textContaining('Presente'), findsOneWidget);
  });

  testWidgets('botão Confirmar chama onConfirm', (tester) async {
    bool called = false;
    await tester.pumpWidget(_wrap(_pkg, onConfirm: () => called = true));
    await tester.tap(find.textContaining('Confirmar'));
    await tester.pump();
    expect(called, isTrue);
  });

  testWidgets('botão Cancelar chama onCancel', (tester) async {
    bool called = false;
    await tester.pumpWidget(_wrap(_pkg, onCancel: () => called = true));
    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    expect(called, isTrue);
  });
}
