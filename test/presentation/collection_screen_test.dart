import 'dart:io';
import 'package:capivara_2048/data/models/daily_rewards_state_adapter.dart';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/domain/game_engine/game_engine.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/screens/collection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

late Directory _tempDir;

class _FakeGameNotifier extends GameNotifier {
  _FakeGameNotifier(GameState s) : super(GameEngine()) {
    state = s;
  }
}

Widget _wrapWithMaxLevel(int maxLevel) {
  final fakeState = GameState(
    board: List.generate(4, (_) => List.filled(4, null)),
    score: 0,
    highScore: 0,
    isGameOver: false,
    hasWon: false,
    maxLevel: maxLevel,
  );
  return ProviderScope(
    overrides: [
      gameProvider.overrideWith((_) => _FakeGameNotifier(fakeState)),
    ],
    child: const MaterialApp(home: CollectionScreen()),
  );
}

void main() {
  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('hive_collection_test');
    Hive.init(_tempDir.path);
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LivesStateAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DailyRewardsStateAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    await _tempDir.delete(recursive: true);
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('maxLevel=0 → 11 cards bloqueados, cabeçalho "0/11"', (tester) async {
    await tester.pumpWidget(_wrapWithMaxLevel(0));
    await tester.pump();
    expect(find.text('0/11 animais descobertos'), findsOneWidget);
    expect(find.text('???'), findsNWidgets(11));
  });

  testWidgets('maxLevel=1 → 1 card colorido, 10 bloqueados', (tester) async {
    await tester.pumpWidget(_wrapWithMaxLevel(1));
    await tester.pump();
    expect(find.text('1/11 animais descobertos'), findsOneWidget);
    expect(find.text('???'), findsNWidgets(10));
    expect(find.text('Tanajura'), findsOneWidget);
  });

  testWidgets('maxLevel=5 → 5 coloridos, 6 bloqueados', (tester) async {
    await tester.pumpWidget(_wrapWithMaxLevel(5));
    await tester.pump();
    expect(find.text('5/11 animais descobertos'), findsOneWidget);
    expect(find.text('???'), findsNWidgets(6));
  });

  testWidgets('maxLevel=11 → 11 coloridos, cabeçalho "11/11"', (tester) async {
    await tester.pumpWidget(_wrapWithMaxLevel(11));
    await tester.pump();
    expect(find.text('11/11 animais descobertos'), findsOneWidget);
    expect(find.text('???'), findsNothing);
  });

  testWidgets('tap em card desbloqueado abre bottom sheet com nome e funFact', (tester) async {
    await tester.pumpWidget(_wrapWithMaxLevel(1));
    await tester.pump();
    await tester.tap(find.text('Tanajura'));
    await tester.pumpAndSettle();
    expect(find.text('Atta laevigata'), findsOneWidget);
    expect(find.textContaining('carregar'), findsOneWidget);
  });

  testWidgets('tap em card bloqueado não abre bottom sheet', (tester) async {
    await tester.pumpWidget(_wrapWithMaxLevel(0));
    await tester.pump();
    await tester.tap(find.text('???').first);
    await tester.pumpAndSettle();
    expect(find.text('Atta laevigata'), findsNothing);
  });

  testWidgets('LinearProgressIndicator.value correto para maxLevel=5', (tester) async {
    await tester.pumpWidget(_wrapWithMaxLevel(5));
    await tester.pump();
    final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator));
    expect(indicator.value, closeTo(5 / 11.0, 0.001));
  });
}
