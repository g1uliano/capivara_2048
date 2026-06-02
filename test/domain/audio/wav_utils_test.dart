import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/audio/wav_utils.dart';

void main() {
  group('buildWav', () {
    test('header starts with RIFF and WAVE magic bytes', () {
      final samples = Int16List(100);
      final wav = buildWav(samples);
      expect(wav[0], 0x52); // R
      expect(wav[1], 0x49); // I
      expect(wav[2], 0x46); // F
      expect(wav[3], 0x46); // F
      expect(wav[8], 0x57);  // W
      expect(wav[9], 0x41);  // A
      expect(wav[10], 0x56); // V
      expect(wav[11], 0x45); // E
    });

    test('total size is 44 + samples * 2', () {
      final samples = Int16List(1000);
      final wav = buildWav(samples);
      expect(wav.length, 44 + 1000 * 2);
    });

    test('sample rate is written correctly at offset 24', () {
      final samples = Int16List(10);
      final wav = buildWav(samples, sampleRate: 22050);
      final view = ByteData.sublistView(wav);
      expect(view.getUint32(24, Endian.little), 22050);
    });

    test('data chunk size is samples * 2', () {
      final samples = Int16List(500);
      final wav = buildWav(samples);
      final view = ByteData.sublistView(wav);
      expect(view.getUint32(40, Endian.little), 500 * 2);
    });
  });
}
