// lib/core/utils/age_check.dart
//
// Pure age helpers — no Flutter dependency, unit-testable.

/// True se [birth] garante pelo menos 12 anos completos em [now].
bool isAtLeast12(DateTime birth, DateTime now) {
  final twelfthBirthday = DateTime(birth.year + 12, birth.month, birth.day);
  return !now.isBefore(twelfthBirthday);
}

/// Número de dias no [month] (1–12) de [year], tratando ano bissexto.
/// O dia 0 do mês seguinte é o último dia deste mês.
int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
