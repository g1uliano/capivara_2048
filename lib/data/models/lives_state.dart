class LivesState {
  int lives;
  int maxLives;
  DateTime lastRegenAt;
  int adWatchedToday;
  DateTime adCounterResetAt;
  String? userId;
  DateTime? lastSyncedAt;

  LivesState({
    required this.lives,
    required this.maxLives,
    required this.lastRegenAt,
    required this.adWatchedToday,
    required this.adCounterResetAt,
    this.userId,
    this.lastSyncedAt,
  });

  LivesState copyWith({
    int? lives,
    int? maxLives,
    DateTime? lastRegenAt,
    int? adWatchedToday,
    DateTime? adCounterResetAt,
    String? userId,
    DateTime? lastSyncedAt,
  }) {
    return LivesState(
      lives: lives ?? this.lives,
      maxLives: maxLives ?? this.maxLives,
      lastRegenAt: lastRegenAt ?? this.lastRegenAt,
      adWatchedToday: adWatchedToday ?? this.adWatchedToday,
      adCounterResetAt: adCounterResetAt ?? this.adCounterResetAt,
      userId: userId ?? this.userId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  factory LivesState.initial() => LivesState(
        lives: 5,
        maxLives: 5,
        lastRegenAt: DateTime.now(),
        adWatchedToday: 0,
        adCounterResetAt: _nextMidnight(),
      );

  static DateTime _nextMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }
}
