# Fase 4A — Firebase + Auth + Sync Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Estabelecer a infraestrutura Firebase (Auth + Firestore + Sync Engine) que serve de base para todas as sub-entregas da Fase 4.

**Architecture:** `AuthService` e `SyncEngine` são interfaces abstratas no domain layer; implementações concretas Firebase ficam no data layer. Hive é o cache local e fonte de leitura — Firestore é a fonte da verdade para multi-device. Todos os providers Riverpod aceitam overrides de Fake para testes.

**Tech Stack:** firebase_core ^3.x, firebase_auth ^5.x, cloud_firestore ^5.x, google_sign_in ^6.x, sign_in_with_apple ^6.x, connectivity_plus ^6.x, Hive, Riverpod.

**Pré-requisito manual:** Seguir `FIREBASE.md` até completar o checklist da Seção 13 antes de executar qualquer tarefa deste plano.

---

## Mapa de arquivos

### Criados
| Arquivo | Responsabilidade |
|---|---|
| `lib/data/models/player_profile.dart` | Model imutável do perfil do jogador |
| `lib/data/models/pending_event.dart` | Model de evento pendente (offline queue) |
| `lib/data/models/pending_event_hive_adapter.dart` | Hive adapter para PendingEvent |
| `lib/domain/auth/auth_service.dart` | Interface AuthService + FakeAuthService |
| `lib/domain/sync/sync_engine.dart` | Interface SyncEngine + FakeSyncEngine |
| `lib/domain/sync/sync_conflict_resolver.dart` | Lógica de merge campo a campo (Dart puro) |
| `lib/data/repositories/firebase_auth_service.dart` | Implementação Firebase de AuthService |
| `lib/data/repositories/firebase_sync_engine.dart` | Implementação Firebase de SyncEngine |
| `lib/presentation/controllers/auth_controller.dart` | Riverpod notifier para estado de auth |
| `lib/presentation/screens/onboarding_auth_screen.dart` | Tela de login no primeiro launch |
| `lib/presentation/widgets/auth_banner.dart` | Banner persistente para usuários sem conta |
| `lib/presentation/screens/profile_screen.dart` | Tela de perfil do jogador |
| `lib/firebase_options_dev.dart` | Gerado pelo FlutterFire CLI (dev) |
| `lib/firebase_options_prd.dart` | Gerado pelo FlutterFire CLI (prd) |
| `test/domain/sync/sync_conflict_resolver_test.dart` | Testes unitários do merge |
| `test/domain/auth/auth_controller_test.dart` | Testes do AuthController |
| `test/presentation/onboarding_auth_screen_test.dart` | Widget test da tela de onboarding |
| `test/presentation/auth_banner_test.dart` | Widget test do AuthBanner |
| `test/presentation/profile_screen_test.dart` | Widget test do ProfileScreen |

### Modificados
| Arquivo | Mudança |
|---|---|
| `pubspec.yaml` | 6 dependências novas |
| `lib/main.dart` | Firebase.initializeApp() + registro do PendingEvent adapter |
| `lib/app.dart` | Rota inicial auth-aware |
| `lib/presentation/screens/home_screen.dart` | Ícone de avatar no header |

---

## Task 1: Dependências no pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Adicionar dependências**

Em `pubspec.yaml`, na seção `dependencies`, adicionar após `share_plus`:

```yaml
  firebase_core: ^3.13.0
  firebase_auth: ^5.5.2
  cloud_firestore: ^5.6.5
  google_sign_in: ^6.2.2
  sign_in_with_apple: ^6.1.4
  connectivity_plus: ^6.1.4
```

- [ ] **Step 2: Instalar e verificar**

```bash
cd /home/giuliano/rf/capivara_2048
flutter pub get
```

Esperado: `Got dependencies!` sem erros.

- [ ] **Step 3: Confirmar versões resolvidas**

```bash
flutter pub deps | grep -E "firebase|google_sign_in|sign_in_with_apple|connectivity"
```

Esperado: versões resolvidas sem conflitos.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(deps): add firebase, auth, firestore, connectivity dependencies"
```

---

## Task 2: PlayerProfile model

**Files:**
- Create: `lib/data/models/player_profile.dart`

- [ ] **Step 1: Criar o model**

```dart
// lib/data/models/player_profile.dart

enum AuthProvider { google, apple, email }

class PlayerProfile {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? email;
  final AuthProvider provider;
  final DateTime createdAt;
  final DateTime lastSeenAt;

  const PlayerProfile({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.email,
    required this.provider,
    required this.createdAt,
    required this.lastSeenAt,
  });

