import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/player_profile.dart';

void main() {
  group('PlayerProfile.tutorialCompleted', () {
    final base = PlayerProfile(
      userId: 'u1',
      displayName: 'Test',
      provider: AuthProvider.email,
      createdAt: DateTime(2026, 1, 1),
      lastSeenAt: DateTime(2026, 1, 1),
    );

    test('default é false', () {
      expect(base.tutorialCompleted, false);
    });

    test('copyWith preserva outros campos', () {
      final updated = base.copyWith(tutorialCompleted: true);
      expect(updated.tutorialCompleted, true);
      expect(updated.userId, 'u1');
      expect(updated.displayName, 'Test');
    });

    test('toJson inclui o flag quando true', () {
      final json = base.copyWith(tutorialCompleted: true).toJson();
      expect(json['tutorialCompleted'], true);
    });

    test('fromJson sem o campo retorna false', () {
      final p = PlayerProfile.fromJson({
        'userId': 'u1',
        'displayName': 'Test',
        'provider': 'email',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'lastSeenAt': DateTime(2026, 1, 1).toIso8601String(),
      });
      expect(p.tutorialCompleted, false);
    });

    test('round-trip preserva o flag', () {
      final original = base.copyWith(tutorialCompleted: true);
      final restored = PlayerProfile.fromJson(original.toJson());
      expect(restored.tutorialCompleted, true);
    });
  });
}
