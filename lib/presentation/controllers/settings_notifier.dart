import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool hapticEnabled;
  final String locale;

  const SettingsState({this.hapticEnabled = true, this.locale = 'pt'});

  SettingsState copyWith({bool? hapticEnabled, String? locale}) => SettingsState(
        hapticEnabled: hapticEnabled ?? this.hapticEnabled,
        locale: locale ?? this.locale,
      );
}

/// Must be overridden in ProviderScope/ProviderContainer with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class SettingsNotifier extends Notifier<SettingsState> {
  static const _hapticKey = 'settings.haptic_enabled';
  static const _localeKey = 'settings.locale';

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SettingsState(
      hapticEnabled: prefs.getBool(_hapticKey) ?? true,
      locale: prefs.getString(_localeKey) ?? 'pt',
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
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
