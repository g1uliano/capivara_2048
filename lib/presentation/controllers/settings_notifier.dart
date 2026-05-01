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

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static SettingsState _load(SharedPreferences p) => SettingsState(
        hapticEnabled: p.getBool('settings.haptic_enabled') ?? true,
        locale: p.getString('settings.locale') ?? 'pt',
      );

  void setHaptic(bool value) {
    _prefs.setBool('settings.haptic_enabled', value);
    state = state.copyWith(hapticEnabled: value);
  }

  void setLocale(String locale) {
    _prefs.setString('settings.locale', locale);
    state = state.copyWith(locale: locale);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  throw UnimplementedError('settingsProvider must be overridden with SharedPreferences');
});
