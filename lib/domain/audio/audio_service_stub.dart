import 'audio_service.dart';

class AudioServiceStub implements AudioService {
  @override Future<void> init() async {}
  @override void dispose() {}
  @override void playEffect(GameSoundEvent event) {}
  @override void setSfxVolume(double v) {}
  @override void setSfxEnabled(bool v) {}
}
