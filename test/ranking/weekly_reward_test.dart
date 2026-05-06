import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/ranking/weekly_reward_result.dart';

void main() {
  group('WeeklyRewardResult.forPosition', () {
    test('position 1 → lives=5, bomb3=3, bomb2=0, undo1=3', () {
      final r = WeeklyRewardResult.forPosition(1, weekId: '2025-W19');
      expect(r.lives, 5);
      expect(r.bomb3, 3);
      expect(r.bomb2, 0);
      expect(r.undo1, 3);
      expect(r.hasReward, true);
      expect(r.weekId, '2025-W19');
    });

    test('position 2 → lives=4, bomb3=2, bomb2=0, undo1=2', () {
      final r = WeeklyRewardResult.forPosition(2, weekId: '2025-W19');
      expect(r.lives, 4);
      expect(r.bomb3, 2);
      expect(r.bomb2, 0);
      expect(r.undo1, 2);
      expect(r.hasReward, true);
    });

    test('position 3 → lives=3, bomb3=0, bomb2=2, undo1=1', () {
      final r = WeeklyRewardResult.forPosition(3, weekId: '2025-W19');
      expect(r.lives, 3);
      expect(r.bomb3, 0);
      expect(r.bomb2, 2);
      expect(r.undo1, 1);
      expect(r.hasReward, true);
    });

    test('position 4 → lives=2, bomb2=1', () {
      final r = WeeklyRewardResult.forPosition(4, weekId: '2025-W19');
      expect(r.lives, 2);
      expect(r.bomb2, 1);
      expect(r.bomb3, 0);
      expect(r.undo1, 0);
      expect(r.hasReward, true);
    });

    test('position 10 → lives=2, bomb2=1', () {
      final r = WeeklyRewardResult.forPosition(10, weekId: '2025-W19');
      expect(r.lives, 2);
      expect(r.bomb2, 1);
      expect(r.hasReward, true);
    });

    test('position 11 → lives=1, bomb2=0, bomb3=0', () {
      final r = WeeklyRewardResult.forPosition(11, weekId: '2025-W19');
      expect(r.lives, 1);
      expect(r.bomb2, 0);
      expect(r.bomb3, 0);
      expect(r.hasReward, true);
    });

    test('position 50 → lives=1', () {
      final r = WeeklyRewardResult.forPosition(50, weekId: '2025-W19');
      expect(r.lives, 1);
      expect(r.hasReward, true);
    });

    test('position 51 → hasReward == false', () {
      final r = WeeklyRewardResult.forPosition(51, weekId: '2025-W19');
      expect(r.hasReward, false);
    });

    test('position 0 → hasReward == false', () {
      final r = WeeklyRewardResult.forPosition(0, weekId: '2025-W19');
      expect(r.hasReward, false);
    });
  });

  group('WeeklyRewardResult constructor', () {
    test('position=100 with all defaults → hasReward == false', () {
      const r = WeeklyRewardResult(position: 100, weekId: 'x');
      expect(r.hasReward, false);
    });

    test('position=1, lives=5 → hasReward == true', () {
      const r = WeeklyRewardResult(position: 1, weekId: 'x', lives: 5);
      expect(r.hasReward, true);
    });
  });

  group('WeeklyRewardResult.copyWith', () {
    test('copies with updated field', () {
      const r = WeeklyRewardResult(
        position: 1,
        weekId: 'x',
        lives: 5,
        bomb3: 3,
      );
      final r2 = r.copyWith(lives: 10);
      expect(r2.lives, 10);
      expect(r2.bomb3, 3);
      expect(r2.position, 1);
      expect(r2.weekId, 'x');
    });

    test('unchanged original after copyWith', () {
      const r = WeeklyRewardResult(position: 2, weekId: 'y', lives: 4);
      r.copyWith(lives: 0);
      expect(r.lives, 4);
    });
  });
}
