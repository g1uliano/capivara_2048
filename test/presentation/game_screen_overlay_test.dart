import 'dart:io';

import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/domain/game_engine/game_engine.dart';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/data/repositories/lives_repository.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';
import 'package:capivara_2048/presentation/screens/game/game_over_item_overlay.dart';
import 'package:capivara_2048/presentation/screens/game/game_screen.dart';
import 'package:capivara_2048/presentation/widgets/game_over_modal.dart';
import 'package:capivara_2048/presentation/widgets/game_over_no_items_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

late Directory _tempDir;

Future<void> _initHive() async {
  _tempDir = await Directory.systemTemp.createTemp('game_screen_overlay_test');
  Hive.init(_tempDir.path);
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LivesStateAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
}

Future<void> _teardownHive() async {
  await Hive.close();
  await _tempDir.delete(recursive: true);
}

// GameState com tabuleiro travado e isAwaitingGameOverResolution controlado
GameState _awaitingState({required bool isAwaitingResolution}) {
  return GameState(
    board: GameEngine().newGame().board,
    score: 0,
    highScore: 0,
    isGameOver: true,
    hasWon: false,
    maxLevel: 1,
    isAwaitingGameOverResolution: isAwaitingResolution,
  );
}

Widget _buildScreen({
  required GameState gameState,
  required Inventory inventory,
  required SharedPreferences prefs,
}) {
  return ProviderScope(
    overrides: [
      gameProvider.overrideWith((ref) {
        final notifier = GameNotifier(GameEngine());
        notifier.state = gameState;
        return notifier;
      }),
      inventoryRepositoryProvider.overrideWithValue(InventoryRepository()),
      inventoryProvider.overrideWith((ref) {
        final notifier = InventoryNotifier(ref.read(inventoryRepositoryProvider));
        notifier.setStateForTest(inventory);
        return notifier;
      }),
      livesRepositoryProvider.overrideWithValue(LivesRepository()),
      livesProvider.overrideWith((ref) => LivesNotifier(ref.read(livesRepositoryProvider))),
      settingsProvider.overrideWith((ref) => SettingsNotifier(prefs)),
    ],
    child: const MaterialApp(home: GameScreen()),
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

  testWidgets(
      'game over com itens → GameOverItemOverlay visível, GameOverModal ausente',
      (tester) async {
    final inv = const Inventory(bomb2: 0, bomb3: 2, undo1: 0, undo3: 1);
    await tester.pumpWidget(_buildScreen(
      gameState: _awaitingState(isAwaitingResolution: true),
      inventory: inv,
      prefs: prefs,
    ));
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.byType(GameOverItemOverlay), findsOneWidget);
    expect(find.byType(GameOverNoItemsOverlay), findsNothing);
    expect(find.byType(GameOverModal), findsNothing);
  });

  testWidgets(
      'game over sem itens → GameOverNoItemsOverlay visível, GameOverModal ausente',
      (tester) async {
    final inv = const Inventory(bomb2: 0, bomb3: 0, undo1: 0, undo3: 0);
    await tester.pumpWidget(_buildScreen(
      gameState: _awaitingState(isAwaitingResolution: true),
      inventory: inv,
      prefs: prefs,
    ));
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.byType(GameOverNoItemsOverlay), findsOneWidget);
    expect(find.byType(GameOverItemOverlay), findsNothing);
    expect(find.byType(GameOverModal), findsNothing);
  });

  testWidgets(
      'após encerrar (isAwaitingResolution=false, sem itens) → GameOverModal visível',
      (tester) async {
    final inv = const Inventory(bomb2: 0, bomb3: 0, undo1: 0, undo3: 0);
    await tester.pumpWidget(_buildScreen(
      gameState: _awaitingState(isAwaitingResolution: false),
      inventory: inv,
      prefs: prefs,
    ));
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.byType(GameOverModal), findsOneWidget);
    expect(find.byType(GameOverNoItemsOverlay), findsNothing);
  });
}
