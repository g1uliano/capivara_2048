// lib/core/constants/ad_config.dart
//
// Configurações de anúncios lidas via --dart-define em tempo de build.
// IDs de teste (dev): https://developers.google.com/admob/flutter/test-ads
// IDs reais (prd): cadastrados no AdMob e injetados via GitHub Secrets no CI.

class AdConfig {
  AdConfig._();

  /// Flavor atual — 'dev' ou 'prd'.
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  /// Ad Unit ID para Android.
  /// Dev: ID de teste oficial do Google.
  /// Prd: injetado via --dart-define=AD_UNIT_ANDROID no CI.
  static const adUnitAndroid = String.fromEnvironment(
    'AD_UNIT_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );

  /// Ad Unit ID para iOS.
  /// Dev: ID de teste oficial do Google.
  /// Prd: injetado via --dart-define=AD_UNIT_IOS no CI.
  static const adUnitIos = String.fromEnvironment(
    'AD_UNIT_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313',
  );

  /// Limite diário de anúncios recompensados.
  /// Compartilhado entre GameOverNoItemsOverlay e DailyRewardOverlay.
  static const maxAdsPerDay = 40;
}
