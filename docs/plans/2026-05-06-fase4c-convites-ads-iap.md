# Fase 4C — Convites + Anúncios Reais + IAP Real

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task.

**Data:** 2026-05-06  
**Versão alvo:** v1.4.5  
**Status:** Aguardando execução  
**Pré-requisito:** Fase 4B concluída (v1.4.4) — Ranking Global + Lendas operacionais.  
**Ref spec:** `docs/specs/2026-05-05-fase4-backend-ranking-monetizacao.md` §7 (Sub-D), §8 (Sub-E), §9 (Sub-F)

---

## Escopo

| Sub-entrega | Nome                              | Dependências |
| ----------- | --------------------------------- | ------------ |
| D           | Sistema de Convites               | 4A ✅        |
| E           | Anúncios Reais (Google Mobile Ads)| —            |
| F           | IAP Real (in_app_purchase)        | 4A ✅        |

---

## Mapa de arquivos

### Criados

| Arquivo                                                    | Sub | Responsabilidade                                        |
| ---------------------------------------------------------- | --- | ------------------------------------------------------- |
| `lib/domain/invites/invite_service.dart`                   | D   | Interface `InviteService` + `FakeInviteService`         |
| `lib/data/repositories/firestore_invite_repository.dart`   | D   | Implementação Firestore de `InviteService`              |
| `lib/presentation/controllers/invite_controller.dart`      | D   | Riverpod notifier + deep link listener                  |
| `lib/data/repositories/google_mobile_ads_service.dart`     | E   | `GoogleMobileAdsService implements AdService`           |
| `lib/domain/shop/iap_service.dart`                         | F   | Interface `IAPService` + `FakeIAPService`               |
| `lib/data/repositories/iap_service_impl.dart`              | F   | `IAPServiceImpl` com purchase stream                    |
| `lib/presentation/widgets/iap_confirmation_sheet.dart`     | F   | Bottom sheet de confirmação antes de chamar IAP do SO   |
| `lib/presentation/widgets/purchase_success_sheet.dart`     | F   | Sheet pós-compra com ShareCode                          |
| `test/domain/invite_service_test.dart`                     | D   | Testes unitários do InviteService / FakeInviteService   |
| `test/presentation/iap_confirmation_sheet_test.dart`       | F   | Widget tests do IAPConfirmationSheet                    |
| `test/presentation/purchase_success_sheet_test.dart`       | F   | Widget tests do PurchaseSuccessSheet                    |

### Modificados

| Arquivo                                                          | Sub | Mudança                                                          |
| ---------------------------------------------------------------- | --- | ---------------------------------------------------------------- |
| `pubspec.yaml`                                                   | D/E/F | Adicionar `app_links`, `google_mobile_ads`, `in_app_purchase`  |
| `lib/main.dart`                                                  | D/E | Init deep link listener + MobileAds.instance.initialize()       |
| `android/app/src/main/AndroidManifest.xml`                       | D/E | `intent-filter` deep link + `meta-data` AdMob App ID            |
| `ios/Runner/Info.plist`                                          | D/E | URL scheme `olhabichim` + `GADApplicationIdentifier`            |
| `lib/domain/daily_rewards/ad_service.dart`                       | E   | `adServiceProvider` usa `GoogleMobileAdsService` em prd         |
| `lib/presentation/screens/invite_friends_screen.dart`            | D   | Substituir stub por implementação real                           |
| `lib/presentation/controllers/game_notifier.dart`                | D   | Detectar 1ª partida + completar convite pendente                 |
| `lib/presentation/screens/shop_screen.dart`                      | F   | `_onBuy` usa `IAPConfirmationSheet` + `IAPService`              |
| `lib/presentation/widgets/game_over_no_items_overlay.dart`       | F   | `_confirmBuy` usa `IAPConfirmationSheet` + `IAPService`         |
| `lib/data/repositories/share_codes_repository.dart`              | F   | Adicionar escrita no Firestore ao gerar ShareCode               |

---

## Task 1 — Sub-D: `InviteService` interface + `FakeInviteService` + testes

**Files:**
- Create: `lib/domain/invites/invite_service.dart`
- Create: `test/domain/invite_service_test.dart`

### Especificação

