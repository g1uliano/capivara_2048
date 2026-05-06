# IAP Runtime Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Corrigir 4 gaps de runtime no IAP (pending/restored, startup drain, Riverpod refresh, flag USE_REAL_IAP), corrigir bug de key do Hive inventory que afeta entrega de itens, e documentar como configurar e testar IAP nas lojas.

**Architecture:** `IAPStartupService` dedicado (padrão SyncEngine) iniciado pelo `AuthController` após login; `Box.watch()` em `InventoryNotifier` e `LivesNotifier` para reatividade externa; flag `USE_REAL_IAP` dart-define para o flavor `tst`; `IAP.md` como referência operacional.

**Tech Stack:** Flutter, Riverpod, Hive, `in_app_purchase ^3.2.0`, Cloud Firestore, Dart.

---

## Mapa de arquivos

| Arquivo | Ação |
|---------|------|
| `lib/data/repositories/iap_startup_service.dart` | **Novo** — serviço de drain de compras pendentes |
| `lib/data/repositories/iap_service_impl.dart` | Corrigir `restored`/`pending` cases + key do Hive |
| `lib/data/repositories/firestore_invite_repository.dart` | Corrigir key do Hive inventory (`'inventory'` → `'data'`) |
| `lib/data/repositories/firestore_ranking_repository.dart` | Corrigir key do Hive inventory (`'inventory'` → `'data'`) |
| `lib/domain/inventory/inventory_notifier.dart` | Adicionar `Box.watch()` para reatividade externa |
| `lib/domain/lives/lives_notifier.dart` | Adicionar `Box.watch()` para reatividade externa |
| `lib/domain/shop/iap_service.dart` | Atualizar provider com `USE_REAL_IAP` dart-define |
| `lib/presentation/controllers/auth_controller.dart` | Init/dispose `IAPStartupService` no login/logout |
| `IAP.md` | **Novo** — instruções Play Console + App Store Connect + builds |
| `README.md` | Adicionar seção "Builds com IAP" |

---

## Task 1 — Corrigir bug de key do Hive inventory

**Bug:** `IAPServiceImpl`, `FirestoreInviteRepository` e `FirestoreRankingRepository` escrevem itens no Hive usando key `'inventory'`, mas `InventoryRepository` lê e escreve usando key `'data'`. Resultado: toda entrega de itens via IAP, convite e recompensa semanal é escrita num slot invisível — o inventário exibido nunca atualiza.

**Files:**
- Modify: `lib/data/repositories/iap_service_impl.dart`
- Modify: `lib/data/repositories/firestore_invite_repository.dart`
- Modify: `lib/data/repositories/firestore_ranking_repository.dart`
- Verify: `lib/data/repositories/inventory_repository.dart` (referência — NÃO modificar)

- [ ] **Step 1: Confirmar a key correta**

```bash
grep -n "get\|put\|_key\|key" /home/giuliano/rf/capivara_2048/lib/data/repositories/inventory_repository.dart
```

Esperado: `box.get('data')` e `box.put('data', ...)` — confirma que a key correta é `'data'`.

- [ ] **Step 2: Corrigir `iap_service_impl.dart`**

Em `_deliverToHive()`, substituir:
```dart
// ANTES:
final inv = invBox.get('inventory') ?? Inventory.empty();
await invBox.put('inventory', Inventory(...));

// DEPOIS:
final inv = invBox.get('data') ?? Inventory.empty();
await invBox.put('data', Inventory(...));
```

- [ ] **Step 3: Corrigir `firestore_invite_repository.dart`**

Em `_deliverLocalReward()`, substituir:
```dart
// ANTES:
final inv = invBox.get('inventory') ?? Inventory.empty();
await invBox.put('inventory', Inventory(...));

// DEPOIS:
final inv = invBox.get('data') ?? Inventory.empty();
await invBox.put('data', Inventory(...));
```

- [ ] **Step 4: Corrigir `firestore_ranking_repository.dart`**

Em `_deliverReward()`, substituir:
```dart
// ANTES:
final current = box.get('inventory') ?? Inventory.empty();
await box.put('inventory', Inventory(...));

// DEPOIS:
final current = box.get('data') ?? Inventory.empty();
await box.put('data', Inventory(...));
```

- [ ] **Step 5: Verificar compilação**

