import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_service_impl.dart';
import 'audio_service_stub.dart';

sealed class GameSoundEvent {
  const GameSoundEvent();
}

class Bomb2xUsed extends GameSoundEvent {
  const Bomb2xUsed();
}

class Bomb3xUsed extends GameSoundEvent {
  const Bomb3xUsed();
}

class TilesMerged extends GameSoundEvent {
  const TilesMerged(this.level);
  final int level; // 1–11
}

class VictoryReached extends GameSoundEvent {
  const VictoryReached();
}

class GameOver extends GameSoundEvent {
  const GameOver();
}

abstract class AudioService {
  Future<void> init();
  void dispose();

  void playEffect(GameSoundEvent event);

  void startMusic();
  void pauseMusic();
  void stopMusic();

  void setSfxVolume(double v);
  void setMusicVolume(double v);
  void setSfxEnabled(bool v);
  void setMusicEnabled(bool v);
}

final audioServiceProvider = Provider<AudioService>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  final service = flavor == 'prd' ? AudioServiceImpl() : AudioServiceStub();
  ref.onDispose(service.dispose);
  return service;
});
