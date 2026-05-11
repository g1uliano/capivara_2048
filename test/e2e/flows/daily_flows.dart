import 'package:flutter/material.dart';
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

// Navigate to DailyRewardsScreen without pumpAndSettle (screen has Timer.periodic).
Future<void> _navToDailyRewards(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home_btn_recompensas')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void _setLargeScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
}

// ─── flow.daily_reward_claim ─────────────────────────────────────────────────

final dailyRewardClaimScenario = E2EScenario(
  id: 'flow.daily_reward_claim',
  title: 'recompensa disponível → badge "!" na home → coletar → currentDay avança',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    _setLargeScreen(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _bootToHome(tester, harness);

    // Day 1 reward: lives=0, undo1=1, bomb2=0 — no discard dialog.
    harness.container.read(dailyRewardsProvider.notifier).debugSetState(
      DailyRewardsState(
        currentDay: 1,
        lastClaimedDate: DateTime(1970),
        claimedThisCycle: false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Badge '!' should be visible on HomeScreen.
    expect(find.text('!'), findsOneWidget);

    // Navigate manually — DailyRewardsScreen has Timer.periodic, pumpAndSettle hangs.
    await _navToDailyRewards(tester);

    // Coletar button should be visible (status == available).
    expect(find.text('Coletar recompensa'), findsOneWidget);

    // Tap Coletar — triggers _onClaim → async claim() call.
    await tester.tap(find.text('Coletar recompensa'));
    await tester.pump();

    // Use runAsync to let the Hive write (and inventory add) complete in real time.
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // After claiming Day 1: currentDay advances from 1 → 2.
    // (claimedThisCycle stays false because nextDay != currentDay for day 1–6)
    final state = harness.container.read(dailyRewardsProvider);
    expect(state.currentDay, equals(2),
        reason: 'após coletar, currentDay deve avançar de 1 para 2');
  },
);

// ─── flow.daily_reward_locked_same_day ───────────────────────────────────────

final dailyRewardLockedSameDayScenario = E2EScenario(
  id: 'flow.daily_reward_locked_same_day',
  title: 'recompensa já coletada hoje → badge "!" ausente + sem botão Coletar',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    _setLargeScreen(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _bootToHome(tester, harness);

    // lastClaimedDate = DateTime.now() → today.isBefore(last) is true (midnight < now) → alreadyClaimed.
    harness.container.read(dailyRewardsProvider.notifier).debugSetState(
      DailyRewardsState(
        currentDay: 1,
        lastClaimedDate: DateTime.now(),
        claimedThisCycle: true,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Badge '!' should NOT be visible.
    expect(find.text('!'), findsNothing);

    // Navigate to DailyRewardsScreen.
    await _navToDailyRewards(tester);

    // No claim button (status == alreadyClaimed → claimable == false).
    expect(find.text('Coletar'), findsNothing);
    expect(find.text('Iniciar novo ciclo'), findsNothing);

    // State remains locked.
    expect(harness.container.read(dailyRewardsProvider).claimedThisCycle, isTrue);
  },
);
