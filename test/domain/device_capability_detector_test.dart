import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/performance/device_capability_detector.dart';

void main() {
  group('DeviceCapabilityDetector.isLowEndFromModel', () {
    test('Redmi Note detectado como fraco', () {
      expect(
        DeviceCapabilityDetector.isLowEndFromModel('Redmi Note 9S', 30),
        true,
      );
    });

    test('Poco M detectado como fraco', () {
      expect(
        DeviceCapabilityDetector.isLowEndFromModel('Poco M3 Pro', 31),
        true,
      );
    });

    test('Galaxy A23 detectado como fraco', () {
      expect(
        DeviceCapabilityDetector.isLowEndFromModel('Samsung Galaxy A23', 32),
        true,
      );
    });

    test('Moto G detectado como fraco', () {
      expect(
        DeviceCapabilityDetector.isLowEndFromModel('Moto G82', 33),
        true,
      );
    });

    test('Pixel 8 não detectado como fraco', () {
      expect(
        DeviceCapabilityDetector.isLowEndFromModel('Pixel 8', 34),
        false,
      );
    });

    test('Samsung Galaxy S24 não detectado como fraco', () {
      expect(
        DeviceCapabilityDetector.isLowEndFromModel('SM-S926B', 34),
        false,
      );
    });

    test('SDK < 31 detectado como fraco independente do modelo', () {
      expect(
        DeviceCapabilityDetector.isLowEndFromModel('Pixel 9', 30),
        true,
      );
    });
  });
}
