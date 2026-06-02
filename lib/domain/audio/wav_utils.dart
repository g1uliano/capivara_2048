import 'dart:typed_data';

Uint8List buildWav(Int16List samples, {int sampleRate = 22050}) {
  final dataSize = samples.length * 2;
  final fileSize = 44 + dataSize;
  final buffer = ByteData(fileSize);

  void setStr(int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      buffer.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  setStr(0, 'RIFF');
  buffer.setUint32(4, fileSize - 8, Endian.little);
  setStr(8, 'WAVE');
  setStr(12, 'fmt ');
  buffer.setUint32(16, 16, Endian.little);
  buffer.setUint16(20, 1, Endian.little);   // PCM
  buffer.setUint16(22, 1, Endian.little);   // mono
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, sampleRate * 2, Endian.little); // byteRate
  buffer.setUint16(32, 2, Endian.little);   // blockAlign
  buffer.setUint16(34, 16, Endian.little);  // bitsPerSample
  setStr(36, 'data');
  buffer.setUint32(40, dataSize, Endian.little);

  final bytes = buffer.buffer.asUint8List();
  final sampleBytes = samples.buffer.asUint8List(samples.offsetInBytes, samples.lengthInBytes);
  bytes.setRange(44, fileSize, sampleBytes);
  return bytes;
}