```bash
cd /home/giuliano/rf/capivara_2048
flutter analyze lib/data/repositories/iap_service_impl.dart \
  lib/data/repositories/firestore_invite_repository.dart \
  lib/data/repositories/firestore_ranking_repository.dart \
  2>&1 | grep error | head -5
```

Esperado: nenhum erro.

- [ ] **Step 6: Suite completa**

```bash
flutter test --reporter=compact 2>&1 | tail -4
```

Esperado: mesma contagem de passes de antes, sem regressões.

- [ ] **Step 7: Commit**

```bash
cd /home/giuliano/rf/capivara_2048
git add lib/data/repositories/iap_service_impl.dart \
        lib/data/repositories/firestore_invite_repository.dart \
        lib/data/repositories/firestore_ranking_repository.dart
git commit -m "fix(hive): correct inventory key from 'inventory' to 'data' in IAP, invite and ranking delivery"
```

---

## Task 2 — `Box.watch()` em `InventoryNotifier`

**Files:**
- Modify: `lib/domain/inventory/inventory_notifier.dart`

- [ ] **Step 1: Ler o arquivo atual**

```bash
cat /home/giuliano/rf/capivara_2048/lib/domain/inventory/inventory_notifier.dart
```

- [ ] **Step 2: Adicionar `StreamSubscription` e `Box.watch()` em `load()`**

Adicionar import no topo:
```dart
import 'dart:async';
import 'package:hive/hive.dart';
```

Adicionar campo na classe:
```dart
StreamSubscription<BoxEvent>? _boxSub;
```

Substituir o método `load()`:
```dart
Future<void> load() async {
  state = await _repo.load();
  // Observar escritas externas (IAP, SyncEngine, ranking rewards)
  // A box já foi aberta pelo _repo.load(), abrir novamente é idempotente
  final box = await Hive.openBox<Inventory>('inventory');
  _boxSub?.cancel();
  _boxSub = box.watch(key: 'data').listen((event) {
    final updated = event.value as Inventory?;
    if (updated != null && mounted) state = updated;
  });
}
```

Adicionar `dispose()` sobrescrito:
```dart
@override
void dispose() {
  _boxSub?.cancel();
  super.dispose();
}
```

- [ ] **Step 3: Verificar compilação**

```bash
cd /home/giuliano/rf/capivara_2048
flutter analyze lib/domain/inventory/inventory_notifier.dart 2>&1 | grep error | head -5
```

Esperado: sem erros.

- [ ] **Step 4: Suite completa**

```bash
flutter test --reporter=compact 2>&1 | tail -4
```

Esperado: todos passam.

- [ ] **Step 5: Commit**

```bash
cd /home/giuliano/rf/capivara_2048
git add lib/domain/inventory/inventory_notifier.dart
git commit -m "feat(inventory): add Box.watch() to InventoryNotifier for external Hive write reactivity"
```

---

## Task 3 — `Box.watch()` em `LivesNotifier`

**Files:**
- Modify: `lib/domain/lives/lives_notifier.dart`

- [ ] **Step 1: Ler o arquivo atual**

```bash
cat /home/giuliano/rf/capivara_2048/lib/domain/lives/lives_notifier.dart
```

`LivesNotifier` usa `_init()` assíncrono (não `load()`). O `Box.watch()` deve ser configurado dentro de `_init()`, após carregar o estado inicial.

- [ ] **Step 2: Adicionar `StreamSubscription` e `Box.watch()` em `_init()`**

Adicionar campo na classe (já tem `dart:async`):
```dart
StreamSubscription<BoxEvent>? _boxSub;
```

No `_init()`, após `_ready.complete()` (na branch que NÃO é migração) e após `_ready.complete()` (na branch de migração), adicionar o watch. Localizar o bloco onde `_ready.complete()` é chamado pela segunda vez (após a migração bem-sucedida ou após o load normal) e adicionar logo após:

```dart
// Observar escritas externas (IAP, ranking rewards, invite rewards)
final box = await Hive.openBox<LivesState>('lives');
_boxSub?.cancel();
_boxSub = box.watch(key: 'state').listen((event) {
  final updated = event.value as LivesState?;
  if (updated != null && mounted) {
    state = updated;
    _startRegenTimer();
  }
});
```

