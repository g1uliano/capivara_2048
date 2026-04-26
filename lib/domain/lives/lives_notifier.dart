import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/lives_state.dart';
import '../../data/repositories/lives_repository.dart';

class LivesNotifier extends StateNotifier<LivesState> {
  final LivesRepository _repo;
  final _ready = Completer<void>();

  LivesNotifier(this._repo) : super(LivesState.initial()) {
    _init();
  }

  Future<void> _init() async {
    var loaded = await _repo.load();
    loaded = calcRegen(state: loaded, now: DateTime.now());

    final hasReset = await _repo.getMigrationFlag('lives_reset_v235');
    if (!hasReset) {
      loaded = loaded.copyWith(lives: loaded.maxLives);
      await _repo.setMigrationFlag('lives_reset_v235');
    }

    state = loaded;
    await _repo.save(state);
    _ready.complete();
  }

  static LivesState calcRegen({required LivesState state, required DateTime now}) {
    final delta = now.difference(state.lastRegenAt);
    final totalMinutes = delta.inMinutes;
    final gained = state.maxLives == -1
        ? totalMinutes ~/ 30
        : (totalMinutes ~/ 30).clamp(0, state.maxLives - state.lives);
    if (gained == 0) return state;
    return state.copyWith(
      lives: state.lives + gained,
      lastRegenAt: state.lastRegenAt.add(Duration(minutes: gained * 30)),
    );
  }

  static LivesState applyConsume(LivesState state) {
    if (state.lives <= 0) return state;
    return state.copyWith(lives: state.lives - 1);
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
    return s.copyWith(
      lives: s.lives + 1,
      adWatchedToday: s.adWatchedToday + 1,
    );
  }

  Future<void> consume() async {
    await _ready.future;
    state = applyConsume(state);
    await _repo.save(state);
  }

  Future<void> rewardFromAd() async {
    await _ready.future;
    state = applyAdReward(state);
    await _repo.save(state);
  }

  bool get canWatchAd => canWatchAdFor(state);
  bool get canPlay => state.lives > 0;
}

final livesRepositoryProvider = Provider((_) => LivesRepository());

final livesProvider = StateNotifierProvider<LivesNotifier, LivesState>(
  (ref) => LivesNotifier(ref.read(livesRepositoryProvider)),
);
