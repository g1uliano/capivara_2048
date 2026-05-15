import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/widgets/shop_overlay.dart';
import 'package:capivara_2048/presentation/widgets/shop_package_card.dart';
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
  tags: {ScenarioTag.critical, ScenarioTag.demo},
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

    // ShopPackageCard renders as tappable image (p1–p6) — no "Comprar" text.
    final packageCards = find.byType(ShopPackageCard);
    expect(
      packageCards,
      findsWidgets,
      reason: 'ShopOverlay deve exibir pelo menos um ShopPackageCard',
    );
    await tester.tap(packageCards.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // IAPConfirmationSheet aparece com botão 'Confirmar — R$ X,XX'.
    await tester.tap(find.textContaining('Confirmar'));
    await tester.pump(const Duration(milliseconds: 200));

    // FakeIAPService tem 100ms de delay; aguardar atualização do estado.
    await tester.pump(const Duration(milliseconds: 200));

    // State is updated after deliverIAPItems — verify after settling.
    final inventoryAfter = harness.container.read(inventoryProvider);
    final totalBefore =
        inventoryBefore.bomb2 +
        inventoryBefore.bomb3 +
        inventoryBefore.undo1 +
        inventoryBefore.undo3;
    final totalAfter =
        inventoryAfter.bomb2 +
        inventoryAfter.bomb3 +
        inventoryAfter.undo1 +
        inventoryAfter.undo3;
    expect(
      totalAfter,
      greaterThan(totalBefore),
      reason: 'compra deve incrementar pelo menos um item no inventário',
    );

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

// ─── flow.shop_redeem_code_navigation ─────────────────────────────────────────

final shopRedeemCodeNavigationScenario = E2EScenario(
  id: 'flow.shop_redeem_code_navigation',
  title: 'ShopScreen: tap "Resgatar código" → RedeemCodeScreen renderiza',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    final widget = await tester.runAsync(() => harness.boot());
    await tester.pumpWidget(widget!);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Navigate to ShopScreen from HomeScreen
    await tester.tap(find.byKey(const Key('home_btn_loja')));
    await tester.pumpAndSettle();

    // Tap "Resgatar código de presente"
    await tester.tap(find.text('Resgatar código de presente'));
    await tester.pumpAndSettle();

    // RedeemCodeScreen should be visible
    expect(find.text('Resgatar Código'), findsOneWidget);
    expect(find.text('Resgatar'), findsOneWidget);
  },
);