Adicionar ao `dispose()` existente:
```dart
@override
void dispose() {
  _regenTimer?.cancel();
  _boxSub?.cancel();       // ← adicionar esta linha
  _lifecycleListener?.dispose();
  super.dispose();
}
```

Adicionar import no topo se não existir:
```dart
import 'package:hive/hive.dart';
```

- [ ] **Step 3: Verificar compilação**

```bash
cd /home/giuliano/rf/capivara_2048
flutter analyze lib/domain/lives/lives_notifier.dart 2>&1 | grep error | head -5
```

Esperado: sem erros.

- [ ] **Step 4: Suite completa**

```bash
flutter test --reporter=compact 2>&1 | tail -4
```

Esperado: todos passam.

- [ ] **Step 5: Commit**

```bash
cd /home/giuliano/rf/capivara_2048
git add lib/domain/lives/lives_notifier.dart
git commit -m "feat(lives): add Box.watch() to LivesNotifier for external Hive write reactivity"
```

---

## Task 4 — `IAPStartupService` (novo)

**Files:**
- Create: `lib/data/repositories/iap_startup_service.dart`

- [ ] **Step 1: Criar o arquivo**

```dart
// lib/data/repositories/iap_startup_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

abstract class IAPStartupService {
  /// Abre subscription permanente no purchaseStream.
  /// Deve ser chamado após login, com o userId do usuário logado.
  Future<void> initialize(String userId);

  /// Cancela a subscription. Chamado no logout.
  Future<void> dispose();
}

/// Implementação real — usada em prd e tst com USE_REAL_IAP=true.
class IAPStartupServiceImpl implements IAPStartupService {
  final FirebaseFirestore _firestore;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  String? _userId;

  IAPStartupServiceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> initialize(String userId) async {
    _userId = userId;
    // Cancela subscription anterior se houver (ex: re-login)
    await _sub?.cancel();
    _sub = InAppPurchase.instance.purchaseStream.listen(
      (purchases) => _handlePurchases(purchases),
      onError: (_) {}, // Nunca travar o app por erro de IAP
    );
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _userId = null;
  }

  void _handlePurchases(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Processar de forma idempotente via Firestore
          if (_userId != null) {
            unawaited(_deliverAndComplete(p));
          }
        case PurchaseStatus.pending:
          // Google Pay, boleto, operadora — aguarda status final.
          // NÃO chamar completePurchase aqui.
          debugPrint('[IAPStartup] purchase pending: ${p.productID}');
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          // Confirmar para o SO mesmo em caso de erro/cancelamento
          unawaited(InAppPurchase.instance.completePurchase(p));
      }
    }
  }

  Future<void> _deliverAndComplete(PurchaseDetails p) async {
    try {
      final purchaseId =
          p.purchaseID ?? p.verificationData.serverVerificationData;
      final docRef = _firestore
          .collection('purchases')
          .doc(_userId)
          .collection('items')
          .doc(purchaseId);

      final existing = await docRef.get();

      if (existing.exists && existing.data()?['status'] == 'delivered') {
        // Já entregue — apenas confirmar para o SO
        await InAppPurchase.instance.completePurchase(p);
        return;
      }

      // Compra não entregue (crash mid-purchase ou restore).
      // Não temos o ShopPackage aqui, então marcamos para auditoria.
      // Na Fase 7, uma Cloud Function processará 'pending_orphan' automaticamente.
      await docRef.set({
        'status': 'pending_orphan',
        'productId': p.productID,
        'platform': p.verificationData.source,
        'processedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await InAppPurchase.instance.completePurchase(p);

      debugPrint(
          '[IAPStartup] pending_orphan registered for ${p.productID} — '
          'user can restore purchases from ProfileScreen');
    } catch (e) {
      debugPrint('[IAPStartup] error processing purchase: $e');
      // Nunca travar o app por falha de IAP
    }
  }
}

/// Fake para testes e flavors sem IAP real.
class FakeIAPStartupService implements IAPStartupService {
  bool initializeCalled = false;
  bool disposeCalled = false;
  String? lastUserId;

  @override
  Future<void> initialize(String userId) async {
    initializeCalled = true;
    lastUserId = userId;
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
  }
}

final iapStartupServiceProvider = Provider<IAPStartupService>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  const useRealIap = bool.fromEnvironment('USE_REAL_IAP', defaultValue: false);
  if (flavor == 'prd' || (flavor == 'tst' && useRealIap)) {
    return IAPStartupServiceImpl();
  }
  return FakeIAPStartupService();
});
```

