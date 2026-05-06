/// Deterministic ISO week identifier for the global ranking system.
///
/// Reset boundary: every Saturday at 21:00 UTC (= Saturday 18:00 BRT).
/// Format: "yyyy-Www" (e.g., "2025-W19").
class WeekId {
  WeekId._();

  static const int _resetDayOfWeek = DateTime.saturday; // 6
  static const int _resetHourUtc = 21;

  /// Returns the week identifier for the given UTC instant.
  static String fromUtc(DateTime now) {
    if (!now.isUtc) throw ArgumentError('now must be UTC');
    final start = weekStartsAt(now);
    // Advance 27 h to land on Monday 00:00 UTC — use as ISO week anchor.
    final anchor = start.add(const Duration(hours: 27));
    final (:year, :week) = _isoWeekComponents(anchor);
    return '$year-W${week.toString().padLeft(2, '0')}';
  }

  /// Returns the next Saturday 21:00 UTC that closes the current period.
  static DateTime weekEndsAt(DateTime now) {
    if (!now.isUtc) throw ArgumentError('now must be UTC');
    return weekStartsAt(now).add(const Duration(days: 7));
  }

  /// Returns the most recent Saturday 21:00 UTC that opened the current period.
  static DateTime weekStartsAt(DateTime now) {
    if (!now.isUtc) throw ArgumentError('now must be UTC');
    // Dart weekday: Mon=1 … Sat=6, Sun=7.
    // Days to subtract to reach the preceding (or current) Saturday.
    final int daysBack = (now.weekday - _resetDayOfWeek + 7) % 7;
    final satDay = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysBack));
    final candidate = DateTime.utc(
      satDay.year,
      satDay.month,
      satDay.day,
      _resetHourUtc,
      0,
    );
    // If the Saturday reset hasn't happened yet today, step back one full week.
    if (candidate.isAfter(now)) {
      return candidate.subtract(const Duration(days: 7));
    }
    return candidate;
  }

  // ── ISO 8601 helpers ──────────────────────────────────────────────────────

  /// Returns the ISO week year and week number for [date].
  static ({int year, int week}) _isoWeekComponents(DateTime date) {
    final doy = date.difference(DateTime.utc(date.year, 1, 1)).inDays + 1;
    final wd = date.weekday; // Mon=1
    final w = ((doy - wd + 10) / 7).floor();
    if (w < 1) return (year: date.year - 1, week: _isoWeeksInYear(date.year - 1));
    if (w > _isoWeeksInYear(date.year)) return (year: date.year + 1, week: 1);
    return (year: date.year, week: w);
  }

  /// A year has 53 ISO weeks iff Jan 1 or Dec 31 falls on Thursday.
  static int _isoWeeksInYear(int year) {
    final jan1wd = DateTime.utc(year, 1, 1).weekday;
    final dec31wd = DateTime.utc(year, 12, 31).weekday;
    return (jan1wd == DateTime.thursday || dec31wd == DateTime.thursday)
        ? 53
        : 52;
  }
}