```dart
// lib/domain/invites/invite_service.dart

abstract class InviteService {
  /// Gera ou recupera o link de convite para o userId atual.
  /// Retorna a URL: "olhabichim://invite?ref={userId}"
  Future<String> generateInviteLink(String userId);

  /// Registra que o convidado (inviteeId) foi referenciado pelo convidante (inviterId).
  /// No-op se inviteeId já estiver vinculado.
  Future<void> registerInvite({
    required String inviterId,
    required String inviteeId,
    required String inviteeDisplayName,
  });

  /// Completa o convite: entrega recompensas ao convidante e ao convidado.
  /// Chamado quando o convidado conclui a 1ª partida.
  /// Retorna true se o convite foi completado, false se não havia convite pendente.
  Future<bool> completeInviteReward({
    required String inviteeId,
    required String inviteeDisplayName,
  });
}

// Recompensas de convite
// Convidante: 2 vidas + 1× Bomba 2
// Convidado:  2 vidas + 1× Bomba 2

class FakeInviteService implements InviteService {
  // Armazena convites em memória para testes
  final Map<String, String> _inviterByInvitee = {}; // inviteeId → inviterId
  bool lastCompleteResult = false;

  @override
  Future<String> generateInviteLink(String userId) async =>
      'olhabichim://invite?ref=$userId';

  @override
  Future<void> registerInvite({
    required String inviterId,
    required String inviteeId,
    required String inviteeDisplayName,
  }) async {
    if (!_inviterByInvitee.containsKey(inviteeId)) {
      _inviterByInvitee[inviteeId] = inviterId;
    }
  }

  @override
  Future<bool> completeInviteReward({
    required String inviteeId,
    required String inviteeDisplayName,
  }) async {
    if (_inviterByInvitee.containsKey(inviteeId)) {
      lastCompleteResult = true;
      return true;
    }
    return false;
  }
}

final inviteServiceProvider = Provider<InviteService>((_) => FakeInviteService());
```

### Testes

```dart
// test/domain/invite_service_test.dart
void main() {
  group('FakeInviteService', () {
    test('generateInviteLink retorna URL correta', () async {
      final svc = FakeInviteService();
      final link = await svc.generateInviteLink('user123');
      expect(link, 'olhabichim://invite?ref=user123');
    });

    test('registerInvite vincula convidado ao convidante', () async {
      final svc = FakeInviteService();
      await svc.registerInvite(
        inviterId: 'alice', inviteeId: 'bob', inviteeDisplayName: 'Bob');
      final result = await svc.completeInviteReward(
        inviteeId: 'bob', inviteeDisplayName: 'Bob');
      expect(result, isTrue);
    });

    test('segundo registerInvite para mesmo inviteeId é no-op', () async {
      final svc = FakeInviteService();
      await svc.registerInvite(
        inviterId: 'alice', inviteeId: 'bob', inviteeDisplayName: 'Bob');
      await svc.registerInvite(
        inviterId: 'carol', inviteeId: 'bob', inviteeDisplayName: 'Bob');
      // bob ainda está vinculado a alice
      expect(svc.lastCompleteResult, isFalse);
    });

    test('completeInviteReward retorna false sem convite pendente', () async {
      final svc = FakeInviteService();
      final result = await svc.completeInviteReward(
        inviteeId: 'nobody', inviteeDisplayName: 'Nobody');
      expect(result, isFalse);
    });
  });
}
```

### Steps

- [ ] Criar `lib/domain/invites/` e `lib/domain/invites/invite_service.dart`
- [ ] Criar `test/domain/invite_service_test.dart` com os 4 testes acima
- [ ] Confirmar FAIL: `flutter test test/domain/invite_service_test.dart 2>&1 | tail -4`
- [ ] Implementar conforme spec
- [ ] Todos os testes passam
- [ ] Suite completa: `flutter test --reporter=compact 2>&1 | tail -4`
- [ ] Commit: `feat(invites): add InviteService interface and FakeInviteService`

---

## Task 2 — Sub-D: `FirestoreInviteRepository`

**Files:**
- Create: `lib/data/repositories/firestore_invite_repository.dart`

### Especificação

```dart
class FirestoreInviteRepository implements InviteService {
  final String userId;           // usuário logado (convidante ou convidado)
  final String? displayName;
  final FirebaseFirestore _firestore;

  FirestoreInviteRepository({
    required this.userId,
    this.displayName,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
```

#### Firestore schema

```
invites/{inviterId}
  inviterDisplayName: string
  invites: [
    { inviteeId, inviteeDisplayName, status: "pending"|"completed", completedAt? }
  ]
  totalRewardsClaimed: int
```

#### `generateInviteLink`

```dart
// Cria doc invites/{userId} se não existir (SetOptions merge: true)
// Retorna 'olhabichim://invite?ref=$userId'
await _firestore.collection('invites').doc(userId).set({
  'inviterDisplayName': displayName ?? 'Jogador',
  'invites': [],
  'totalRewardsClaimed': 0,
}, SetOptions(merge: true));
return 'olhabichim://invite?ref=$userId';
```

#### `registerInvite`