- [ ] **Step 2: Verificar compilação**

```bash
cd /home/giuliano/rf/capivara_2048
flutter analyze lib/data/repositories/iap_startup_service.dart 2>&1 | grep error | head -5
```

Esperado: sem erros.

- [ ] **Step 3: Suite completa**

```bash
flutter test --reporter=compact 2>&1 | tail -4
```

- [ ] **Step 4: Commit**

```bash
cd /home/giuliano/rf/capivara_2048
git add lib/data/repositories/iap_startup_service.dart
git commit -m "feat(iap): add IAPStartupService for global purchase stream drain"
```

---

## Task 5 — Corrigir `IAPServiceImpl`: `restored`/`pending` cases

**Files:**
- Modify: `lib/data/repositories/iap_service_impl.dart`

- [ ] **Step 1: Ler o switch atual em `buyPackage()`**

```bash
grep -n "PurchaseStatus\|case\|switch" /home/giuliano/rf/capivara_2048/lib/data/repositories/iap_service_impl.dart
```

- [ ] **Step 2: Adicionar `restored` e `pending` ao switch**

No `switch (purchase.status)` dentro de `iap.purchaseStream.listen(...)`:

```dart
// ANTES:
switch (purchase.status) {
  case PurchaseStatus.purchased:
    final result = await _deliverAndRecord(purchase, package);
    await iap.completePurchase(purchase);
    if (!completer.isCompleted) completer.complete(result);
    await sub.cancel();
  case PurchaseStatus.error:
    await iap.completePurchase(purchase);
    if (!completer.isCompleted) {
      completer.complete(PurchaseResult.failed(
          purchase.error?.message ?? 'Erro desconhecido'));
    }
    await sub.cancel();
  case PurchaseStatus.canceled:
    if (!completer.isCompleted) {
      completer.complete(const PurchaseResult.cancelled());
    }
    await sub.cancel();
  default:
    break;
}

// DEPOIS:
switch (purchase.status) {
  case PurchaseStatus.purchased:
  case PurchaseStatus.restored:
    // restored: idempotência Firestore garante não duplicar
    final result = await _deliverAndRecord(purchase, package);
    await iap.completePurchase(purchase);
    if (!completer.isCompleted) completer.complete(result);
    await sub.cancel();
  case PurchaseStatus.pending:
    // Pagamento pendente (boleto, Google Pay, operadora)
    // NÃO fechar subscription — aguarda status final
    // NÃO chamar completePurchase
    break;
  case PurchaseStatus.error:
    await iap.completePurchase(purchase);
    if (!completer.isCompleted) {
      completer.complete(PurchaseResult.failed(
          purchase.error?.message ?? 'Erro desconhecido'));
    }
    await sub.cancel();
  case PurchaseStatus.canceled:
    if (!completer.isCompleted) {
      completer.complete(const PurchaseResult.cancelled());
    }
    await sub.cancel();
}
```

- [ ] **Step 3: Verificar compilação**

```bash
cd /home/giuliano/rf/capivara_2048
flutter analyze lib/data/repositories/iap_service_impl.dart 2>&1 | grep error | head -5
```

- [ ] **Step 4: Suite completa**

```bash
flutter test --reporter=compact 2>&1 | tail -4
```

- [ ] **Step 5: Commit**

```bash
cd /home/giuliano/rf/capivara_2048
git add lib/data/repositories/iap_service_impl.dart
git commit -m "fix(iap): handle PurchaseStatus.restored and pending in IAPServiceImpl"
```

---

## Task 6 — Atualizar `iapServiceProvider` com `USE_REAL_IAP`

**Files:**
- Modify: `lib/domain/shop/iap_service.dart`

- [ ] **Step 1: Ler o provider atual**

```bash
grep -n "iapServiceProvider\|flavor\|FLAVOR" /home/giuliano/rf/capivara_2048/lib/domain/shop/iap_service.dart
```

- [ ] **Step 2: Atualizar o provider**

Substituir o `iapServiceProvider` atual por:

```dart
final iapServiceProvider = Provider<IAPService>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  const useRealIap = bool.fromEnvironment('USE_REAL_IAP', defaultValue: false);

  if (flavor == 'prd' || (flavor == 'tst' && useRealIap)) {
    final profile = ref.watch(authControllerProvider);
    if (profile != null) return IAPServiceImpl(userId: profile.userId);
  }
  return FakeIAPService();
});
```

