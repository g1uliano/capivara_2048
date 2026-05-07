import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReduceEffectsNotifier extends Notifier<bool> {
  static const _key = 'reduce_effects';

  @override
  bool build() => false;

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

final reduceEffectsProvider = NotifierProvider<ReduceEffectsNotifier, bool>(
  ReduceEffectsNotifier.new,
);
