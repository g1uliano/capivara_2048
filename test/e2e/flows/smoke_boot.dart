import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/screens/home_screen.dart';
import '../_harness/scenario.dart';

final smokeBootScenario = E2EScenario(
  id: 'flow.smoke_boot',
  title: 'app abre, splash navega para HomeScreen',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    final widget = await tester.runAsync(() => harness.boot());
    await tester.pumpWidget(widget!);
    // Splash has 1500ms min + precacheFutureOverride (completes instantly).
    // Pump up to 5s to allow the nav timer to fire and HomeScreen to render.
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Novo jogo'), findsOneWidget);
  },
);
