import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/daily_rewards_state.dart';
import 'package:capivara_2048/domain/daily_rewards/daily_rewards_notifier.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';

Future<void> _bootToHome(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

// ─── daily.streak_increments ─────────────────────────────────────────────────

final dailyStreakIncrementsScenario = E2EScenario(
  id: 'daily.streak_increments',
  title: 'coletar dia 1 → currentDay avança para 2',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    // Force claimable state: day 1, never claimed.
    harness.container.read(dailyRewardsProvider.notifier).debugSetState(
      DailyRewardsState(
        currentDay: 1,
        lastClaimedDate: DateTime(1970),
        claimedThisCycle: false,
      ),
    );

    // claim() is async (writes to Hive, reads inventory) — run in real async zone.
    await tester.runAsync(() =>
        harness.container.read(dailyRewardsProvider.notifier).claim(DateTime.now()));
    await tester.pump(const Duration(milliseconds: 300));

    // applyClaim: nextDay = currentDay < 7 ? currentDay + 1 : 7 = 2.
    expect(
      harness.container.read(dailyRewardsProvider).currentDay,
      equals(2),
      reason: 'após claim do dia 1, currentDay deve avançar de 1 para 2',
    );
  },
);

// ─── daily.cycle_resets_after_streak_break ───────────────────────────────────

final dailyCycleResetsScenario = E2EScenario(
  id: 'daily.cycle_resets_after_streak_break',
  title: 'streak quebrado (3 dias sem coletar) → claim → currentDay reseta e avança para 2',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    // gap=3 ≥ 2 AND claimedThisCycle=true → computeDailyRewardStatus returns streakBroken.
    // (claimedThisCycle=false would return 'available' before the gap check, skipping reset)
    harness.container.read(dailyRewardsProvider.notifier).debugSetState(
      DailyRewardsState(
        currentDay: 4,
        lastClaimedDate: DateTime.now().subtract(const Duration(days: 3)),
        claimedThisCycle: true,
      ),
    );

    await tester.runAsync(() =>
        harness.container.read(dailyRewardsProvider.notifier).claim(DateTime.now()));
    await tester.pump(const Duration(milliseconds: 300));

    // streakBroken path: applyStreakReset(→ currentDay=1) then applyClaim(→ currentDay=2).
    expect(
      harness.container.read(dailyRewardsProvider).currentDay,
      equals(2),
      reason:
          'streak quebrado → applyStreakReset (day=1) + applyClaim (day=2)',
    );
  },
);
