import 'dart:io';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/item_type.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/data/repositories/lives_repository.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/presentation/widgets/shop_overlay.dart';
import 'package:capivara_2048/presentation/widgets/shop_package_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

late Directory _tempDir;

Future<void> _initHive() async {
  _tempDir = await Directory.systemTemp.createTemp('shop_overlay_test');
  Hive.init(_tempDir.path);
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LivesStateAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
}

Future<void> _teardownHive() async {
  await Hive.close();
  await _tempDir.delete(recursive: true);
}

Widget _buildOverlay({
  ItemType itemType = ItemType.bomb3,
  VoidCallback? onClose,
  void Function(ItemType)? onItemPurchased,
}) {
  return ProviderScope(
    overrides: [
      inventoryRepositoryProvider.overrideWithValue(InventoryRepository()),
      livesRepositoryProvider.overrideWithValue(LivesRepository()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: ShopOverlay(
          itemType: itemType,
          onClose: onClose ?? () {},
          onItemPurchased: onItemPurchased ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  setUp(() async { await _initHive(); });
  tearDown(_teardownHive);

  testWidgets('exibe 6 ShopPackageCard', (tester) async {
    await tester.pumpWidget(_buildOverlay());
    await tester.pumpAndSettle();
    expect(find.byType(ShopPackageCard), findsNWidgets(6));
  });

  testWidgets('bomb3: pacotes p1 e p6 têm highlighted:true', (tester) async {
    await tester.pumpWidget(_buildOverlay(itemType: ItemType.bomb3));
    await tester.pumpAndSettle();
    final cards = tester.widgetList<ShopPackageCard>(find.byType(ShopPackageCard)).toList();
    final highlightedIds = cards.where((c) => c.highlighted).map((c) => c.package.id).toSet();
    expect(highlightedIds, {'p1', 'p6'});
  });

  testWidgets('botão X chama onClose', (tester) async {
    var closed = false;
    await tester.pumpWidget(_buildOverlay(onClose: () => closed = true));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    expect(closed, isTrue);
  });

  testWidgets('fundo tem AbsorbPointer', (tester) async {
    await tester.pumpWidget(_buildOverlay());
    await tester.pumpAndSettle();
    expect(find.byType(AbsorbPointer), findsWidgets);
  });

  testWidgets('overlay permanece aberto após compra', (tester) async {
    await tester.pumpWidget(_buildOverlay());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Comprar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(find.byType(ShopOverlay), findsOneWidget);
  });

  testWidgets('compra chama onItemPurchased', (tester) async {
    ItemType? purchased;
    await tester.pumpWidget(_buildOverlay(
      itemType: ItemType.bomb3,
      onItemPurchased: (t) => purchased = t,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Comprar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(purchased, isNotNull);
  });
}
