import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/lives_state.dart';
import '../../data/repositories/lives_repository.dart';

class LivesNotifier extends StateNotifier<LivesState> {
  static const _migrationKeyV235 = 'lives_reset_v235';
  static const _migrationKeyV238 = 'lives_reset_v238';

  final LivesRepository _repo;
  final _ready = Completer<void>();

  LivesNotifier(this._repo) : super(LivesState.initial()) {
    _init();
  }

  Future<void> _init() async {
    // Migration v238: reset to initial (new schema with regenCap/earnedCap)
    final hasResetV238 = await _repo.getMigrationFlag(_migrationKeyV238);
    if (!hasResetV238) {
      final fresh = LivesState.initial();
      await _repo.save(fresh);
      await _repo.setMigrationFlag(_migrationKeyV238);
      state = fresh;
      _ready.complete();
      return;
    }

    var loaded = await _repo.load();
    loaded = calcRegen(state: loaded, now: DateTime.now());
    state = loaded;
    await _repo.save(state);
    _ready.complete();
  }

  static LivesState calcRegen({required LivesState state, required DateTime now}) {
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
    return state.copyWith(lives: state.lives - 1);
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

  Future<void> consume() async {
    await _ready.future;
    state = applyConsume(state);
    await _repo.save(state);
  }

  Future<void> addEarned(int amount) async {
    await _ready.future;
    state = applyAddEarned(state, amount);
    await _repo.save(state);
  }

  Future<void> addPurchased(int amount) async {
    await _ready.future;
    state = applyAddPurchased(state, amount);
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
