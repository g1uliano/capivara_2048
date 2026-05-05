// test/e2e/run_all_test.dart
import 'package:flutter_test/flutter_test.dart';
import '_harness/registry.dart';
import '_harness/scenario.dart';
import '_harness/test_harness.dart';
import 'golden/golden_tests.dart';

void main() {
  if (allScenarios.isEmpty) {
    test('E2E SUITE — no scenarios registered yet', () {
      // Placeholder so this file passes when the registry is empty.
    });
    return;
  }

  for (final scenario in allScenarios.where(
    (s) => !s.tags.contains(ScenarioTag.tier2Only),
  )) {
    testWidgets('[${scenario.id}] ${scenario.title}', (tester) async {
      final h = GameTestHarness();
      addTearDown(() => tester.runAsync(h.teardown));
      await scenario.run(tester, h);
    });
  }

  // Golden tests — usa goldenTest() do alchemist (cria testWidgets internamente,
  // não pode ser encapsulado em E2EScenario). Registra 15 testes: 5 telas × 3 viewports.
  runGoldenTests();
}
