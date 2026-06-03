import 'dart:async';

import 'package:flutter_soloud/flutter_soloud.dart';

import 'animal_voices.dart';
import 'audio_service.dart';
import 'sfxr_synth.dart';
import 'sound_presets.dart';

class AudioServiceImpl implements AudioService {
  AudioSource? _bomb2x;
  AudioSource? _bomb3x;
  final _mergeSounds = <int, AudioSource>{};
  final _animalVoices = <int, AudioSource>{};
  AudioSource? _undo1;
  AudioSource? _undo3;
  AudioSource? _victory;
  AudioSource? _gameOver;

  double _sfxVolume = 1.0;
  bool _sfxEnabled = true;

  @override
  Future<void> init() async {
    await SoLoud.instance.init();
    await _loadSfx();
  }

  Future<void> _loadSfx() async {
    final synth = SfxrSynth();
    _bomb2x = await SoLoud.instance.loadMem('bomb2x', synth.generate(SoundPresets.bomb2x));
    _bomb3x = await SoLoud.instance.loadMem('bomb3x', synth.generate(SoundPresets.bomb3x));
    for (int level = 1; level <= 11; level++) {
      _mergeSounds[level] = await SoLoud.instance.loadMem(
        'merge_$level',
        synth.generateMerge(level),
      );
    }
    for (int level = 1; level <= 11; level++) {
      _animalVoices[level] = await SoLoud.instance.loadMem(
        'animal_$level',
        AnimalVoices.voice(level),
      );
    }
    _undo1 = await SoLoud.instance.loadMem('undo1', synth.generateUndo1());
    _undo3 = await SoLoud.instance.loadMem('undo3', synth.generateUndo3());
    _victory = await SoLoud.instance.loadMem('victory', synth.generateVictory());
    _gameOver = await SoLoud.instance.loadMem('gameover', synth.generateGameOver());
  }

  @override
  void playEffect(GameSoundEvent event) {
    if (!_sfxEnabled) return;
    final source = switch (event) {
      Bomb2xUsed() => _bomb2x,
      Bomb3xUsed() => _bomb3x,
      TilesMerged(:final level) => _mergeSounds[level.clamp(1, 11)],
      AnimalReached(:final level) => _animalVoices[level.clamp(1, 11)],
      Undo1Used() => _undo1,
      Undo3Used() => _undo3,
      VictoryReached() => _victory,
      GameOver() => _gameOver,
    };
    if (source != null) {
      unawaited(SoLoud.instance.play(source, volume: _sfxVolume));
    }
  }

  @override
  void setSfxVolume(double v) {
    _sfxVolume = v.clamp(0.0, 1.0);
  }

  @override
  void setSfxEnabled(bool v) => _sfxEnabled = v;

  @override
  void dispose() {
    SoLoud.instance.deinit();
  }
}
