import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/ranking/week_id.dart';

void main() {
  group('WeekId', () {
    test('sexta-feira 23h UTC → mesmo weekId da semana corrente', () {
      // Reset é sábado 21h UTC. Sexta 23h UTC ainda é a semana corrente.
      final beforeReset = DateTime.utc(2025, 5, 9, 23, 0); // sex 9/5 23h UTC
      final id = WeekId.fromUtc(beforeReset);
      expect(id, '2025-W19');
    });

    test('sábado 22h UTC → novo weekId (após reset 21h UTC)', () {
      final afterReset = DateTime.utc(2025, 5, 10, 22, 0); // sáb 10/5 22h UTC
      final id = WeekId.fromUtc(afterReset);
      expect(id, '2025-W20');
    });

    test('sábado 21h UTC exato → novo weekId', () {
      final exactReset = DateTime.utc(2025, 5, 10, 21, 0);
      final id = WeekId.fromUtc(exactReset);
      expect(id, '2025-W20');
    });

    test('dois devices no mesmo instante produzem o mesmo weekId', () {
      final now = DateTime.utc(2025, 5, 7, 12, 0);
      expect(WeekId.fromUtc(now), WeekId.fromUtc(now));
    });

    test('weekEndsAt retorna sábado 21h UTC da semana corrente', () {
      final wednesday = DateTime.utc(2025, 5, 7, 12, 0);
      final endsAt = WeekId.weekEndsAt(wednesday);
      expect(endsAt, DateTime.utc(2025, 5, 10, 21, 0));
    });

    test('weekStartsAt retorna sábado 21h UTC anterior', () {
      final wednesday = DateTime.utc(2025, 5, 7, 12, 0);
      final startsAt = WeekId.weekStartsAt(wednesday);
      expect(startsAt, DateTime.utc(2025, 5, 3, 21, 0)); // sáb 3/5 21h UTC
    });

    test('quarta-feira qualquer → weekId correto', () {
      final wednesday = DateTime.utc(2025, 5, 7, 12, 0);
      final id = WeekId.fromUtc(wednesday);
      expect(id, '2025-W19');
    });

    test('ano-limite ISO: 29/12/2025 22h UTC → 2026-W01', () {
      // Dec 27, 2025 (Saturday) is the reset boundary.
      // Dec 29, 2025 (Monday) 22:00 UTC is after that reset.
      // ISO week: w=53 > 52 weeks in 2025 → rolls to 2026-W01.
      final d = DateTime.utc(2025, 12, 29, 22, 0);
      expect(WeekId.fromUtc(d), '2026-W01');
    });
  });
}
