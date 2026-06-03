import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/audio/audio_service.dart';

class SettingsState {
  final bool hapticEnabled;
  final String locale;
  final bool sfxEnabled;
  final double sfxVolume;

  const SettingsState({
    this.hapticEnabled = true,
    this.locale = 'pt',
    this.sfxEnabled = true,
    this.sfxVolume = 1.0,
  });

  SettingsState copyWith({
    bool? hapticEnabled,
    String? locale,
    bool? sfxEnabled,
    double? sfxVolume,
  }) => SettingsState(
    hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    locale: locale ?? this.locale,
    sfxEnabled: sfxEnabled ?? this.sfxEnabled,
    sfxVolume: sfxVolume ?? this.sfxVolume,
  );
}

/// Must be overridden in ProviderScope/ProviderContainer with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class SettingsNotifier extends Notifier<SettingsState> {
  static const _hapticKey = 'settings.haptic_enabled';
  static const _localeKey = 'settings.locale';
  static const _sfxEnabledKey = 'settings.sfx_enabled';
  static const _sfxVolumeKey = 'settings.sfx_volume';

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SettingsState(
      hapticEnabled: prefs.getBool(_hapticKey) ?? true,
      locale: prefs.getString(_localeKey) ?? 'pt',
      sfxEnabled: prefs.getBool(_sfxEnabledKey) ?? true,
      sfxVolume: prefs.getDouble(_sfxVolumeKey) ?? 1.0,
    );
  }

  void setHaptic(bool value) {
    ref.read(sharedPreferencesProvider).setBool(_hapticKey, value);
    state = state.copyWith(hapticEnabled: value);
  }

  void setLocale(String locale) {
    ref.read(sharedPreferencesProvider).setString(_localeKey, locale);
    state = state.copyWith(locale: locale);
  }

  void setSfxEnabled(bool value) {
    ref.read(sharedPreferencesProvider).setBool(_sfxEnabledKey, value);
    state = state.copyWith(sfxEnabled: value);
    ref.read(audioServiceProvider).setSfxEnabled(value);
  }

  void setSfxVolume(double value) {
    ref.read(sharedPreferencesProvider).setDouble(_sfxVolumeKey, value);
    state = state.copyWith(sfxVolume: value);
    ref.read(audioServiceProvider).setSfxVolume(value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
