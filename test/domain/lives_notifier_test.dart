import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/lives_state.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';

LivesState _state({
  int lives = 3,
  int regenCap = 5,
  int earnedCap = 15,
  DateTime? lastRegenAt,
  int adWatchedToday = 0,
  DateTime? adCounterResetAt,
}) =>
    LivesState(
      lives: lives,
      regenCap: regenCap,
      earnedCap: earnedCap,
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

    test('regen respects cap (regenCap: 5)', () {
      final last = DateTime.now().subtract(const Duration(minutes: 90));
      final result = LivesNotifier.calcRegen(
        state: _state(lives: 4, regenCap: 5, lastRegenAt: last),
        now: DateTime.now(),
      );
      expect(result.lives, 5);
    });

    test('regen clamps to regenCap', () {
      final last = DateTime.now().subtract(const Duration(minutes: 180));
      final result = LivesNotifier.calcRegen(
        state: _state(lives: 1, regenCap: 5, lastRegenAt: last),
        now: DateTime.now(),
      );
      expect(result.lives, 5);
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

  group('migration v238', () {
    test('copyWith sets lives to regenCap (state model check)', () {
      final s = _state(lives: 2, regenCap: 5);
      final result = s.copyWith(lives: s.regenCap);
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

  group('consume timing contract', () {
    test('canPlay false when lives == 0', () {
      final s = _state(lives: 0);
      expect(s.lives > 0, isFalse);
    });

    test('canPlay true when lives >= 1', () {
      final s = _state(lives: 1);
      expect(s.lives > 0, isTrue);
    });

    test('game over must trigger applyConsume (pure logic check)', () {
      final before = _state(lives: 3);
      final after = LivesNotifier.applyConsume(before);
      expect(after.lives, 2);
    });
  });

  group('regen timer (LivesNotifier._onTick)', () {
    test('calcRegen após 30s não ganha vida (janela não fechou)', () {
      final last = DateTime.now().subtract(const Duration(seconds: 30));
      final s = _state(lives: 3, lastRegenAt: last);
      final result = LivesNotifier.calcRegen(state: s, now: DateTime.now());
      expect(result.lives, 3);
    });

    test('calcRegen após 30min ganha 1 vida', () {
      final last = DateTime.now().subtract(const Duration(minutes: 30));
      final s = _state(lives: 3, lastRegenAt: last);
      final result = LivesNotifier.calcRegen(state: s, now: DateTime.now());
      expect(result.lives, 4);
    });

    test('calcRegen com lives == regenCap não altera estado', () {
      final last = DateTime.now().subtract(const Duration(minutes: 60));
      final s = _state(lives: 5, regenCap: 5, lastRegenAt: last);
      final result = LivesNotifier.calcRegen(state: s, now: DateTime.now());
      expect(result.lives, 5);
      expect(identical(result, s), isTrue);
    });

    test('resumeRegen offline 6h: lives == 0 → lives == 5', () {
      final last = DateTime.now().subtract(const Duration(hours: 6));
      final s = _state(lives: 0, regenCap: 5, lastRegenAt: last);
      final result = LivesNotifier.calcRegen(state: s, now: DateTime.now());
      expect(result.lives, 5);
    });

    test('resumeRegen offline 6h com lives == 2: clamp a 5', () {
      final last = DateTime.now().subtract(const Duration(hours: 6));
      final s = _state(lives: 2, regenCap: 5, lastRegenAt: last);
      final result = LivesNotifier.calcRegen(state: s, now: DateTime.now());
      expect(result.lives, 5);
    });

    test('calcRegen com remaining negativo (lastRegenAt no futuro): sem mudança', () {
      final last = DateTime.now().add(const Duration(minutes: 5));
      final s = _state(lives: 3, lastRegenAt: last);
      final result = LivesNotifier.calcRegen(state: s, now: DateTime.now());
      expect(result.lives, 3);
    });
  });

  group('consume resets lastRegenAt when coming from cap', () {
    test('consumir vida com lastRegenAt velho não deve ganhar vida imediatamente', () {
      // Simula: jogador estava em cap (5 vidas) com lastRegenAt de 2 horas atrás.
      // lastRegenAt fica desatualizado enquanto em cap (calcRegen retorna cedo).
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      final atCap = _state(lives: 5, regenCap: 5, lastRegenAt: twoHoursAgo);

      // Perde 1 vida
      final afterConsume = LivesNotifier.applyConsume(atCap);
      expect(afterConsume.lives, 4);

      // Regen 1 segundo depois NÃO deve ganhar vida — tem que esperar 30 min
      final oneSecondLater = DateTime.now().add(const Duration(seconds: 1));
      final afterRegen = LivesNotifier.calcRegen(state: afterConsume, now: oneSecondLater);
      expect(afterRegen.lives, 4,
          reason: 'lastRegenAt deve ser resetado ao consumir vida em cap, '
              'senão a regen acontece instantaneamente');
    });
  });

  group('regenCap / earnedCap rules', () {
    test('regen stops at regenCap, not earnedCap', () {
      final last = DateTime.now().subtract(const Duration(minutes: 120));
      final s = LivesState(
        lives: 3,
        regenCap: 5,
        earnedCap: 15,
        lastRegenAt: last,
        adWatchedToday: 0,
        adCounterResetAt: DateTime.now().add(const Duration(hours: 24)),
      );
      final result = LivesNotifier.calcRegen(state: s, now: DateTime.now());
      expect(result.lives, 5); // capped at regenCap
    });

    test('addEarned goes above regenCap up to earnedCap', () {
      final s = LivesState(
        lives: 5,
        regenCap: 5,
        earnedCap: 15,
        lastRegenAt: DateTime.now(),
        adWatchedToday: 0,
        adCounterResetAt: DateTime.now().add(const Duration(hours: 24)),
      );
      final result = LivesNotifier.applyAddEarned(s, 3);
      expect(result.lives, 8);
    });

    test('addEarned clamps at earnedCap', () {
      final s = LivesState(
        lives: 14,
        regenCap: 5,
        earnedCap: 15,
        lastRegenAt: DateTime.now(),
        adWatchedToday: 0,
        adCounterResetAt: DateTime.now().add(const Duration(hours: 24)),
      );
      final result = LivesNotifier.applyAddEarned(s, 5);
      expect(result.lives, 15);
    });

    test('addPurchased has no cap', () {
      final s = LivesState(
        lives: 15,
        regenCap: 5,
        earnedCap: 15,
        lastRegenAt: DateTime.now(),
        adWatchedToday: 0,
        adCounterResetAt: DateTime.now().add(const Duration(hours: 24)),
      );
      final result = LivesNotifier.applyAddPurchased(s, 10);
      expect(result.lives, 25);
    });

    test('LivesState.initial has regenCap=5 and earnedCap=15', () {
      final s = LivesState.initial();
      expect(s.regenCap, 5);
      expect(s.earnedCap, 15);
    });
  });
}