```dart
// Verifica se inviteeId já está em algum doc de invites (Hive cache é suficiente)
// Usa transação para evitar duplicata
// Máximo 20 invites ativos por inviterId
await _firestore.runTransaction((tx) async {
  final ref = _firestore.collection('invites').doc(inviterId);
  final snap = await tx.get(ref);
  final invites = List<Map<String, dynamic>>.from(
    snap.data()?['invites'] as List? ?? []);
  // Verifica se inviteeId já existe
  if (invites.any((i) => i['inviteeId'] == inviteeId)) return;
  if (invites.length >= 20) return;
  invites.add({
    'inviteeId': inviteeId,
    'inviteeDisplayName': inviteeDisplayName,
    'status': 'pending',
  });
  tx.update(ref, {'invites': invites});
});
```

#### `completeInviteReward`

```dart
// Busca pendingInviteRef do Hive (box 'invite_refs', key 'pending_ref')
// Se nulo → return false
// Lê invites/{inviterId}, encontra entry do inviteeId com status 'pending'
// Transação:
//   - Marca status: 'completed', completedAt: now
//   - Entrega 2 vidas + 1× Bomba 2 ao convidante (users/{inviterId}/inventory)
//   - Entrega 2 vidas + 1× Bomba 2 ao convidado (users/{inviteeId}/inventory) via SyncEngine
//   - Incrementa totalRewardsClaimed
// Limpa Hive box 'invite_refs'
// return true
```

**Recompensas locais ao convidado** (Hive direto — mesma pattern de `checkAndClaimWeeklyReward`):
```dart
// Inventory box 'inventory', key 'inventory'
// Lives box 'lives', key 'state'
```

### Steps

- [ ] Criar `lib/data/repositories/firestore_invite_repository.dart`
- [ ] Compilação: `flutter analyze lib/data/repositories/firestore_invite_repository.dart 2>&1 | grep error | head -5`
- [ ] Suite completa passa
- [ ] Commit: `feat(invites): add FirestoreInviteRepository`

---

## Task 3 — Sub-D: `InviteController` + `InviteFriendsScreen` + deps nativas

**Files:**
- Create: `lib/presentation/controllers/invite_controller.dart`
- Modify: `lib/presentation/screens/invite_friends_screen.dart`
- Modify: `pubspec.yaml` — adicionar `app_links: ^6.x`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Modify: `lib/main.dart` — inicializar deep link listener

### `InviteController`

```dart
// lib/presentation/controllers/invite_controller.dart

class InviteController extends StateNotifier<AsyncValue<String?>> {
  InviteController(this._service, this._authController)
      : super(const AsyncValue.data(null));

  final InviteService _service;
  final AuthController _authController;

  /// Gera o link de convite para o usuário atual.
  /// Retorna null se não estiver logado.
  Future<String?> generateLink() async {
    final profile = _authController.state;
    if (profile == null) return null;
    state = const AsyncValue.loading();
    try {
      final link = await _service.generateInviteLink(profile.userId);
      state = AsyncValue.data(link);
      return link;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final inviteControllerProvider =
    StateNotifierProvider<InviteController, AsyncValue<String?>>(
  (ref) => InviteController(
    ref.watch(inviteServiceProvider),
    ref.read(authControllerProvider.notifier),
  ),
);
```

### `InviteFriendsScreen` (substituir stub)

```dart
// lib/presentation/screens/invite_friends_screen.dart
// Implementação real da tela de convites
//
// Layout:
//   - Título "Convidar Amigos"
//   - Texto explicativo das recompensas (2 vidas + 1× Bomba 2 para ambos)
//   - Botão "Gerar Link de Convite" → chama InviteController.generateLink()
//   - Exibe o link gerado (se houver) com botão Copiar e botão Compartilhar
//   - Se não logado: AuthBanner + mensagem "Faça login para convidar amigos"
```

### `pubspec.yaml`

Adicionar em `dependencies`:
```yaml
app_links: ^6.x
```

### AndroidManifest

Dentro da tag `<activity>`, após o `intent-filter` existente do LAUNCHER:

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW"/>
  <category android:name="android.intent.category.DEFAULT"/>
  <category android:name="android.intent.category.BROWSABLE"/>
  <data android:scheme="olhabichim"/>
</intent-filter>
```

### iOS Info.plist

Antes do `</dict>` final:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>olhabichim</string>
    </array>
    <key>CFBundleURLName</key>
    <string>com.example.capivara2048</string>
  </dict>
</array>
```

### `main.dart` — deep link listener

Após `Firebase.initializeApp()`:

```dart
// Captura deep link no cold start
final appLinks = AppLinks();
final initialUri = await appLinks.getInitialLink();
if (initialUri != null) {
  _handleDeepLink(initialUri);
}
// Captura deep link em foreground
appLinks.uriLinkStream.listen(_handleDeepLink);

void _handleDeepLink(Uri uri) {
  if (uri.scheme == 'olhabichim' && uri.host == 'invite') {
    final ref = uri.queryParameters['ref'];
    if (ref != null && ref.isNotEmpty) {
      // Salva no Hive para ser lido pelo InviteController na próxima sessão
      Hive.openBox<String>('invite_refs').then((box) {
        box.put('pending_ref', ref);
      });
    }
  }
}
```

