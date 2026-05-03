// test/presentation/widgets/shop_package_card_test.dart

import 'package:capivara_2048/data/models/shop_package.dart';
import 'package:capivara_2048/presentation/widgets/shop_package_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _testPackage = ShopPackage(
  id: 'test',
  name: 'Pacote Teste',
  description: 'Descrição teste',
  originalPrice: 9.99,
  currentPrice: 4.99,
  discountPercent: 50,
  contents: RewardBundle(lives: 0, bomb2: 0, bomb3: 4, undo1: 0, undo3: 0),
  giftContents: RewardBundle(lives: 0, bomb2: 0, bomb3: 2, undo1: 0, undo3: 0),
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('highlighted=false: no orange border', (tester) async {
    await tester.pumpWidget(_wrap(
      ShopPackageCard(
        package: _testPackage,
        onBuy: () {},
        highlighted: false,
      ),
    ));

    final card = tester.widget<Card>(find.byType(Card));
    final shape = card.shape as RoundedRectangleBorder;
    expect(shape.side, BorderSide.none);
  });

  testWidgets('highlighted=true: orange border present', (tester) async {
    await tester.pumpWidget(_wrap(
      ShopPackageCard(
        package: _testPackage,
        onBuy: () {},
        highlighted: true,
      ),
    ));

    final card = tester.widget<Card>(find.byType(Card));
    final shape = card.shape as RoundedRectangleBorder;
    expect(shape.side.color, const Color(0xFFFF8C42));
    expect(shape.side.width, 2.0);
  });

  testWidgets('tap Comprar calls onBuy', (tester) async {
    var called = false;
    await tester.pumpWidget(_wrap(
      ShopPackageCard(
        package: _testPackage,
        onBuy: () => called = true,
      ),
    ));

    await tester.tap(find.text('Comprar'));
    expect(called, isTrue);
  });
}
