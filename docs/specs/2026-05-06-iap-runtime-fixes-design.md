# Spec — IAP: Correções de Runtime + Testabilidade

**Data:** 2026-05-06  
**Versão alvo:** v1.4.7  
**Status:** Aguardando plano de implementação  
**Contexto:** Fase 4 completa (v1.4.6). A implementação base de IAP existe (`IAPServiceImpl`, `IAPConfirmationSheet`, `PurchaseSuccessSheet`, `ShopScreen`, `GameOverNoItemsOverlay`), mas tem 4 gaps de runtime e falta infraestrutura de teste.

---

## 1. Problemas a corrigir

| # | Gap | Impacto |
|---|-----|---------|
| 1 | `PurchaseStatus.pending` e `restored` ignorados em `IAPServiceImpl` | Compras via Google Pay/boleto nunca entregues; `restorePurchases()` silencioso |
| 2 | Nenhum listener global no startup | Compras de sessões anteriores não concluídas são perdidas |
| 3 | `InventoryNotifier`/`LivesNotifier` não reagem a escritas externas do Hive | Após compra em prd, itens aparecem na UI só no próximo launch |
| 4 | APK `tst` sempre usa `FakeIAPService` — não há como testar IAP real em sandbox | Testador não consegue validar o fluxo completo com as lojas |

---

## 2. Decisões de design

| Decisão | Escolha | Justificativa |
|---------|---------|---------------|
| Validação de recibo | Client-side apenas | Pacotes de baixo valor (R$1,99–R$9,99), idempotência Firestore já previne duplicação |
| Startup listener | `IAPStartupService` dedicado | Consistente com padrão `SyncEngine` do projeto |
| Riverpod refresh | `Box.watch()` nos notifiers | Reatividade automática sem acoplamento entre camadas |
| IAP em `tst` | `USE_REAL_IAP=true` dart-define | Fake por padrão, real ativado explicitamente pelo testador |
| Documentação | `IAP.md` + seção no `README.md` | Mesmo padrão do `FIREBASE.md` já existente |

---

## 3. Arquitetura

```
main.dart
  ├── IAPStartupService.initialize(userId)   ← novo, startup drain
  │     └── InAppPurchase.purchaseStream      ← subscription permanente
  │           ├── purchased / restored → _deliverAndComplete() (idempotente)
  │           ├── pending             → log, aguarda
  │           └── error/canceled      → completePurchase(), log
  │
  └── (existente) Firebase, Hive, SyncEngine...

IAPServiceImpl.buyPackage()
  └── InAppPurchase.purchaseStream            ← subscription por compra (local)
        ├── purchased ✅
        ├── restored  ← ADICIONAR (mesmo fluxo de purchased)
        ├── pending   ← ADICIONAR (log + continue, não fecha sub)
        ├── error ✅
        └── canceled ✅

InventoryNotifier
  └── Box.watch() após load()                 ← novo, recarrega ao receber write externo

LivesNotifier
  └── Box.watch() após load()                 ← idem

iapServiceProvider
  └── prd                     → IAPServiceImpl ✅
  └── tst + USE_REAL_IAP=true → IAPServiceImpl ← novo
  └── default                 → FakeIAPService ✅
```

### Sobre dupla subscription (IAPStartupService + IAPServiceImpl)

`purchaseStream` do `in_app_purchase` é um broadcast stream — múltiplas subscriptions recebem os mesmos eventos. Ambos os listeners irão processar o mesmo evento de compra. A idempotência via Firestore (`status == 'delivered'` → retorna sem recriar) garante que itens não são entregues duas vezes. Nenhuma coordenação extra necessária.

---

## 4. `IAPStartupService` (novo)

**Arquivo:** `lib/data/repositories/iap_startup_service.dart`

**Responsabilidade única:** Abrir e manter uma subscription global no `purchaseStream` do app inteiro, processando compras pendentes de sessões anteriores.

