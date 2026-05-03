import 'dart:io';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/data/repositories/lives_repository.dart';
import 'package:capivara_2048/data/repositories/share_codes_repository.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/domain/shop/share_codes_notifier.dart';
import 'package:capivara_2048/presentation/screens/game/game_screen.dart';
import 'package:capivara_2048/presentation/widgets/shop_overlay.dart';
import 'package:capivara_2048/presentation/widgets/inventory_item_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

late Directory _tempDir;

Future<void> _initHive() async {
  _tempDir = await Directory.systemTemp.createTemp('game_211_test');
  Hive.init(_tempDir.path);
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LivesStateAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
}

Widget _buildGame() {
  return ProviderScope(
    overrides: [
      inventoryRepositoryProvider.overrideWithValue(InventoryRepository()),
      livesRepositoryProvider.overrideWithValue(LivesRepository()),
      shareCodesRepositoryProvider.overrideWithValue(ShareCodesRepository()),
    ],
    child: const MaterialApp(home: GameScreen()),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _initHive();
  });

  tearDown(() async {
    await Hive.close();
    await _tempDir.delete(recursive: true);
  });

  testWidgets('tap em ícone desabilitado (count==0) → ShopOverlay aparece', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_buildGame());
    await tester.pumpAndSettle();

    // All items start at 0 → tapping any InventoryItemButton should open ShopOverlay
    final buttons = find.byType(InventoryItemButton);
    expect(buttons, findsWidgets);
    await tester.tap(buttons.first);
    await tester.pumpAndSettle();

    expect(find.byType(ShopOverlay), findsOneWidget);
  });

  testWidgets('ShopOverlay fecha ao tap no botão X', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_buildGame());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InventoryItemButton).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(ShopOverlay), findsNothing);
  });
}
