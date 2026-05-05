import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/data/models/item_type.dart';
import 'package:capivara_2048/domain/game_engine/bomb_mode.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/widgets/bomb_grid_overlay.dart';
import 'package:capivara_2048/presentation/widgets/bomb_selection_overlay.dart';
import 'package:capivara_2048/presentation/widgets/shop_overlay.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';
import '../_harness/tester_extensions.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

Future<void> _bootToGame(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
  await tester.gotoGame(harness);
}

// ─── items.bomb2_requires_target_selection ────────────────────────────────────

final itemsBomb2RequiresTargetScenario = E2EScenario(
  id: 'items.bomb2_requires_target_selection',
  title: 'bomb2: tap → confirmar dialog → BombGridOverlay e BombDimOverlay visíveis',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    harness.container.read(inventoryProvider.notifier)
        .debugSetState(const Inventory(bomb2: 1, bomb3: 0, undo1: 0, undo3: 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap bomb2 button → "Usar Bomba 2?" dialog appears.
    await tester.tap(find.byKey(const Key('inventory_bomb2')));
    await tester.pump();

    // Confirm the dialog ("Confirmar" button).
    expect(find.text('Confirmar'), findsOneWidget,
        reason: 'confirmação deve aparecer antes de ativar bomb');
    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // After confirmation: bomb mode active → overlays rendered.
    expect(tester.readGame(harness).bombMode, equals(BombMode.bomb2));
    expect(find.byType(BombDimOverlay), findsOneWidget,
        reason: 'BombDimOverlay deve cobrir a tela');
    expect(find.byType(BombGridOverlay), findsOneWidget,
        reason: 'BombGridOverlay deve aparecer para seleção de tiles');
  },
);

// ─── items.bomb2_cancellable_with_back ────────────────────────────────────────

final itemsBomb2CancellableScenario = E2EScenario(
  id: 'items.bomb2_cancellable_with_back',
  title: 'bomb2 ativo → cancelBomb() → bombMode null, overlays somem',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    harness.container.read(inventoryProvider.notifier)
        .debugSetState(const Inventory(bomb2: 1, bomb3: 0, undo1: 0, undo3: 0));

    // Activate bomb mode directly (bypass confirm dialog for speed).
    harness.container.read(gameProvider.notifier)
        .enterBombMode(BombMode.bomb2, ItemType.bomb2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.readGame(harness).bombMode, equals(BombMode.bomb2),
        reason: 'bomb mode deve estar ativo após enterBombMode');
    expect(find.byType(BombDimOverlay), findsOneWidget);

    // Cancel via notifier.
    harness.container.read(gameProvider.notifier).cancelBomb();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.readGame(harness).bombMode, isNull,
        reason: 'cancelBomb() deve limpar bombMode');
    expect(find.byType(BombDimOverlay), findsNothing,
        reason: 'BombDimOverlay deve sumir após cancelamento');
  },
);

// ─── items.bomb3_requires_target_selection ────────────────────────────────────

final itemsBomb3RequiresTargetScenario = E2EScenario(
  id: 'items.bomb3_requires_target_selection',
  title: 'bomb3: tap → confirmar → bombMode=bomb3, BombGridOverlay visível',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    harness.container.read(inventoryProvider.notifier)
        .debugSetState(const Inventory(bomb2: 0, bomb3: 1, undo1: 0, undo3: 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('inventory_bomb3')));
    await tester.pump();

    expect(find.text('Confirmar'), findsOneWidget);
    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.readGame(harness).bombMode, equals(BombMode.bomb3));
    expect(find.byType(BombGridOverlay), findsOneWidget,
        reason: 'BombGridOverlay para seleção de 3 tiles');
  },
);

// ─── items.undo1_disabled_at_game_start ──────────────────────────────────────

