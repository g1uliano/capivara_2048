import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/core/utils/haptic_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('maybeHaptic', () {
    final List<MethodCall> log = [];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') log.add(call);
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('não dispara quando hapticEnabled é false', () {
      maybeHaptic(() => false, intensity: HapticIntensity.heavy);
      expect(log, isEmpty);
    });

    test('dispara quando hapticEnabled é true (light)', () {
      maybeHaptic(() => true, intensity: HapticIntensity.light);
      expect(log.length, 1);
    });

    test('dispara quando hapticEnabled é true (heavy)', () {
      maybeHaptic(() => true, intensity: HapticIntensity.heavy);
      expect(log.length, 1);
    });

    test('dispara quando hapticEnabled é true (medium)', () {
      maybeHaptic(() => true, intensity: HapticIntensity.medium);
      expect(log.length, 1);
    });
  });
}
