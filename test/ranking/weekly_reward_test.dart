import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/ranking/weekly_reward_result.dart';

void main() {
  group('WeeklyRewardResult.forPosition', () {
    test('1º → 10 vidas + 10 desfazer + 10 bomba3', () {
      final r = WeeklyRewardResult.forPosition(1, weekId: '2026-W19');
      expect(r.lives, 10);
      expect(r.undo1, 10);
      expect(r.bomb3, 10);
      expect(r.bomb2, 0);
      expect(r.hasReward, true);
    });

    test('2º → 5 vidas + 5 desfazer + 5 bomba3', () {
      final r = WeeklyRewardResult.forPosition(2, weekId: '2026-W19');
      expect(r.lives, 5);
      expect(r.undo1, 5);
      expect(r.bomb3, 5);
      expect(r.bomb2, 0);
    });

    test('3º → 3 vidas + 3 desfazer + 3 bomba3', () {
      final r = WeeklyRewardResult.forPosition(3, weekId: '2026-W19');
      expect(r.lives, 3);
      expect(r.undo1, 3);
      expect(r.bomb3, 3);
      expect(r.bomb2, 0);
    });

    test('4º → 3 vidas + 0 desfazer + 3 bomba3', () {
      final r = WeeklyRewardResult.forPosition(4, weekId: '2026-W19');
      expect(r.lives, 3);
      expect(r.undo1, 0);
      expect(r.bomb3, 3);
      expect(r.bomb2, 0);
    });

    test('5º → 3 vidas + 0 desfazer + 3 bomba3', () {
      final r = WeeklyRewardResult.forPosition(5, weekId: '2026-W19');
      expect(r.lives, 3);
      expect(r.undo1, 0);
      expect(r.bomb3, 3);
    });

    test('6º → 3 vidas + 0 desfazer + 3 bomba3', () {
      final r = WeeklyRewardResult.forPosition(6, weekId: '2026-W19');
      expect(r.lives, 3);
      expect(r.undo1, 0);
      expect(r.bomb3, 3);
    });

    test('7º → 3 vidas + 3 desfazer + 0 bomba', () {
      final r = WeeklyRewardResult.forPosition(7, weekId: '2026-W19');
      expect(r.lives, 3);
      expect(r.undo1, 3);
      expect(r.bomb3, 0);
      expect(r.bomb2, 0);
    });

    test('8º → 3 vidas + 3 desfazer + 0 bomba', () {
      final r = WeeklyRewardResult.forPosition(8, weekId: '2026-W19');
      expect(r.lives, 3);
      expect(r.undo1, 3);
      expect(r.bomb3, 0);
    });

    test('9º → 3 vidas + 3 desfazer + 0 bomba', () {
      final r = WeeklyRewardResult.forPosition(9, weekId: '2026-W19');
      expect(r.lives, 3);
      expect(r.undo1, 3);
      expect(r.bomb3, 0);
    });

    test('10º → 3 vidas + 0 desfazer + 0 bomba', () {
      final r = WeeklyRewardResult.forPosition(10, weekId: '2026-W19');
      expect(r.lives, 3);
      expect(r.undo1, 0);
      expect(r.bomb3, 0);
      expect(r.hasReward, true);
    });

    test('11º → sem recompensa', () {
      final r = WeeklyRewardResult.forPosition(11, weekId: '2026-W19');
      expect(r.hasReward, false);
    });

    test('50º → sem recompensa', () {
      final r = WeeklyRewardResult.forPosition(50, weekId: '2026-W19');
      expect(r.hasReward, false);
    });
  });
}
