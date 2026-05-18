import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/models/lives_state.dart';
import '../../data/repositories/lives_repository.dart';

class LivesNotifier extends Notifier<LivesState> {
  static const _migrationKeyV238 = 'lives_reset_v238';

  final _ready = Completer<void>();
  Timer? _regenTimer;
  StreamSubscription<BoxEvent>? _boxSub;
  AppLifecycleListener? _lifecycleListener;

  @override
  LivesState build() {
    ref.onDispose(() {
      _regenTimer?.cancel();
      _boxSub?.cancel();
      _lifecycleListener?.dispose();
    });
    unawaited(_init());
    return LivesState.initial();
  }

  Future<void> _init() async {
    // Migration v238: reset to initial (new schema with regenCap/earnedCap)
    final hasResetV238 = await ref
        .read(livesRepositoryProvider)
        .getMigrationFlag(_migrationKeyV238);
    if (!hasResetV238) {
      final fresh = LivesState.initial();
      await ref.read(livesRepositoryProvider).save(fresh);
      await ref
          .read(livesRepositoryProvider)
          .setMigrationFlag(_migrationKeyV238);
      state = fresh;
      // runZonedGuarded absorbs orphaned Hive-internal Future rejections
      // that escape try-catch when Hive is not initialized (e.g. in tests).
      Box<LivesState>? migBox;
      await runZonedGuarded<Future<void>>(() async {
        migBox = await Hive.openBox<LivesState>('lives');
      }, (_, _) {});
      if (migBox != null) {
        await _boxSub?.cancel();
        _boxSub = migBox!
            .watch(key: 'state')
            .listen(
              (event) {
                final updated = event.value as LivesState?;
                if (updated != null) {
                  state = updated;
                }
              },
              onError: (_) {},
              cancelOnError: false,
            );
      }
      // Complete _ready only after Hive box subscription is set up.
      if (!_ready.isCompleted) _ready.complete();
      return;
    }

    var loaded = await ref.read(livesRepositoryProvider).load();
    loaded = calcRegen(state: loaded, now: DateTime.now());
    state = loaded;
    await ref.read(livesRepositoryProvider).save(state);
    _startRegenTimer();
    // runZonedGuarded absorbs orphaned Hive-internal Future rejections
    // that escape try-catch when Hive is not initialized (e.g. in tests).
    Box<LivesState>? box;
    await runZonedGuarded<Future<void>>(() async {
      box = await Hive.openBox<LivesState>('lives');
    }, (_, _) {});
    if (box != null) {
      await _boxSub?.cancel();
      _boxSub = box!
          .watch(key: 'state')
          .listen(
            (event) {
              final updated = event.value as LivesState?;
              if (updated != null) {
                state = updated;
                // Restart regen timer with the new state
                _startRegenTimer();
              }
            },
            onError: (_) {},
            cancelOnError: false,
          );
    }
    // Complete _ready only after Hive box subscription is set up.
    if (!_ready.isCompleted) _ready.complete();
    try {
      _lifecycleListener = AppLifecycleListener(
        onPause: _pauseRegen,
        onResume: _resumeRegen,
      );
    } catch (_) {
      // Flutter binding not available (e.g. plain unit tests) — skip lifecycle
    }
  }

  static LivesState calcRegen({
    required LivesState state,
    required DateTime now,
  }) {
    if (state.lives >= state.regenCap) return state;
    final delta = now.difference(state.lastRegenAt);
    final totalMinutes = delta.inMinutes;
    final gained = (totalMinutes ~/ 30).clamp(0, state.regenCap - state.lives);
    if (gained <= 0) return state;
    return state.copyWith(
      lives: state.lives + gained,
      lastRegenAt: state.lastRegenAt.add(Duration(minutes: gained * 30)),
    );
  }