### Steps

- [ ] Adicionar `app_links: ^6.x` ao pubspec.yaml e rodar `flutter pub get`
- [ ] Criar `lib/presentation/controllers/invite_controller.dart`
- [ ] Implementar `lib/presentation/screens/invite_friends_screen.dart`
- [ ] Adicionar `intent-filter` ao AndroidManifest
- [ ] Adicionar URL scheme ao iOS Info.plist
- [ ] Atualizar `lib/main.dart` com deep link listener
- [ ] Compilação: `flutter build apk --debug --dart-define=FLAVOR=dev 2>&1 | tail -5`
- [ ] Suite completa passa
- [ ] Commit: `feat(invites): add InviteController, InviteFriendsScreen, deep link setup`

---

## Task 4 — Sub-D: Game hook — detectar 1ª partida + completar convite

**Files:**
- Modify: `lib/presentation/controllers/game_notifier.dart`

### Lógica

Em `_saveGameRecord()`, após salvar o record e antes de submeter ranking, adicionar:

```dart
// Completar convite pendente na 1ª partida
try {
  final records = _ref.read(gameRecordRepositoryProvider).all;
  if (records.length == 1) {
    // Esta é a 1ª partida
    final inviteService = _ref.read(inviteServiceProvider);
    final authProfile = _ref.read(authControllerProvider);
    if (authProfile != null) {
      unawaited(inviteService.completeInviteReward(
        inviteeId: authProfile.userId,
        inviteeDisplayName: authProfile.displayName,
      ));
    }
  }
} catch (_) {}
```

### Steps

- [ ] Adicionar os imports necessários
- [ ] Implementar o hook em `_saveGameRecord()`
- [ ] Suite completa passa (FakeInviteService não afeta testes existentes)
- [ ] Commit: `feat(invites): complete invite reward on first game in game_notifier`

---

## Task 5 — Sub-E: `GoogleMobileAdsService` + provider + config nativa

**Files:**
- Modify: `pubspec.yaml` — adicionar `google_mobile_ads: ^5.x`
- Create: `lib/data/repositories/google_mobile_ads_service.dart`
- Modify: `lib/domain/daily_rewards/ad_service.dart` — atualizar `adServiceProvider`
- Modify: `android/app/src/main/AndroidManifest.xml` — App ID AdMob
- Modify: `ios/Runner/Info.plist` — `GADApplicationIdentifier`
- Modify: `lib/main.dart` — `MobileAds.instance.initialize()`

### `GoogleMobileAdsService`

```dart
// lib/data/repositories/google_mobile_ads_service.dart

import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/ad_config.dart';
import '../../domain/daily_rewards/ad_service.dart';

class GoogleMobileAdsService implements AdService {
  RewardedAd? _preloaded;
  bool _loading = false;

  @override
  Future<bool> showRewardedAd() async {
    // Se não há anúncio pré-carregado, tenta carregar agora
    if (_preloaded == null) {
      await _loadAd();
      if (_preloaded == null) return false;
    }

    final ad = _preloaded!;
    _preloaded = null;
    unawaited(_loadAd()); // pré-carrega o próximo

    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) {
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (_, __) {
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, __) {
      if (!completer.isCompleted) completer.complete(true);
    });
    return completer.future;
  }

  Future<void> _loadAd() async {
    if (_loading) return;
    _loading = true;
    final unitId = Platform.isIOS ? AdConfig.adUnitIos : AdConfig.adUnitAndroid;
    await RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _preloaded = ad;
          _loading = false;
        },
        onAdFailedToLoad: (_) {
          _loading = false;
        },
      ),
    );
  }

  /// Pré-carrega no startup.
  Future<void> preload() => _loadAd();
}
```

### `adServiceProvider` atualizado

```dart
// Em lib/domain/daily_rewards/ad_service.dart
final adServiceProvider = Provider<AdService>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  if (flavor == 'prd') return GoogleMobileAdsService();
  return FakeAdService();
});
```

### `lib/main.dart` — inicialização AdMob

Após Firebase.initializeApp() e antes de Hive.initFlutter():
```dart
// AdMob — inicializa apenas em prd
const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
if (flavor == 'prd') {
  await MobileAds.instance.initialize();
  await MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
      tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
      maxAdContentRating: MaxAdContentRating.g,
    ),
  );
}
```

### AndroidManifest — AdMob App ID

Na seção `<application>`, antes do `</application>`:
```xml
<!-- AdMob App ID — injetado via --dart-define=ADMOB_APP_ID em prd -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="${admobAppId}"/>
```

No `android/app/build.gradle`, em `defaultConfig`:
```gradle
manifestPlaceholders = [
    admobAppId: System.getenv("ADMOB_APP_ID") ?: "ca-app-pub-3940256099942544~3347511713"
]
```

