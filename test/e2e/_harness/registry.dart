// test/e2e/_harness/registry.dart
import 'scenario.dart';

/// Single source of truth for all E2E scenarios.
///
/// Consumed by:
/// - Tier 1: [test/e2e/run_all_test.dart] (headless WidgetTester)
/// - Tier 2: TestRunnerScreen (future Phase 3.x, APK with live results)
///
/// Add new scenarios here as they are implemented.
final List<E2EScenario> allScenarios = <E2EScenario>[
  // Scenarios added in Tasks 6–8 and beyond.
];
