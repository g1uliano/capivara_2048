import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/core/constants/game_constants.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/controllers/personal_records_notifier.dart';
import 'package:capivara_2048/presentation/screens/game/game_screen.dart';
import 'package:capivara_2048/presentation/screens/home_screen.dart';
import 'package:capivara_2048/presentation/widgets/host_artwork.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';
import '../_harness/tester_extensions.dart';

// ─── helpers ────────────────────────────────────────────────────────────────

Future<void> _bootToHome(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

// ─── regression.v1.2.7_header_grows_with_vertical_slack ─────────────────────

final regressionHeaderGrowsScenario = E2EScenario(
  id: 'regression.v1.2.7_header_grows_with_vertical_slack',
  title:
      '[v1.2.7] HostArtwork cresce além do baseline em tela alta (folga vertical)',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    tester.view.physicalSize = const Size(390, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _bootToHome(tester, harness);
    await tester.gotoGame(harness);

    expect(
      find.byType(HostArtwork),
      findsOneWidget,
      reason: 'HostArtwork deve estar visível na GameScreen',
    );

    final artworkSize = tester.getSize(find.byType(HostArtwork));

    expect(
      artworkSize.width,
      greaterThan(GameConstants.twoCellWidth),
      reason:
          '[v1.2.7] HostArtwork deve crescer além do baseline (${GameConstants.twoCellWidth}dp) '
          'quando há folga vertical — width encontrado: ${artworkSize.width}dp',
    );
  },
);

// ─── regression.v1.2.8_no_progressive_icon_loading ──────────────────────────

final regressionNoProgressiveLoadingScenario = E2EScenario(
  id: 'regression.v1.2.8_no_progressive_icon_loading',
  title:
      '[v1.2.8] todos os 6 botões PNG da Home estão no widget tree após splash',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    for (final key in [
      'home_btn_colecao',
      'home_btn_configuracao',
      'home_btn_recompensas',
      'home_btn_ranking',
      'home_btn_loja',
      'home_btn_comojogar',
    ]) {
      expect(
        find.byKey(Key(key)),
        findsOneWidget,
        reason:
            '[v1.2.8] botão "$key" deve estar no widget tree imediatamente após splash',
      );
    }
  },
);

// ─── regression.v1.2.9_continuar_after_back_unpause ─────────────────────────

final regressionContinuarAfterBackScenario = E2EScenario(
  id: 'regression.v1.2.9_continuar_after_back_unpause',
  title: '[v1.2.9] "Continuar Jogo" após back do sistema despausa corretamente',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);
    await tester.gotoGame(harness);

    harness.container
        .read(gameProvider.notifier)
        .debugSetState(
          GameState(
            board: List.generate(4, (_) => List<Tile?>.filled(4, null))
              ..[0][0] = const Tile(id: 't1', level: 2, row: 0, col: 0),
            score: 100,
            highScore: 100,
            maxLevel: 2,
            isGameOver: false,
            hasWon: false,
          ),
        );
    await tester.pump();

    harness.container.read(gameProvider.notifier).pause();
    await tester.pump();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byType(HomeScreen),
      findsOneWidget,
      reason: 'deve estar na HomeScreen após pop',
    );
    expect(
      find.text('Continuar Jogo'),
      findsOneWidget,
      reason: '"Continuar Jogo" deve aparecer pois há partida em andamento',
    );

    await tester.tap(find.text('Continuar Jogo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byType(GameScreen),
      findsOneWidget,
      reason: 'deve navegar para GameScreen',
    );
    expect(
      harness.container.read(gameProvider).isPaused,
      isFalse,
      reason:
          '[v1.2.9] "Continuar Jogo" deve desparar o jogo — isPaused deve ser false',
    );
    expect(
      find.text('Pausado'),
      findsNothing,
      reason:
          '[v1.2.9] PauseOverlay não deve aparecer ao entrar via "Continuar Jogo"',
    );
  },
);

// ─── regression.v1.2.10_collection_survives_cold_start ──────────────────────

final regressionCollectionSurvivesScenario = E2EScenario(
  id: 'regression.v1.2.10_collection_survives_cold_start',
  title:
      '[v1.2.10] highestLevelEver persiste após cold restart (coleção não reseta)',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    final widget = await tester.runAsync(() => harness.boot());
    await tester.pumpWidget(widget!);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.runAsync(
      () => harness.container
          .read(personalRecordsProvider.notifier)
          .updateHighestLevel(9),
    );
    expect(
      harness.container.read(personalRecordsProvider).highestLevelEver,
      equals(9),
    );

    final widget2 = await tester.runAsync(() => harness.restart());
    await tester.pumpWidget(widget2!);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(
      harness.container.read(personalRecordsProvider).highestLevelEver,
      equals(9),
      reason:
          '[v1.2.10] coleção não deve resetar após cold restart — '
          'highestLevelEver deve ser 9, não 0',
    );
  },
);
