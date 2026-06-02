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

class AnimalReached extends GameSoundEvent {
  const AnimalReached(this.level); // 1–11
  final int level;
}

class Undo1Used extends GameSoundEvent {
  const Undo1Used();
}

class Undo3Used extends GameSoundEvent {
  const Undo3Used();
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
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: '');
  final service = flavor.isNotEmpty ? AudioServiceImpl() : AudioServiceStub();
  ref.onDispose(service.dispose);
  return service;
});
