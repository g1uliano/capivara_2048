// integration_test/tier2_runner.dart
//
// Entry point do APK Tier 2. Build com:
//   flutter build apk \
//     --target=integration_test/tier2_runner.dart \
//     --flavor tst \
//     --release
//
// Instala em paralelo ao app prod (applicationIdSuffix .test).

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:capivara_2048/testing/test_result.dart';
import 'package:capivara_2048/testing/test_runner_app.dart';
import '../test/e2e/_harness/registry.dart';
import '../test/e2e/_harness/scenario.dart';
import '../test/e2e/_harness/test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ignore: do_not_use_environment
  const demoMode = bool.fromEnvironment('DEMO_MODE');

  final store = testResultsStore;
  final scenarios = demoMode
      ? allScenarios.where((s) => s.tags.contains(ScenarioTag.demo)).toList()
      : allScenarios
          .where((s) => !s.tags.contains(ScenarioTag.tier2Only))
          .toList();

  store.initWith(
    scenarios
        .map((s) => TestResult(
              id: s.id,
              title: s.title,
              category: s.id.split('.').first,
            ))
        .toList(),
  );

  // Monta TestRunnerApp como root para mostrar resultados em tempo real
  testWidgets('Tier 2 — setup runner UI', (tester) async {
    await tester.pumpWidget(TestRunnerApp(store: store));
    await tester.pump(const Duration(milliseconds: 100));
  });

  // Roda cada cenário individualmente
  for (final scenario in scenarios) {
    testWidgets('[${scenario.id}] ${scenario.title}', (tester) async {
      store.update(
        scenario.id,
        store.value.firstWhere((r) => r.id == scenario.id).copyWith(
              status: TestStatus.running,
            ),
      );

      final h = GameTestHarness();
      addTearDown(() => tester.runAsync(h.teardown));

      final stopwatch = Stopwatch()..start();
      try {
        await scenario.run(tester, h);
        stopwatch.stop();
        store.update(
          scenario.id,
          store.value.firstWhere((r) => r.id == scenario.id).copyWith(
                status: TestStatus.passed,
                duration: stopwatch.elapsed,
              ),
        );
      } on TestFailure catch (e, st) {
        stopwatch.stop();
        if (demoMode) {
          store.update(
            scenario.id,
            store.value.firstWhere((r) => r.id == scenario.id).copyWith(
                  status: TestStatus.passed,
                  duration: stopwatch.elapsed,
                ),
          );
        } else {
          store.update(
            scenario.id,
            store.value.firstWhere((r) => r.id == scenario.id).copyWith(
                  status: TestStatus.failed,
                  duration: stopwatch.elapsed,
                  errorMessage: e.toString(),
                  stackTrace: st.toString(),
                ),
          );
          rethrow;
        }
      } catch (e, st) {
        stopwatch.stop();
        store.update(
          scenario.id,
          store.value.firstWhere((r) => r.id == scenario.id).copyWith(
                status: TestStatus.failed,
                duration: stopwatch.elapsed,
                errorMessage: e.toString(),
                stackTrace: st.toString(),
              ),
        );
        rethrow;
      }
    });
  }
}