### iOS Info.plist — GADApplicationIdentifier

Antes do `</dict>` final:
```xml
<key>GADApplicationIdentifier</key>
<string>$(ADMOB_APP_ID)</string>
```

> **Nota:** em Xcode, adicionar `ADMOB_APP_ID` como User-Defined build setting.
> Dev usa o test App ID: `ca-app-pub-3940256099942544~3347511713`

### Steps

- [ ] Adicionar `google_mobile_ads: ^5.x` ao pubspec.yaml + `flutter pub get`
- [ ] Criar `lib/data/repositories/google_mobile_ads_service.dart`
- [ ] Atualizar `adServiceProvider` em `ad_service.dart`
- [ ] Atualizar `lib/main.dart` com init AdMob
- [ ] Adicionar meta-data ao AndroidManifest + manifestPlaceholders no build.gradle
- [ ] Adicionar GADApplicationIdentifier ao iOS Info.plist
- [ ] Compilação APK dev: `flutter build apk --debug --dart-define=FLAVOR=dev 2>&1 | tail -5`
- [ ] Suite completa passa (FakeAdService ainda usado em dev/test)
- [ ] Commit: `feat(ads): add GoogleMobileAdsService with preload pool, prd-only init`

---

## Task 6 — Sub-F: `IAPService` interface + `FakeIAPService`

**Files:**
- Create: `lib/domain/shop/iap_service.dart`

### Especificação

```dart
// lib/domain/shop/iap_service.dart

import '../../data/models/shop_package.dart';

class PurchaseResult {
  final bool success;
  final String? error;
  final String? shareCode; // código gerado após compra bem-sucedida

  const PurchaseResult({required this.success, this.error, this.shareCode});

  const PurchaseResult.success({required String shareCode})
      : this(success: true, shareCode: shareCode);

  const PurchaseResult.failure(String error)
      : this(success: false, error: error);

  const PurchaseResult.cancelled()
      : this(success: false, error: null);
}

abstract class IAPService {
  /// Inicia o fluxo de compra para o pacote.
  /// Retorna PurchaseResult após o fluxo ser concluído.
  Future<PurchaseResult> buyPackage(ShopPackage package);

  /// Restaura compras anteriores (obrigatório App Store).
  Future<void> restorePurchases();

  /// Verifica se IAP está disponível neste dispositivo/plataforma.
  bool get isAvailable;
}

class FakeIAPService implements IAPService {
  @override
  bool get isAvailable => true;

  @override
  Future<PurchaseResult> buyPackage(ShopPackage package) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Gera código fake no formato correto: {animal}-{4digits}-{2letters}
    return const PurchaseResult.success(shareCode: 'CAPIVARA-1234-AB');
  }

  @override
  Future<void> restorePurchases() async {}
}

final iapServiceProvider = Provider<IAPService>((_) => FakeIAPService());
```

### Steps

- [ ] Criar `lib/domain/shop/` se não existir
- [ ] Criar `lib/domain/shop/iap_service.dart`
- [ ] Verificar compilação
- [ ] Suite completa passa
- [ ] Commit: `feat(iap): add IAPService interface and FakeIAPService`

---

## Task 7 — Sub-F: `IAPConfirmationSheet` + `PurchaseSuccessSheet` + widget tests

**Files:**
- Create: `lib/presentation/widgets/iap_confirmation_sheet.dart`
- Create: `lib/presentation/widgets/purchase_success_sheet.dart`
- Create: `test/presentation/iap_confirmation_sheet_test.dart`
- Create: `test/presentation/purchase_success_sheet_test.dart`

### `IAPConfirmationSheet` — layout e spec

```dart
class IAPConfirmationSheet extends StatelessWidget {
  const IAPConfirmationSheet({super.key, required this.package, this.onConfirm, this.onCancel});
  
  final ShopPackage package;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  static Future<bool> show(BuildContext context, ShopPackage package) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => IAPConfirmationSheet(
        package: package,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );
    return result == true;
  }
}
```

**Conteúdo (de cima para baixo):**
1. Drag handle (barra cinza centralizada)
2. `📦 {package.name}` — Fredoka Bold 20sp
3. Divisor
4. **"Conteúdo:"** label + grid com ícones dos itens do pacote (`contents`)
5. Se `giftContents` não é zero: divisor + **"🎁 Presente para um amigo:"** + itens do gift
6. Divisor
7. `ElevatedButton` "Confirmar — R$ {price}" (AppColors.primary, largura total)
8. `TextButton` "Cancelar"

**Itens exibidos** (usar emoji igual ao `WeeklyRewardModal`):
- ❤️ N Vidas, 🧨 N× Bomba 3, 💣 N× Bomba 2, ↩️ N× Desfazer

