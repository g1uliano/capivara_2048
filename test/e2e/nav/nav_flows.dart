import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/screens/ranking_screen.dart';
import 'package:capivara_2048/presentation/screens/shop_screen.dart';
import 'package:capivara_2048/presentation/screens/daily_rewards/daily_rewards_screen.dart';
import 'package:capivara_2048/presentation/screens/home_screen.dart';
import 'package:capivara_2048/presentation/screens/collection_screen.dart';
import 'package:capivara_2048/presentation/screens/settings_screen.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';

Future<void> _bootToHome(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

// ─── nav.home_to_ranking ─────────────────────────────────────────────────────

final navHomeToRankingScenario = E2EScenario(
  id: 'nav.home_to_ranking',
  title: 'tap em Ranking navega para RankingScreen',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    await tester.tap(find.byKey(const Key('home_btn_ranking')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(RankingScreen), findsOneWidget);
  },
);

// ─── nav.home_to_shop ────────────────────────────────────────────────────────

final navHomeToShopScenario = E2EScenario(
  id: 'nav.home_to_shop',
  title: 'tap em Loja navega para ShopScreen (tela completa)',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    await tester.tap(find.byKey(const Key('home_btn_loja')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ShopScreen), findsOneWidget);
  },
);

// ─── nav.home_to_daily_rewards ───────────────────────────────────────────────

final navHomeToDailyRewardsScenario = E2EScenario(
  id: 'nav.home_to_daily_rewards',
  title: 'tap em Recompensas navega para DailyRewardsScreen',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    // DailyRewardsScreen requires portrait height to avoid layout overflow
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _bootToHome(tester, harness);

    await tester.tap(find.byKey(const Key('home_btn_recompensas')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DailyRewardsScreen), findsOneWidget);
  },
);

// ─── nav.home_to_tutorial_bottomsheet ────────────────────────────────────────

final navHomeToTutorialScenario = E2EScenario(
  id: 'nav.home_to_tutorial_bottomsheet',
  title: 'tap em ComoJogar navega para TutorialScreen',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    await tester.tap(find.byKey(const Key('home_btn_comojogar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Tutorial'), findsOneWidget);
  },
);

// ─── nav.collection_back_returns_home ────────────────────────────────────────

final navCollectionBackScenario = E2EScenario(
  id: 'nav.collection_back_returns_home',
  title: 'CollectionScreen → back → HomeScreen',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    await tester.tap(find.byKey(const Key('home_btn_colecao')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CollectionScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CollectionScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  },
);

// ─── nav.settings_back_returns_home ──────────────────────────────────────────

final navSettingsBackScenario = E2EScenario(
  id: 'nav.settings_back_returns_home',
  title: 'SettingsScreen → back → HomeScreen',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    await tester.tap(find.byKey(const Key('home_btn_configuracao')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(SettingsScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  },
);

// ─── nav.new_game_back_returns_home ──────────────────────────────────────────

final navNewGameBackScenario = E2EScenario(
  id: 'nav.new_game_back_returns_home',
  title: 'GameScreen → pause → Menu → HomeScreen',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    await tester.tap(find.text('Novo jogo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Pause and use Menu to go back
    harness.container.read(gameProvider.notifier).pause();
    await tester.pump();

    await tester.tap(find.text('Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(HomeScreen), findsOneWidget);
  },
);