final itemsUndo1DisabledScenario = E2EScenario(
  id: 'items.undo1_disabled_at_game_start',
  title: 'undo1 com undoStack vazio → tap → dialog "Ops!" → inventário inalterado',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // Give undo1=2, undoStack is empty (fresh game, no moves yet).
    harness.container.read(inventoryProvider.notifier)
        .debugSetState(const Inventory(bomb2: 0, bomb3: 0, undo1: 2, undo3: 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final countBefore = harness.container.read(inventoryProvider).undo1;

    // Tap undo1 → forceDisabled=true → onTapWhenDisabled → dialog "Ops! 🙈"
    await tester.tap(find.byKey(const Key('inventory_undo1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Dialog should appear — dismiss it.
    if (find.text('Entendi!').evaluate().isNotEmpty) {
      await tester.tap(find.text('Entendi!'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    final countAfter = harness.container.read(inventoryProvider).undo1;
    expect(countAfter, equals(countBefore),
        reason: 'undo1 NÃO deve ser consumido quando undoStack está vazio');
  },
);

// ─── items.undo3_disabled_when_no_history ────────────────────────────────────

final itemsUndo3DisabledScenario = E2EScenario(
  id: 'items.undo3_disabled_when_no_history',
  title: 'undo3 com undoStack vazio → tap → dialog "Ops!" → inventário inalterado',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    harness.container.read(inventoryProvider.notifier)
        .debugSetState(const Inventory(bomb2: 0, bomb3: 0, undo1: 0, undo3: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final countBefore = harness.container.read(inventoryProvider).undo3;

    await tester.tap(find.byKey(const Key('inventory_undo3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    if (find.text('Entendi!').evaluate().isNotEmpty) {
      await tester.tap(find.text('Entendi!'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    final countAfter = harness.container.read(inventoryProvider).undo3;
    expect(countAfter, equals(countBefore),
        reason: 'undo3 NÃO deve ser consumido quando undoStack está vazio');
  },
);

// ─── items.bomb_dim_overlay_appears ──────────────────────────────────────────

final itemsBombDimOverlayScenario = E2EScenario(
  id: 'items.bomb_dim_overlay_appears',
  title: 'bombMode ativo → BombDimOverlay cobre a tela',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    harness.container.read(inventoryProvider.notifier)
        .debugSetState(const Inventory(bomb2: 1, bomb3: 0, undo1: 0, undo3: 0));

    // Activate directly (no dialog).
    harness.container.read(gameProvider.notifier)
        .enterBombMode(BombMode.bomb2, ItemType.bomb2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BombDimOverlay), findsOneWidget,
        reason: 'BombDimOverlay deve aparecer quando bombMode != null');

    // Cleanup: cancel bomb mode so teardown is clean.
    harness.container.read(gameProvider.notifier).cancelBomb();
    await tester.pump();
  },
);

// ─── items.item_count_persists_across_sessions ────────────────────────────────

final itemsCountPersistsScenario = E2EScenario(
  id: 'items.item_count_persists_across_sessions',
  title: 'contagem de itens persiste após cold restart',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    // Boot 1: add items via add() which saves to Hive.
    final widget1 = await tester.runAsync(() => harness.boot());
    await tester.pumpWidget(widget1!);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.runAsync(() async {
      await harness.container
          .read(inventoryProvider.notifier)
          .add(ItemType.bomb2, 3);
    });
    await tester.pump();

    // Cold restart — new ProviderContainer loads from Hive.
    final widget2 = await tester.runAsync(() => harness.restart());
    await tester.pumpWidget(widget2!);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    final inventory = harness.container.read(inventoryProvider);
    expect(inventory.bomb2, equals(3),
        reason: 'bomb2=3 deve persistir após cold restart');
  },
);

// ─── items.empty_item_opens_shop ─────────────────────────────────────────────

final itemsEmptyItemOpensShopScenario = E2EScenario(
  id: 'items.empty_item_opens_shop',
  title: 'item com count=0 → tap → onTapWhenEmpty → ShopOverlay abre',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToGame(tester, harness);

    // All items empty → onTapWhenEmpty wired to _openShop.
    harness.container.read(inventoryProvider.notifier)
        .debugSetState(Inventory.empty());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap undo1 (count=0) → _openShop(ItemType.undo1) → ShopOverlay appears.
    await tester.tap(find.byKey(const Key('inventory_undo1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ShopOverlay), findsOneWidget,
        reason: 'tap em item vazio deve abrir ShopOverlay');
  },
);
