import 'scenario.dart';
import '../flows/smoke_boot.dart';
import '../flows/nav_smokes.dart';
import '../flows/pause_flows.dart';
import '../flows/game_over_flows.dart';
import '../flows/items_flows.dart';
import '../persistence/collection_survives_restart.dart';

/// Single source of truth for all E2E scenarios.
///
/// Consumed by:
/// - Tier 1: [test/e2e/run_all_test.dart] (headless WidgetTester)
/// - Tier 2: TestRunnerScreen (future Phase 3.x, APK with live results)
///
/// Add new scenarios here as they are implemented.
final List<E2EScenario> allScenarios = <E2EScenario>[
  smokeBootScenario,
  navHomeToCollectionScenario,
  navHomeToSettingsScenario,
  navNewGameScenario,
  collectionSurvivesRestartScenario,
  // Task 2
  continueAfterPauseScenario,
  continueAfterBackButtonScenario,
  // Task 3
  gameOverNoItemsScenario,
  gameOverWithItemsScenario,
  // Task 4
  useUndoDuringGameScenario,
  useBomb2DuringGameScenario,
  useBomb3DuringGameScenario,
];
