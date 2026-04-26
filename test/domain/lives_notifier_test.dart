import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/lives_state.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';

LivesState _state({
  int lives = 3,
  int maxLives = 5,
  DateTime? lastRegenAt,
  int adWatchedToday = 0,
  DateTime? adCounterResetAt,
}) =>
    LivesState(
      lives: lives,
      maxLives: maxLives,
      lastRegenAt: lastRegenAt ?? DateTime.now(),
      adWatchedToday: adWatchedToday,
      adCounterResetAt: adCounterResetAt ?? DateTime.now().add(const Duration(hours: 24)),
    );

void main() {
  group('applyRegen', () {
    test('0 min elapsed → 0 lives gained', () {
      final now = DateTime.now();
      final result = LivesNotifier.calcRegen(
        state: _state(lives: 3, lastRegenAt: now),
        now: now,
      );
      expect(result.lives, 3);
    });

    test('30 min elapsed → +1 life', () {
      final last = DateTime.now().subtract(const Duration(minutes: 30));
      final result = LivesNotifier.calcRegen(
        state: _state(lives: 3, lastRegenAt: last),
        now: DateTime.now(),
      );
      expect(result.lives, 4);
    });

    test('75 min elapsed → +2 lives', () {
      final last = DateTime.now().subtract(const Duration(minutes: 75));
      final result = LivesNotifier.calcRegen(
        state: _state(lives: 2, lastRegenAt: last),
        now: DateTime.now(),
      );
      expect(result.lives, 4);
    });

    test('regen respects cap (maxLives: 5)', () {
      final last = DateTime.now().subtract(const Duration(minutes: 90));
      final result = LivesNotifier.calcRegen(
        state: _state(lives: 4, maxLives: 5, lastRegenAt: last),
        now: DateTime.now(),
      );
      expect(result.lives, 5);
    });

    test('regen no cap when maxLives == -1', () {
      final last = DateTime.now().subtract(const Duration(minutes: 120));
      final result = LivesNotifier.calcRegen(
        state: _state(lives: 8, maxLives: -1, lastRegenAt: last),
        now: DateTime.now(),
      );
      expect(result.lives, 12);
    });

    test('lastRegenAt advances by gained*30min, not total elapsed', () {
      final base = DateTime(2026, 1, 1, 10, 0);
      final now = base.add(const Duration(minutes: 75));
      final result = LivesNotifier.calcRegen(
        state: _state(lives: 1, lastRegenAt: base),
        now: now,
      );
      expect(result.lastRegenAt, base.add(const Duration(minutes: 60)));
    });
  });

  group('consume', () {
    test('decrements by 1', () {
      final s = _state(lives: 3);
      final result = LivesNotifier.applyConsume(s);
      expect(result.lives, 2);
    });

    test('does not go below 0', () {
      final s = _state(lives: 0);
      final result = LivesNotifier.applyConsume(s);
      expect(result.lives, 0);
    });

    test('applyConsume from 1 → 0', () {
      final s = _state(lives: 1);
      expect(LivesNotifier.applyConsume(s).lives, 0);
    });
  });

  group('migration v235', () {
    test('copyWith sets lives to maxLives (state model check)', () {
      final s = _state(lives: 2, maxLives: 5);
      final result = s.copyWith(lives: s.maxLives);
      expect(result.lives, 5);
    });
  });

  group('rewardFromAd', () {
    test('increments lives and adWatchedToday', () {
      final s = _state(lives: 2, adWatchedToday: 5);
      final result = LivesNotifier.applyAdReward(s);
      expect(result.lives, 3);
      expect(result.adWatchedToday, 6);
    });

    test('blocks when adWatchedToday >= 40', () {
      final s = _state(lives: 2, adWatchedToday: 40);
      expect(LivesNotifier.canWatchAdFor(s), isFalse);
    });

    test('adCounterResetAt in past → resets counter before reward', () {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      final s = _state(lives: 2, adWatchedToday: 39, adCounterResetAt: past);
      final result = LivesNotifier.applyAdReward(s);
      // counter was reset to 0 first, then incremented to 1
      expect(result.adWatchedToday, 1);
    });
  });
}