- [ ] **Step 3: Verificar compilação**

```bash
flutter analyze lib/domain/shop/iap_service.dart 2>&1 | grep error | head -5
```

- [ ] **Step 4: Suite completa**

```bash
flutter test --reporter=compact 2>&1 | tail -4
```

- [ ] **Step 5: Commit**

```bash
cd /home/giuliano/rf/capivara_2048
git add lib/domain/shop/iap_service.dart
git commit -m "feat(iap): add USE_REAL_IAP dart-define to iapServiceProvider for tst flavor"
```

---

## Task 7 — `AuthController`: init/dispose `IAPStartupService`

**Files:**
- Modify: `lib/presentation/controllers/auth_controller.dart`

- [ ] **Step 1: Ler o arquivo atual**

```bash
cat /home/giuliano/rf/capivara_2048/lib/presentation/controllers/auth_controller.dart
```

- [ ] **Step 2: Adicionar import**

```dart
import '../../data/repositories/iap_startup_service.dart';
```

- [ ] **Step 3: Adicionar método privado `_initIAPStartup`**

Adicionar antes de `signOut()`:

```dart
/// Inicializa o IAPStartupService após login bem-sucedido.
/// No-op em dev (FakeIAPStartupService).
void _initIAPStartup(String userId) {
  unawaited(_ref.read(iapStartupServiceProvider).initialize(userId));
}
```

- [ ] **Step 4: Chamar `_initIAPStartup` nos 4 métodos de login**

Em `signInWithGoogle`, `signInWithApple`, `signInWithEmail` — adicionar dentro do `try {}` após `drainPendingEvents()`:
```dart
_initIAPStartup(profile.userId);
```

Em `createAccountWithEmail` — adicionar após `_syncEngine.init(...)`:
```dart
_initIAPStartup(profile.userId);
```

- [ ] **Step 5: Chamar `dispose()` no `signOut()`**

Em `signOut()`, antes de `state = null`:
```dart
unawaited(_ref.read(iapStartupServiceProvider).dispose());
```

- [ ] **Step 6: Verificar compilação**

```bash
flutter analyze lib/presentation/controllers/auth_controller.dart 2>&1 | grep error | head -5
```

- [ ] **Step 7: Rodar testes de auth**

```bash
flutter test test/domain/auth/ --reporter=compact 2>&1 | tail -4
```

Esperado: todos passam (FakeIAPStartupService é no-op).

- [ ] **Step 8: Suite completa**

```bash
flutter test --reporter=compact 2>&1 | tail -4
```

- [ ] **Step 9: Commit**

```bash
cd /home/giuliano/rf/capivara_2048
git add lib/presentation/controllers/auth_controller.dart
git commit -m "feat(iap): init/dispose IAPStartupService on login/logout in AuthController"
```

---

## Task 8 — `IAP.md` (instruções operacionais)

**Files:**
- Create: `IAP.md`

- [ ] **Step 1: Criar o arquivo**