  static LivesState applyConsume(LivesState state) {
    if (state.lives <= 0) return state;
    // If at or above regenCap, reset lastRegenAt so the 30-min countdown
    // starts from now instead of from a stale timestamp.
    final wasAtCap = state.lives >= state.regenCap;
    return state.copyWith(
      lives: state.lives - 1,
      lastRegenAt: wasAtCap ? DateTime.now() : state.lastRegenAt,
    );
  }

  static LivesState applyAddEarned(LivesState state, int amount) {
    final capped = (state.lives + amount).clamp(0, state.earnedCap);
    return state.copyWith(lives: capped);
  }

  static LivesState applyAddPurchased(LivesState state, int amount) {
    return state.copyWith(lives: state.lives + amount);
  }

  static bool canWatchAdFor(LivesState state) {
    final now = DateTime.now();
    if (now.isAfter(state.adCounterResetAt)) return true;
    return state.adWatchedToday < 40;
  }

  static LivesState applyAdReward(LivesState state) {
    final now = DateTime.now();
    LivesState s = state;
    if (now.isAfter(s.adCounterResetAt)) {
      s = s.copyWith(
        adWatchedToday: 0,
        adCounterResetAt: DateTime(now.year, now.month, now.day + 1),
      );
    }
    return applyAddEarned(s.copyWith(adWatchedToday: s.adWatchedToday + 1), 1);
  }

  static LivesState applyAdWatched(LivesState state) {
    final now = DateTime.now();
    LivesState s = state;
    if (now.isAfter(s.adCounterResetAt)) {
      s = s.copyWith(
        adWatchedToday: 0,
        adCounterResetAt: DateTime(now.year, now.month, now.day + 1),
      );
    }
    return s.copyWith(adWatchedToday: s.adWatchedToday + 1);
  }

  void _startRegenTimer() {
    _regenTimer?.cancel();
    _regenTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _onRegenTick(),
    );
  }

  void _onRegenTick() {
    final before = state.lives;
    final updated = calcRegen(state: state, now: DateTime.now());
    if (updated.lives != before) {
      state = updated;
      ref.read(livesRepositoryProvider).save(state);
    }
  }

  void _pauseRegen() {
    _regenTimer?.cancel();
    _regenTimer = null;
  }

  void _resumeRegen() {
    final updated = calcRegen(state: state, now: DateTime.now());
    if (updated.lives != state.lives) {
      state = updated;
      ref.read(livesRepositoryProvider).save(state);
    }
    _startRegenTimer();
  }

  Future<void> consume() async {
    await _ready.future;
    state = applyConsume(state);
    await ref.read(livesRepositoryProvider).save(state);
  }

  Future<void> addEarned(int amount) async {
    await _ready.future;
    state = applyAddEarned(state, amount);
    await ref.read(livesRepositoryProvider).save(state);
  }

  Future<void> addPurchased(int amount) async {
    await _ready.future;
    state = applyAddPurchased(state, amount);
    await ref.read(livesRepositoryProvider).save(state);
  }

  Future<void> rewardFromAd() async {
    await _ready.future;
    state = applyAdReward(state);
    await ref.read(livesRepositoryProvider).save(state);
  }

  Future<void> recordAdWatched() async {
    await _ready.future;
    state = applyAdWatched(state);
    await ref.read(livesRepositoryProvider).save(state);
  }

  bool get canWatchAd => canWatchAdFor(state);
  bool get canPlay => state.lives > 0;

  @visibleForTesting
  void debugSetLives(int n) {
    if (!kDebugMode) return;
    state = state.copyWith(lives: n.clamp(0, state.earnedCap));
  }

  @visibleForTesting
  void debugSetState(LivesState s) => state = s;

  /// Waits for [_init] to complete. Use in tests to synchronize before checking
  /// lives state or calling methods that depend on [_ready].
  @visibleForTesting
  Future<void> awaitReady() => _ready.future;
}

final livesRepositoryProvider = Provider((_) => LivesRepository());

final livesProvider = NotifierProvider<LivesNotifier, LivesState>(
  LivesNotifier.new,
);