### `PurchaseSuccessSheet` — layout e spec

```dart
class PurchaseSuccessSheet extends StatelessWidget {
  const PurchaseSuccessSheet({super.key, required this.shareCode, this.onDismiss});
  
  final String shareCode;
  final VoidCallback? onDismiss;

  static Future<void> show(BuildContext context, String shareCode) => ...
}
```

**Conteúdo:**
1. ✅ "Compra realizada!" — Fredoka 22sp, verde
2. "Seus itens foram adicionados." — Nunito 14sp
3. Divisor
4. **"🎁 Presente para um amigo:"**
5. Código grande: `shareCode` — Fredoka Mono/Bold 20sp, fundo cinza-claro
6. Botões linha: `[📋 Copiar]` e `[📤 Compartilhar]` (usa Clipboard + share_plus)
7. "Válido por 30 dias · 1 uso" — caption cinza
8. `ElevatedButton` "Continuar jogando"

### Widget tests

Testar:
- `IAPConfirmationSheet` exibe nome do pacote
- `IAPConfirmationSheet` exibe conteúdo com emoji correto
- `IAPConfirmationSheet` botão Confirmar chama `onConfirm`
- `IAPConfirmationSheet` botão Cancelar chama `onCancel`
- `PurchaseSuccessSheet` exibe shareCode
- `PurchaseSuccessSheet` botão Copiar presente
- `PurchaseSuccessSheet` botão Continuar presente

### Steps

- [ ] Criar `lib/presentation/widgets/iap_confirmation_sheet.dart`
- [ ] Criar `lib/presentation/widgets/purchase_success_sheet.dart`
- [ ] Criar os widget tests (TDD: tests first)
- [ ] Todos os widget tests passam
- [ ] Suite completa passa
- [ ] Commit: `feat(iap): add IAPConfirmationSheet and PurchaseSuccessSheet widgets`

---

## Task 8 — Sub-F: `IAPServiceImpl` + `in_app_purchase` + `iapServiceProvider` prd

**Files:**
- Modify: `pubspec.yaml` — adicionar `in_app_purchase: ^3.x`
- Create: `lib/data/repositories/iap_service_impl.dart`
- Modify: `lib/domain/shop/iap_service.dart` — `iapServiceProvider` usa impl em prd

### Produto IDs

Padrão: `bichim_pack_{package.id}` (ex: `bichim_pack_floresta`). Todos consumable.

### `IAPServiceImpl` — fluxo

```dart
class IAPServiceImpl implements IAPService {
  final String userId;
  final FirebaseFirestore _firestore;

  IAPServiceImpl({required this.userId, FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  bool get isAvailable => true; // verificado na init

  @override
  Future<PurchaseResult> buyPackage(ShopPackage package) async {
    final iap = InAppPurchase.instance;
    if (!await iap.isAvailable()) {
      return const PurchaseResult.failure('Loja não disponível no momento.');
    }

    final productId = 'bichim_pack_${package.id}';
    final param = PurchaseParam(productDetails: ProductDetails(
      id: productId, title: package.name, description: package.description,
      price: 'R\$ ${package.currentPrice.toStringAsFixed(2)}',
      rawPrice: package.currentPrice, currencyCode: 'BRL',
    ));

    final completer = Completer<PurchaseResult>();
    late StreamSubscription<List<PurchaseDetails>> sub;

    sub = iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.productID != productId) continue;
        if (purchase.status == PurchaseStatus.purchased) {
          // Idempotência via Firestore
          final result = await _deliverAndRecord(purchase, package);
          await iap.completePurchase(purchase);
          if (!completer.isCompleted) completer.complete(result);
          await sub.cancel();
        } else if (purchase.status == PurchaseStatus.error) {
          await iap.completePurchase(purchase);
          if (!completer.isCompleted)
            completer.complete(PurchaseResult.failure(
              purchase.error?.message ?? 'Erro desconhecido'));
          await sub.cancel();
        } else if (purchase.status == PurchaseStatus.canceled) {
          if (!completer.isCompleted)
            completer.complete(const PurchaseResult.cancelled());
          await sub.cancel();
        }
      }
    });

    await iap.buyConsumable(purchaseParam: param);
    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => const PurchaseResult.failure('Tempo esgotado.'),
    );
  }

  @override
  Future<void> restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
  }

  Future<PurchaseResult> _deliverAndRecord(
      PurchaseDetails purchase, ShopPackage package) async {
    final purchaseId = purchase.purchaseID ?? purchase.verificationData.serverVerificationData;
    final docRef = _firestore.collection('purchases').doc(userId).collection('items').doc(purchaseId);

    // Idempotência: se já entregue, retorna sem duplicar
    final existing = await docRef.get();
    if (existing.exists && existing.data()?['status'] == 'delivered') {
      return PurchaseResult.success(shareCode: existing.data()?['shareCode'] as String? ?? '');
    }

    // Marca pending
    await docRef.set({'status': 'pending', 'packageId': package.id, 'purchasedAt': FieldValue.serverTimestamp()});

    // Entrega items ao Hive local
    await _deliverToHive(package.contents);

    // Gera ShareCode
    final code = _generateShareCode();
    await _firestore.collection('shareCodes').doc(code).set({
      'code': code,
      'packageId': package.id,
      'giftContents': {
        'lives': package.giftContents.lives,
        'bomb2': package.giftContents.bomb2,
        'bomb3': package.giftContents.bomb3,
        'undo1': package.giftContents.undo1,
        'undo3': package.giftContents.undo3,
      },
      'status': 'pending',
      'createdByUserId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
    });

    // Marca delivered
    await docRef.update({'status': 'delivered', 'shareCode': code, 'deliveredAt': FieldValue.serverTimestamp()});

    return PurchaseResult.success(shareCode: code);
  }

  Future<void> _deliverToHive(RewardBundle contents) async {
    // Inventory
    final invBox = await Hive.openBox<Inventory>('inventory');
    final inv = invBox.get('inventory') ?? Inventory.empty();
    await invBox.put('inventory', Inventory(
      bomb2: inv.bomb2 + contents.bomb2,
      bomb3: inv.bomb3 + contents.bomb3,
      undo1: inv.undo1 + contents.undo1,
      undo3: inv.undo3 + contents.undo3,
    ));
    // Lives
    if (contents.lives > 0) {
      final livesBox = await Hive.openBox<LivesState>('lives');
      final ls = livesBox.get('state');
      if (ls != null) {
        await livesBox.put('state', ls.copyWith(
          lives: (ls.lives + contents.lives).clamp(0, 15)));
      }
    }
  }

  String _generateShareCode() {
    const animals = ['CAPIVARA', 'ONCA', 'BOTO', 'SUCURI', 'TUCANO', 'PREGUICA'];
    final animal = animals[Random().nextInt(animals.length)];
    final digits = (1000 + Random().nextInt(9000)).toString();
    final letters = String.fromCharCodes(
      List.generate(2, (_) => 65 + Random().nextInt(26)));
    return '$animal-$digits-$letters';
  }
}
```

