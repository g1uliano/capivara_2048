import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/screens/collection_screen.dart';
import 'package:capivara_2048/presentation/screens/settings_screen.dart';
import 'package:capivara_2048/presentation/screens/game/game_screen.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';
import '../_harness/tester_extensions.dart';

// Helper: boot → splash → home
Future<void> _bootToHome(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

final navHomeToCollectionScenario = E2EScenario(
  id: 'nav.home_to_collection',
  title: 'tap em Coleção navega para CollectionScreen',
  tags: {ScenarioTag.critical, ScenarioTag.demo},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);
    await tester.tapByKey('home_btn_colecao');
    expect(find.byType(CollectionScreen), findsOneWidget);
  },
);

final navHomeToSettingsScenario = E2EScenario(
  id: 'nav.home_to_settings',
  title: 'tap em Configurações navega para SettingsScreen',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);
    await tester.tapByKey('home_btn_configuracao');
    expect(find.byType(SettingsScreen), findsOneWidget);
  },
);

final navNewGameScenario = E2EScenario(
  id: 'flow.new_game_basic',
  title: 'Novo jogo abre GameScreen com tabuleiro renderizado',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);
    await tester.tap(find.text('Novo jogo'));
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
  },
);