```markdown
# IAP.md — Configuração de In-App Purchases

Guia para configurar e testar compras no Google Play Store e Apple App Store.
Siga este guia antes de testar com `USE_REAL_IAP=true`.

---

## 1. Product IDs

Os 6 pacotes da loja têm IDs exatos cadastrados nas lojas:

| Pacote | Nome | ID na loja | Preço BRL |
|--------|------|-----------|-----------|
| p1 | 4× Bomba 3 | `bichim_pack_p1` | R$ 3,99 |
| p2 | 4× Desfazer 3 | `bichim_pack_p2` | R$ 1,99 |
| p3 | 6 Vidas | `bichim_pack_p3` | R$ 2,49 |
| p4 | 10 Vidas | `bichim_pack_p4` | R$ 4,99 |
| p5 | Combo Mata Atlântica | `bichim_pack_p5` | R$ 4,99 |
| p6 | Combo Floresta Amazônica | `bichim_pack_p6` | R$ 9,99 |

Todos os produtos são do tipo **Consumable** (podem ser comprados múltiplas vezes).

---

## 2. Google Play Console

### 2.1 Pré-requisitos

- App criado no Google Play Console (pode ser em closed testing — não precisa estar publicado)
- APK `tst` ou `prd` enviado para alguma track (mesmo um upload de draft serve para liberar a seção de In-App Products)
- Conta de desenvolvedor com acesso à conta do app

### 2.2 Criar os produtos

1. Acesse [Google Play Console](https://play.google.com/console)
2. Selecione o app "Olha o Bichim!"
3. No menu lateral: **Monetizar → Produtos → Produtos para apps**
4. Clique em **Criar produto**
5. Para cada pacote da tabela acima:
   - **ID do produto:** exatamente como na coluna "ID na loja" (ex: `bichim_pack_p1`)
   - **Nome:** nome do pacote (ex: `4× Bomba 3`)
   - **Descrição:** descrição do pacote
   - **Status:** Ativo
   - **Preço padrão:** valor em BRL (o Google converte automaticamente para outras moedas)
6. Salvar e repetir para todos os 6 pacotes

### 2.3 Licença de teste (testes gratuitos)

Para testar sem cobrar o cartão do testador:

1. No Google Play Console → **Configurações → Licença e informações sobre o app**
2. Em **Testadores de licença**, adicione o e-mail da conta Google do testador
3. Essa conta pode comprar qualquer produto sem cobrança real
4. **Importante:** a conta do testador deve estar conectada no dispositivo Android como conta principal (ou adicionada ao dispositivo)

### 2.4 Closed Testing Track

Para distribuir o APK `tst` com IAP real para testadores internos:

1. **Testes → Testadores internos → Criar release**
2. Upload do APK `tst` gerado com:
   ```bash
   flutter build apk --dart-define=FLAVOR=tst --dart-define=USE_REAL_IAP=true
   ```
3. Adicionar e-mails dos testadores
4. Cada testador instala via link da track (não pela loja pública)

### 2.5 Testar em dispositivo

Requisitos:
- Dispositivo físico Android (emulador **não** suporta compras reais)
- APK instalado da closed testing track ou via `flutter install`
- Conta Google do testador configurada como conta principal no dispositivo
- `FLAVOR=tst` + `USE_REAL_IAP=true` → usa `IAPServiceImpl`

---

## 3. App Store Connect

### 3.1 Pré-requisitos

- App criado no App Store Connect
- Contrato de pagamento ativo (mesmo para testes)
- Xcode com o projeto Flutter configurado

### 3.2 Criar os produtos

1. Acesse [App Store Connect](https://appstoreconnect.apple.com)
2. Selecione o app → **Features → In-App Purchases**
3. Clique em **+** e escolha **Consumable**
4. Para cada pacote:
   - **Reference Name:** nome legível (ex: `4x Bomba 3`)
   - **Product ID:** exatamente como na coluna "ID na loja" (ex: `bichim_pack_p1`)
   - **Pricing:** escolher o tier de preço equivalente a BRL
   - **Localization (pt-BR):** Display Name + Description
5. Status: **Ready to Submit** (não precisa de aprovação para sandbox)

### 3.3 Sandbox Testers

1. App Store Connect → **Users and Access → Sandbox → Testers**
2. Criar conta de sandbox (e-mail fictício, nunca usado antes em Apple ID real)
3. No iPhone de teste: **Configurações → App Store → Conta Sandbox** → fazer login
4. Compras em sandbox são gratuitas e não cobram o cartão

### 3.4 StoreKit Configuration (testes locais no Xcode)

Para testar sem conectar ao servidor da Apple (mais rápido, funciona em simulador):

1. No Xcode, menu **File → New → File → StoreKit Configuration File**
2. Salvar como `Configuration.storekit` dentro de `ios/Runner/`
3. Para cada produto:
   - **+** → **Add Product** → **Consumable**
   - **Product ID:** `bichim_pack_p1` (etc.)
   - **Reference Name:** nome legível
   - **Price:** R$ 3.99 (etc.)
4. No scheme de teste: **Edit Scheme → Run → Options → StoreKit Configuration** → selecionar `Configuration.storekit`
5. Executar `flutter run` — as compras vão usar o StoreKit local, sem precisar de conta Apple

> **Nota:** `Configuration.storekit` deve ser adicionado ao `.gitignore` se contiver dados sensíveis, ou commitado como referência de configuração.

---

## 4. Builds com IAP

| Comando | Flavor | IAP | Uso |
|---------|--------|-----|-----|
| `flutter run --dart-define=FLAVOR=dev` | dev | Fake | Desenvolvimento local (sem lojas) |
| `flutter build apk --dart-define=FLAVOR=tst` | tst | Fake | QA — testa UI sem lojas |
| `flutter build apk --dart-define=FLAVOR=tst --dart-define=USE_REAL_IAP=true` | tst | Real (sandbox) | QA — testa fluxo completo com Play Store sandbox |
| `flutter build apk --dart-define=FLAVOR=prd` | prd | Real (produção) | Release |

### Build `tst` com IAP real (sandbox)

```bash
# Android
flutter build apk \
  --dart-define=FLAVOR=tst \
  --dart-define=USE_REAL_IAP=true

