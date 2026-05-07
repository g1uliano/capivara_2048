# Fase 4 Conclusão — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fechar os 10 requisitos pendentes da Fase 4: gestão de conta (exclusão LGPD, nome, senha), persistência de avatar e auth gates em todo o app.

**Architecture:** Domain-first — novos métodos nos contratos abstratos (`AuthService`, `SyncEngine`) antes das implementações Firebase. Cada bloco é independente; o Bloco C depende do Bloco B apenas para o estado de login. `AuthGateOverlay` é o único widget novo; todo o resto é extensão de arquivos existentes.

**Tech Stack:** Flutter 3, Dart, Riverpod 3, Firebase Auth, Firestore, Hive, `flutter_test`

---

## File Map

| Arquivo | Ação |
|---|---|
| `lib/domain/auth/auth_service.dart` | Modificar — novos contratos + FakeAuthService |
| `lib/data/repositories/firebase_auth_service.dart` | Modificar — implementar novos métodos |
| `lib/domain/sync/sync_engine.dart` | Modificar — novos contratos + FakeSyncEngine + fix provider |
| `lib/data/repositories/firebase_sync_engine.dart` | Modificar — implementar novos métodos |
| `lib/data/models/game_record.dart` | Modificar — adicionar `toJson` / `fromJson` |
| `lib/presentation/controllers/auth_controller.dart` | Modificar — `deleteAccount`, `updateDisplayName`, fix avatar |
| `lib/presentation/controllers/game_notifier.dart` | Modificar — sync game record + auth check |
| `lib/presentation/widgets/auth_gate_overlay.dart` | **Criar** |
| `lib/presentation/screens/splash_screen.dart` | Modificar — auth gate na navegação |
| `lib/presentation/screens/onboarding_auth_screen.dart` | Modificar — `showSkip` param + benefits |
| `lib/presentation/screens/profile_screen.dart` | Modificar — exclusão, editar nome, trocar senha, ocultar avatar Google |
| `lib/presentation/screens/email_auth_screen.dart` | Modificar — campo nome, esqueci senha |
| `lib/presentation/widgets/shop_overlay.dart` | Modificar — wrap com `AuthGateOverlay` |
| `lib/presentation/screens/ranking_screen.dart` | Modificar — banner Lendas, sync pessoal |
| `lib/presentation/screens/home_screen.dart` | Modificar — auth guards |
| `test/domain/auth/auth_service_extensions_test.dart` | **Criar** |
| `test/domain/sync/sync_engine_extensions_test.dart` | **Criar** |
| `test/presentation/widgets/auth_gate_overlay_test.dart` | **Criar** |

---

## Task 1: GameRecord — adicionar toJson / fromJson

**Spec:** C6b (sync de gameRecords no Firestore exige serialização)

**Files:**
- Modify: `lib/data/models/game_record.dart`

- [ ] **Step 1: Adicionar métodos de serialização**

  Substituir o conteúdo de `lib/data/models/game_record.dart`:

  ```dart
  class GameRecord {
    static const int hiveTypeId = 11;

    final DateTime playedAt;
    final int elapsedMs;
    final int score;
    final int maxLevel;

    const GameRecord({
      required this.playedAt,
      required this.elapsedMs,
      required this.score,
      required this.maxLevel,
    });

    Map<String, dynamic> toJson() => {
      'playedAt': playedAt.toIso8601String(),
      'elapsedMs': elapsedMs,
      'score': score,
      'maxLevel': maxLevel,
    };

    factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
      playedAt: DateTime.parse(json['playedAt'] as String),
      elapsedMs: json['elapsedMs'] as int,
      score: json['score'] as int,
      maxLevel: json['maxLevel'] as int,
    );
  }
  ```

- [ ] **Step 2: Verificar que testes existentes ainda passam**

  ```bash
  flutter test --name "GameRecord" 2>/dev/null || flutter test test/
  ```
  Expected: sem regressões em testes relacionados a GameRecord.

- [ ] **Step 3: Commit**

  ```bash
  git add lib/data/models/game_record.dart
  git commit -m "feat: GameRecord toJson/fromJson para sync Firestore"
  ```

---

## Task 2: AuthService — novos contratos e FakeAuthService

**Spec:** A1, A2, A3+A4

**Files:**
- Modify: `lib/domain/auth/auth_service.dart`
- Create: `test/domain/auth/auth_service_extensions_test.dart`

- [ ] **Step 1: Escrever testes que falham**

  Criar `test/domain/auth/auth_service_extensions_test.dart`:

  ```dart
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
  ```

- [ ] **Step 2: Rodar — esperar falha**

  ```bash
  flutter test test/domain/auth/auth_service_extensions_test.dart
  ```
  Expected: compilation errors ou test failures.

- [ ] **Step 3: Atualizar `auth_service.dart`**

  Substituir o conteúdo completo de `lib/domain/auth/auth_service.dart`:

  ```dart
  // lib/domain/auth/auth_service.dart

  import 'dart:async';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../../data/models/player_profile.dart';
  import '../../data/repositories/firebase_auth_service.dart';

  abstract class AuthService {
    Stream<PlayerProfile?> get authStateChanges;
    PlayerProfile? get currentProfile;
    Future<PlayerProfile> signInWithGoogle();
    Future<PlayerProfile> signInWithApple();
    Future<PlayerProfile> signInWithEmail(String email, String password);
    Future<PlayerProfile> createAccountWithEmail(
      String email,
      String password,
      String displayName,
    );
    Future<void> updateDisplayName(String name);
    Future<void> sendPasswordReset(String email);
    // senha: obrigatório para AuthProvider.email; ignorado para Google
    Future<void> deleteAccount({String? senha});
    Future<void> signOut();
  }

  class FakeAuthService implements AuthService {
    PlayerProfile? _profile;
    final _controller = StreamController<PlayerProfile?>.broadcast();

    FakeAuthService({PlayerProfile? initialProfile}) : _profile = initialProfile;

    @override
    Stream<PlayerProfile?> get authStateChanges => _controller.stream;

    @override
    PlayerProfile? get currentProfile => _profile;

    @override
    Future<PlayerProfile> signInWithGoogle() async {
      _profile = _fakeProfile(AuthProvider.google);
      _controller.add(_profile);
      return _profile!;
    }

    @override
    Future<PlayerProfile> signInWithApple() async {
      _profile = _fakeProfile(AuthProvider.apple);
      _controller.add(_profile);
      return _profile!;
    }

    @override
    Future<PlayerProfile> signInWithEmail(String email, String password) async {
      _profile = _fakeProfile(AuthProvider.email, email: email);
      _controller.add(_profile);
      return _profile!;
    }

    @override
    Future<PlayerProfile> createAccountWithEmail(
      String email,
      String password,
      String displayName,
    ) async {
      _profile = _fakeProfile(AuthProvider.email, email: email, name: displayName);
      _controller.add(_profile);
      return _profile!;
    }

    @override
    Future<void> updateDisplayName(String name) async {
      if (_profile == null) return;
      _profile = _profile!.copyWith(displayName: name);
      _controller.add(_profile);
    }

    @override
    Future<void> sendPasswordReset(String email) async {}

    @override
    Future<void> deleteAccount({String? senha}) async {
      _profile = null;
      _controller.add(null);
    }

    @override
    Future<void> signOut() async {
      _profile = null;
      _controller.add(null);
    }

    void dispose() => _controller.close();

    PlayerProfile _fakeProfile(
      AuthProvider provider, {
      String? email,
      String? name,
    }) =>
        PlayerProfile(
          userId: 'fake-user-id',
          displayName: name ?? 'Jogador Teste',
          email: email,
          provider: provider,
          createdAt: DateTime(2025, 1, 1),
          lastSeenAt: DateTime.now(),
        );
  }

  final authServiceProvider = Provider<AuthService>((ref) {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    if (flavor == 'prd' || flavor == 'dev' || flavor == 'tst') {
      return FirebaseAuthService();
    }
    return FakeAuthService();
  });
  ```

