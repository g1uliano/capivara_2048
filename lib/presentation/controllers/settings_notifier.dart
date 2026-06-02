import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/audio/audio_service.dart';

class SettingsState {
  final bool hapticEnabled;
  final String locale;
  final bool musicEnabled;
  final bool sfxEnabled;
  final double musicVolume;
  final double sfxVolume;

  const SettingsState({
    this.hapticEnabled = true,
    this.locale = 'pt',
    this.musicEnabled = true,
    this.sfxEnabled = true,
    this.musicVolume = 0.7,
    this.sfxVolume = 1.0,
  });

  SettingsState copyWith({
    bool? hapticEnabled,
    String? locale,
    bool? musicEnabled,
    bool? sfxEnabled,
    double? musicVolume,
    double? sfxVolume,
  }) => SettingsState(
    hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    locale: locale ?? this.locale,
    musicEnabled: musicEnabled ?? this.musicEnabled,
    sfxEnabled: sfxEnabled ?? this.sfxEnabled,
    musicVolume: musicVolume ?? this.musicVolume,
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
  static const _musicEnabledKey = 'settings.music_enabled';
  static const _sfxEnabledKey = 'settings.sfx_enabled';
  static const _musicVolumeKey = 'settings.music_volume';
  static const _sfxVolumeKey = 'settings.sfx_volume';

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SettingsState(
      hapticEnabled: prefs.getBool(_hapticKey) ?? true,
      locale: prefs.getString(_localeKey) ?? 'pt',
      musicEnabled: prefs.getBool(_musicEnabledKey) ?? true,
      sfxEnabled: prefs.getBool(_sfxEnabledKey) ?? true,
      musicVolume: prefs.getDouble(_musicVolumeKey) ?? 0.7,
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

  void setMusicEnabled(bool value) {
    ref.read(sharedPreferencesProvider).setBool(_musicEnabledKey, value);
    state = state.copyWith(musicEnabled: value);
    ref.read(audioServiceProvider).setMusicEnabled(value);
  }

  void setSfxEnabled(bool value) {
    ref.read(sharedPreferencesProvider).setBool(_sfxEnabledKey, value);
    state = state.copyWith(sfxEnabled: value);
    ref.read(audioServiceProvider).setSfxEnabled(value);
  }

  void setMusicVolume(double value) {
    ref.read(sharedPreferencesProvider).setDouble(_musicVolumeKey, value);
    state = state.copyWith(musicVolume: value);
    ref.read(audioServiceProvider).setMusicVolume(value);
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
