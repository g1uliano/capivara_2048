import 'dart:io';

import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';
import 'package:capivara_2048/presentation/screens/game/game_over_item_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

late Directory _tempDir;

Future<void> _initHive() async {
  _tempDir = await Directory.systemTemp.createTemp('game_over_item_test');
  Hive.init(_tempDir.path);
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
}

Future<void> _teardownHive() async {
  await Hive.close();
  await _tempDir.delete(recursive: true);
}

Widget _buildOverlay({required Inventory inventory, required SharedPreferences prefs}) {
  return ProviderScope(
    overrides: [
      inventoryRepositoryProvider.overrideWithValue(InventoryRepository()),
      inventoryProvider.overrideWith((ref) {
        final notifier = InventoryNotifier(ref.read(inventoryRepositoryProvider));
        notifier.setStateForTest(inventory);
        return notifier;
      }),
      settingsProvider.overrideWith((ref) => SettingsNotifier(prefs)),
    ],
    child: const MaterialApp(home: Scaffold(body: GameOverItemOverlay())),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'settings.haptic_enabled': false});
    prefs = await SharedPreferences.getInstance();
    await _initHive();
  });

  tearDown(_teardownHive);

  final inv = const Inventory(bomb2: 0, bomb3: 2, undo1: 0, undo3: 1);

  testWidgets('shows first item by priority (undo3 before bomb3)', (tester) async {
    await tester.pumpWidget(_buildOverlay(inventory: inv, prefs: prefs));
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Desfazer 3'), findsOneWidget);
    expect(find.text('Você tem 1 deste item'), findsOneWidget);
  });

  testWidgets('Próximo item button advances to next item', (tester) async {
    await tester.pumpWidget(_buildOverlay(inventory: inv, prefs: prefs));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.tap(find.text('Próximo item →'));
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Bomba 3'), findsOneWidget);
    expect(find.text('Você tem 2 deste item'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('last item shows Desistir button in red', (tester) async {
    await tester.pumpWidget(_buildOverlay(inventory: inv, prefs: prefs));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.tap(find.text('Próximo item →'));
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Desistir'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('shows correct PNG for highest-priority item', (tester) async {
    await tester.pumpWidget(_buildOverlay(inventory: inv, prefs: prefs));
    await tester.pump(const Duration(milliseconds: 1));
    expect(
      find.byWidgetPredicate(
        (w) => w is Image && (w.image as AssetImage).assetName == 'assets/icons/inventory/undo_3.png',
      ),
      findsOneWidget,
    );
  });
}
