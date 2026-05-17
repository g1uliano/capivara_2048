import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/performance/performance_settings.dart';
import 'settings_notifier.dart'; // exports sharedPreferencesProvider

class PerformanceSettingsNotifier extends Notifier<PerformanceSettings> {
  static const _key = 'performance_settings';

  @override
  PerformanceSettings build() => const PerformanceSettings();

  Future<void> load() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      state = PerformanceSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> enable() async {
    state = state.copyWith(
      enabled: true,
      hasShownSuggestionDialog: true,
      tileQuality: TileQuality.simple,
      blurEffectsEnabled: false,
      animationsEnabled: false,
    );
    await _save();
  }

  Future<void> disable() async {
    state = state.copyWith(
      enabled: false,
      tileQuality: TileQuality.full,
      blurEffectsEnabled: true,
      animationsEnabled: true,
    );
    await _save();
  }

  Future<void> markDialogShown() async {
    state = state.copyWith(hasShownSuggestionDialog: true);
    await _save();
  }

  Future<void> setTileQuality(TileQuality quality) async {
    state = state.copyWith(tileQuality: quality);
    await _save();
  }

  Future<void> setBlurEffects(bool value) async {
    state = state.copyWith(blurEffectsEnabled: value);
    await _save();
  }

  Future<void> setAnimations(bool value) async {
    state = state.copyWith(animationsEnabled: value);
    await _save();
  }

  Future<void> setAutoDetect(bool value) async {
    state = state.copyWith(autoDetectEnabled: value);
    await _save();
  }
}

final performanceSettingsProvider =
    NotifierProvider<PerformanceSettingsNotifier, PerformanceSettings>(
      PerformanceSettingsNotifier.new,
    );
