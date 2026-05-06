import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/google_mobile_ads_service.dart';

abstract class AdService {
  Future<bool> showRewardedAd();
}

class FakeAdService implements AdService {
  @override
  Future<bool> showRewardedAd() async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}

final adServiceProvider = Provider<AdService>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  if (flavor == 'prd') return GoogleMobileAdsService();
  return FakeAdService();
});
