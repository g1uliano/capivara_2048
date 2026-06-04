enum WaveType { square, triangle, sine }

class SoundPreset {
  const SoundPreset({
    required this.waveType,
    required this.baseFreq,
    this.freqSweep = 0,
    required this.attack,
    required this.sustain,
    required this.decay,
    this.volume = 1.0,
    this.hasNoise = false,
  }) : assert(attack > 0, 'attack must be > 0 to avoid division by zero in envelope');

  final WaveType waveType;
  final double baseFreq;
  final double freqSweep;
  final double attack;
  final double sustain;
  final double decay;
  final double volume;
  final bool hasNoise;

  double get totalDuration => attack + sustain + decay;
}

class SoundPresets {
  const SoundPresets._();

  static const bomb2x = SoundPreset(
    waveType: WaveType.square,
    baseFreq: 300,
    freqSweep: 8.0,
    attack: 0.001,
    sustain: 0.05,
    decay: 0.35,
    volume: 0.8,
    hasNoise: true,
  );

  static const bomb3x = SoundPreset(
    waveType: WaveType.square,
    baseFreq: 200,
    freqSweep: 5.0,
    attack: 0.001,
    sustain: 0.08,
    decay: 0.55,
    volume: 1.0,
    hasNoise: true,
  );

  // Desfazer: o SFX de rebobinar fita VHS é sintetizado proceduralmente em
  // SfxrSynth._generateVhsRewind (motor + atrito da fita + clunk), não via
  // SoundPreset — a varredura simples de pitch não soava como uma fita VHS.

  // Merge pitches by level (1–11)
  static const mergePitches = [
    220.00, // 1 - Tanajura
    246.94, // 2
    261.63, // 3
    293.66, // 4
    329.63, // 5 - Sagui
    369.99, // 6
    415.30, // 7
    440.00, // 8
    493.88, // 9
    587.33, // 10
    880.00, // 11 - Capivara Lendária
  ];

  // Victory arpeggio: C4→G4→C5→E5
  static const victoryNotes = [261.63, 392.0, 523.25, 659.25];
  static const victoryNoteDuration = 0.13;

  // Game over sequence: C4→A3→F3
  static const gameOverNotes = [261.63, 220.0, 174.61];
  static const gameOverNoteDuration = 0.28;
}
