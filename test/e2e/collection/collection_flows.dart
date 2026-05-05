import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/controllers/personal_records_notifier.dart';
import 'package:capivara_2048/presentation/screens/collection_screen.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';

// ─── helpers ────────────────────────────────────────────────────────────────

Future<void> _bootToCollection(
  WidgetTester tester,
  GameTestHarness harness, {
  int highest = 0,
}) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));

  if (highest > 0) {
    await tester.runAsync(
      () => harness.container
          .read(personalRecordsProvider.notifier)
          .updateHighestLevel(highest),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  await tester.tap(find.byKey(const Key('home_btn_colecao')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  expect(
    find.byType(CollectionScreen),
    findsOneWidget,
    reason: 'deve navegar para CollectionScreen',
  );
}

// ─── collection.shows_X_of_13_animals ───────────────────────────────────────

final collectionShowsCountScenario = E2EScenario(
  id: 'collection.shows_X_of_13_animals',
  title: 'CollectionScreen exibe "X/13 animais descobertos" com X correto',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToCollection(tester, harness, highest: 5);

    expect(
      find.text('5/13 animais descobertos'),
      findsOneWidget,
      reason:
          'deve exibir "5/13 animais descobertos" quando highestLevelEver=5',
    );
  },
);

// ─── collection.locked_animals_show_question_marks ──────────────────────────

final collectionLockedShowsQuestionMarkScenario = E2EScenario(
  id: 'collection.locked_animals_show_question_marks',
  title: 'animais bloqueados exibem "???" na CollectionScreen',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToCollection(tester, harness, highest: 0);

    expect(
      find.text('???'),
      findsWidgets,
      reason: 'animais bloqueados devem exibir "???"',
    );

    expect(
      find.text('Tanajura'),
      findsNothing,
      reason: 'Tanajura deve estar bloqueado quando highest=0',
    );
  },
);

// ─── collection.unlocked_card_opens_detail_sheet ────────────────────────────

final collectionUnlockedCardOpensSheetScenario = E2EScenario(
  id: 'collection.unlocked_card_opens_detail_sheet',
  title: 'tap em card desbloqueado abre bottom sheet com nome do animal',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToCollection(tester, harness, highest: 1);

    expect(
      find.text('Tanajura'),
      findsOneWidget,
      reason: 'Tanajura deve estar desbloqueada com highest=1',
    );

    await tester.tap(find.text('Tanajura'));
    await tester.pumpAndSettle();

    expect(
      find.text('Tanajura'),
      findsWidgets,
      reason: 'bottom sheet deve exibir o nome do animal',
    );
  },
);

// ─── collection.detail_shows_scientific_name_when_present ───────────────────

final collectionDetailScientificNameScenario = E2EScenario(
  id: 'collection.detail_shows_scientific_name_when_present',
  title:
      'bottom sheet de animal desbloqueado exibe nome científico quando presente',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToCollection(tester, harness, highest: 1);

    await tester.tap(find.text('Tanajura'));
    await tester.pumpAndSettle();

    expect(
      find.text('Atta laevigata'),
      findsOneWidget,
      reason: 'bottom sheet deve exibir o nome científico do animal',
    );
  },
);

// ─── collection.detail_shows_funfact ────────────────────────────────────────

final collectionDetailFunFactScenario = E2EScenario(
  id: 'collection.detail_shows_funfact',
  title: 'bottom sheet de animal desbloqueado exibe fun fact',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToCollection(tester, harness, highest: 1);

    await tester.tap(find.text('Tanajura'));
    await tester.pumpAndSettle();

    expect(
      find.text('Pode carregar até 50× seu próprio peso!'),
      findsOneWidget,
      reason: 'bottom sheet deve exibir o fun fact do animal',
    );
  },
);

// ─── collection.progress_bar_matches_count ──────────────────────────────────

final collectionProgressBarScenario = E2EScenario(
  id: 'collection.progress_bar_matches_count',
  title: 'barra de progresso tem valor = highest/13',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToCollection(tester, harness, highest: 7);

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );

    expect(
      bar.value,
      closeTo(7 / 13.0, 0.001),
      reason: 'barra de progresso deve ter value = 7/13 quando highest=7',
    );
  },
);