# iOS (requer Mac + Xcode)
flutter build ipa \
  --dart-define=FLAVOR=tst \
  --dart-define=USE_REAL_IAP=true
```

### Instalar no dispositivo

```bash
# Android
flutter install --dart-define=FLAVOR=tst --dart-define=USE_REAL_IAP=true

# iOS — usar Xcode ou TestFlight
```

---

## 5. Checklist antes de testar IAP

- [ ] Todos os 6 produtos cadastrados no Play Console / App Store Connect com IDs exatos
- [ ] Status dos produtos: **Ativo** (Google) / **Ready to Submit** (Apple)
- [ ] Conta de testador configurada (Google License Tester / Apple Sandbox)
- [ ] Dispositivo físico (Android) ou simulador com StoreKit Config (iOS)
- [ ] APK `tst` instalado com `USE_REAL_IAP=true`
- [ ] Usuário logado no app (IAP requer conta — `FakeIAPService` é retornado se não logado)

---

## 6. Troubleshooting

### "BillingClient is not ready"
- Causa: Google Play Services não inicializado ou dispositivo sem Google Play
- Solução: testar em dispositivo físico com Google Play instalado; reiniciar o app

### "SKErrorDomain code 0" (iOS)
- Causa: StoreKit não conseguiu carregar o produto
- Solução: verificar se o Product ID está exatamente igual ao cadastrado no App Store Connect

### "Produto não encontrado na loja"
- Causa: ID do produto no app não bate com o cadastrado na loja
- Solução: verificar tabela de IDs na seção 1 deste guia; no Play Console, confirmar status "Ativo"

### Compra não entregue após sucesso
- Verificar Firestore → `purchases/{userId}/items/{purchaseId}` → status deve ser `'delivered'`
- Se status for `'pending_orphan'`: usar "Restaurar compras" na ProfileScreen
- Se não houver documento: verificar logs do app (`[IAPStartup]` e `[IAPServiceImpl]`)

### "Usuário não tem permissão" (emulador Android)
- Causa: emuladores não suportam Google Play Billing
- Solução: usar dispositivo físico
```

- [ ] **Step 2: Commit**

```bash
cd /home/giuliano/rf/capivara_2048
git add IAP.md
git commit -m "docs: add IAP.md with Play Console, App Store Connect and build instructions"
```

---

## Task 9 — Atualizar `README.md` com seção de builds IAP

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Ler o README atual**

```bash
grep -n "## Build\|## Flavor\|flutter build\|dart-define\|FLAVOR" /home/giuliano/rf/capivara_2048/README.md | head -20
```

- [ ] **Step 2: Localizar ou criar seção de builds**

Encontrar a seção de builds existente (pode chamar "Flavors", "Builds", "Como rodar" etc.) e adicionar ou expandir com a tabela de IAP.

Se não existir seção de builds, adicionar após a seção de "Configuração":

```markdown
## Builds

| Comando | Flavor | IAP | Uso |
|---------|--------|-----|-----|
| `flutter run --dart-define=FLAVOR=dev` | dev | Fake | Desenvolvimento local |
| `flutter build apk --dart-define=FLAVOR=tst` | tst | Fake | QA — UI sem lojas |
| `flutter build apk --dart-define=FLAVOR=tst --dart-define=USE_REAL_IAP=true` | tst | Real (sandbox) | QA com Play Store sandbox |
| `flutter build apk --dart-define=FLAVOR=prd` | prd | Real (produção) | Release |

Para configurar produtos nas lojas e contas de teste, consulte [`IAP.md`](IAP.md).
```

