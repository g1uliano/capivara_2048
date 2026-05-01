import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final adServiceProvider = Provider<AdService>((_) => FakeAdService());
