import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/ad_config.dart';
import '../../domain/daily_rewards/ad_service.dart';

class GoogleMobileAdsService implements AdService {
  RewardedAd? _preloaded;
  bool _loading = false;

  @override
  Future<bool> showRewardedAd() async {
    if (_preloaded == null) {
      await _loadAd();
      if (_preloaded == null) return false;
    }

    final ad = _preloaded!;
    _preloaded = null;
    unawaited(_loadAd()); // preload next

    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) {
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (_, __) {
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, __) {
      if (!completer.isCompleted) completer.complete(true);
    });
    return completer.future;
  }

  Future<void> preload() => _loadAd();

  Future<void> _loadAd() async {
    if (_loading) return;
    _loading = true;
    final unitId =
        Platform.isIOS ? AdConfig.adUnitIos : AdConfig.adUnitAndroid;
    await RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _preloaded = ad;
          _loading = false;
        },
        onAdFailedToLoad: (_) {
          _loading = false;
        },
      ),
    );
  }
}
