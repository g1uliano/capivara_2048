import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceCapabilityDetector {
  static const _lowEndPatterns = [
    'redmi note',
    'redmi',
    'poco m',
    'poco c',
    'galaxy a0',
    'galaxy a1',
    'galaxy a2',
    'galaxy a3',
    'galaxy a4',
    'galaxy a5',
    'moto g',
    'moto e',
  ];

  /// Retorna `true` se o dispositivo for considerado fraco pela heurística.
  /// Só roda no Android; iOS sempre retorna `false`.
  static Future<bool> isLowEndDevice() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    final info = await DeviceInfoPlugin().androidInfo;
    return isLowEndFromModel(info.model, info.version.sdkInt);
  }

  @visibleForTesting
  static bool isLowEndFromModel(String model, int sdkInt) {
    if (sdkInt < 31) return true;
    final lower = model.toLowerCase();
    return _lowEndPatterns.any((p) => lower.contains(p));
  }
}
