import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/lives_state.dart';

void main() {
  group('LivesState', () {
    test('copyWith preserves nullable sync fields', () {
      final state = LivesState(
        lives: 3,
        maxLives: 5,
        lastRegenAt: DateTime(2026, 1, 1, 10, 0),
        adWatchedToday: 0,
        adCounterResetAt: DateTime(2026, 1, 2, 0, 0),
        userId: null,
        lastSyncedAt: null,
      );
      final copy = state.copyWith(lives: 4);
      expect(copy.userId, isNull);
      expect(copy.lastSyncedAt, isNull);
      expect(copy.lives, 4);
      expect(copy.maxLives, 5);
    });

    test('lastRegenAt advances by exact gained * 30min on copyWith', () {
      final base = DateTime(2026, 1, 1, 10, 0);
      final state = LivesState(
        lives: 1,
        maxLives: 5,
        lastRegenAt: base,
        adWatchedToday: 0,
        adCounterResetAt: DateTime(2026, 1, 2),
      );
      final newLastRegen = base.add(const Duration(minutes: 60));
      final updated = state.copyWith(lives: 3, lastRegenAt: newLastRegen);
      expect(updated.lastRegenAt, base.add(const Duration(minutes: 60)));
    });
  });
}
