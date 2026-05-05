import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/widgets/shop_overlay.dart';
import '../_harness/test_harness.dart';
import '../_harness/tester_extensions.dart';
import '../_harness/scenario.dart';

Future<void> _bootToGame(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
  await tester.gotoGame(harness);
}

// ─── flow.shop_overlay_from_empty_inventory ───────────────────────────────────

final shopOverlayFromEmptyInventoryScenario = E2EScenario(
  id: 'flow.shop_overlay_from_empty_inventory',
  title: 'tap em item vazio na GameScreen → ShopOverlay abre',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Ensure inventory is empty so onTapWhenEmpty fires.
    harness.container
        .read(inventoryProvider.notifier)
        .debugSetState(Inventory.empty());
    await tester.pump();

    // Tap bomb2 (empty) → _openShop(ItemType.bomb2) → ShopOverlay rendered.
    await tester.tap(find.byKey(const Key('inventory_bomb2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ShopOverlay), findsOneWidget);
    expect(find.text('Loja'), findsOneWidget);
  },
);

// ─── flow.shop_purchase_item ──────────────────────────────────────────────────

final shopPurchaseItemScenario = E2EScenario(
  id: 'flow.shop_purchase_item',
  title: 'ShopOverlay: tap "Comprar" → confirmar → inventário incrementa',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Empty inventory → onTapWhenEmpty fires for bomb2.
    harness.container
        .read(inventoryProvider.notifier)
        .debugSetState(Inventory.empty());
    await tester.pump();

    // Open ShopOverlay.
    await tester.tap(find.byKey(const Key('inventory_bomb2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ShopOverlay), findsOneWidget);

    final inventoryBefore = harness.container.read(inventoryProvider);

    // ShopPackageCard renders ElevatedButton with text 'Comprar'.
    // SingleChildScrollView renders all cards regardless of viewport.
    final buyButtons = find.text('Comprar');
    expect(buyButtons, findsWidgets,
        reason: 'ShopOverlay deve exibir pelo menos um botão "Comprar"');
    await tester.tap(buyButtons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // AlertDialog de confirmação.
    expect(find.text('Confirmar compra'), findsOneWidget);
    await tester.tap(find.text('Confirmar'));
    await tester.pump();

    // State is updated synchronously by add() — verify before any pumping.
    final inventoryAfter = harness.container.read(inventoryProvider);
    final totalBefore = inventoryBefore.bomb2 +
        inventoryBefore.bomb3 +
        inventoryBefore.undo1 +
        inventoryBefore.undo3;
    final totalAfter = inventoryAfter.bomb2 +
        inventoryAfter.bomb3 +
        inventoryAfter.undo1 +
        inventoryAfter.undo3;
    expect(totalAfter, greaterThan(totalBefore),
        reason: 'compra deve incrementar pelo menos um item no inventário');

    // Remove PauseOverlay (BackdropFilter) before pumping: _openShop() called
    // pause() so the overlay is still open. BackdropFilter causes pump(Duration)
    // to hang in headless tests. resume() removes it from the tree.
    harness.container.read(gameProvider.notifier).resume();
    await tester.pump();
    // Advance fake clock past the 300ms Timer from _onItemPurchased (without
    // BackdropFilter in tree, this pump completes normally).
    // The unawaited Hive write from add() completes in harness teardown
    // (2-second timeout on Hive.close() prevents hanging).
    await tester.pump(const Duration(milliseconds: 500));
  },
);