### `iapServiceProvider` atualizado

Em `lib/domain/shop/iap_service.dart`:
```dart
final iapServiceProvider = Provider<IAPService>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  if (flavor == 'prd') {
    final profile = ref.watch(authControllerProvider);
    if (profile != null) return IAPServiceImpl(userId: profile.userId);
  }
  return FakeIAPService();
});
```

### Steps

- [ ] Adicionar `in_app_purchase: ^3.x` ao pubspec + `flutter pub get`
- [ ] Criar `lib/data/repositories/iap_service_impl.dart`
- [ ] Atualizar `iapServiceProvider` em `iap_service.dart`
- [ ] Compilação APK dev: `flutter build apk --debug --dart-define=FLAVOR=dev 2>&1 | tail -5`
- [ ] Suite completa passa
- [ ] Commit: `feat(iap): add IAPServiceImpl with purchase stream, idempotent delivery, ShareCode`

---

## Task 9 — Sub-F: Wiring — `ShopScreen` + `GameOverNoItemsOverlay`

**Files:**
- Modify: `lib/presentation/screens/shop_screen.dart`
- Modify: `lib/presentation/widgets/game_over_no_items_overlay.dart`

### `ShopScreen._onBuy` — substituir mock por `IAPConfirmationSheet` + `IAPService`

Substituir o `AlertDialog` de confirmação + lógica de mock por:

```dart
Future<void> _onBuy(BuildContext context, WidgetRef ref, ShopPackage package) async {
  // 1. Mostrar IAPConfirmationSheet
  final confirmed = await IAPConfirmationSheet.show(context, package);
  if (!confirmed) return;

  // 2. Chamar IAPService.buyPackage (FakeIAPService em dev)
  final iapService = ref.read(iapServiceProvider);
  final result = await iapService.buyPackage(package);

  if (!context.mounted) return;

  if (result.success && result.shareCode != null) {
    // 3. Entregar itens ao estado local (Riverpod) — necessário em dev/fake
    // Em prd, IAPServiceImpl já entregou via Hive; Riverpod recarrega via listener
    // Em dev, entregar manualmente:
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    if (flavor != 'prd') {
      final c = package.contents;
      if (c.lives > 0) unawaited(ref.read(livesProvider.notifier).addPurchased(c.lives));
      if (c.bomb2 > 0) unawaited(ref.read(inventoryProvider.notifier).add(ItemType.bomb2, c.bomb2));
      if (c.bomb3 > 0) unawaited(ref.read(inventoryProvider.notifier).add(ItemType.bomb3, c.bomb3));
      if (c.undo1 > 0) unawaited(ref.read(inventoryProvider.notifier).add(ItemType.undo1, c.undo1));
      if (c.undo3 > 0) unawaited(ref.read(inventoryProvider.notifier).add(ItemType.undo3, c.undo3));
      unawaited(ref.read(shareCodesProvider.notifier).add(ShareCode(
        code: result.shareCode!,
        packageId: package.id,
        giftContents: package.giftContents,
        status: ShareCodeStatus.pending,
        createdAt: DateTime.now(),
      )));
    }
    // 4. Mostrar PurchaseSuccessSheet
    await PurchaseSuccessSheet.show(context, result.shareCode!);
  } else if (result.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro na compra: ${result.error}')));
  }
  // result.cancelled → nada
}
```

