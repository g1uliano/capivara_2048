// test/domain/daily_rewards_engine_test.dart
import 'package:capivara_2048/data/models/daily_rewards_state.dart';
import 'package:capivara_2048/domain/daily_rewards/daily_rewards_engine.dart';
import 'package:flutter_test/flutter_test.dart';

DailyRewardsState _state({
  int currentDay = 1,
  DateTime? lastClaimedDate,
  bool claimedThisCycle = false,
}) =>
    DailyRewardsState(
      currentDay: currentDay,
      lastClaimedDate: lastClaimedDate ?? DateTime(1970),
      claimedThisCycle: claimedThisCycle,
    );

DateTime day(int d) => DateTime(2026, 5, d);

void main() {
  group('computeDailyRewardStatus', () {
    test('1: nunca coletou → available', () {
      final s = DailyRewardsState.initial();
      expect(computeDailyRewardStatus(day(1), s), DailyRewardStatus.available);
    });

    test('2: coletou hoje (gap=0) → alreadyClaimed', () {
      final s = _state(
        currentDay: 2,
        lastClaimedDate: day(5),
        claimedThisCycle: true,
      );
      expect(computeDailyRewardStatus(day(5), s), DailyRewardStatus.alreadyClaimed);
    });

    test('3: coletou ontem, dia 1–6 → available', () {
      final s = _state(
        currentDay: 3,
        lastClaimedDate: day(4),
        claimedThisCycle: true,
      );
      expect(computeDailyRewardStatus(day(5), s), DailyRewardStatus.available);
    });

    test('4: coletou Dia 7 ontem (gap=1) → cycleCompleted', () {
      final s = _state(
        currentDay: 7,
        lastClaimedDate: day(7),
        claimedThisCycle: true,
      );
      expect(computeDailyRewardStatus(day(8), s), DailyRewardStatus.cycleCompleted);
    });

    test('5: gap=2 → streakBroken', () {
      final s = _state(
        currentDay: 3,
        lastClaimedDate: day(3),
        claimedThisCycle: true,
      );
      expect(computeDailyRewardStatus(day(5), s), DailyRewardStatus.streakBroken);
    });

    test('6: gap=10 → streakBroken', () {
      final s = _state(
        currentDay: 2,
        lastClaimedDate: day(1),
        claimedThisCycle: true,
      );
      expect(computeDailyRewardStatus(day(11), s), DailyRewardStatus.streakBroken);
    });

    test('7: relógio retrocedeu (now < last) → alreadyClaimed', () {
      final s = _state(
        currentDay: 2,
        lastClaimedDate: day(10),
        claimedThisCycle: true,
      );
      expect(computeDailyRewardStatus(day(9), s), DailyRewardStatus.alreadyClaimed);
    });

    test('8: meia-noite — coletou dia anterior, abre dia seguinte → available', () {
      final s = _state(
        currentDay: 4,
        lastClaimedDate: day(4),
        claimedThisCycle: true,
      );
      expect(computeDailyRewardStatus(day(5), s), DailyRewardStatus.available);
    });

    test('9: 7 dias consecutivos — Dia 8 cycleCompleted, Dia 9 streakBroken', () {
      var s = DailyRewardsState.initial();
      for (int d = 1; d <= 7; d++) {
        expect(computeDailyRewardStatus(day(d), s), DailyRewardStatus.available);
        s = applyClaim(day(d), s);
      }
      expect(computeDailyRewardStatus(day(8), s), DailyRewardStatus.cycleCompleted);
      expect(computeDailyRewardStatus(day(9), s), DailyRewardStatus.streakBroken);
    });
  });

  group('applyStreakReset', () {
    test('10: reset retorna currentDay=1, claimedThisCycle=false', () {
      final s = _state(currentDay: 5, claimedThisCycle: true, lastClaimedDate: day(3));
      final result = applyStreakReset(s);
      expect(result.currentDay, 1);
      expect(result.claimedThisCycle, false);
      expect(result.lastClaimedDate, day(3)); // lastClaimedDate não muda
    });
  });

  group('applyClaim', () {
    test('11: applyClaim Dia 6 avança para Dia 7', () {
      final s = _state(currentDay: 6, lastClaimedDate: day(3), claimedThisCycle: false);
      final result = applyClaim(day(4), s);
      expect(result.currentDay, 7);
      expect(result.claimedThisCycle, false); // advanced to new slot, not yet claimed
      expect(result.lastClaimedDate, day(4));
    });

    test('12: applyClaim Dia 7 permanece em 7', () {
      final s = _state(currentDay: 7, lastClaimedDate: day(6), claimedThisCycle: false);
      final result = applyClaim(day(7), s);
      expect(result.currentDay, 7);
      expect(result.claimedThisCycle, true);
      expect(result.lastClaimedDate, day(7));
    });
  });

  group('rewardForDay', () {
    test('Dia 1: 1x undo1', () {
      final r = rewardForDay(1);
      expect(r.undo1, 1);
      expect(r.bomb2, 0);
      expect(r.lives, 0);
    });

    test('Dia 7: combo completo', () {
      final r = rewardForDay(7);
      expect(r.undo1, 2);
      expect(r.bomb2, 2);
      expect(r.lives, 2);
    });
  });
}
