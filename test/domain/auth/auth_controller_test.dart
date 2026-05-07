import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:capivara_2048/domain/auth/auth_service.dart';
import 'package:capivara_2048/domain/sync/sync_engine.dart';
import 'package:capivara_2048/presentation/controllers/auth_controller.dart';
import 'package:capivara_2048/data/models/player_profile.dart';

void main() {
  late FakeAuthService fakeAuth;
  late FakeSyncEngine fakeSyncEngine;
  late ProviderContainer container;

  setUpAll(() async {
    Hive.init('/tmp/capivara_auth_test');
  });

  setUp(() {
    fakeAuth = FakeAuthService();
    fakeSyncEngine = FakeSyncEngine();
    container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(fakeAuth),
        syncEngineProvider.overrideWithValue(fakeSyncEngine),
      ],
    );
  });

  tearDown(() {
    fakeAuth.dispose();
    container.dispose();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  test('estado inicial é null (não logado)', () {
    expect(container.read(authControllerProvider), isNull);
  });

  test('signInWithGoogle atualiza estado com PlayerProfile', () async {
    await container.read(authControllerProvider.notifier).signInWithGoogle();
    final profile = container.read(authControllerProvider);
    expect(profile, isNotNull);
    expect(profile!.provider, AuthProvider.google);
    expect(profile.displayName, 'Jogador Teste');
  });

  test('signOut limpa o estado', () async {
    await container.read(authControllerProvider.notifier).signInWithGoogle();
    await container.read(authControllerProvider.notifier).signOut();
    expect(container.read(authControllerProvider), isNull);
  });

  test('signInWithEmail atualiza estado com email correto', () async {
    await container
        .read(authControllerProvider.notifier)
        .signInWithEmail('user@example.com', 'pass123');
    final profile = container.read(authControllerProvider);
    expect(profile!.email, 'user@example.com');
    expect(profile.provider, AuthProvider.email);
  });

  test('signIn chama syncEngine.init', () async {
    await container.read(authControllerProvider.notifier).signInWithGoogle();
    expect(fakeSyncEngine.initCalled, isTrue);
  });

  test('createAccountWithEmail cria perfil e inicializa sync engine', () async {
    await container
        .read(authControllerProvider.notifier)
        .createAccountWithEmail('novo@example.com', 'senha123');
    final profile = container.read(authControllerProvider);
    expect(profile, isNotNull);
    expect(profile!.email, 'novo@example.com');
    expect(fakeSyncEngine.initCalled, isTrue);
    // New account: syncProfile and drainPendingEvents NOT called
    expect(fakeSyncEngine.drained, isEmpty);
  });

  test('signInWithApple atualiza estado com AuthProvider.apple', () async {
    await container.read(authControllerProvider.notifier).signInWithApple();
    final profile = container.read(authControllerProvider);
    expect(profile, isNotNull);
    expect(profile!.provider, AuthProvider.apple);
  });

  test('updateAvatar atualiza estado local e chama syncEngine', () async {
    await container.read(authControllerProvider.notifier).signInWithGoogle();
    await container
        .read(authControllerProvider.notifier)
        .updateAvatar('tile:Capivara');
    final profile = container.read(authControllerProvider);
    expect(profile!.avatarUrl, 'tile:Capivara');
    expect(fakeSyncEngine.lastAvatarUrl, 'tile:Capivara');
  });

  test('updateAvatar com null limpa o avatar', () async {
    await container.read(authControllerProvider.notifier).signInWithGoogle();
    await container
        .read(authControllerProvider.notifier)
        .updateAvatar('tile:Onca');
    await container.read(authControllerProvider.notifier).updateAvatar(null);
    final profile = container.read(authControllerProvider);
    expect(profile!.avatarUrl, isNull);
    expect(fakeSyncEngine.lastAvatarUrl, isNull);
  });

  test('updateAvatar não faz nada se não logado', () async {
    await container
        .read(authControllerProvider.notifier)
        .updateAvatar('tile:Tucano');
    expect(container.read(authControllerProvider), isNull);
    expect(fakeSyncEngine.lastAvatarUrl, '__not_set__');
  });
}
