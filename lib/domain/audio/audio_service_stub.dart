import 'audio_service.dart';

class AudioServiceStub implements AudioService {
  @override Future<void> init() async {}
  @override void dispose() {}
  @override void playEffect(GameSoundEvent event) {}
  @override void startMusic() {}
  @override void pauseMusic() {}
  @override void stopMusic() {}
  @override void setSfxVolume(double v) {}
  @override void setMusicVolume(double v) {}
  @override void setSfxEnabled(bool v) {}
  @override void setMusicEnabled(bool v) {}
}