```dart
abstract class IAPStartupService {
  Future<void> initialize(String userId);
  Future<void> dispose();
}

class IAPStartupServiceImpl implements IAPStartupService {
  final FirebaseFirestore _firestore;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  IAPStartupServiceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> initialize(String userId) async {
    _sub = InAppPurchase.instance.purchaseStream.listen(
      (purchases) => _handlePurchases(purchases, userId),
    );
  }

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _handlePurchases(List<PurchaseDetails> purchases, String userId) {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          unawaited(_deliverAndComplete(p, userId));
        case PurchaseStatus.pending:
          // Aguarda — Google Pay / boleto / operadora
          // completePurchase NÃO chamado aqui
          break;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          unawaited(InAppPurchase.instance.completePurchase(p));
      }
    }
  }

  Future<void> _deliverAndComplete(PurchaseDetails p, String userId) async {
    try {
      final purchaseId = p.purchaseID
          ?? p.verificationData.serverVerificationData;
      final docRef = _firestore
          .collection('purchases').doc(userId)
          .collection('items').doc(purchaseId);

      final existing = await docRef.get();
      if (existing.exists && existing.data()?['status'] == 'delivered') {
        // Já entregue — apenas confirmar para o SO
        await InAppPurchase.instance.completePurchase(p);
        return;
      }
      // Entrega parcial ou nova: não conseguimos determinar o packageId aqui
      // sem o ShopPackage original. Marcamos como 'pending_orphan' para auditoria.
      // O usuário pode usar "Restaurar compras" na ProfileScreen para resolução manual.
      await docRef.set({
        'status': 'pending_orphan',
        'productId': p.productID,
        'processedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await InAppPurchase.instance.completePurchase(p);
    } catch (_) {
      // Nunca travar o startup por falha de IAP
    }
  }
}

class FakeIAPStartupService implements IAPStartupService {
  @override Future<void> initialize(String userId) async {}
  @override Future<void> dispose() async {}
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

**Nota sobre `pending_orphan`:** Quando o app é reaberto após um crash entre `purchased` e `completePurchase()`, `IAPStartupService` recebe o evento mas não tem acesso ao `ShopPackage` original (necessário para saber o que entregar). Marcar como `pending_orphan` no Firestore preserva o auditTrail; a entrega real deve vir do `IAPServiceImpl` quando o usuário tenta comprar novamente ou via `restorePurchases()`. Para a Fase 7, um Cloud Function pode processar `pending_orphan` entries automaticamente.

---

## 5. Correções em `IAPServiceImpl`

**Arquivo:** `lib/data/repositories/iap_service_impl.dart`

Adicionar os cases faltantes no `switch` dentro da subscription de `buyPackage()`:

```dart
case PurchaseStatus.restored:
  // Mesmo fluxo de purchased — idempotência Firestore garante não duplicar
  final result = await _deliverAndRecord(purchase, package);
  await iap.completePurchase(purchase);
  if (!completer.isCompleted) completer.complete(result);
  await sub.cancel();

case PurchaseStatus.pending:
  // Pagamento pendente (boleto, Google Pay, operadora)
  // NÃO fechar a subscription — aguardar o status final
  // NÃO chamar completePurchase aqui
  break;
```

---

## 6. `Box.watch()` em `InventoryNotifier` e `LivesNotifier`

### `InventoryNotifier`

**Arquivo:** `lib/domain/inventory/inventory_notifier.dart`

Adicionar campo `StreamSubscription? _boxSub` e subscription no `load()`:

```dart
StreamSubscription? _boxSub;

Future<void> load() async {
  // ... código existente que abre o box e carrega o estado ...
  
  // Observar escritas externas (ex: IAP, SyncEngine)
  _boxSub = box.watch(key: 'inventory').listen((_) async {
    final updated = box.get('inventory');
    if (updated != null) state = updated;
  });
}

@override
void dispose() {
  _boxSub?.cancel();
  super.dispose();
}
```

### `LivesNotifier`

**Arquivo:** `lib/domain/lives/lives_notifier.dart`

Mesmo padrão, observando a key correta do box de vidas.

---

## 7. `iapServiceProvider` atualizado

**Arquivo:** `lib/domain/shop/iap_service.dart`

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

---

## 8. `main.dart` — inicializar `IAPStartupService`

Após `SyncEngine.init()` (dentro do `authStateChanges` listener ou após login), inicializar o startup service:

```dart
// Após Firebase.initializeApp() e Hive.initFlutter():
final container = ProviderContainer(...);

