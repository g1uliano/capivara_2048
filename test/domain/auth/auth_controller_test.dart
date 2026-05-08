import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:capivara_2048/data/repositories/iap_startup_service.dart';
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
        iapStartupServiceProvider.overrideWithValue(FakeIAPStartupService()),
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

  group('cold start session restore', () {
    test(
      'ao iniciar com sessão existente, busca avatar tile do Firestore',
      () async {
        // Simula cold start: auth service já tem perfil salvo (sem avatar)
        final profileSemAvatar = PlayerProfile(
          userId: 'fake-user-id',
          displayName: 'Giuliano',
          email: 'giuliano@example.com',
          provider: AuthProvider.email,
          createdAt: DateTime(2025, 1, 1),
          lastSeenAt: DateTime.now(),
        );
        final authComSessao = FakeAuthService(
          initialProfile: profileSemAvatar,
        );
        final syncComAvatar = FakeSyncEngine()
          ..remoteAvatarUrl = 'tile:Capivara';

        final c = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(authComSessao),
            syncEngineProvider.overrideWithValue(syncComAvatar),
            iapStartupServiceProvider.overrideWithValue(FakeIAPStartupService()),
          ],
        );
        addTearDown(() {
          authComSessao.dispose();
          c.dispose();
        });

        // Estado inicial (síncrono) vem do cache do Firebase Auth
        expect(c.read(authControllerProvider)?.avatarUrl, isNull);

        // Aguarda microtask do _restoreSessionOnColdStart
        await Future<void>.delayed(Duration.zero);

        final profile = c.read(authControllerProvider);
        expect(profile?.avatarUrl, 'tile:Capivara');
        expect(syncComAvatar.initCalled, isTrue);
      },
    );

    test(
      'ao iniciar com sessão existente, corrige displayName vazio do Firestore',
      () async {
        // Simula Firebase Auth retornando displayName vazio (bug conhecido)
        final profileNomVazio = PlayerProfile(
          userId: 'fake-user-id',
          displayName: '', // Firebase Auth retornou string vazia
          email: 'giuliano@example.com',
          provider: AuthProvider.email,
          createdAt: DateTime(2025, 1, 1),
          lastSeenAt: DateTime.now(),
        );
        final authComSessao = FakeAuthService(
          initialProfile: profileNomVazio,
        );
        final syncComNome = FakeSyncEngine()
          ..remoteDisplayName = 'Giuliano'
          ..remoteAvatarUrl = 'tile:Onca';

        final c = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(authComSessao),
            syncEngineProvider.overrideWithValue(syncComNome),
            iapStartupServiceProvider.overrideWithValue(FakeIAPStartupService()),
          ],
        );
        addTearDown(() {
          authComSessao.dispose();
          c.dispose();
        });

        expect(c.read(authControllerProvider)?.displayName, '');

        await Future<void>.delayed(Duration.zero);

        final profile = c.read(authControllerProvider);
        expect(profile?.displayName, 'Giuliano');
        expect(profile?.avatarUrl, 'tile:Onca');
      },
    );

    test(
      'não sobrescreve displayName correto com valor remoto',
      () async {
        // Firebase Auth já tem nome correto — remoto não deve sobrescrever
        final profileCorreto = PlayerProfile(
          userId: 'fake-user-id',
          displayName: 'Giuliano',
          email: 'giuliano@example.com',
          provider: AuthProvider.email,
          createdAt: DateTime(2025, 1, 1),
          lastSeenAt: DateTime.now(),
        );
        final authComSessao = FakeAuthService(
          initialProfile: profileCorreto,
        );
        final syncComOutroNome = FakeSyncEngine()
          ..remoteDisplayName = 'Outro Nome';

        final c = ProviderContainer(
          overrides: [
            authServiceProvider.overrideWithValue(authComSessao),
            syncEngineProvider.overrideWithValue(syncComOutroNome),
            iapStartupServiceProvider.overrideWithValue(FakeIAPStartupService()),
          ],
        );
        addTearDown(() {
          authComSessao.dispose();
          c.dispose();
        });

        await Future<void>.delayed(Duration.zero);

        // Nome local não-vazio não deve ser sobrescrito
        expect(c.read(authControllerProvider)?.displayName, 'Giuliano');
      },
    );
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
        .createAccountWithEmail(
          'novo@example.com',
          'senha123',
          'Jogador Teste',
        );
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
