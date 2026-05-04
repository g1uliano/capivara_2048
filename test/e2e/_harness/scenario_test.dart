import 'package:flutter_test/flutter_test.dart';
import 'scenario.dart';

void main() {
  test('E2EScenario armazena id, title, tags, run', () {
    var ran = false;
    final s = E2EScenario(
      id: 'flow.example',
      title: 'Example',
      tags: {ScenarioTag.critical, ScenarioTag.demo},
      run: (tester, harness) async => ran = true,
    );
    expect(s.id, 'flow.example');
    expect(s.title, 'Example');
    expect(s.tags, contains(ScenarioTag.critical));
    expect(ran, isFalse);
  });

  test('matchesTag retorna true se a tag está presente', () {
    final s = E2EScenario(
      id: 'x', title: 'x',
      tags: {ScenarioTag.golden},
      run: (_, __) async {},
    );
    expect(s.matchesTag(ScenarioTag.golden), isTrue);
    expect(s.matchesTag(ScenarioTag.tier2Only), isFalse);
  });
}
