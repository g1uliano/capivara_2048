import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReduceEffectsNotifier extends StateNotifier<bool> {
  ReduceEffectsNotifier() : super(false);

  static const _key = 'reduce_effects';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

final reduceEffectsProvider =
    StateNotifierProvider<ReduceEffectsNotifier, bool>(
  (ref) => ReduceEffectsNotifier(),
);
