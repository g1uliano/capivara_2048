import 'dart:io';

import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/data/repositories/lives_repository.dart';
import 'package:capivara_2048/domain/daily_rewards/ad_service.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/presentation/widgets/game_over_no_items_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

late Directory _tempDir;

Future<void> _initHive() async {
  _tempDir = await Directory.systemTemp.createTemp('no_items_test');
  Hive.init(_tempDir.path);
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LivesStateAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
}

Future<void> _teardownHive() async {
  await Hive.close();
  await _tempDir.delete(recursive: true);
}

Widget _buildOverlay({AdService? adService}) {
  return ProviderScope(
    overrides: [
      inventoryRepositoryProvider.overrideWithValue(InventoryRepository()),
      livesRepositoryProvider.overrideWithValue(LivesRepository()),
      if (adService != null) adServiceProvider.overrideWithValue(adService),
    ],
    child: const MaterialApp(
      home: Scaffold(body: GameOverNoItemsOverlay()),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _initHive();
  });
  tearDown(_teardownHive);

  testWidgets('shows title and all three option buttons', (tester) async {
    await tester.pumpWidget(_buildOverlay());
    await tester.pumpAndSettle();
    expect(find.textContaining('não possui mais itens'), findsOneWidget);
    expect(find.textContaining('Ver anúncio'), findsOneWidget);
    expect(find.textContaining('Comprar'), findsOneWidget);
    expect(find.text('Encerrar partida'), findsOneWidget);
  });

  testWidgets('drawn item is one of the four valid types', (tester) async {
    await tester.pumpWidget(_buildOverlay());
    await tester.pumpAndSettle();
    final validNames = ['Bomba 2', 'Bomba 3', 'Desfazer 1', 'Desfazer 3'];
    final found = validNames.any((n) => find.text(n).evaluate().isNotEmpty);
    expect(found, isTrue);
  });

  testWidgets('back button does not close overlay (WillPopScope)', (tester) async {
    await tester.pumpWidget(_buildOverlay());
    await tester.pumpAndSettle();
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.textContaining('não possui mais itens'), findsOneWidget);
  });

  testWidgets('tap buy shows AlertDialog with price', (tester) async {
    await tester.pumpWidget(_buildOverlay());
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Comprar'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar compra'), findsOneWidget);
    expect(find.textContaining('R\$'), findsWidgets);
  });

  testWidgets('tap buy → cancel → returns to overlay', (tester) async {
    await tester.pumpWidget(_buildOverlay());
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Comprar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('não possui mais itens'), findsOneWidget);
  });

  testWidgets('tap quit shows AlertDialog', (tester) async {
    await tester.pumpWidget(_buildOverlay());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Encerrar partida'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tem certeza'), findsOneWidget);
  });

  testWidgets('tap quit → cancel → returns to overlay', (tester) async {
    await tester.pumpWidget(_buildOverlay());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Encerrar partida'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('não possui mais itens'), findsOneWidget);
  });

  testWidgets('tap buy → confirm → overlay closes', (tester) async {
    await tester.pumpWidget(_buildOverlay());
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Comprar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar compra'));
    await tester.pumpAndSettle();
    expect(find.textContaining('não possui mais itens'), findsNothing);
  });

  testWidgets('watch ad → item delivered (FakeAdService returns true)', (tester) async {
    await tester.pumpWidget(_buildOverlay(adService: FakeAdService()));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Ver anúncio'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('adicionado'), findsOneWidget);
  });
}