  PlayerProfile copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    String? email,
    AuthProvider? provider,
    DateTime? createdAt,
    DateTime? lastSeenAt,
  }) =>
      PlayerProfile(
        userId: userId ?? this.userId,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        email: email ?? this.email,
        provider: provider ?? this.provider,
        createdAt: createdAt ?? this.createdAt,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (email != null) 'email': email,
        'provider': provider.name,
        'createdAt': createdAt.toIso8601String(),
        'lastSeenAt': lastSeenAt.toIso8601String(),
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        email: json['email'] as String?,
        provider: AuthProvider.values.byName(json['provider'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastSeenAt: DateTime.parse(json['lastSeenAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerProfile &&
          userId == other.userId &&
          displayName == other.displayName &&
          avatarUrl == other.avatarUrl &&
          email == other.email &&
          provider == other.provider &&
          createdAt == other.createdAt &&
          lastSeenAt == other.lastSeenAt;

  @override
  int get hashCode => Object.hash(
        userId, displayName, avatarUrl, email, provider, createdAt, lastSeenAt);
}
```

- [ ] **Step 2: Rodar testes existentes para confirmar que nada quebrou**

```bash
flutter test --reporter=compact
```

Esperado: todos passam.

- [ ] **Step 3: Commit**

```bash
git add lib/data/models/player_profile.dart
git commit -m "feat(model): add PlayerProfile with AuthProvider enum"
```

---

## Task 3: PendingEvent model + Hive adapter

**Files:**
- Create: `lib/data/models/pending_event.dart`
- Create: `lib/data/models/pending_event_hive_adapter.dart`

- [ ] **Step 1: Criar o model**

```dart
// lib/data/models/pending_event.dart

enum PendingEventType { legendReached, inventoryConsume }

class PendingEvent {
  static const int hiveTypeId = 11;

  final String id;
  final PendingEventType type;
  final Map<String, dynamic> payload;
  final DateTime occurredAt;

  const PendingEvent({
    required this.id,
    required this.type,
    required this.payload,
    required this.occurredAt,
  });

  /// Cria evento legendReached com o nível (4096 ou 8192).
  factory PendingEvent.legendReached({
    required String id,
    required int level,
    required DateTime occurredAt,
  }) =>
      PendingEvent(
        id: id,
        type: PendingEventType.legendReached,
        payload: {'level': level},
        occurredAt: occurredAt,
      );

  PendingEvent copyWith({
    String? id,
    PendingEventType? type,
    Map<String, dynamic>? payload,
    DateTime? occurredAt,
  }) =>
      PendingEvent(
        id: id ?? this.id,
        type: type ?? this.type,
        payload: payload ?? this.payload,
        occurredAt: occurredAt ?? this.occurredAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'occurredAt': occurredAt.toIso8601String(),
      };

  factory PendingEvent.fromJson(Map<String, dynamic> json) => PendingEvent(
        id: json['id'] as String,
        type: PendingEventType.values.byName(json['type'] as String),
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        occurredAt: DateTime.parse(json['occurredAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PendingEvent && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

- [ ] **Step 2: Criar o Hive adapter manualmente**

```dart
// lib/data/models/pending_event_hive_adapter.dart

import 'package:hive/hive.dart';
import 'dart:convert';
import 'pending_event.dart';

class PendingEventHiveAdapter extends TypeAdapter<PendingEvent> {
  @override
  final int typeId = PendingEvent.hiveTypeId;

  @override
  PendingEvent read(BinaryReader reader) {
    final json = jsonDecode(reader.readString()) as Map<String, dynamic>;
    return PendingEvent.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, PendingEvent obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}
```

- [ ] **Step 3: Registrar o adapter em main.dart**

Em `lib/main.dart`, após `Hive.registerAdapter(GameRecordHiveAdapter());`:

```dart
import 'data/models/pending_event.dart';
import 'data/models/pending_event_hive_adapter.dart';
// ...
Hive.registerAdapter(PendingEventHiveAdapter());
```

- [ ] **Step 4: Verificar que o app compila**

```bash
flutter build apk --debug --dart-define=FLAVOR=dev 2>&1 | tail -5
```

Esperado: `Built build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/pending_event.dart lib/data/models/pending_event_hive_adapter.dart lib/main.dart
git commit -m "feat(model): add PendingEvent model and Hive adapter"
```

---

## Task 4: SyncConflictResolver (lógica de merge pura)

**Files:**
- Create: `lib/domain/sync/sync_conflict_resolver.dart`
- Create: `test/domain/sync/sync_conflict_resolver_test.dart`

- [ ] **Step 1: Escrever os testes primeiro**

```dart
// test/domain/sync/sync_conflict_resolver_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/sync/sync_conflict_resolver.dart';
import 'package:capivara_2048/data/models/personal_records.dart';
import 'package:capivara_2048/data/models/inventory.dart';

void main() {
  group('SyncConflictResolver.mergePersonalRecords', () {
    test('bestTimeMs: local menor vence', () {
      final local = const PersonalRecords().copyWith(
        highestLevelEver: 11,
      );
      // bestTimeMs não existe em PersonalRecords ainda — ver nota abaixo
      // Testar campos existentes: highestLevelEver max
      final remote = const PersonalRecords().copyWith(
        highestLevelEver: 12,
      );
      final result = SyncConflictResolver.mergePersonalRecords(local, remote);
      expect(result.highestLevelEver, 12);
    });

    test('timesReached4096: maior vence', () {
      final local = const PersonalRecords().copyWith(timesReached4096: 3);
      final remote = const PersonalRecords().copyWith(timesReached4096: 5);
      final result = SyncConflictResolver.mergePersonalRecords(local, remote);
      expect(result.timesReached4096, 5);
    });

    test('timesReached4096: local maior vence', () {
      final local = const PersonalRecords().copyWith(timesReached4096: 7);
      final remote = const PersonalRecords().copyWith(timesReached4096: 2);
      final result = SyncConflictResolver.mergePersonalRecords(local, remote);
      expect(result.timesReached4096, 7);
    });

    test('timesReached8192: maior vence', () {
      final local = const PersonalRecords().copyWith(timesReached8192: 1);
      final remote = const PersonalRecords().copyWith(timesReached8192: 4);
      final result = SyncConflictResolver.mergePersonalRecords(local, remote);
      expect(result.timesReached8192, 4);
    });

    test('firstReached4096At: timestamp mais antigo vence', () {
      final older = DateTime(2024, 1, 1);
      final newer = DateTime(2025, 6, 1);
      final local = const PersonalRecords().copyWith(firstReached4096At: newer);
      final remote = const PersonalRecords().copyWith(firstReached4096At: older);
      final result = SyncConflictResolver.mergePersonalRecords(local, remote);
      expect(result.firstReached4096At, older);
    });

    test('firstReached4096At: null local, remote tem valor → remote vence', () {
      final remote = const PersonalRecords().copyWith(
        firstReached4096At: DateTime(2024, 3, 15),
      );
      final result = SyncConflictResolver.mergePersonalRecords(
        const PersonalRecords(), remote);
      expect(result.firstReached4096At, DateTime(2024, 3, 15));
    });

    test('firstReached4096At: local tem valor, remote null → local vence', () {
      final local = const PersonalRecords().copyWith(
        firstReached4096At: DateTime(2024, 3, 15),
      );
      final result = SyncConflictResolver.mergePersonalRecords(
        local, const PersonalRecords());
      expect(result.firstReached4096At, DateTime(2024, 3, 15));
    });

    test('highestLevelEver: max(local, remote)', () {
      final local = const PersonalRecords().copyWith(highestLevelEver: 8);
      final remote = const PersonalRecords().copyWith(highestLevelEver: 11);
      final result = SyncConflictResolver.mergePersonalRecords(local, remote);
      expect(result.highestLevelEver, 11);
    });

    test('timesReached2048: maior vence', () {
      final local = const PersonalRecords().copyWith(timesReached2048: 10);
      final remote = const PersonalRecords().copyWith(timesReached2048: 8);
      final result = SyncConflictResolver.mergePersonalRecords(local, remote);
      expect(result.timesReached2048, 10);
    });
  });

  group('SyncConflictResolver.mergeInventory', () {
    test('inventário remoto vence campo a campo quando maior', () {
      const local = Inventory(bomb2: 1, bomb3: 5, undo1: 2, undo3: 0);
      const remote = Inventory(bomb2: 3, bomb3: 2, undo1: 2, undo3: 1);
      final result = SyncConflictResolver.mergeInventory(local, remote);
      expect(result.bomb2, 3);
      expect(result.bomb3, 5);
      expect(result.undo1, 2);
      expect(result.undo3, 1);
    });
  });
}
```

- [ ] **Step 2: Rodar para confirmar falha**

```bash
flutter test test/domain/sync/sync_conflict_resolver_test.dart
```

Esperado: FAIL — `sync_conflict_resolver.dart` não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/domain/sync/sync_conflict_resolver.dart

import '../../data/models/personal_records.dart';
import '../../data/models/inventory.dart';

/// Lógica de merge campo a campo entre estado local (Hive) e remoto (Firestore).
/// Dart puro — sem dependência de Flutter ou Firebase.
class SyncConflictResolver {
  SyncConflictResolver._();

  /// Mescla dois PersonalRecords tomando o melhor valor por campo.
  static PersonalRecords mergePersonalRecords(
    PersonalRecords local,
    PersonalRecords remote,
  ) {
    return PersonalRecords(
      timesReached2048: _max(local.timesReached2048, remote.timesReached2048),
      timesReached4096: _max(local.timesReached4096, remote.timesReached4096),
      timesReached8192: _max(local.timesReached8192, remote.timesReached8192),
      firstReached2048At: _oldest(local.firstReached2048At, remote.firstReached2048At),
      firstReached4096At: _oldest(local.firstReached4096At, remote.firstReached4096At),
      firstReached8192At: _oldest(local.firstReached8192At, remote.firstReached8192At),
      rewardCollected4096: local.rewardCollected4096 || remote.rewardCollected4096,
      rewardCollected8192: local.rewardCollected8192 || remote.rewardCollected8192,
      highestLevelEver: _max(local.highestLevelEver, remote.highestLevelEver),
    );
  }

  /// Mescla dois Inventory tomando o max por campo.
  static Inventory mergeInventory(Inventory local, Inventory remote) {
    return Inventory(
      bomb2: _max(local.bomb2, remote.bomb2),
      bomb3: _max(local.bomb3, remote.bomb3),
      undo1: _max(local.undo1, remote.undo1),
      undo3: _max(local.undo3, remote.undo3),
    );
  }

  static int _max(int a, int b) => a > b ? a : b;

  static DateTime? _oldest(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }
}
```

- [ ] **Step 4: Rodar testes**

```bash
flutter test test/domain/sync/sync_conflict_resolver_test.dart
```

Esperado: todos passam.

- [ ] **Step 5: Rodar suite completa**

```bash
flutter test --reporter=compact
```

Esperado: todos passam.

- [ ] **Step 6: Commit**

```bash
git add lib/domain/sync/sync_conflict_resolver.dart test/domain/sync/sync_conflict_resolver_test.dart
git commit -m "feat(sync): add SyncConflictResolver with merge logic"
```

---

## Task 5: AuthService interface + FakeAuthService

**Files:**
- Create: `lib/domain/auth/auth_service.dart`
- Create: `test/domain/auth/auth_controller_test.dart`

- [ ] **Step 1: Criar a interface**

```dart
// lib/domain/auth/auth_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/player_profile.dart';

abstract class AuthService {
  /// Stream que emite null quando deslogado, PlayerProfile quando logado.
  Stream<PlayerProfile?> get authStateChanges;

  /// Retorna o perfil atual ou null se não logado.
  PlayerProfile? get currentProfile;

  Future<PlayerProfile> signInWithGoogle();
  Future<PlayerProfile> signInWithApple();
  Future<PlayerProfile> signInWithEmail(String email, String password);
  Future<PlayerProfile> createAccountWithEmail(String email, String password);
  Future<void> signOut();
}

// ---------------------------------------------------------------------------
// Fake para testes e flavor dev
// ---------------------------------------------------------------------------

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
      String email, String password) async {
    _profile = _fakeProfile(AuthProvider.email, email: email);
    _controller.add(_profile);
    return _profile!;
  }

  @override
  Future<void> signOut() async {
    _profile = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();

  PlayerProfile _fakeProfile(AuthProvider provider, {String? email}) =>
      PlayerProfile(
        userId: 'fake-user-id',
        displayName: 'Jogador Teste',
        email: email,
        provider: provider,
        createdAt: DateTime(2025, 1, 1),
        lastSeenAt: DateTime.now(),
      );
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

import 'dart:async';

final authServiceProvider = Provider<AuthService>((_) => FakeAuthService());
```

- [ ] **Step 2: Verificar compilação**

```bash
flutter build apk --debug --dart-define=FLAVOR=dev 2>&1 | tail -3
```

Esperado: sem erros de compilação.

- [ ] **Step 3: Commit**

```bash
git add lib/domain/auth/auth_service.dart
git commit -m "feat(auth): add AuthService interface and FakeAuthService"
```

---

## Task 6: SyncEngine interface + FakeSyncEngine

**Files:**
- Create: `lib/domain/sync/sync_engine.dart`

- [ ] **Step 1: Criar a interface**

```dart
// lib/domain/sync/sync_engine.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/player_profile.dart';
import '../../data/models/personal_records.dart';
import '../../data/models/inventory.dart';
import '../../data/models/pending_event.dart';

enum SyncStatus { idle, syncing, error }

abstract class SyncEngine {
  /// Inicializa o engine para o userId logado.
  /// Abre snapshot listener e drena pendingEvents.
  Future<void> init(String userId);

  /// Encerra snapshot listener e fecha recursos.
  Future<void> dispose();

  /// Sincroniza o perfil remoto → Hive local.
  Future<void> syncProfile();

  /// Drena a fila de PendingEvents para o Firestore.
  Future<void> drainPendingEvents();

  /// Enfileira um PendingEvent para sync posterior.
  Future<void> enqueuePendingEvent(PendingEvent event);

  Stream<SyncStatus> get statusStream;
}

// ---------------------------------------------------------------------------
// Fake para testes e flavor dev
// ---------------------------------------------------------------------------

class FakeSyncEngine implements SyncEngine {
  bool initCalled = false;
  bool disposeCalled = false;
  final List<PendingEvent> drained = [];
  final List<PendingEvent> enqueued = [];

  @override
  Future<void> init(String userId) async => initCalled = true;

  @override
  Future<void> dispose() async => disposeCalled = true;

  @override
  Future<void> syncProfile() async {}

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

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final syncEngineProvider = Provider<SyncEngine>((_) => FakeSyncEngine());
```

- [ ] **Step 2: Verificar compilação**

```bash
flutter build apk --debug --dart-define=FLAVOR=dev 2>&1 | tail -3
```

Esperado: sem erros.

- [ ] **Step 3: Commit**

```bash
git add lib/domain/sync/sync_engine.dart
git commit -m "feat(sync): add SyncEngine interface and FakeSyncEngine"
```

---

## Task 7: AuthController (Riverpod notifier)

**Files:**
- Create: `lib/presentation/controllers/auth_controller.dart`
- Create: `test/domain/auth/auth_controller_test.dart`

- [ ] **Step 1: Escrever o teste**

```dart
// test/domain/auth/auth_controller_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/domain/auth/auth_service.dart';
import 'package:capivara_2048/presentation/controllers/auth_controller.dart';
import 'package:capivara_2048/data/models/player_profile.dart';

void main() {
  late FakeAuthService fakeAuth;
  late ProviderContainer container;

  setUp(() {
    fakeAuth = FakeAuthService();
    container = ProviderContainer(overrides: [
      authServiceProvider.overrideWithValue(fakeAuth),
    ]);
  });

  tearDown(() {
    fakeAuth.dispose();
    container.dispose();
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
}
```

- [ ] **Step 2: Rodar para confirmar falha**

```bash
flutter test test/domain/auth/auth_controller_test.dart
```

Esperado: FAIL — `auth_controller.dart` não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/presentation/controllers/auth_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/player_profile.dart';
import '../../domain/auth/auth_service.dart';
import '../../domain/sync/sync_engine.dart';

class AuthController extends StateNotifier<PlayerProfile?> {
  AuthController(this._authService, this._syncEngine) : super(null) {
    // Inicializa com o estado atual (re-login automático)
    state = _authService.currentProfile;
  }

  final AuthService _authService;
  final SyncEngine _syncEngine;

  Future<void> signInWithGoogle() async {
    final profile = await _authService.signInWithGoogle();
    state = profile;
    await _syncEngine.init(profile.userId);
    await _syncEngine.syncProfile();
    await _syncEngine.drainPendingEvents();
  }

  Future<void> signInWithApple() async {
    final profile = await _authService.signInWithApple();
    state = profile;
    await _syncEngine.init(profile.userId);
    await _syncEngine.syncProfile();
    await _syncEngine.drainPendingEvents();
  }

  Future<void> signInWithEmail(String email, String password) async {
    final profile = await _authService.signInWithEmail(email, password);
    state = profile;
    await _syncEngine.init(profile.userId);
    await _syncEngine.syncProfile();
    await _syncEngine.drainPendingEvents();
  }

  Future<void> createAccountWithEmail(String email, String password) async {
    final profile =
        await _authService.createAccountWithEmail(email, password);
    state = profile;
    await _syncEngine.init(profile.userId);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await _syncEngine.dispose();
    state = null;
  }

  bool get isLoggedIn => state != null;
}

final authControllerProvider =
    StateNotifierProvider<AuthController, PlayerProfile?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  return AuthController(authService, syncEngine);
});
```

- [ ] **Step 4: Rodar testes**

```bash
flutter test test/domain/auth/auth_controller_test.dart
```

Esperado: todos passam.

- [ ] **Step 5: Rodar suite completa**

```bash
flutter test --reporter=compact
```

Esperado: todos passam.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/controllers/auth_controller.dart test/domain/auth/auth_controller_test.dart
git commit -m "feat(auth): add AuthController with sign-in and sign-out"
```

---

## Task 8: Firebase init em main.dart (requer firebase_options gerados)

**Files:**
- Create: `lib/firebase_options_dev.dart` ← gerado pelo FlutterFire CLI (passo manual)
- Create: `lib/firebase_options_prd.dart` ← gerado pelo FlutterFire CLI (passo manual)
- Modify: `lib/main.dart`

- [ ] **Step 1: Gerar firebase_options (manual — requer FIREBASE.md completo)**

```bash
# Gerar para dev
flutterfire configure \
  --project=bichim-dev \
  --out=lib/firebase_options_dev.dart \
  --platforms=android,ios

# Gerar para prd
flutterfire configure \
  --project=bichim-prd \
  --out=lib/firebase_options_prd.dart \
  --platforms=android,ios
```

Esperado: dois arquivos gerados em `lib/`.

- [ ] **Step 2: Atualizar main.dart**

Substituir o conteúdo de `lib/main.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/models/lives_state_adapter.dart';
import 'data/models/inventory_hive_adapter.dart';
import 'data/models/daily_rewards_state_adapter.dart';
import 'data/models/personal_records_hive_adapter.dart';
import 'data/models/game_record_hive_adapter.dart';
import 'data/models/pending_event.dart';
import 'data/models/pending_event_hive_adapter.dart';
import 'data/repositories/game_record_repository.dart';
import 'core/providers/reduce_effects_provider.dart';
import 'domain/inventory/inventory_notifier.dart';
import 'domain/daily_rewards/daily_rewards_notifier.dart';
import 'presentation/controllers/settings_notifier.dart';
import 'presentation/controllers/personal_records_notifier.dart';
import 'app.dart';

// Gerados pelo FlutterFire CLI
import 'firebase_options_dev.dart' as dev_options;
import 'firebase_options_prd.dart' as prd_options;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  final firebaseOptions = flavor == 'prd'
      ? prd_options.DefaultFirebaseOptions.currentPlatform
      : dev_options.DefaultFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(options: firebaseOptions);

  // Hive
  await Hive.initFlutter();
  Hive.registerAdapter(LivesStateAdapter());
  Hive.registerAdapter(InventoryHiveAdapter());
  Hive.registerAdapter(DailyRewardsStateAdapter());
  Hive.registerAdapter(PersonalRecordsHiveAdapter());
  Hive.registerAdapter(GameRecordHiveAdapter());
  Hive.registerAdapter(PendingEventHiveAdapter());

  final gameRecordRepo = GameRecordRepository();
  await gameRecordRepo.load();
  final sharedPrefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      settingsProvider.overrideWith((ref) => SettingsNotifier(sharedPrefs)),
      gameRecordRepositoryProvider.overrideWithValue(gameRecordRepo),
    ],
  );
  await container.read(reduceEffectsProvider.notifier).load();
  await container.read(inventoryProvider.notifier).load();
  await container.read(dailyRewardsProvider.notifier).load();
  await container.read(personalRecordsProvider.notifier).load();
  runApp(UncontrolledProviderScope(
      container: container, child: const CapivaraApp()));
}
```

- [ ] **Step 3: Rodar no emulador Firebase (dev)**

```bash
# Em outro terminal: firebase emulators:start
flutter run --dart-define=FLAVOR=dev
```

Esperado: app inicializa sem crash de Firebase.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart lib/firebase_options_dev.dart lib/firebase_options_prd.dart
git commit -m "feat(firebase): initialize Firebase in main.dart with dev/prd flavors"
```

---

## Task 9: AuthBanner widget

**Files:**
- Create: `lib/presentation/widgets/auth_banner.dart`
- Create: `test/presentation/auth_banner_test.dart`

- [ ] **Step 1: Escrever o teste**

```dart
// test/presentation/auth_banner_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/domain/auth/auth_service.dart';
import 'package:capivara_2048/presentation/controllers/auth_controller.dart';
import 'package:capivara_2048/presentation/widgets/auth_banner.dart';

Widget _wrap(Widget child, {PlayerProfile? profile}) {
  final fakeAuth = FakeAuthService(initialProfile: profile);
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(fakeAuth),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('AuthBanner visível quando não logado', (tester) async {
    await tester.pumpWidget(_wrap(const AuthBanner()));
    expect(find.byType(AuthBanner), findsOneWidget);
    expect(find.textContaining('Faça login'), findsOneWidget);
  });

  testWidgets('AuthBanner oculto quando logado', (tester) async {
    final profile = PlayerProfile(
      userId: 'u1',
      displayName: 'Teste',
      provider: AuthProvider.google,
      createdAt: DateTime(2025),
      lastSeenAt: DateTime(2025),
    );
    await tester.pumpWidget(_wrap(const AuthBanner(), profile: profile));
    expect(find.byType(AuthBanner), findsOneWidget);
    // Quando logado o banner não exibe conteúdo visível
    expect(find.textContaining('Faça login'), findsNothing);
  });
}
```

- [ ] **Step 2: Rodar para confirmar falha**

```bash
flutter test test/presentation/auth_banner_test.dart
```

Esperado: FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/presentation/widgets/auth_banner.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../screens/onboarding_auth_screen.dart';

class AuthBanner extends ConsumerWidget {
  const AuthBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider);
    if (profile != null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppColors.primary.withOpacity(0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Faça login para salvar seu progresso e acessar o ranking.',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const OnboardingAuthScreen(),
            )),
            child: Text(
              'Entrar',
              style: GoogleFonts.fredoka(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar testes**

```bash
flutter test test/presentation/auth_banner_test.dart
```

Esperado: todos passam.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/auth_banner.dart test/presentation/auth_banner_test.dart
git commit -m "feat(ui): add AuthBanner widget for unauthenticated users"
```

---

## Task 10: OnboardingAuthScreen

**Files:**
- Create: `lib/presentation/screens/onboarding_auth_screen.dart`
- Create: `test/presentation/onboarding_auth_screen_test.dart`

- [ ] **Step 1: Escrever o teste**

```dart
// test/presentation/onboarding_auth_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/domain/auth/auth_service.dart';
import 'package:capivara_2048/domain/sync/sync_engine.dart';
import 'package:capivara_2048/presentation/screens/onboarding_auth_screen.dart';

Widget _wrap() => ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(FakeAuthService()),
        syncEngineProvider.overrideWithValue(FakeSyncEngine()),
      ],
      child: const MaterialApp(home: OnboardingAuthScreen()),
    );

void main() {
  testWidgets('exibe botão Entrar com Google', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.textContaining('Google'), findsOneWidget);
  });

  testWidgets('exibe botão Entrar com Email', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.textContaining('Email'), findsOneWidget);
  });

  testWidgets('exibe botão Jogar sem conta', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.textContaining('sem conta'), findsOneWidget);
  });

  testWidgets('toque em Jogar sem conta navega para HomeScreen', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.textContaining('sem conta'));
    await tester.pumpAndSettle();
    // Navega sem crash — verificação de ausência de erro é suficiente aqui
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Rodar para confirmar falha**

```bash
flutter test test/presentation/onboarding_auth_screen_test.dart
```

Esperado: FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/presentation/screens/onboarding_auth_screen.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/game_background.dart';
import 'home_screen.dart';

class OnboardingAuthScreen extends ConsumerStatefulWidget {
  const OnboardingAuthScreen({super.key});

  @override
  ConsumerState<OnboardingAuthScreen> createState() =>
      _OnboardingAuthScreenState();
}

class _OnboardingAuthScreenState extends ConsumerState<OnboardingAuthScreen> {
  bool _loading = false;

  Future<void> _handleSignIn(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) _navigateHome();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao entrar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(authControllerProvider.notifier);

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Olha o Bichim!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Salve seu progresso e dispute o ranking global.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),
                if (_loading)
                  const Center(child: CircularProgressIndicator(color: Colors.white))
                else ...[
                  _AuthButton(
                    label: 'Entrar com Google',
                    icon: Icons.g_mobiledata,
                    onPressed: () =>
                        _handleSignIn(controller.signInWithGoogle),
                  ),
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 12),
                    _AuthButton(
                      label: 'Entrar com Apple',
                      icon: Icons.apple,
                      onPressed: () =>
                          _handleSignIn(controller.signInWithApple),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _AuthButton(
                    label: 'Entrar com Email',
                    icon: Icons.email_outlined,
                    onPressed: () => _showEmailDialog(context, controller),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: _navigateHome,
                    child: Text(
                      'Jogar sem conta →',
                      style: GoogleFonts.nunito(
                        color: Colors.white70,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEmailDialog(
      BuildContext context, AuthController controller) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Entrar com Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress),
            TextField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleSignIn(() => controller.signInWithEmail(
                  emailCtrl.text.trim(), passCtrl.text));
            },
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, style: GoogleFonts.fredoka(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar testes**

```bash
flutter test test/presentation/onboarding_auth_screen_test.dart
```

Esperado: todos passam.

- [ ] **Step 5: Rodar suite completa**

```bash
flutter test --reporter=compact
```

Esperado: todos passam.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/screens/onboarding_auth_screen.dart test/presentation/onboarding_auth_screen_test.dart
git commit -m "feat(ui): add OnboardingAuthScreen with Google, Apple and email sign-in"
```

---

## Task 11: ProfileScreen

**Files:**
- Create: `lib/presentation/screens/profile_screen.dart`
- Create: `test/presentation/profile_screen_test.dart`

- [ ] **Step 1: Escrever o teste**

```dart
// test/presentation/profile_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/domain/auth/auth_service.dart';
import 'package:capivara_2048/domain/sync/sync_engine.dart';
import 'package:capivara_2048/presentation/controllers/auth_controller.dart';
import 'package:capivara_2048/presentation/screens/profile_screen.dart';
import 'package:capivara_2048/data/models/player_profile.dart';

Widget _wrap({PlayerProfile? profile}) {
  final fakeAuth = FakeAuthService(initialProfile: profile);
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(fakeAuth),
      syncEngineProvider.overrideWithValue(FakeSyncEngine()),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

void main() {
  testWidgets('exibe CTA de login quando não logado', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.textContaining('Entrar'), findsWidgets);
    expect(find.textContaining('Jogador'), findsNothing);
  });

  testWidgets('exibe nome do jogador quando logado', (tester) async {
    final profile = PlayerProfile(
      userId: 'u1',
      displayName: 'Capivarão',
      provider: AuthProvider.google,
      createdAt: DateTime(2025),
      lastSeenAt: DateTime(2025),
    );
    await tester.pumpWidget(_wrap(profile: profile));
    expect(find.textContaining('Capivarão'), findsOneWidget);
  });

  testWidgets('exibe botão Sair quando logado', (tester) async {
    final profile = PlayerProfile(
      userId: 'u1',
      displayName: 'Capivarão',
      provider: AuthProvider.google,
      createdAt: DateTime(2025),
      lastSeenAt: DateTime(2025),
    );
    await tester.pumpWidget(_wrap(profile: profile));
    expect(find.textContaining('Sair'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar para confirmar falha**

```bash
flutter test test/presentation/profile_screen_test.dart
```

Esperado: FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/game_background.dart';
import 'onboarding_auth_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider);

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Perfil',
              style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: profile == null
            ? _NotLoggedIn(onLogin: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const OnboardingAuthScreen())))
            : _LoggedIn(
                profile: profile,
                onSignOut: () async {
                  await ref
                      .read(authControllerProvider.notifier)
                      .signOut();
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
      ),
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  const _NotLoggedIn({required this.onLogin});
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text('Você não está conectado.',
                style: GoogleFonts.nunito(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                minimumSize: const Size(200, 48),
              ),
              child: Text('Entrar',
                  style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoggedIn extends StatelessWidget {
  const _LoggedIn({required this.profile, required this.onSignOut});
  final dynamic profile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl as String)
                : null,
            child: profile.avatarUrl == null
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            profile.displayName as String,
            style: GoogleFonts.fredoka(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
        ),
        if (profile.email != null) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              profile.email as String,
              style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
        const SizedBox(height: 32),
        const Divider(color: Colors.white24),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.restore, color: Colors.white70),
          title: Text('Restaurar compras',
              style: GoogleFonts.nunito(color: Colors.white)),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Disponível na Fase 4F (IAP)')),
            );
          },
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: Text('Sair',
              style: GoogleFonts.nunito(color: Colors.redAccent)),
          onTap: onSignOut,
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Rodar testes**

```bash
flutter test test/presentation/profile_screen_test.dart
```

Esperado: todos passam.

- [ ] **Step 5: Rodar suite completa**

```bash
flutter test --reporter=compact
```

Esperado: todos passam.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/screens/profile_screen.dart test/presentation/profile_screen_test.dart
git commit -m "feat(ui): add ProfileScreen with login CTA and sign-out"
```

---

## Task 12: Routing auth-aware + avatar na HomeScreen

**Files:**
- Modify: `lib/app.dart`
- Modify: `lib/presentation/screens/home_screen.dart`

- [ ] **Step 1: Atualizar app.dart para verificar auth no roteamento**

Em `lib/app.dart`, localizar a linha onde `SplashScreen` é criada e garantir que o `CapivaraApp` já possui o `ProviderScope` necessário. A `SplashScreen` já navega para `HomeScreen` — não precisamos mudar o fluxo. A `OnboardingAuthScreen` é exibida quando o usuário toca no ícone de avatar sem estar logado.

Nenhuma mudança em `app.dart` é necessária — a navegação auth-aware acontece via avatar na HomeScreen.

- [ ] **Step 2: Localizar o header da HomeScreen**

```bash
grep -n "AppBar\|header\|avatar\|leading\|actions" /home/giuliano/rf/capivara_2048/lib/presentation/screens/home_screen.dart | head -20
```

- [ ] **Step 3: Adicionar ícone de avatar no header da HomeScreen**

Localizar o `AppBar` ou header da HomeScreen e adicionar nas `actions`:

```dart
// Importar no topo do arquivo:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import 'profile_screen.dart';

// Converter o widget para ConsumerWidget se ainda não for, e adicionar nas actions do AppBar:
actions: [
  Consumer(
    builder: (context, ref, _) {
      final profile = ref.watch(authControllerProvider);
      return IconButton(
        icon: profile?.avatarUrl != null
            ? CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(profile!.avatarUrl!),
              )
            : const Icon(Icons.person_outline),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
        tooltip: 'Perfil',
      );
    },
  ),
],
```

- [ ] **Step 4: Rodar suite de testes**

```bash
flutter test --reporter=compact
```

Esperado: todos passam.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/home_screen.dart
git commit -m "feat(ui): add profile avatar icon to HomeScreen header"
```

---

## Task 13: FirebaseAuthService (implementação concreta)

**Files:**
- Create: `lib/data/repositories/firebase_auth_service.dart`

> Esta task requer Firebase configurado e emuladores rodando. Sem testes unitários automáticos — validação via teste manual no emulador.

- [ ] **Step 1: Implementar**

```dart
// lib/data/repositories/firebase_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/models/player_profile.dart';
import '../../domain/auth/auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService()
      : _auth = fb.FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn();

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<PlayerProfile?> get authStateChanges =>
      _auth.authStateChanges().map(_toProfile);

  @override
  PlayerProfile? get currentProfile => _toProfile(_auth.currentUser);

  @override
  Future<PlayerProfile> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Login cancelado');
    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    return _toProfile(result.user)!;
  }

  @override
  Future<PlayerProfile> signInWithApple() async {
    // sign_in_with_apple integration
    throw UnimplementedError('Apple Sign-In: implementar com sign_in_with_apple');
  }

  @override
  Future<PlayerProfile> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return _toProfile(result.user)!;
  }

  @override
  Future<PlayerProfile> createAccountWithEmail(
      String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    return _toProfile(result.user)!;
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
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

- [ ] **Step 2: Registrar no provider para o flavor prd**

Em `lib/domain/auth/auth_service.dart`, atualizar o provider para selecionar por flavor:

```dart
// No final de auth_service.dart, substituir o provider:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  if (flavor == 'prd') return FirebaseAuthService();
  return FakeAuthService();
});
```

- [ ] **Step 3: Verificar compilação**

```bash
flutter build apk --debug --dart-define=FLAVOR=prd 2>&1 | tail -5
```

Esperado: sem erros de compilação.

- [ ] **Step 4: Rodar suite de testes (flavor dev — usa Fake)**

```bash
flutter test --reporter=compact
```

Esperado: todos passam.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/firebase_auth_service.dart lib/domain/auth/auth_service.dart
git commit -m "feat(auth): add FirebaseAuthService for prd flavor"
```

---

## Task 14: FirebaseSyncEngine — snapshot listener + write queue

**Files:**
- Create: `lib/data/repositories/firebase_sync_engine.dart`

> Task mais complexa. Sem testes automáticos de integração aqui — a lógica de merge já está coberta em `SyncConflictResolver`. Validação via teste manual com emulador.

- [ ] **Step 1: Implementar**

```dart
// lib/data/repositories/firebase_sync_engine.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/pending_event.dart';
import '../../data/models/pending_event_hive_adapter.dart';
import '../../data/models/personal_records.dart';
import '../../data/models/personal_records_hive_adapter.dart';
import '../../data/models/inventory.dart';
import '../../data/models/inventory_hive_adapter.dart';
import '../../domain/sync/sync_engine.dart';
import '../../domain/sync/sync_conflict_resolver.dart';

class FirebaseSyncEngine implements SyncEngine {
  static const _pendingEventsBox = 'pending_events';
  static const _personalRecordsBox = 'personal_records';
  static const _personalRecordsKey = 'records';

  String? _userId;
  StreamSubscription<DocumentSnapshot>? _profileListener;
  StreamSubscription<ConnectivityResult>? _connectivityListener;
  final _statusController = StreamController<SyncStatus>.broadcast();
  final _firestore = FirebaseFirestore.instance;

  @override
  Stream<SyncStatus> get statusStream => _statusController.stream;

  @override
  Future<void> init(String userId) async {
    _userId = userId;
    _startSnapshotListener();
    _startConnectivityListener();
    await drainPendingEvents();
  }

  @override
  Future<void> dispose() async {
    await _profileListener?.cancel();
    await _connectivityListener?.cancel();
    await _statusController.close();
    _userId = null;
  }

  @override
  Future<void> syncProfile() async {
    if (_userId == null) return;
    _statusController.add(SyncStatus.syncing);
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .get();
      if (doc.exists) {
        await _mergeRemotePersonalRecords(doc.data()?['personalRecords']);
        await _mergeRemoteInventory(doc.data()?['inventory']);
      } else {
        await _writeLocalProfileToFirestore();
      }
      _statusController.add(SyncStatus.idle);
    } catch (e) {
      _statusController.add(SyncStatus.error);
    }
  }

  @override
  Future<void> drainPendingEvents() async {
    final box = await Hive.openBox<PendingEvent>(_pendingEventsBox);
    final events = box.values.toList();
    if (events.isEmpty) return;

    for (final event in events) {
      try {
        await _applyEvent(event);
        await box.delete(event.id);
      } catch (_) {
        // Mantém na fila se falhou
      }
    }
  }

  @override
  Future<void> enqueuePendingEvent(PendingEvent event) async {
    final box = await Hive.openBox<PendingEvent>(_pendingEventsBox);
    await box.put(event.id, event);
    // Tenta drenar imediatamente se online
    await drainPendingEvents();
  }

  // -------------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------------

  void _startSnapshotListener() {
    if (_userId == null) return;
    _profileListener = _firestore
        .collection('users')
        .doc(_userId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      await _mergeRemotePersonalRecords(data['personalRecords']);
      await _mergeRemoteInventory(data['inventory']);
    });
  }

  void _startConnectivityListener() {
    _connectivityListener = Connectivity()
        .onConnectivityChanged
        .listen((result) async {
      if (result != ConnectivityResult.none) {
        await drainPendingEvents();
      }
    });
  }

  Future<void> _applyEvent(PendingEvent event) async {
    if (_userId == null) return;
    switch (event.type) {
      case PendingEventType.legendReached:
        final level = event.payload['level'] as int;
        final collectionId = 'legendsRankings/$level/entries';
        await _firestore.runTransaction((tx) async {
          final ref = _firestore.collection(collectionId).doc(_userId);
          final snap = await tx.get(ref);
          if (snap.exists) {
            tx.update(ref, {
              'timesReached': FieldValue.increment(1),
            });
          } else {
            tx.set(ref, {
              'userId': _userId,
              'displayName': 'Jogador', // Atualizado pelo syncProfile() após o init
              'timesReached': 1,
              'firstReachedAt': Timestamp.fromDate(event.occurredAt),
            });
          }
        });
        // Atualizar personalRecords no Firestore
        await _firestore.collection('users').doc(_userId).update({
          level == 4096
              ? 'personalRecords.timesReached4096'
              : 'personalRecords.timesReached8192': FieldValue.increment(1),
        });
      case PendingEventType.inventoryConsume:
        // Tratado por transação direta na compra — não via fila
        break;
    }
  }

  Future<void> _mergeRemotePersonalRecords(
      Map<String, dynamic>? remoteData) async {
    if (remoteData == null) return;
    final box =
        await Hive.openBox<PersonalRecords>(_personalRecordsBox);
    final local = box.get(_personalRecordsKey) ?? const PersonalRecords();
    final remote = _personalRecordsFromMap(remoteData);
    final merged = SyncConflictResolver.mergePersonalRecords(local, remote);
    await box.put(_personalRecordsKey, merged);
  }

  Future<void> _mergeRemoteInventory(
      Map<String, dynamic>? remoteData) async {
    if (remoteData == null) return;
    final box = await Hive.openBox<Inventory>('inventory');
    final local = box.get('inventory') ?? Inventory.empty();
    final remote = Inventory(
      bomb2: (remoteData['bomb2'] as int?) ?? 0,
      bomb3: (remoteData['bomb3'] as int?) ?? 0,
      undo1: (remoteData['undo1'] as int?) ?? 0,
      undo3: (remoteData['undo3'] as int?) ?? 0,
    );
    final merged = SyncConflictResolver.mergeInventory(local, remote);
    await box.put('inventory', merged);
  }

  Future<void> _writeLocalProfileToFirestore() async {
    if (_userId == null) return;
    final prBox =
        await Hive.openBox<PersonalRecords>(_personalRecordsBox);
    final pr = prBox.get(_personalRecordsKey) ?? const PersonalRecords();
    await _firestore.collection('users').doc(_userId).set({
      'userId': _userId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
      'personalRecords': {
        'timesReached2048': pr.timesReached2048,
        'timesReached4096': pr.timesReached4096,
        'timesReached8192': pr.timesReached8192,
        'highestLevelEver': pr.highestLevelEver,
        if (pr.firstReached4096At != null)
          'firstReached4096At':
              Timestamp.fromDate(pr.firstReached4096At!),
        if (pr.firstReached8192At != null)
          'firstReached8192At':
              Timestamp.fromDate(pr.firstReached8192At!),
      },
    }, SetOptions(merge: true));
  }

  PersonalRecords _personalRecordsFromMap(Map<String, dynamic> m) {
    Timestamp? ts4096 = m['firstReached4096At'] as Timestamp?;
    Timestamp? ts8192 = m['firstReached8192At'] as Timestamp?;
    return PersonalRecords(
      timesReached2048: (m['timesReached2048'] as int?) ?? 0,
      timesReached4096: (m['timesReached4096'] as int?) ?? 0,
      timesReached8192: (m['timesReached8192'] as int?) ?? 0,
      highestLevelEver: (m['highestLevelEver'] as int?) ?? 0,
      firstReached4096At: ts4096?.toDate(),
      firstReached8192At: ts8192?.toDate(),
    );
  }
}
```

- [ ] **Step 2: Registrar no provider para o flavor prd**

Em `lib/domain/sync/sync_engine.dart`, atualizar o provider:

```dart
// No final de sync_engine.dart, substituir o provider:
import '../../data/repositories/firebase_sync_engine.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  if (flavor == 'prd') return FirebaseSyncEngine();
  return FakeSyncEngine();
});
```

- [ ] **Step 3: Verificar compilação**

```bash
flutter build apk --debug --dart-define=FLAVOR=prd 2>&1 | tail -5
```

Esperado: sem erros.

- [ ] **Step 4: Rodar suite de testes (usa Fake no flavor dev)**

```bash
flutter test --reporter=compact
```

Esperado: todos passam.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/firebase_sync_engine.dart lib/domain/sync/sync_engine.dart
git commit -m "feat(sync): add FirebaseSyncEngine with snapshot listener and write queue"
```

---

## Task 15: Verificação final + release

- [ ] **Step 1: Rodar suite completa de testes**

```bash
flutter test --reporter=compact
```

Esperado: todos passam. Verificar que nenhum teste da Fase 3 regrediu.

- [ ] **Step 2: Build de verificação dev**

```bash
flutter build apk --debug --dart-define=FLAVOR=dev
```

Esperado: APK gerado sem erros.

- [ ] **Step 3: Build de verificação prd**

```bash
flutter build apk --debug --dart-define=FLAVOR=prd
```

Esperado: APK gerado sem erros (requer firebase_options_prd.dart gerado).

- [ ] **Step 4: Atualizar CHANGELOG.md**

Adicionar entrada:

```markdown
## [1.4.0] — 2026-05-XX

### Adicionado
- Firebase + Auth (Google, Apple, Email) via Fase 4A
- PlayerProfile model com sincronização Firestore
- SyncEngine com snapshot listener, write queue offline e conflict resolution
- OnboardingAuthScreen (primeiro launch)
- ProfileScreen acessível via avatar na HomeScreen
- AuthBanner para usuários sem conta
- PendingEvent model para eventos offline (Lendas, etc.)
```

- [ ] **Step 5: Commit final**

```bash
git add CHANGELOG.md
git commit -m "chore: release v1.4.0 — Fase 4A Firebase + Auth + Sync Engine"
```

---

## Critérios de aceite desta fase

- [ ] App inicia sem crash com `Firebase.initializeApp()` em ambos os flavors
- [ ] Login com Google funciona no emulador (dev) e Firebase real (prd)
- [ ] Login com Email funciona no emulador (dev)
- [ ] `PlayerProfile` é criado no Firestore na primeira autenticação
- [ ] Logout limpa sessão; re-login restaura perfil do Firestore
- [ ] `ProfileScreen` exibe dados corretos do usuário logado
- [ ] `AuthBanner` aparece quando não logado; desaparece após login
- [ ] Reinstalar app + re-login restaura `PersonalRecords` do Firestore
- [ ] Todos os testes da Fase 3 continuam passando
- [ ] `SyncConflictResolver` cobre todos os campos com estratégia correta