### `GameOverNoItemsOverlay._confirmBuy` — substituir mock

Substituir o `AlertDialog` por `IAPConfirmationSheet` + `IAPService`:

```dart
Future<void> _confirmBuy() async {
  // Pega o primeiro pacote da loja (o mais barato — último da lista kShopPackages ou o sorteado)
  // Por spec: "compra sempre passa pelo pacote completo via in_app_purchase"
  // Usa o pacote que contém o _drawnItem
  final packages = kShopPackages;
  final cheapest = packages.last; // assume ordenação por preço asc

  if (!mounted) return;
  final confirmed = await IAPConfirmationSheet.show(context, cheapest);
  if (!confirmed || !mounted) return;

  final iapService = ref.read(iapServiceProvider);
  final result = await iapService.buyPackage(cheapest);
  if (!mounted) return;

  if (result.success) {
    // Entrega em dev/fake (prd entregou via Hive)
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    if (flavor != 'prd') {
      final c = cheapest.contents;
      if (c.bomb2 > 0) unawaited(ref.read(inventoryProvider.notifier).add(ItemType.bomb2, c.bomb2));
      if (c.bomb3 > 0) unawaited(ref.read(inventoryProvider.notifier).add(ItemType.bomb3, c.bomb3));
      if (c.undo1 > 0) unawaited(ref.read(inventoryProvider.notifier).add(ItemType.undo1, c.undo1));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Itens adicionados! Boa sorte! 🎉')));
    _dismiss();
  } else if (result.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro: ${result.error}')));
  }
}
```

### Steps

- [ ] Atualizar `lib/presentation/screens/shop_screen.dart`
- [ ] Atualizar `lib/presentation/widgets/game_over_no_items_overlay.dart`
- [ ] Suite completa passa (FakeIAPService em testes não afeta flows existentes)
- [ ] Commit: `feat(iap): wire IAPConfirmationSheet and IAPService into ShopScreen and GameOverNoItemsOverlay`

---

## Task 10 — Release + documentação

- [ ] Suite completa: `flutter test --reporter=compact 2>&1 | tail -4`
- [ ] Build APK dev: `flutter build apk --debug --dart-define=FLAVOR=dev 2>&1 | tail -5`
- [ ] `pubspec.yaml` — bumpar versão para `1.4.5+1`
- [ ] `CHANGELOG.md` — adicionar entrada v1.4.5 com todas as features
- [ ] `AGENTS.md` — atualizar fase atual para `Fase 4C concluída (v1.4.5) — Fase 4 completa — próximo: Fase 5`
- [ ] Commit: `chore: release v1.4.5 — Fase 4C Convites + Anúncios + IAP`
- [ ] Merge em main + push

---

## Critérios de aceite

### Sub-D — Convites

- [ ] `FakeInviteService`: 4 testes unitários passam
- [ ] `InviteFriendsScreen` exibe botão Gerar Link quando logado, `AuthBanner` quando não logado
- [ ] Deep link `olhabichim://invite?ref=X` capturado em cold start (Android)
- [ ] Recompensa de convite entregue na 1ª partida (verificável em dev com FakeInviteService)

### Sub-E — Anúncios

- [ ] `FakeAdService` continua sendo usado em flavor dev e em todos os testes
- [ ] `GoogleMobileAdsService` compila sem erros no flavor prd
- [ ] `tagForChildDirectedTreatment: yes` configurado no init
- [ ] APK dev compila com `admobAppId` de teste

### Sub-F — IAP

- [ ] `FakeIAPService.buyPackage` retorna `PurchaseResult.success` com shareCode
- [ ] `IAPConfirmationSheet`: 4 widget tests passam
- [ ] `PurchaseSuccessSheet`: 3 widget tests passam
- [ ] `ShopScreen` usa `IAPConfirmationSheet` em vez de `AlertDialog`
- [ ] `GameOverNoItemsOverlay` usa `IAPConfirmationSheet` em vez de `AlertDialog`
- [ ] Todos os testes E2E existentes passam sem modificação