- [ ] **Step 3: Suite completa (verificação final)**

```bash
cd /home/giuliano/rf/capivara_2048
flutter test --reporter=compact 2>&1 | tail -4
```

Esperado: mesma contagem de passes, sem regressões.

- [ ] **Step 4: Commit**

```bash
cd /home/giuliano/rf/capivara_2048
git add README.md
git commit -m "docs(readme): add IAP builds table with USE_REAL_IAP flag"
```

---

## Task 10 — Release v1.4.7

**Files:**
- Modify: `pubspec.yaml`
- Modify: `CHANGELOG.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: Bumpar versão**

Em `pubspec.yaml`: `version: 1.4.6+1` → `version: 1.4.7+1`

- [ ] **Step 2: Adicionar entrada no CHANGELOG**

Após `## [Unreleased]` e antes de `## [1.4.6]`:

```markdown
## [1.4.7] — 2026-05-06

### Fixed

- Bug crítico: `IAPServiceImpl`, `FirestoreInviteRepository` e `FirestoreRankingRepository` escreviam itens no Hive com key `'inventory'` em vez de `'data'` — inventário nunca era atualizado por entregas externas
- `IAPServiceImpl`: `PurchaseStatus.restored` agora entrega itens (idempotente via Firestore); `PurchaseStatus.pending` não fecha a subscription, aguarda status final
- `InventoryNotifier`: `Box.watch()` recarrega estado automaticamente quando IAP, ranking ou convite entregam itens diretamente no Hive
- `LivesNotifier`: idem — vidas atualizadas na UI sem restart após entrega por IAP ou ranking

### Added

- `IAPStartupService`: serviço dedicado com subscription permanente no `purchaseStream`; inicializado pelo `AuthController` após login; processa compras pendentes de sessões anteriores de forma idempotente
- `iapServiceProvider`: aceita `--dart-define=USE_REAL_IAP=true` no flavor `tst` para ativar `IAPServiceImpl` real no sandbox das lojas
- `IAP.md`: guia completo para cadastrar produtos no Google Play Console e App Store Connect, configurar contas de teste, StoreKit Configuration e builds por ambiente
- `README.md`: tabela de builds com IAP explicando cada variante e quando usar
```

- [ ] **Step 3: Atualizar `AGENTS.md`**

Na linha de fase atual, atualizar referência de versão de `v1.4.6` para `v1.4.7`.

- [ ] **Step 4: Suite final**

```bash
cd /home/giuliano/rf/capivara_2048
flutter test --reporter=compact 2>&1 | tail -4
```

Esperado: todos passam.

- [ ] **Step 5: Commit de release**

```bash
cd /home/giuliano/rf/capivara_2048
git add pubspec.yaml CHANGELOG.md AGENTS.md \
        docs/plans/2026-05-06-iap-runtime-fixes-plan.md
git commit -m "chore: release v1.4.7 — IAP runtime fixes, Box.watch, IAPStartupService"
```

- [ ] **Step 6: Merge e push**

```bash
cd /home/giuliano/rf/capivara_2048
git log --oneline -3
# Confirmar que estamos na branch correta antes do push
git push origin main
```

---

## Critérios de aceite finais

- [ ] `IAPServiceImpl._deliverToHive()` usa key `'data'` para inventory
- [ ] `FirestoreInviteRepository._deliverLocalReward()` usa key `'data'` para inventory
- [ ] `FirestoreRankingRepository._deliverReward()` usa key `'data'` para inventory
- [ ] `InventoryNotifier` tem `Box.watch(key: 'data')` e `dispose()` cancela subscription
- [ ] `LivesNotifier` tem `Box.watch(key: 'state')` e `dispose()` cancela subscription
- [ ] `IAPStartupService`: `FakeIAPStartupService` em dev/tst sem flag; `IAPStartupServiceImpl` em prd ou tst+USE_REAL_IAP
- [ ] `AuthController` chama `_initIAPStartup` em todos os 4 logins e `dispose()` no logout
- [ ] `iapServiceProvider` ativa `IAPServiceImpl` com `USE_REAL_IAP=true` em tst
- [ ] `IAP.md` existe com todos os 6 product IDs, instruções Play Console, App Store Connect e StoreKit Config
- [ ] `README.md` tem tabela de builds com IAP
- [ ] Suite de testes existente passa sem regressões
