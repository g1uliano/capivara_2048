import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/auth/auth_service.dart';

void main() {
  late FakeAuthService sut;

  setUp(() => sut = FakeAuthService());

  group('FakeAuthService — novos métodos', () {
    test('createAccountWithEmail aceita displayName', () async {
      final profile = await sut.createAccountWithEmail(
        'a@b.com', 'senha123', 'Jogador Teste',
      );
      expect(profile.displayName, 'Jogador Teste');
    });

    test('updateDisplayName atualiza o perfil atual', () async {
      await sut.signInWithEmail('a@b.com', 'senha123');
      await sut.updateDisplayName('Novo Nome');
      expect(sut.currentProfile?.displayName, 'Novo Nome');
    });

    test('sendPasswordReset completa sem lançar', () async {
      await expectLater(
        sut.sendPasswordReset('a@b.com'),
        completes,
      );
    });

    test('deleteAccount limpa o perfil', () async {
      await sut.signInWithEmail('a@b.com', 'senha123');
      await sut.deleteAccount();
      expect(sut.currentProfile, isNull);
    });
  });
}
