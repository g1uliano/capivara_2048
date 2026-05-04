import 'package:flutter_test/flutter_test.dart';
import 'test_harness.dart';

enum ScenarioTag {
  critical,
  slow,
  demo,
  tier1Only,
  tier2Only,
  golden,
}

typedef ScenarioRun = Future<void> Function(
  WidgetTester tester,
  GameTestHarness harness,
);

class E2EScenario {
  final String id;
  final String title;
  final Set<ScenarioTag> tags;
  final ScenarioRun run;

  E2EScenario({
    required this.id,
    required this.title,
    required this.tags,
    required this.run,
  });

  bool matchesTag(ScenarioTag tag) => tags.contains(tag);
}
