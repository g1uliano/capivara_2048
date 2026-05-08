// test/presentation/controllers/tutorial_controller_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capivara_2048/presentation/controllers/tutorial_controller.dart';
import 'package:capivara_2048/presentation/controllers/auth_controller.dart';
import 'package:capivara_2048/domain/sync/sync_engine.dart';
import 'package:capivara_2048/data/models/player_profile.dart';

class _FakeAuthController extends AuthController {
  final PlayerProfile? _profile;
  _FakeAuthController(this._profile);
  @override
  PlayerProfile? build() => _profile;
}

PlayerProfile _makeProfile({bool tutorialCompleted = false}) => PlayerProfile(
      userId: 'u1',
      displayName: 'Test',
      provider: AuthProvider.email,
      createdAt: DateTime(2026, 1, 1),
      lastSeenAt: DateTime(2026, 1, 1),
      tutorialCompleted: tutorialCompleted,
    );

void main() {
  group('TutorialController - anonymous user', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('isCompleted returns false by default', () async {
      final container = ProviderContainer(overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(null)),
        syncEngineProvider.overrideWithValue(FakeSyncEngine()),
      ]);
      addTearDown(container.dispose);
      final result =
          await container.read(tutorialControllerProvider.notifier).isCompleted();
      expect(result, false);
    });

    test('markCompleted saves to SharedPreferences', () async {
      final container = ProviderContainer(overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(null)),
        syncEngineProvider.overrideWithValue(FakeSyncEngine()),
      ]);
      addTearDown(container.dispose);
      await container
          .read(tutorialControllerProvider.notifier)
          .markCompleted();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('tutorial_completed'), true);
    });
  });

  group('TutorialController - logged in user', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('isCompleted returns profile.tutorialCompleted', () async {
      final profile = _makeProfile(tutorialCompleted: false);
      final container = ProviderContainer(overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(profile)),
        syncEngineProvider.overrideWithValue(FakeSyncEngine()),
      ]);
      addTearDown(container.dispose);
      final result =
          await container.read(tutorialControllerProvider.notifier).isCompleted();
      expect(result, false);
    });

    test('markCompleted calls syncEngine.updateTutorialCompleted', () async {
      final fake = FakeSyncEngine();
      final profile = _makeProfile(tutorialCompleted: false);
      final container = ProviderContainer(overrides: [
        authControllerProvider.overrideWith(() => _FakeAuthController(profile)),
        syncEngineProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);
      await container
          .read(tutorialControllerProvider.notifier)
          .markCompleted();
      expect(fake.tutorialCompleted, true);
    });
  });
}
