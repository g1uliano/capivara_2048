import 'dart:async';

import 'package:flutter_soloud/flutter_soloud.dart';

import 'audio_service.dart';
import 'sfxr_synth.dart';
import 'sound_presets.dart';

class AudioServiceImpl implements AudioService {
  AudioSource? _bomb2x;
  AudioSource? _bomb3x;
  final _mergeSounds = <int, AudioSource>{};
  AudioSource? _victory;
  AudioSource? _gameOver;
  AudioSource? _music;

  SoundHandle? _musicHandle;

  double _sfxVolume = 1.0;
  double _musicVolume = 0.7;
  bool _sfxEnabled = true;
  bool _musicEnabled = true;

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
      VictoryReached() => _victory,
      GameOver() => _gameOver,
    };
    if (source != null) {
      unawaited(SoLoud.instance.play(source, volume: _sfxVolume));
    }
  }

  @override
  void startMusic() {
    if (!_musicEnabled || _music == null) return;
    if (_musicHandle != null) {
      SoLoud.instance.setPause(_musicHandle!, false);
      return;
    }
    unawaited(
      SoLoud.instance
          .play(_music!, looping: true, volume: _musicVolume)
          .then((handle) => _musicHandle = handle),
    );
  }

  @override
  void pauseMusic() {
    if (_musicHandle != null) {
      SoLoud.instance.setPause(_musicHandle!, true);
    }
  }

  @override
  void stopMusic() {
    if (_musicHandle != null) {
      unawaited(SoLoud.instance.stop(_musicHandle!));
      _musicHandle = null;
    }
  }

  @override
  void setSfxVolume(double v) {
    _sfxVolume = v.clamp(0.0, 1.0);
  }

  @override
  void setMusicVolume(double v) {
    _musicVolume = v.clamp(0.0, 1.0);
    if (_musicHandle != null) {
      SoLoud.instance.setVolume(_musicHandle!, _musicVolume);
    }
  }

  @override
  void setSfxEnabled(bool v) => _sfxEnabled = v;

  @override
  void setMusicEnabled(bool v) {
    _musicEnabled = v;
    if (!v) pauseMusic();
    if (v) startMusic();
  }

  @override
  void dispose() {
    stopMusic();
    SoLoud.instance.deinit();
  }
}