- [ ] **Step 4: Rodar testes — esperar verde**

  ```bash
  flutter test test/domain/auth/auth_service_extensions_test.dart
  ```
  Expected: 4 tests passed.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/domain/auth/auth_service.dart \
          test/domain/auth/auth_service_extensions_test.dart
  git commit -m "feat: AuthService — deleteAccount, updateDisplayName, sendPasswordReset, displayName no signup"
  ```

---

## Task 3: SyncEngine — novos contratos e FakeSyncEngine

**Spec:** A1, A2, B, C6b

**Files:**
- Modify: `lib/domain/sync/sync_engine.dart`
- Create: `test/domain/sync/sync_engine_extensions_test.dart`

- [ ] **Step 1: Escrever testes que falham**

  Criar `test/domain/sync/sync_engine_extensions_test.dart`:

  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:capivara_2048/domain/sync/sync_engine.dart';
  import 'package:capivara_2048/data/models/game_record.dart';

  void main() {
    late FakeSyncEngine sut;

    setUp(() => sut = FakeSyncEngine());

    group('FakeSyncEngine — novos métodos', () {
      test('deleteUserData completa sem lançar', () async {
        await expectLater(sut.deleteUserData(), completes);
      });

      test('updateDisplayName completa sem lançar', () async {
        await expectLater(sut.updateDisplayName('Nome'), completes);
      });

      test('syncGameRecord completa sem lançar', () async {
        final record = GameRecord(
          playedAt: DateTime(2025),
          elapsedMs: 60000,
          score: 1234,
          maxLevel: 5,
        );
        await expectLater(sut.syncGameRecord(record), completes);
      });

      test('remoteAvatarUrl retorna null por padrão', () {
        expect(sut.remoteAvatarUrl, isNull);
      });
    });
  }
  ```

- [ ] **Step 2: Rodar — esperar falha**

  ```bash
  flutter test test/domain/sync/sync_engine_extensions_test.dart
  ```

- [ ] **Step 3: Atualizar `sync_engine.dart`**

  Substituir o conteúdo completo de `lib/domain/sync/sync_engine.dart`:

  ```dart
  // lib/domain/sync/sync_engine.dart

  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../../data/models/game_record.dart';
  import '../../data/models/pending_event.dart';
  import '../../data/repositories/firebase_sync_engine.dart';

  enum SyncStatus { idle, syncing, error }

  abstract class SyncEngine {
    Future<void> init(String userId, {String? displayName});
    Future<void> dispose();
    Future<void> syncProfile();
    Future<void> updateAvatar(String? avatarUrl);
    Future<void> updateDisplayName(String name);
    Future<void> deleteUserData();
    Future<void> syncGameRecord(GameRecord record);
    Future<void> drainPendingEvents();
    Future<void> enqueuePendingEvent(PendingEvent event);
    Stream<SyncStatus> get statusStream;
    String? get remoteAvatarUrl;
  }

  class FakeSyncEngine implements SyncEngine {
    bool initCalled = false;
    bool disposeCalled = false;
    final List<PendingEvent> drained = [];
    final List<PendingEvent> enqueued = [];
    String? lastAvatarUrl = _sentinel;
    static const _sentinel = '__not_set__';

    @override
    String? remoteAvatarUrl;

    @override
    Future<void> init(String userId, {String? displayName}) async =>
        initCalled = true;

    @override
    Future<void> dispose() async => disposeCalled = true;

    @override
    Future<void> syncProfile() async {}

    @override
    Future<void> updateAvatar(String? avatarUrl) async {
      lastAvatarUrl = avatarUrl;
    }

    @override
    Future<void> updateDisplayName(String name) async {}

    @override
    Future<void> deleteUserData() async {}

    @override
    Future<void> syncGameRecord(GameRecord record) async {}

    @override
    Future<void> drainPendingEvents() async {
      drained.addAll(enqueued);
      enqueued.clear();
    }

    @override
    Future<void> enqueuePendingEvent(PendingEvent event) async {
      enqueued.add(event);
    }

    @override
    Stream<SyncStatus> get statusStream => Stream.value(SyncStatus.idle);
  }

  final syncEngineProvider = Provider<SyncEngine>((ref) {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    if (flavor == 'prd' || flavor == 'dev' || flavor == 'tst') {
      return FirebaseSyncEngine();
    }
    return FakeSyncEngine();
  });
  ```

