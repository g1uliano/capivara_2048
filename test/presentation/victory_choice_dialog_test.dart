import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:capivara_2048/presentation/widgets/victory_choice_dialog.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/data/models/tile.dart';

GameState _stateWithMilestone(int milestone) {
  final board = List.generate(4, (r) => List<Tile?>.filled(4, null));
  return GameState(
    board: board, score: 0, highScore: 0,
    isGameOver: false, hasWon: false,
    pendingMilestone: milestone,
  );
}

Widget _wrap(int milestone) {
  return ProviderScope(
    overrides: [
      gameProvider.overrideWith((ref) {
        final notifier = GameNotifier(ref.read(gameEngineProvider), ref);
        notifier.setStateForTest(_stateWithMilestone(milestone));
        return notifier;
      }),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: VictoryChoiceDialog(milestone: milestone),
      ),
    ),
  );
}

void main() {
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('hive_victory_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  testWidgets('marco 11: exibe botões Continuar e Encerrar', (tester) async {
    await tester.pumpWidget(_wrap(11));
    await tester.pump();
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Encerrar'), findsOneWidget);
  });

  testWidgets('marco 12: exibe botões Continuar e Encerrar', (tester) async {
    await tester.pumpWidget(_wrap(12));
    await tester.pump();
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Encerrar'), findsOneWidget);
  });

  testWidgets('marco 13: exibe apenas Encerrar', (tester) async {
    await tester.pumpWidget(_wrap(13));
    await tester.pump();
    expect(find.text('Continuar'), findsNothing);
    expect(find.text('Encerrar'), findsOneWidget);
  });

  testWidgets('título correto para marco 11', (tester) async {
    await tester.pumpWidget(_wrap(11));
    await tester.pump();
    expect(find.text('Capivara Lendária! 🎉'), findsOneWidget);
  });

  testWidgets('título correto para marco 12', (tester) async {
    await tester.pumpWidget(_wrap(12));
    await tester.pump();
    expect(find.text('Peixe-boi! Incrível! 🌊'), findsOneWidget);
  });

  testWidgets('título correto para marco 13', (tester) async {
    await tester.pumpWidget(_wrap(13));
    await tester.pump();
    expect(find.text('Jacaré! Lendário! 🐊'), findsOneWidget);
  });
}
