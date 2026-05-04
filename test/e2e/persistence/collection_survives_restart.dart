import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/controllers/personal_records_notifier.dart';
import '../_harness/scenario.dart';

final collectionSurvivesRestartScenario = E2EScenario(
  id: 'persistence.collection_survives_restart',
  title: 'highestLevelEver persiste após cold restart (regressão v1.2.10)',
  tags: {ScenarioTag.critical, ScenarioTag.tier1Only},
  run: (tester, harness) async {
    // Initial boot.
    final widget = await tester.runAsync(() => harness.boot());
    await tester.pumpWidget(widget!);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Write level 8 to Hive via provider.
    await tester.runAsync(() =>
        harness.container.read(personalRecordsProvider.notifier).updateHighestLevel(8));
    expect(
      harness.container.read(personalRecordsProvider).highestLevelEver,
      8,
    );

    // Cold restart.
    final widget2 = await tester.runAsync(() => harness.restart());
    await tester.pumpWidget(widget2!);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(
      harness.container.read(personalRecordsProvider).highestLevelEver,
      8,
      reason: 'Coleção não pode resetar entre sessões (regressão v1.2.10)',
    );
  },
);