- [ ] **Step 4: Rodar testes — esperar verde**

  ```bash
  flutter test test/domain/sync/sync_engine_extensions_test.dart
  ```
  Expected: 4 tests passed.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/domain/sync/sync_engine.dart \
          test/domain/sync/sync_engine_extensions_test.dart
  git commit -m "feat: SyncEngine — deleteUserData, updateDisplayName, syncGameRecord, remoteAvatarUrl"
  ```

---

## Task 4: FirebaseAuthService — implementar novos métodos

**Spec:** A1, A2, A3+A4

**Files:**
- Modify: `lib/data/repositories/firebase_auth_service.dart`

- [ ] **Step 1: Implementar os métodos**

  Substituir o conteúdo completo de `lib/data/repositories/firebase_auth_service.dart`:

  ```dart
  // lib/data/repositories/firebase_auth_service.dart

  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart' as fb;
  import 'package:google_sign_in/google_sign_in.dart';
  import '../../data/models/player_profile.dart';
  import '../../domain/auth/auth_service.dart';

  class FirebaseAuthService implements AuthService {
    FirebaseAuthService() : _auth = fb.FirebaseAuth.instance;

    final fb.FirebaseAuth _auth;

    @override
    Stream<PlayerProfile?> get authStateChanges =>
        _auth.authStateChanges().map(_toProfile);

    @override
    PlayerProfile? get currentProfile => _toProfile(_auth.currentUser);

    @override
    Future<PlayerProfile> signInWithGoogle() async {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      return _toProfile(result.user)!;
    }

    @override
    Future<PlayerProfile> signInWithApple() async {
      throw UnimplementedError(
          'Apple Sign-In: implementar com sign_in_with_apple');
    }

    @override
    Future<PlayerProfile> signInWithEmail(String email, String pass) async {
      final result = await _auth.signInWithEmailAndPassword(
          email: email, password: pass);
      return _toProfile(result.user)!;
    }

    @override
    Future<PlayerProfile> createAccountWithEmail(
      String email,
      String pass,
      String displayName,
    ) async {
      final result = await _auth.createUserWithEmailAndPassword(
          email: email, password: pass);
      await result.user?.updateDisplayName(displayName);
      return _toProfile(result.user)!;
    }

    @override
    Future<void> updateDisplayName(String name) async {
      final user = _auth.currentUser;
      if (user == null) return;
      await user.updateDisplayName(name);
      await fb.FirebaseAuth.instance.currentUser?.reload();
    }

    @override
    Future<void> sendPasswordReset(String email) async {
      await _auth.sendPasswordResetEmail(email: email);
    }

    @override
    Future<void> deleteAccount({String? senha}) async {
      final user = _auth.currentUser;
      if (user == null) return;
      final isGoogle = user.providerData
          .any((p) => p.providerId.contains('google'));
      if (isGoogle) {
        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;
        final credential = fb.GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        if (senha == null || user.email == null) {
          throw Exception('Senha obrigatória para exclusão de conta e-mail');
        }
        final credential = fb.EmailAuthProvider.credential(
          email: user.email!,
          password: senha,
        );
        await user.reauthenticateWithCredential(credential);
      }
      await user.delete();
    }

    @override
    Future<void> signOut() async {
      final isGoogle = _auth.currentUser?.providerData
              .any((p) => p.providerId.contains('google')) ??
          false;
      if (isGoogle) await GoogleSignIn.instance.signOut();
      await _auth.signOut();
    }

    PlayerProfile? _toProfile(fb.User? user) {
      if (user == null) return null;
      final provider = _detectProvider(user);
      return PlayerProfile(
        userId: user.uid,
        displayName: user.displayName ?? 'Jogador',
        avatarUrl: user.photoURL,
        email: user.email,
        provider: provider,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        lastSeenAt: DateTime.now(),
      );
    }

    AuthProvider _detectProvider(fb.User user) {
      final providerId = user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'password';
      if (providerId.contains('google')) return AuthProvider.google;
      if (providerId.contains('apple')) return AuthProvider.apple;
      return AuthProvider.email;
    }
  }
  ```

- [ ] **Step 2: Verificar compilação**

  ```bash
  flutter analyze lib/data/repositories/firebase_auth_service.dart
  ```
  Expected: No issues found.

- [ ] **Step 3: Commit**

  ```bash
  git add lib/data/repositories/firebase_auth_service.dart
  git commit -m "feat: FirebaseAuthService — deleteAccount, updateDisplayName, sendPasswordReset, displayName no signup"
  ```

---

## Task 5: FirebaseSyncEngine — implementar novos métodos + fix remoteAvatarUrl

**Spec:** A1, A2, B, C6b

**Files:**
- Modify: `lib/data/repositories/firebase_sync_engine.dart`

- [ ] **Step 1: Adicionar campos e métodos ao FirebaseSyncEngine**

  Localizar a declaração da classe e adicionar o campo `_remoteAvatarUrl`:

  ```dart
  // Após a linha: final _firestore = FirebaseFirestore.instance;
  String? _remoteAvatarUrl;

  @override
  String? get remoteAvatarUrl => _remoteAvatarUrl;
  ```

- [ ] **Step 2: Atualizar `syncProfile()` para ler avatarUrl e gameRecords**

  Substituir o método `syncProfile()` existente:

  ```dart
  @override
  Future<void> syncProfile() async {
    if (_userId == null) return;
    _statusController.add(SyncStatus.syncing);
    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        // Avatar (apenas para contas e-mail com tile animal)
        _remoteAvatarUrl = data['avatarUrl'] as String?;
        await _mergeRemotePersonalRecords(
          data['personalRecords'] as Map<String, dynamic>?,
        );
        await _mergeRemoteInventory(
          data['inventory'] as Map<String, dynamic>?,
        );
        await _mergeRemoteGameRecords(
          (data['gameRecords'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList(),
        );
      } else {
        await _writeLocalProfileToFirestore();
      }
      _statusController.add(SyncStatus.idle);
    } catch (_) {
      _statusController.add(SyncStatus.error);
    }
  }
  ```

- [ ] **Step 3: Adicionar os 3 novos métodos públicos e `_mergeRemoteGameRecords`**

  Adicionar após o método `updateAvatar()` existente:

  ```dart
  @override
  Future<void> updateDisplayName(String name) async {
    if (_userId == null) return;
    await _firestore.collection('users').doc(_userId).set(
      {'displayName': name},
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> deleteUserData() async {
    if (_userId == null) return;
    await _firestore.collection('users').doc(_userId).delete();
  }

  @override
  Future<void> syncGameRecord(GameRecord record) async {
    if (_userId == null) return;
    final docRef = _firestore.collection('users').doc(_userId);
    final doc = await docRef.get();
    final existing = ((doc.data()?['gameRecords'] as List<dynamic>?) ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
    existing.add(record.toJson());
    existing.sort(
        (a, b) => (b['score'] as int).compareTo(a['score'] as int));
    final top20 = existing.take(20).toList();
    await docRef.set({'gameRecords': top20}, SetOptions(merge: true));
  }
  ```

  Adicionar o método privado `_mergeRemoteGameRecords` junto aos outros métodos `_merge*`:

  ```dart
  Future<void> _mergeRemoteGameRecords(
      List<Map<String, dynamic>>? remoteData) async {
    if (remoteData == null || remoteData.isEmpty) return;
    final box = await Hive.openBox<GameRecord>('game_records');
    final local = box.values.toList();

    // Merge: combinar local + remote, deduplicar por playedAt+score, top 20 por score
    final Map<String, GameRecord> byKey = {};
    for (final r in local) {
      byKey['${r.playedAt.toIso8601String()}_${r.score}'] = r;
    }
    for (final json in remoteData) {
      try {
        final r = GameRecord.fromJson(json);
        byKey['${r.playedAt.toIso8601String()}_${r.score}'] = r;
      } catch (_) {}
    }
    final merged = byKey.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final top20 = merged.take(20).toList();

    await box.clear();
    for (final r in top20) {
      await box.add(r);
    }
  }
  ```

  Também adicionar o import necessário no topo do arquivo (se não existir):

  ```dart
  import '../../data/models/game_record.dart';
  import '../../data/models/game_record_hive_adapter.dart';
  ```

  E registrar o adapter em `_mergeRemoteGameRecords` antes de `Hive.openBox`:

  ```dart
  if (!Hive.isAdapterRegistered(GameRecord.hiveTypeId)) {
    Hive.registerAdapter(GameRecordHiveAdapter());
  }
  ```

- [ ] **Step 4: Verificar compilação**

  ```bash
  flutter analyze lib/data/repositories/firebase_sync_engine.dart
  ```
  Expected: No issues found.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/data/repositories/firebase_sync_engine.dart
  git commit -m "feat: FirebaseSyncEngine — deleteUserData, updateDisplayName, syncGameRecord, remoteAvatarUrl, merge gameRecords"
  ```

---

## Task 6: AuthController — deleteAccount, updateDisplayName e fix avatar e-mail

**Spec:** A1, A2, B

**Files:**
- Modify: `lib/presentation/controllers/auth_controller.dart`

- [ ] **Step 1: Adicionar imports e novos métodos**

  Substituir o conteúdo completo de `lib/presentation/controllers/auth_controller.dart`:

  ```dart
  // lib/presentation/controllers/auth_controller.dart

  import 'dart:async';

  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:hive_flutter/hive_flutter.dart';
  import '../../data/models/player_profile.dart';
  import '../../domain/auth/auth_service.dart';
  import '../../domain/invites/invite_service.dart';
  import '../../domain/sync/sync_engine.dart';
  import '../../data/repositories/iap_startup_service.dart';

  class AuthController extends Notifier<PlayerProfile?> {
    @override
    PlayerProfile? build() => ref.read(authServiceProvider).currentProfile;

    Future<void> signInWithGoogle() async {
      final profile = await ref.read(authServiceProvider).signInWithGoogle();
      state = profile;
      try {
        await ref
            .read(syncEngineProvider)
            .init(profile.userId, displayName: profile.displayName);
        await ref.read(syncEngineProvider).syncProfile();
        await ref.read(syncEngineProvider).drainPendingEvents();
        _initIAPStartup(profile.userId);
        unawaited(_registerPendingInvite(profile));
      } catch (_) {
        state = null;
        rethrow;
      }
    }

    Future<void> signInWithApple() async {
      final profile = await ref.read(authServiceProvider).signInWithApple();
      state = profile;
      try {
        await ref
            .read(syncEngineProvider)
            .init(profile.userId, displayName: profile.displayName);
        await ref.read(syncEngineProvider).syncProfile();
        await ref.read(syncEngineProvider).drainPendingEvents();
        _initIAPStartup(profile.userId);
        unawaited(_registerPendingInvite(profile));
      } catch (_) {
        state = null;
        rethrow;
      }
    }

    Future<void> signInWithEmail(String email, String password) async {
      final profile = await ref
          .read(authServiceProvider)
          .signInWithEmail(email, password);
      state = profile;
      try {
        await ref
            .read(syncEngineProvider)
            .init(profile.userId, displayName: profile.displayName);
        await ref.read(syncEngineProvider).syncProfile();
        // Fix: restaurar avatar tile salvo no Firestore (apenas e-mail)
        final tileAvatar = ref.read(syncEngineProvider).remoteAvatarUrl;
        if (tileAvatar != null && tileAvatar.startsWith('tile:')) {
          state = state!.copyWith(avatarUrl: tileAvatar);
        }
        await ref.read(syncEngineProvider).drainPendingEvents();
        _initIAPStartup(profile.userId);
        unawaited(_registerPendingInvite(profile));
      } catch (_) {
        state = null;
        rethrow;
      }
    }

    Future<void> createAccountWithEmail(
      String email,
      String password,
      String displayName,
    ) async {
      final profile = await ref
          .read(authServiceProvider)
          .createAccountWithEmail(email, password, displayName);
      state = profile;
      // New account: no remote data to sync yet — only init the engine.
      await ref
          .read(syncEngineProvider)
          .init(profile.userId, displayName: profile.displayName);
      _initIAPStartup(profile.userId);
      unawaited(_registerPendingInvite(profile));
    }

    Future<void> updateDisplayName(String name) async {
      if (state == null) return;
      state = state!.copyWith(displayName: name);
      try {
        await ref.read(authServiceProvider).updateDisplayName(name);
        await ref.read(syncEngineProvider).updateDisplayName(name);
      } catch (_) {
        // Local state already updated; remote failure is non-fatal
      }
    }

    Future<void> deleteAccount({String? senha}) async {
      // 1. Deletar dados no Firestore primeiro (pode falhar sem bloquear)
      try {
        await ref.read(syncEngineProvider).deleteUserData();
      } catch (_) {}

      // 2. Limpar todos os boxes Hive locais
      const boxNames = [
        'inventory',
        'lives',
        'personal_records',
        'pending_events',
        'daily_rewards',
        'invite_refs',
        'game_records',
        'ranking_rewards',
      ];
      for (final name in boxNames) {
        try {
          final box = await Hive.openBox(name);
          await box.clear();
        } catch (_) {}
      }

      // 3. Deletar conta no Firebase Auth (inclui re-autenticação)
      await ref.read(authServiceProvider).deleteAccount(senha: senha);

      // 4. Dispose serviços
      unawaited(ref.read(iapStartupServiceProvider).dispose());
      try {
        await ref.read(syncEngineProvider).dispose();
      } catch (_) {}

      // 5. Limpar state
      state = null;
    }

    Future<void> signOut() async {
      await ref.read(authServiceProvider).signOut();
      unawaited(ref.read(iapStartupServiceProvider).dispose());
      await ref.read(syncEngineProvider).dispose();
      state = null;
    }

    Future<void> updateAvatar(String? avatarUrl) async {
      if (state == null) return;
      state = state!.copyWith(avatarUrl: avatarUrl);
      try {
        await ref.read(syncEngineProvider).updateAvatar(avatarUrl);
      } catch (_) {}
    }

    void _initIAPStartup(String userId) {
      unawaited(ref.read(iapStartupServiceProvider).initialize(userId));
    }

    Future<void> _registerPendingInvite(PlayerProfile profile) async {
      try {
        final box = await Hive.openBox<String>('invite_refs');
        final inviterId = box.get('pending_ref');
        if (inviterId == null || inviterId.isEmpty) return;
        final inviteService = ref.read(inviteServiceProvider);
        await inviteService.registerInvite(
          inviterId: inviterId,
          inviteeId: profile.userId,
          inviteeDisplayName: profile.displayName,
        );
      } catch (_) {}
    }

    bool get isLoggedIn => state != null;
  }

  final authControllerProvider = NotifierProvider<AuthController, PlayerProfile?>(
    AuthController.new,
  );
  ```

- [ ] **Step 2: Verificar compilação**

  ```bash
  flutter analyze lib/presentation/controllers/auth_controller.dart
  ```
  Expected: No issues found.

- [ ] **Step 3: Commit**

  ```bash
  git add lib/presentation/controllers/auth_controller.dart
  git commit -m "feat: AuthController — deleteAccount, updateDisplayName, fix avatar e-mail no login"
  ```

---

## Task 7: game_notifier — sync de gameRecord e auth check no ranking

**Spec:** C6b (sync) + regra geral (ranking submissão)

**Files:**
- Modify: `lib/presentation/controllers/game_notifier.dart`

- [ ] **Step 1: Adicionar import do SyncEngine (se necessário)**

  Verificar se `sync_engine.dart` já está importado:

  ```bash
  grep "sync_engine" lib/presentation/controllers/game_notifier.dart
  ```

  Se não estiver, adicionar o import junto aos outros:

  ```dart
  import '../../domain/sync/sync_engine.dart';
  ```

- [ ] **Step 2: Atualizar `_saveGameRecord()` para sincronizar com Firestore**

  Localizar o bloco após `await ref.read(gameRecordRepositoryProvider).add(record);` e adicionar o sync:

  ```dart
  await ref.read(gameRecordRepositoryProvider).add(record);

  // Sync com Firestore se logado
  final authProfileForSync = ref.read(authControllerProvider);
  if (authProfileForSync != null) {
    unawaited(ref.read(syncEngineProvider).syncGameRecord(record));
  }
  ```

- [ ] **Step 3: Verificar compilação**

  ```bash
  flutter analyze lib/presentation/controllers/game_notifier.dart
  ```
  Expected: No issues found.

- [ ] **Step 4: Commit**

  ```bash
  git add lib/presentation/controllers/game_notifier.dart
  git commit -m "feat: game_notifier — sync gameRecord no Firestore quando logado"
  ```

---

## Task 8: AuthGateOverlay — novo widget

**Spec:** C3, C4

**Files:**
- Create: `lib/presentation/widgets/auth_gate_overlay.dart`
- Create: `test/presentation/widgets/auth_gate_overlay_test.dart`

- [ ] **Step 1: Escrever testes que falham**

  Criar `test/presentation/widgets/auth_gate_overlay_test.dart`:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:capivara_2048/data/models/player_profile.dart';
  import 'package:capivara_2048/domain/auth/auth_service.dart';
  import 'package:capivara_2048/presentation/controllers/auth_controller.dart';
  import 'package:capivara_2048/presentation/widgets/auth_gate_overlay.dart';

  Widget _buildTestApp({
    required PlayerProfile? profile,
    required Widget child,
    required VoidCallback onClose,
  }) {
    return ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(() {
          final notifier = AuthController();
          return notifier;
        }),
      ],
      child: MaterialApp(
        home: ProviderScope(
          overrides: [
            authControllerProvider
                .overrideWith(() => _FakeAuthController(profile)),
          ],
          child: Scaffold(
            body: AuthGateOverlay(
              reason: 'Teste de motivo',
              onClose: onClose,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  // Helper controller para testes
  class _FakeAuthController extends AuthController {
    _FakeAuthController(this._profile);
    final PlayerProfile? _profile;
    @override
    PlayerProfile? build() => _profile;
  }

  void main() {
    final fakeProfile = PlayerProfile(
      userId: 'u1',
      displayName: 'Jogador',
      provider: AuthProvider.email,
      createdAt: DateTime(2025),
      lastSeenAt: DateTime(2025),
    );

    testWidgets('exibe child quando logado', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        profile: fakeProfile,
        child: const Text('conteúdo protegido'),
        onClose: () {},
      ));
      expect(find.text('conteúdo protegido'), findsOneWidget);
      expect(find.text('Fazer login'), findsNothing);
    });

    testWidgets('exibe gate quando não logado', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        profile: null,
        child: const Text('conteúdo protegido'),
        onClose: () {},
      ));
      expect(find.text('conteúdo protegido'), findsNothing);
      expect(find.text('Fazer login'), findsOneWidget);
      expect(find.text('Teste de motivo'), findsOneWidget);
    });

    testWidgets('botão Agora não chama onClose', (tester) async {
      bool called = false;
      await tester.pumpWidget(_buildTestApp(
        profile: null,
        child: const Text('x'),
        onClose: () => called = true,
      ));
      await tester.tap(find.text('Agora não'));
      expect(called, isTrue);
    });
  }
  ```

- [ ] **Step 2: Rodar — esperar falha**

  ```bash
  flutter test test/presentation/widgets/auth_gate_overlay_test.dart
  ```

- [ ] **Step 3: Criar o widget**

  Criar `lib/presentation/widgets/auth_gate_overlay.dart`:

  ```dart
  // lib/presentation/widgets/auth_gate_overlay.dart

  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:google_fonts/google_fonts.dart';
  import '../../core/constants/app_colors.dart';
  import '../../core/theme/text_styles.dart';
  import '../controllers/auth_controller.dart';
  import '../screens/onboarding_auth_screen.dart';
  import 'game_title_image.dart';

  class AuthGateOverlay extends ConsumerWidget {
    const AuthGateOverlay({
      super.key,
      required this.child,
      required this.reason,
      required this.onClose,
    });

    final Widget child;
    final String reason;
    final VoidCallback onClose;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final isLoggedIn = ref.watch(authControllerProvider) != null;
      if (isLoggedIn) return child;

      return Container(
        color: Colors.black.withOpacity(0.85),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GameTitleImage(height: 80),
                const SizedBox(height: 24),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: outlinedWhiteTextStyle(
                    GoogleFonts.fredoka(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),
                ..._buildBenefits(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OnboardingAuthScreen(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C42),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Fazer login',
                      style: GoogleFonts.fredoka(
                          fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onClose,
                  child: Text(
                    'Agora não',
                    style: outlinedWhiteTextStyle(
                        GoogleFonts.fredoka(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    List<Widget> _buildBenefits() {
      const items = [
        (Icons.sync_alt, 'Progresso salvo em todos os dispositivos'),
        (Icons.emoji_events, 'Ranking global semanal'),
        (Icons.card_giftcard, 'Recompensas diárias com itens'),
        (Icons.shopping_bag, 'Acesso à loja de itens'),
      ];
      return items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(item.$1, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: outlinedWhiteTextStyle(
                          GoogleFonts.fredoka(fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList();
    }
  }
  ```

- [ ] **Step 4: Rodar testes**

  ```bash
  flutter test test/presentation/widgets/auth_gate_overlay_test.dart
  ```
  Expected: 3 tests passed.

- [ ] **Step 5: Commit**

  ```bash
  git add lib/presentation/widgets/auth_gate_overlay.dart \
          test/presentation/widgets/auth_gate_overlay_test.dart
  git commit -m "feat: AuthGateOverlay — widget de auth gate para overlays do jogo"
  ```

---

## Task 9: ShopOverlay — integrar AuthGateOverlay

**Spec:** C4

**Files:**
- Modify: `lib/presentation/widgets/shop_overlay.dart`

- [ ] **Step 1: Envolver o conteúdo da ShopOverlay**

  Na `_ShopOverlayState.build()`, o return atual começa com um `Container` ou similar. Envolver todo o conteúdo retornado com `AuthGateOverlay`:

  Localizar o `build` de `_ShopOverlayState` e substituir o `return` para envolver com:

  ```dart
  @override
  Widget build(BuildContext context) {
    return AuthGateOverlay(
      reason: 'Para acessar a Loja você precisa estar conectado.',
      onClose: widget.onClose,
      child: _buildShopContent(context),
    );
  }
  ```

  Extrair o conteúdo atual do `build` para um método `_buildShopContent(BuildContext context)` (mover tudo que estava no `return` para esse método).

  Adicionar o import no topo:

  ```dart
  import 'auth_gate_overlay.dart';
  ```

- [ ] **Step 2: Verificar compilação**

  ```bash
  flutter analyze lib/presentation/widgets/shop_overlay.dart
  ```
  Expected: No issues found.

- [ ] **Step 3: Commit**

  ```bash
  git add lib/presentation/widgets/shop_overlay.dart
  git commit -m "feat: ShopOverlay — auth gate para usuários não logados"
  ```

---

## Task 10: OnboardingAuthScreen — showSkip e bloco de benefícios

**Spec:** C2

**Files:**
- Modify: `lib/presentation/screens/onboarding_auth_screen.dart`

- [ ] **Step 1: Adicionar parâmetro `showSkip` e ajustar navegação pós-login**

  Localizar a declaração da classe `OnboardingAuthScreen`:

  ```dart
  // ANTES
  class OnboardingAuthScreen extends ConsumerStatefulWidget {
    const OnboardingAuthScreen({super.key});
  ```

  Substituir por:

  ```dart
  class OnboardingAuthScreen extends ConsumerStatefulWidget {
    const OnboardingAuthScreen({super.key, this.showSkip = false});
    final bool showSkip;
  ```

- [ ] **Step 2: Ajustar `_navigateHome()` para usar pop quando mid-app**

  Localizar `_navigateHome()` e substituir:

  ```dart
  void _navigateHome() {
    if (widget.showSkip) {
      // Startup: substitui a pilha completa pela Home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      // Mid-app: retorna ao contexto anterior
      Navigator.of(context).pop();
    }
  }
  ```

- [ ] **Step 3: Adicionar bloco de benefícios e botão "Jogar sem conta"**

  No `build()`, logo acima dos botões de login (onde começa a seção dos botões), adicionar condicionalmente:

  ```dart
  if (widget.showSkip) ...[
    _BenefitsBlock(),
    const SizedBox(height: 24),
  ],
  ```

  E após os botões de login (no final do Column dos botões), adicionar:

  ```dart
  if (widget.showSkip) ...[
    const SizedBox(height: 16),
    TextButton(
      onPressed: _navigateHome,
      child: Text(
        'Jogar sem conta →',
        style: outlinedWhiteTextStyle(
          GoogleFonts.fredoka(fontSize: 16, color: Colors.white),
        ),
      ),
    ),
  ],
  ```

- [ ] **Step 4: Criar o widget `_BenefitsBlock` ao final do arquivo**

  ```dart
  class _BenefitsBlock extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      const items = [
        (Icons.sync_alt, 'Progresso salvo em todos os dispositivos'),
        (Icons.emoji_events, 'Ranking global semanal'),
        (Icons.card_giftcard, 'Recompensas diárias com itens'),
        (Icons.shopping_bag, 'Acesso à loja de itens'),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Por que fazer login?',
            style: outlinedWhiteTextStyle(
              GoogleFonts.fredoka(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(item.$1, color: Colors.white70, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    item.$2,
                    style: outlinedWhiteTextStyle(
                        GoogleFonts.fredoka(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }
  ```

- [ ] **Step 5: Verificar compilação**

  ```bash
  flutter analyze lib/presentation/screens/onboarding_auth_screen.dart
  ```

- [ ] **Step 6: Commit**

  ```bash
  git add lib/presentation/screens/onboarding_auth_screen.dart
  git commit -m "feat: OnboardingAuthScreen — showSkip, bloco de benefícios, botão jogar sem conta"
  ```

---

## Task 11: SplashScreen — auth gate na navegação

**Spec:** C1

**Files:**
- Modify: `lib/presentation/screens/splash_screen.dart`

- [ ] **Step 1: Converter para ConsumerStatefulWidget e adicionar auth check**

  Substituir o conteúdo completo de `lib/presentation/screens/splash_screen.dart`:

  ```dart
  import 'dart:async';
  import 'package:flutter/material.dart';
  import 'package:flutter_animate/flutter_animate.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import '../controllers/auth_controller.dart';
  import 'home_screen.dart';
  import 'onboarding_auth_screen.dart';

  class SplashScreen extends ConsumerStatefulWidget {
    const SplashScreen({super.key, this.precacheFuture});

    final Future<void>? precacheFuture;

    static const Duration minDuration = Duration(milliseconds: 1500);
    static const Duration maxWait = Duration(seconds: 4);

    @override
    ConsumerState<SplashScreen> createState() => _SplashScreenState();
  }

  class _SplashScreenState extends ConsumerState<SplashScreen> {
    Timer? _navTimer;
    bool _navigated = false;

    @override
    void initState() {
      super.initState();
      _scheduleNavigation();
    }

    Future<void> _scheduleNavigation() async {
      final shownAt = DateTime.now();
      if (widget.precacheFuture != null) {
        try {
          await widget.precacheFuture!.timeout(SplashScreen.maxWait);
        } catch (_) {}
      }
      if (!mounted) return;
      final elapsed = DateTime.now().difference(shownAt);
      final remaining = SplashScreen.minDuration - elapsed;
      if (remaining > Duration.zero) {
        _navTimer = Timer(remaining, _navigate);
      } else {
        _navigate();
      }
    }

    void _navigate() {
      if (!mounted || _navigated) return;
      _navigated = true;
      final isLoggedIn = ref.read(authControllerProvider) != null;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isLoggedIn
              ? const HomeScreen()
              : const OnboardingAuthScreen(showSkip: true),
        ),
      );
    }

    @override
    void dispose() {
      _navTimer?.cancel();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: const Color(0xFF1B3610),
        body: SizedBox.expand(
          child: Image.asset(
            'assets/images/splash/splashscreen.png',
            fit: BoxFit.cover,
          ).animate().fadeIn(duration: 400.ms),
        ),
      );
    }
  }
  ```

- [ ] **Step 2: Verificar compilação**

  ```bash
  flutter analyze lib/presentation/screens/splash_screen.dart
  ```

- [ ] **Step 3: Commit**

  ```bash
  git add lib/presentation/screens/splash_screen.dart
  git commit -m "feat: SplashScreen — redirecionar para OnboardingAuthScreen quando não logado"
  ```

---

## Task 12: EmailAuthScreen — campo nome no signup + esqueci a senha

**Spec:** A2, A3+A4

**Files:**
- Modify: `lib/presentation/screens/email_auth_screen.dart`

- [ ] **Step 1: Adicionar controller `_nameCtrl` e campo de nome**

  Localizar a declaração dos controllers no `_EmailAuthScreenState`:

  ```dart
  // ANTES
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  ```

  Substituir por:

  ```dart
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  ```

  No `dispose()`, adicionar `_nameCtrl.dispose();` antes dos demais.

- [ ] **Step 2: Adicionar validação de nome**

  Após `_validateEmail`, adicionar:

  ```dart
  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Informe seu nome';
    if (v.trim().length < 2) return 'Mínimo 2 caracteres';
    if (v.trim().length > 30) return 'Máximo 30 caracteres';
    return null;
  }
  ```

- [ ] **Step 3: Adicionar o campo de nome no formulário (apenas signup)**

  No build do formulário, antes do campo de e-mail, adicionar condicionalmente:

  ```dart
  if (_isSignUp) ...[
    TextFormField(
      controller: _nameCtrl,
      decoration: const InputDecoration(
        labelText: 'Nome',
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: _validateName,
      textInputAction: TextInputAction.next,
    ),
    const SizedBox(height: 16),
  ],
  ```

- [ ] **Step 4: Atualizar chamada de `createAccountWithEmail` para passar displayName**

  Localizar o call de `createAccountWithEmail` no handler de submit e atualizar:

  ```dart
  // ANTES
  await controller.createAccountWithEmail(_emailCtrl.text.trim(), _passCtrl.text);

  // DEPOIS
  await controller.createAccountWithEmail(
    _emailCtrl.text.trim(),
    _passCtrl.text,
    _nameCtrl.text.trim(),
  );
  ```

- [ ] **Step 5: Adicionar link "Esqueci minha senha" no modo login**

  Após o botão "Entrar" (apenas quando `!_isSignUp`), adicionar:

  ```dart
  if (!_isSignUp) ...[
    const SizedBox(height: 8),
    TextButton(
      onPressed: _loading ? null : _handleForgotPassword,
      child: Text(
        'Esqueci minha senha',
        style: GoogleFonts.fredoka(fontSize: 14, color: Colors.white70),
      ),
    ),
  ],
  ```

- [ ] **Step 6: Implementar `_handleForgotPassword`**

  Adicionar o método no `_EmailAuthScreenState`:

  ```dart
  Future<void> _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      // Focar no campo de e-mail com mensagem de erro
      _formKey.currentState?.validate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o e-mail para redefinir a senha.'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('E-mail de redefinição enviado para $email'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao enviar e-mail. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  ```

  Adicionar o import de `authServiceProvider`:

  ```dart
  import '../../domain/auth/auth_service.dart';
  ```

- [ ] **Step 7: Limpar `_nameCtrl` ao alternar modo login/signup**

  Localizar onde `_isSignUp` é alternado e adicionar limpeza:

  ```dart
  setState(() {
    _isSignUp = !_isSignUp;
    _nameCtrl.clear();   // adicionar esta linha
    _passCtrl.clear();
    _confirmCtrl.clear();
  });
  ```

- [ ] **Step 8: Verificar compilação**

  ```bash
  flutter analyze lib/presentation/screens/email_auth_screen.dart
  ```

- [ ] **Step 9: Commit**

  ```bash
  git add lib/presentation/screens/email_auth_screen.dart
  git commit -m "feat: EmailAuthScreen — campo nome no cadastro e link esqueci senha"
  ```

---

## Task 13: ProfileScreen — exclusão, editar nome, trocar senha, ocultar avatar Google

**Spec:** A1, A2, A3, B

**Files:**
- Modify: `lib/presentation/screens/profile_screen.dart`

- [ ] **Step 1: Converter `_LoggedIn` para `ConsumerStatefulWidget`**

  Substituir a declaração de `_LoggedIn`:

  ```dart
  // ANTES
  class _LoggedIn extends ConsumerWidget {
    const _LoggedIn({required this.profile, required this.onSignOut});
    final PlayerProfile profile;
    final VoidCallback onSignOut;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
  ```

  Por:

  ```dart
  class _LoggedIn extends ConsumerStatefulWidget {
    const _LoggedIn({required this.profile, required this.onSignOut});
    final PlayerProfile profile;
    final VoidCallback onSignOut;

    @override
    ConsumerState<_LoggedIn> createState() => _LoggedInState();
  }

  class _LoggedInState extends ConsumerState<_LoggedIn> {
    bool _deletingAccount = false;

    @override
    Widget build(BuildContext context) {
      final profile = widget.profile;
  ```

- [ ] **Step 2: Ocultar botão de editar avatar para contas Google**

  Localizar o `Positioned` com o botão de editar avatar e envolver com condição:

  ```dart
  if (profile.provider == AuthProvider.email)
    Positioned(
      bottom: 0,
      right: 0,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AvatarPickerScreen(
              onDone: (ctx) => Navigator.of(ctx).pop(),
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D52),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: const Icon(
            Icons.edit,
            color: Colors.white,
            size: 14,
          ),
        ),
      ),
    ),
  ```

- [ ] **Step 3: Adicionar lápis de edição do nome (apenas email)**

  Localizar o `Text(profile.displayName, ...)` e substituir por:

  ```dart
  Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        profile.displayName,
        style: outlinedWhiteTextStyle(
          GoogleFonts.fredoka(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      if (profile.provider == AuthProvider.email) ...[
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _editName(context, profile),
          child: const Icon(Icons.edit, color: Colors.white70, size: 18),
        ),
      ],
    ],
  ),
  ```

- [ ] **Step 4: Implementar `_editName`**

  Adicionar na `_LoggedInState`:

  ```dart
  Future<void> _editName(BuildContext context, PlayerProfile profile) async {
    final ctrl = TextEditingController(text: profile.displayName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar nome',
            style: GoogleFonts.fredoka(
                fontSize: 20, color: const Color(0xFF3E2723))),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.length >= 2) Navigator.pop(ctx, v);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      await ref.read(authControllerProvider.notifier).updateDisplayName(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nome atualizado!')),
        );
      }
    }
  }
  ```

- [ ] **Step 5: Adicionar ListTile "Trocar senha" (apenas email)**

  Na lista do `ListView`, após o ListTile de "Convidar Amigos", adicionar:

  ```dart
  if (profile.provider == AuthProvider.email) ...[
    const SizedBox(height: 8),
    ListTile(
      leading: const Icon(Icons.lock_reset, color: Colors.white),
      title: Text(
        'Trocar senha',
        style: outlinedWhiteTextStyle(GoogleFonts.fredoka()),
      ),
      onTap: () => _sendPasswordReset(context, profile),
    ),
  ],
  ```

- [ ] **Step 6: Implementar `_sendPasswordReset`**

  ```dart
  Future<void> _sendPasswordReset(
      BuildContext context, PlayerProfile profile) async {
    if (profile.email == null) return;
    try {
      await ref.read(authServiceProvider).sendPasswordReset(profile.email!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'E-mail de redefinição enviado para ${profile.email}'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erro ao enviar e-mail. Tente novamente.')),
        );
      }
    }
  }
  ```

  Adicionar import de `authServiceProvider`:

  ```dart
  import '../../domain/auth/auth_service.dart';
  ```

- [ ] **Step 7: Adicionar ListTile "Excluir conta" (vermelho, ao final)**

  No final da lista, após o ListTile de "Sair":

  ```dart
  const SizedBox(height: 16),
  const Divider(color: Colors.redAccent),
  ListTile(
    leading: const Icon(Icons.delete_forever, color: Colors.red),
    title: Text(
      'Excluir conta',
      style: outlinedWhiteTextStyle(GoogleFonts.fredoka())
          .copyWith(color: Colors.red),
    ),
    onTap: _deletingAccount ? null : () => _confirmDeleteAccount(context, profile),
  ),
  ```

- [ ] **Step 8: Implementar `_confirmDeleteAccount`**

  ```dart
  Future<void> _confirmDeleteAccount(
      BuildContext context, PlayerProfile profile) async {
    // Diálogo 1: aviso geral
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Excluir conta?',
            style: GoogleFonts.fredoka(
                fontSize: 20, color: const Color(0xFF3E2723))),
        content: Text(
          'Todos os seus dados serão apagados permanentemente: '
          'progresso, inventário, histórico e ranking.',
          style: GoogleFonts.nunito(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar →',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return;

    // Diálogo 2: digitar "EXCLUIR"
    String? senha;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDeleteDialog(
        isEmail: profile.provider == AuthProvider.email,
        onConfirm: (s) {
          senha = s;
          Navigator.pop(ctx, true);
        },
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    setState(() => _deletingAccount = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .deleteAccount(senha: senha);
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir conta: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }
  ```

- [ ] **Step 9: Criar `_ConfirmDeleteDialog` ao final do arquivo**

  ```dart
  class _ConfirmDeleteDialog extends StatefulWidget {
    const _ConfirmDeleteDialog({
      required this.isEmail,
      required this.onConfirm,
      required this.onCancel,
    });
    final bool isEmail;
    final void Function(String? senha) onConfirm;
    final VoidCallback onCancel;

    @override
    State<_ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
  }

  class _ConfirmDeleteDialogState extends State<_ConfirmDeleteDialog> {
    final _confirmCtrl = TextEditingController();
    final _senhaCtrl = TextEditingController();
    bool _canDelete = false;
    bool _showSenha = false;

    @override
    void dispose() {
      _confirmCtrl.dispose();
      _senhaCtrl.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return AlertDialog(
        title: Text('Confirmar exclusão',
            style: GoogleFonts.fredoka(
                fontSize: 20, color: const Color(0xFF3E2723))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Digite EXCLUIR para confirmar:',
                style: GoogleFonts.nunito(fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmCtrl,
              decoration: const InputDecoration(labelText: 'EXCLUIR'),
              onChanged: (v) =>
                  setState(() => _canDelete = v == 'EXCLUIR'),
            ),
            if (widget.isEmail) ...[
              const SizedBox(height: 16),
              Text('Confirme sua senha:',
                  style: GoogleFonts.nunito(fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _senhaCtrl,
                obscureText: !_showSenha,
                decoration: InputDecoration(
                  labelText: 'Senha atual',
                  suffixIcon: IconButton(
                    icon: Icon(_showSenha
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _showSenha = !_showSenha),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: widget.onCancel,
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _canDelete
                ? () => widget.onConfirm(
                    widget.isEmail ? _senhaCtrl.text : null)
                : null,
            child: const Text('Excluir conta',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    }
  }
  ```

  Adicionar import de `home_screen.dart` (para navegação pós-exclusão):

  ```dart
  import 'home_screen.dart';
  ```

- [ ] **Step 10: Verificar compilação**

  ```bash
  flutter analyze lib/presentation/screens/profile_screen.dart
  ```

- [ ] **Step 11: Commit**

  ```bash
  git add lib/presentation/screens/profile_screen.dart
  git commit -m "feat: ProfileScreen — exclusão LGPD, editar nome, trocar senha, ocultar avatar Google"
  ```

---

## Task 14: HomeScreen — auth guards para DailyRewards e ShopScreen

**Spec:** C5, C7

**Files:**
- Modify: `lib/presentation/screens/home_screen.dart`

- [ ] **Step 1: Adicionar método `_navGuarded` e atualizar navegações**

  Localizar o método `_nav`:

  ```dart
  void _nav(Widget screen) {
    maybeHaptic(ref);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
  ```

  Adicionar logo após:

  ```dart
  void _navGuarded(Widget screen) {
    maybeHaptic(ref);
    final isLoggedIn = ref.read(authControllerProvider) != null;
    if (!isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingAuthScreen(showSkip: false),
        ),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
  ```

  Adicionar o import de `onboarding_auth_screen.dart` se não existir:

  ```dart
  import 'onboarding_auth_screen.dart';
  ```

- [ ] **Step 2: Trocar `_nav` por `_navGuarded` nas navegações protegidas**

  Localizar as linhas de navegação para `DailyRewardsScreen` e `ShopScreen` e substituir `_nav` por `_navGuarded`:

  ```dart
  // DailyRewards
  onTap: () => _navGuarded(const DailyRewardsScreen()),

  // ShopScreen
  onTap: () => _navGuarded(const ShopScreen()),
  ```

- [ ] **Step 3: Verificar compilação**

  ```bash
  flutter analyze lib/presentation/screens/home_screen.dart
  ```

- [ ] **Step 4: Commit**

  ```bash
  git add lib/presentation/screens/home_screen.dart
  git commit -m "feat: HomeScreen — auth guard para DailyRewards e ShopScreen"
  ```

---

## Task 15: RankingScreen — banner Lendas + sync pessoal

**Spec:** C6, C6b

**Files:**
- Modify: `lib/presentation/screens/ranking_screen.dart`

- [ ] **Step 1: Adicionar banner de login na aba Lendas**

  O `_LegendsRankingTab` existente retorna um widget de lista (provavelmente um `ListView` ou `Column`). Localizar o `return` final do `build()` de `_LegendsRankingTab` e envolver com `Column + Expanded`:

  ```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authControllerProvider) != null;
    final conteudoExistente = /* manter o widget retornado atualmente aqui */;
    return Column(
      children: [
        if (!isLoggedIn)
          _LoginBanner(
            message: 'Faça login para aparecer neste ranking.',
          ),
        Expanded(child: conteudoExistente),
      ],
    );
  }
  ```

  Na prática: ler o `build()` atual de `_LegendsRankingTab`, guardar o widget retornado em uma variável local `body`, e retornar o `Column` acima com `Expanded(child: body)`.

- [ ] **Step 2: Criar `_LoginBanner` widget privado ao final do arquivo**

  ```dart
  class _LoginBanner extends ConsumerWidget {
    const _LoginBanner({required this.message});
    final String message;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      return Container(
        width: double.infinity,
        color: Colors.black38,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: outlinedWhiteTextStyle(
                    GoogleFonts.fredoka(fontSize: 13)),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const OnboardingAuthScreen(showSkip: false),
                ),
              ),
              child: Text(
                'Entrar',
                style: outlinedWhiteTextStyle(
                  GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF8C42)),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
  ```

  Adicionar import:

  ```dart
  import 'onboarding_auth_screen.dart';
  ```

- [ ] **Step 3: Aba Pessoal — exibir dados do Hive (já mergeados no login)**

  A aba "Pessoal" já usa `gameRecordRepositoryProvider` que lê do Hive. Como o `_mergeRemoteGameRecords` no `syncProfile()` escreve no mesmo Hive box, a aba Pessoal automaticamente reflete os dados sincronizados após o login. **Nenhuma mudança adicional** é necessária na aba Pessoal.

- [ ] **Step 4: Verificar compilação**

  ```bash
  flutter analyze lib/presentation/screens/ranking_screen.dart
  ```

- [ ] **Step 5: Commit**

  ```bash
  git add lib/presentation/screens/ranking_screen.dart
  git commit -m "feat: RankingScreen — banner de login na aba Lendas"
  ```

---

## Task 16: Verificação final e suite de testes

- [ ] **Step 1: Rodar todos os testes**

  ```bash
  flutter test
  ```
  Expected: todos os testes existentes passam + novos testes verdes.

- [ ] **Step 2: Análise estática completa**

  ```bash
  flutter analyze lib/
  ```
  Expected: No issues found (ou apenas warnings existentes não relacionados).

- [ ] **Step 3: Build de verificação**

  ```bash
  flutter build apk --debug --flavor dev \
    --dart-define=FLAVOR=dev 2>&1 | tail -20
  ```
  Expected: `✓ Built build/app/outputs/...` sem erros de compilação.

- [ ] **Step 4: Commit de fechamento da fase**

  ```bash
  git add -A
  git commit -m "chore: verificação final Fase 4 conclusão — todos os testes passando"
  ```

---

## Ordem de execução recomendada

```
Task 1  → Task 2 → Task 3   (modelos + contratos — sem dependências entre si)
Task 4  → Task 5             (implementações Firebase — dependem de 2 e 3)
Task 6                       (AuthController — depende de 2, 3)
Task 7                       (game_notifier — depende de 3)
Task 8  → Task 9             (AuthGateOverlay + ShopOverlay — depende de 6)
Task 10 → Task 11            (OnboardingAuthScreen + SplashScreen)
Task 12 → Task 13            (EmailAuthScreen + ProfileScreen — dependem de 2, 6)
Task 14 → Task 15            (HomeScreen + RankingScreen — dependem de 8, 10)
Task 16                      (verificação final)
```
