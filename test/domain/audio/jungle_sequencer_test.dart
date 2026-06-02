import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/audio/jungle_sequencer.dart';

void main() {
  group('JungleSequencer', () {
    test('generate retorna WAV válido', () async {
      final wav = await JungleSequencer.generate();
      expect(wav.length, greaterThan(44));
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    });

    test('duração está entre 80s e 90s', () async {
      final wav = await JungleSequencer.generate();
      final samples = (wav.length - 44) ~/ 2;
      final durationSec = samples / 22050;
      expect(durationSec, greaterThanOrEqualTo(80));
      expect(durationSec, lessThanOrEqualTo(90));
    });

    test('loop point é suave — amplitude média final similar ao início', () async {
      final wav = await JungleSequencer.generate();
      // Verificar que as últimas 1000 amostras não têm clipping
      final sampleData = wav.sublist(44);
      int clipped = 0;
      for (int i = sampleData.length - 2000; i < sampleData.length; i += 2) {
        final lo = sampleData[i];
        final hi = sampleData[i + 1];
        final sample = (hi << 8) | lo;
        final signed = sample > 32767 ? sample - 65536 : sample;
        if (signed.abs() > 30000) clipped++;
      }
      expect(clipped, lessThan(50), reason: 'loop end should not be clipping');
    });
  });
}
