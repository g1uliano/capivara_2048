class LivesState {
  final int lives;
  final int regenCap;
  final int earnedCap;
  final DateTime lastRegenAt;
  final int adWatchedToday;
  final DateTime adCounterResetAt;
  final String? userId;
  final DateTime? lastSyncedAt;

  const LivesState({
    required this.lives,
    required this.regenCap,
    required this.earnedCap,
    required this.lastRegenAt,
    required this.adWatchedToday,
    required this.adCounterResetAt,
    this.userId,
    this.lastSyncedAt,
  });

  static const _sentinel = Object();

  LivesState copyWith({
    int? lives,
    int? regenCap,
    int? earnedCap,
    DateTime? lastRegenAt,
    int? adWatchedToday,
    DateTime? adCounterResetAt,
    Object? userId = _sentinel,
    Object? lastSyncedAt = _sentinel,
  }) {
    return LivesState(
      lives: lives ?? this.lives,
      regenCap: regenCap ?? this.regenCap,
      earnedCap: earnedCap ?? this.earnedCap,
      lastRegenAt: lastRegenAt ?? this.lastRegenAt,
      adWatchedToday: adWatchedToday ?? this.adWatchedToday,
      adCounterResetAt: adCounterResetAt ?? this.adCounterResetAt,
      userId: identical(userId, _sentinel) ? this.userId : userId as String?,
      lastSyncedAt: identical(lastSyncedAt, _sentinel) ? this.lastSyncedAt : lastSyncedAt as DateTime?,
    );
  }

  factory LivesState.initial() => LivesState(
        lives: 5,
        regenCap: 5,
        earnedCap: 15,
        lastRegenAt: DateTime.now(),
        adWatchedToday: 0,
        adCounterResetAt: _nextMidnight(),
      );

  static DateTime _nextMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  bool get canPlay => lives > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LivesState &&
          runtimeType == other.runtimeType &&
          lives == other.lives &&
          regenCap == other.regenCap &&
          earnedCap == other.earnedCap &&
          lastRegenAt == other.lastRegenAt &&
          adWatchedToday == other.adWatchedToday &&
          adCounterResetAt == other.adCounterResetAt &&
          userId == other.userId &&
          lastSyncedAt == other.lastSyncedAt;

  @override
  int get hashCode => Object.hash(
        lives,
        regenCap,
        earnedCap,
        lastRegenAt,
        adWatchedToday,
        adCounterResetAt,
        userId,
        lastSyncedAt,
      );
}