// IAPStartupService — ativo apenas em prd ou tst com USE_REAL_IAP=true
// Será inicializado com userId quando AuthController fizer login
// (via listener no authControllerProvider)
```

Na verdade, o `IAPStartupService` precisa do `userId` para funcionar. O padrão mais limpo: no `AuthController`, após `_syncEngine.init()`, também inicializar o `IAPStartupService`:

```dart
// Em _registerPendingInvite() ou em um novo método _initIAP():
final iapStartup = _ref.read(iapStartupServiceProvider);
unawaited(iapStartup.initialize(profile.userId));
```

E no `signOut()`, chamar `dispose()`.

---

## 9. Arquivos afetados

| Arquivo | Ação |
|---------|------|
| `lib/data/repositories/iap_startup_service.dart` | **Novo** |
| `lib/data/repositories/iap_service_impl.dart` | Adicionar `restored`/`pending` cases |
| `lib/domain/shop/iap_service.dart` | Atualizar provider com `USE_REAL_IAP` |
| `lib/domain/inventory/inventory_notifier.dart` | Adicionar `Box.watch()` |
| `lib/domain/lives/lives_notifier.dart` | Adicionar `Box.watch()` |
| `lib/presentation/controllers/auth_controller.dart` | Init/dispose `IAPStartupService` no login/logout |
| `IAP.md` | **Novo** — instruções Play Store + App Store + builds |
| `README.md` | Adicionar seção "Builds com IAP" |

---

## 10. `IAP.md` — conteúdo esperado

Seguindo o padrão do `FIREBASE.md`, o arquivo deve cobrir:

1. **Visão geral** — Product IDs dos 6 pacotes (`bichim_pack_p1` … `bichim_pack_p6`)
2. **Google Play Console**
   - Criar app no Console (se ainda não existir)
   - Criar In-App Products (tipo: consumable) com os IDs exatos
   - Configurar preços em BRL
   - Adicionar licença de teste (email do testador)
   - Closed testing track para APK `tst`
3. **App Store Connect**
   - Criar In-App Purchases (tipo: consumable)
   - Criar Sandbox Tester accounts
   - Criar `.storekit` Configuration File no Xcode para testes locais sem submissão
4. **Builds**
   - Como gerar cada variante do APK
   - Como testar IAP em dispositivo físico vs emulador
5. **Troubleshooting** — erros comuns (`BillingClient not ready`, `SKErrorDomain`)

---

## 11. `README.md` — seção "Builds"

Adicionar tabela clara ao README:

| Comando | Flavor | IAP | Uso |
|---------|--------|-----|-----|
| `flutter run --dart-define=FLAVOR=dev` | dev | Fake | Desenvolvimento local |
| `flutter build apk --dart-define=FLAVOR=tst` | tst | Fake | QA sem IAP |
| `flutter build apk --dart-define=FLAVOR=tst --dart-define=USE_REAL_IAP=true` | tst | Real (sandbox) | QA com IAP Play Store sandbox |
| `flutter build apk --dart-define=FLAVOR=prd` | prd | Real (produção) | Release |

---

## 12. Critérios de aceite

- [ ] Compra que retorna `PurchaseStatus.restored` entrega itens e exibe `PurchaseSuccessSheet`
- [ ] Compra que retorna `PurchaseStatus.pending` não trava o fluxo — UI exibe mensagem "Pagamento pendente"
- [ ] Ao reabrir o app após crash mid-purchase, `IAPStartupService` processa a compra pendente
- [ ] Após compra em prd, `InventoryNotifier` e `LivesNotifier` atualizam a UI sem restart
- [ ] APK `tst` com `USE_REAL_IAP=false` (padrão): usa `FakeIAPService`
- [ ] APK `tst` com `USE_REAL_IAP=true`: usa `IAPServiceImpl` real
- [ ] `IAP.md` existe com instruções completas para Play Console e App Store Connect
- [ ] `README.md` tem tabela de builds com IAP
- [ ] Suite de testes existente passa sem regressões
