# Invite Deep Links + Gift Code Redemption Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Completar as duas features sociais incompletas: (1) Android App Links interceptando `https://bichim-prd.web.app/invite` e exibindo `InviteWelcomeSheet` para usuários não logados; (2) botão "Resgatar código de presente" na ShopScreen + tela `RedeemCodeScreen` funcional com validação Firestore.

**Architecture:** Feature 1 usa `android:autoVerify` + `StateProvider<String?>` para passar o ref do convite da camada de inicialização até a HomeScreen via `ref.listen`. Feature 2 usa uma transação Firestore atômica em `GiftCodeRepository` + função de validação pura testável sem Firestore.

**Tech Stack:** Flutter/Dart, Riverpod (`StateProvider`, `Provider`), `cloud_firestore` transactions, `app_links`, `firebase_auth`.

**Pré-requisitos:** `assetlinks.json` já está em `public/.well-known/assetlinks.json` e já foi feito deploy no Firebase Hosting.

---

## Mapa de Arquivos

| Arquivo | Ação |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | Modificar — add intent-filter HTTPS com `autoVerify` |
| `lib/core/providers/invite_providers.dart` | Criar — `pendingInviteRefProvider` |
| `lib/main.dart` | Modificar — atualizar `_handleInviteDeepLink` para HTTPS |
| `lib/presentation/widgets/invite_welcome_sheet.dart` | Criar — bottom sheet de boas-vindas |
| `lib/presentation/screens/home_screen.dart` | Modificar — `ref.listen` no provider |
| `firestore.rules` | Modificar — `createdByUserId` → `createdBy`, tighten update |
| `lib/core/utils/iap_delivery.dart` | Modificar — add `deliverRewardBundle` |
| `lib/data/repositories/gift_code_repository.dart` | Criar — `GiftCodeRepository` + `validateGiftCode` |
| `test/unit/gift_code_repository_test.dart` | Criar — unit tests `validateGiftCode` |
| `lib/presentation/screens/shop_screen.dart` | Modificar — botão "Resgatar" + `writeToFirestore` |
| `lib/presentation/screens/redeem_code_screen.dart` | Modificar — implementar stub |
| `test/e2e/flows/shop_flows.dart` | Modificar — add cenário navegação RedeemCodeScreen |

---

### Task 1: AndroidManifest — HTTPS App Links intent filter

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Adicionar intent-filter HTTPS após o filtro existente `olhabichim://`**

No arquivo `android/app/src/main/AndroidManifest.xml`, adicionar o bloco abaixo logo após o `<intent-filter>` existente que tem `<data android:scheme="olhabichim"/>` (após a linha 31):

```xml
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
                <category android:name="android.intent.category.BROWSABLE"/>
                <data android:scheme="https"
                      android:host="bichim-prd.web.app"
                      android:pathPrefix="/invite"/>
            </intent-filter>
```

O arquivo final deve ter a `<activity>` com três `<intent-filter>`:
1. `MAIN` / `LAUNCHER` (linha 22)
2. `VIEW` com `scheme="olhabichim"` (linha 26)
3. `VIEW` com `autoVerify="true"` e `scheme="https"` (novo)

- [ ] **Step 2: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "feat(deep-links): add HTTPS App Links intent filter with autoVerify"
```

---

### Task 2: `pendingInviteRefProvider`

**Files:**
- Create: `lib/core/providers/invite_providers.dart`

- [ ] **Step 1: Criar arquivo com provider**

```dart
// lib/core/providers/invite_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the pending invite ref extracted from a deep link before the user logs in.
/// HomeScreen listens to this and shows InviteWelcomeSheet when it becomes non-null.
/// Cleared (set to null) after the sheet is shown or if the user is already logged in.
final pendingInviteRefProvider = StateProvider<String?>((ref) => null);
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/providers/invite_providers.dart
git commit -m "feat(deep-links): add pendingInviteRefProvider for invite handoff"
```

---

### Task 3: Atualizar `_handleInviteDeepLink` em `main.dart`

**Files:**
- Modify: `lib/main.dart`

O `_handleInviteDeepLink` atual (linha 103) só trata `olhabichim://invite`. Precisa: (a) também tratar HTTPS, (b) receber `ProviderContainer` para atualizar o provider.

- [ ] **Step 1: Adicionar import do provider**

No bloco de imports de `lib/main.dart`, adicionar após `import 'app.dart';`:

```dart
import 'core/providers/invite_providers.dart';
```

- [ ] **Step 2: Atualizar as chamadas de `_handleInviteDeepLink`**

Localizar as linhas 63–64:
```dart
  if (initialUri != null) _handleInviteDeepLink(initialUri);
  appLinks.uriLinkStream.listen(_handleInviteDeepLink);
```

Substituir por:
```dart
  if (initialUri != null) _handleInviteDeepLink(initialUri, container);
  appLinks.uriLinkStream.listen((uri) => _handleInviteDeepLink(uri, container));
```

- [ ] **Step 3: Substituir a função `_handleInviteDeepLink` (linha 103)**

Localizar o bloco atual:
```dart
void _handleInviteDeepLink(Uri uri) {
  if (uri.scheme == 'olhabichim' && uri.host == 'invite') {
    final ref = uri.queryParameters['ref'];
    if (ref != null && ref.isNotEmpty) {
      Hive.openBox<String>('invite_refs').then((box) {
        box.put('pending_ref', ref);
      });
    }
  }
}
```

Substituir por:
```dart
void _handleInviteDeepLink(Uri uri, ProviderContainer container) {
  String? inviteRef;
  if (uri.scheme == 'olhabichim' && uri.host == 'invite') {
    inviteRef = uri.queryParameters['ref'];
  } else if (uri.scheme == 'https' &&
      uri.host == 'bichim-prd.web.app' &&
      uri.path == '/invite') {
    inviteRef = uri.queryParameters['ref'];
  }
  if (inviteRef != null && inviteRef.isNotEmpty) {
    Hive.openBox<String>('invite_refs').then((box) {
      box.put('pending_ref', inviteRef!);
    });
    container.read(pendingInviteRefProvider.notifier).state = inviteRef;
  }
}
```

- [ ] **Step 4: Verificar compilação**

```bash
flutter analyze lib/main.dart
```

Expected: nenhum erro.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart
git commit -m "feat(deep-links): handle HTTPS scheme in _handleInviteDeepLink"
```

---

### Task 4: `InviteWelcomeSheet`

**Files:**
- Create: `lib/presentation/widgets/invite_welcome_sheet.dart`

Exibe mensagem genérica (sem lookup Firestore de nome — o app está unauthenticated neste momento). Botão primário → `OnboardingAuthScreen`. Botão secundário → fecha (ref já foi salvo no Hive e no provider pelo `_handleInviteDeepLink`).

- [ ] **Step 1: Criar o widget**

```dart
// lib/presentation/widgets/invite_welcome_sheet.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/onboarding_auth_screen.dart';

class InviteWelcomeSheet extends StatelessWidget {
  const InviteWelcomeSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const InviteWelcomeSheet(),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Um amigo te convidou! 🎉',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3E2723),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Crie sua conta e ganhe recompensas quando seu amigo se cadastrar.',
              style: GoogleFonts.nunito(fontSize: 15, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const OnboardingAuthScreen(showSkip: true),
                    ),
                  );
                },
                child: Text(
                  'Criar conta',
                  style: GoogleFonts.fredoka(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Agora não',
                style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/widgets/invite_welcome_sheet.dart
git commit -m "feat(deep-links): add InviteWelcomeSheet for invite landing"
```

---

### Task 5: Listener em HomeScreen

**Files:**
- Modify: `lib/presentation/screens/home_screen.dart`

`HomeScreen` é `ConsumerStatefulWidget`, então `ref.listen` vai no `build()`.

- [ ] **Step 1: Adicionar imports**

No bloco de imports de `home_screen.dart`, adicionar:

```dart
import '../../core/providers/invite_providers.dart';
import '../widgets/invite_welcome_sheet.dart';
```

- [ ] **Step 2: Adicionar `ref.listen` no início do método `build()`**

Localizar `Widget build(BuildContext context)` (linha ~88). Logo após `final gameState = ref.watch(gameProvider);`, adicionar:

```dart
    ref.listen<String?>(pendingInviteRefProvider, (_, next) {
      if (next == null) return;
      final isLoggedIn = ref.read(authControllerProvider) != null;
      ref.read(pendingInviteRefProvider.notifier).state = null;
      if (isLoggedIn) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) InviteWelcomeSheet.show(context);
      });
    });
```

- [ ] **Step 3: Verificar compilação**

```bash
flutter analyze lib/presentation/screens/home_screen.dart
```

Expected: nenhum erro.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/screens/home_screen.dart
git commit -m "feat(deep-links): listen to pendingInviteRefProvider in HomeScreen"
```

---

### Task 6: Corrigir Firestore rules para shareCodes

**Files:**
- Modify: `firestore.rules`

Problemas atuais (linhas 49–52):
1. `allow create` verifica `createdByUserId` mas o repositório vai escrever o campo `createdBy`
2. `allow update` permite qualquer update autenticado — deve restringir ao padrão de resgate

- [ ] **Step 1: Substituir o bloco shareCodes**

Localizar:
```
    // Share codes for gifting — creator writes, any authenticated user can read/update to redeem
    match /shareCodes/{code} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
        && request.resource.data.createdByUserId == request.auth.uid;
      allow update: if request.auth != null;
    }
```

Substituir por:
```
    // Share codes for gifting — creator writes, authenticated user redeems
    match /shareCodes/{code} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
        && request.resource.data.createdBy == request.auth.uid;
      allow update: if request.auth != null
        && resource.data.status == 'pending'
        && request.resource.data.status == 'redeemed'
        && request.resource.data.redeemedBy == request.auth.uid;
    }
```

- [ ] **Step 2: Commit**

```bash
git add firestore.rules
git commit -m "fix(firestore): fix shareCodes rules — createdBy field and tighten update"
```

---

### Task 7: `deliverRewardBundle` em `iap_delivery.dart`

**Files:**
- Modify: `lib/core/utils/iap_delivery.dart`

Adicionar função que entrega um `RewardBundle` ao inventário local — paralela a `deliverIAPItems` mas aceita `RewardBundle` diretamente (usado pelo fluxo de resgate de gift code).

- [ ] **Step 1: Adicionar a função**

No final do arquivo `lib/core/utils/iap_delivery.dart`, após a função `deliverIAPItems`, adicionar:

```dart
void deliverRewardBundle(WidgetRef ref, RewardBundle bundle) {
  if (bundle.lives > 0) {
    unawaited(ref.read(livesProvider.notifier).addPurchased(bundle.lives));
  }
  if (bundle.bomb2 > 0) {
    unawaited(
      ref.read(inventoryProvider.notifier).add(ItemType.bomb2, bundle.bomb2),
    );
  }
  if (bundle.bomb3 > 0) {
    unawaited(
      ref.read(inventoryProvider.notifier).add(ItemType.bomb3, bundle.bomb3),
    );
  }
  if (bundle.undo1 > 0) {
    unawaited(
      ref.read(inventoryProvider.notifier).add(ItemType.undo1, bundle.undo1),
    );
  }
  if (bundle.undo3 > 0) {
    unawaited(
      ref.read(inventoryProvider.notifier).add(ItemType.undo3, bundle.undo3),
    );
  }
}
```

O import de `RewardBundle` já está disponível via `'../../data/models/shop_package.dart'` (já importado pelo `deliverIAPItems`).

- [ ] **Step 2: Verificar compilação**

```bash
flutter analyze lib/core/utils/iap_delivery.dart
```

Expected: nenhum erro.

- [ ] **Step 3: Commit**

```bash
git add lib/core/utils/iap_delivery.dart
git commit -m "feat(gift): add deliverRewardBundle to iap_delivery"
```

---

### Task 8: `GiftCodeRepository` + unit tests

**Files:**
- Create: `lib/data/repositories/gift_code_repository.dart`
- Create: `test/unit/gift_code_repository_test.dart`

A lógica de validação é extraída em `validateGiftCode` — função pura, sem Firestore, totalmente testável.

- [ ] **Step 1: Escrever o teste unitário (failing primeiro)**

```dart
// test/unit/gift_code_repository_test.dart

import 'package:test/test.dart';
import 'package:capivara_2048/data/repositories/gift_code_repository.dart';

void main() {
  group('validateGiftCode', () {
    final now = DateTime(2026, 5, 15);
    final recentDate = DateTime(2026, 5, 10);
    const userId = 'user_abc';
    const otherUserId = 'user_xyz';

    test('returns null for valid pending code', () {
      expect(
        validateGiftCode(
          status: 'pending',
          createdBy: otherUserId,
          createdAt: recentDate,
          userId: userId,
          now: now,
        ),
        isNull,
      );
    });

    test('returns alreadyRedeemed when status is redeemed', () {
      expect(
        validateGiftCode(
          status: 'redeemed',
          createdBy: otherUserId,
          createdAt: recentDate,
          userId: userId,
          now: now,
        ),
        RedeemError.alreadyRedeemed,
      );
    });

    test('returns ownCode when createdBy matches userId', () {
      expect(
        validateGiftCode(
          status: 'pending',
          createdBy: userId,
          createdAt: recentDate,
          userId: userId,
          now: now,
        ),
        RedeemError.ownCode,
      );
    });

    test('returns expired when code is older than 30 days', () {
      final oldDate = DateTime(2026, 4, 14); // 31 days before now
      expect(
        validateGiftCode(
          status: 'pending',
          createdBy: otherUserId,
          createdAt: oldDate,
          userId: userId,
          now: now,
        ),
        RedeemError.expired,
      );
    });

    test('returns null for code exactly 30 days old', () {
      final thirtyDaysAgo = DateTime(2026, 4, 15); // exactly 30 days
      expect(
        validateGiftCode(
          status: 'pending',
          createdBy: otherUserId,
          createdAt: thirtyDaysAgo,
          userId: userId,
          now: now,
        ),
        isNull,
      );
    });

    test('alreadyRedeemed takes priority over ownCode', () {
      expect(
        validateGiftCode(
          status: 'redeemed',
          createdBy: userId,
          createdAt: recentDate,
          userId: userId,
          now: now,
        ),
        RedeemError.alreadyRedeemed,
      );
    });
  });
}
```

- [ ] **Step 2: Executar teste para confirmar falha**

```bash
flutter test test/unit/gift_code_repository_test.dart
```

Expected: FAIL — `'package:capivara_2048/data/repositories/gift_code_repository.dart'` não existe.

- [ ] **Step 3: Criar `GiftCodeRepository`**

```dart
// lib/data/repositories/gift_code_repository.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/share_code.dart';
import '../models/shop_package.dart';

enum RedeemError { notFound, alreadyRedeemed, expired, ownCode, offline }

class RedeemException implements Exception {
  final RedeemError error;
  const RedeemException(this.error);
}

/// Pure validation — no Firestore dependency, fully unit-testable.
RedeemError? validateGiftCode({
  required String status,
  required String createdBy,
  required DateTime createdAt,
  required String userId,
  required DateTime now,
}) {
  if (status == 'redeemed') return RedeemError.alreadyRedeemed;
  if (createdBy == userId) return RedeemError.ownCode;
  if (now.difference(createdAt).inDays > 30) return RedeemError.expired;
  return null;
}

class GiftCodeRepository {
  final FirebaseFirestore _db;

  GiftCodeRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<void> writeToFirestore(ShareCode code, String userId) async {
    await _db.collection('shareCodes').doc(code.code).set({
      'code': code.code,
      'packageId': code.packageId,
      'giftContents': {
        'lives': code.giftContents.lives,
        'bomb2': code.giftContents.bomb2,
        'bomb3': code.giftContents.bomb3,
        'undo1': code.giftContents.undo1,
        'undo3': code.giftContents.undo3,
      },
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': userId,
      'redeemedBy': null,
      'redeemedAt': null,
    });
  }

  /// Atomically redeems a gift code and returns the reward bundle.
  /// Throws [RedeemException] for all validation failures.
  Future<RewardBundle> redeemCode(String code, String userId) async {
    final docRef = _db.collection('shareCodes').doc(code.trim());
    RewardBundle? result;
    try {
      await _db.runTransaction((txn) async {
        final snap = await txn.get(docRef);
        if (!snap.exists) throw const RedeemException(RedeemError.notFound);
        final data = snap.data()!;
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final validationError = validateGiftCode(
          status: data['status'] as String,
          createdBy: data['createdBy'] as String,
          createdAt: createdAt,
          userId: userId,
          now: DateTime.now(),
        );
        if (validationError != null) throw RedeemException(validationError);
        final g = data['giftContents'] as Map<String, dynamic>;
        result = RewardBundle(
          lives: g['lives'] as int,
          bomb2: g['bomb2'] as int,
          bomb3: g['bomb3'] as int,
          undo1: g['undo1'] as int,
          undo3: g['undo3'] as int,
        );
        txn.update(docRef, {
          'status': 'redeemed',
          'redeemedBy': userId,
          'redeemedAt': FieldValue.serverTimestamp(),
        });
      });
    } on RedeemException {
      rethrow;
    } on FirebaseException {
      throw const RedeemException(RedeemError.offline);
    } catch (_) {
      throw const RedeemException(RedeemError.offline);
    }
    return result!;
  }
}

final giftCodeRepositoryProvider = Provider<GiftCodeRepository>(
  (ref) => GiftCodeRepository(),
);
```

- [ ] **Step 4: Executar teste para confirmar green**

```bash
flutter test test/unit/gift_code_repository_test.dart
```

Expected: PASS — 6/6 testes passando.

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/gift_code_repository.dart test/unit/gift_code_repository_test.dart
git commit -m "feat(gift): add GiftCodeRepository with Firestore transaction + unit tests"
```

---

### Task 9: Atualizar `ShopScreen`

**Files:**
- Modify: `lib/presentation/screens/shop_screen.dart`

Duas mudanças: (1) botão "Resgatar código de presente" no topo do ListView; (2) chamar `writeToFirestore` após compra bem-sucedida.

- [ ] **Step 1: Adicionar imports**

No bloco de imports de `shop_screen.dart`, adicionar:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/gift_code_repository.dart';
import 'redeem_code_screen.dart';
```

- [ ] **Step 2: Adicionar botão no topo do ListView**

Localizar o `body: ListView(` e o início do `children:`. Logo antes de `...packages.map(`, adicionar:

```dart
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RedeemCodeScreen(),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white60),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.card_giftcard_outlined, size: 20),
                label: Text(
                  'Resgatar código de presente',
                  style: GoogleFonts.fredoka(fontSize: 16),
                ),
              ),
            ),
```

Note: `build` em `ConsumerWidget` recebe `context` como parâmetro — use-o diretamente no `Navigator.push`.

- [ ] **Step 3: Chamar `writeToFirestore` após compra bem-sucedida em `_onBuy`**

Localizar o bloco em `_onBuy`:
```dart
    if (result.success && result.shareCode != null) {
      // Deliver items locally (needed in dev/tst; in prd server-side webhook does it too)
      deliverIAPItems(ref, package);
```

Após `deliverIAPItems(ref, package);`, adicionar:
```dart
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        unawaited(
          ref
              .read(giftCodeRepositoryProvider)
              .writeToFirestore(result.shareCode!, userId),
        );
      }
```

- [ ] **Step 4: Verificar compilação**

```bash
flutter analyze lib/presentation/screens/shop_screen.dart
```

Expected: nenhum erro.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/shop_screen.dart
git commit -m "feat(gift): add redeem button to ShopScreen and write gift codes to Firestore"
```

---

### Task 10: Implementar `RedeemCodeScreen`

**Files:**
- Modify: `lib/presentation/screens/redeem_code_screen.dart`
- Modify: `test/e2e/flows/shop_flows.dart`

- [ ] **Step 1: Escrever o cenário E2E (failing primeiro)**

Em `test/e2e/flows/shop_flows.dart`, adicionar no final do arquivo:

```dart
// ─── flow.shop_redeem_code_navigation ─────────────────────────────────────────

final shopRedeemCodeNavigationScenario = E2EScenario(
  id: 'flow.shop_redeem_code_navigation',
  title: 'ShopScreen: tap "Resgatar código" → RedeemCodeScreen renderiza',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    final widget = await tester.runAsync(() => harness.boot());
    await tester.pumpWidget(widget!);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Navigate to ShopScreen from HomeScreen
    await tester.tap(find.byKey(const Key('home_btn_loja')));
    await tester.pumpAndSettle();

    // Tap "Resgatar código de presente"
    await tester.tap(find.text('Resgatar código de presente'));
    await tester.pumpAndSettle();

    // RedeemCodeScreen should be visible
    expect(find.text('Resgatar Código'), findsOneWidget);
    expect(find.text('Resgatar'), findsOneWidget);
  },
);
```

Também adicionar `shopRedeemCodeNavigationScenario` à lista de cenários onde os outros são registrados (buscar `shopOverlayFromEmptyInventoryScenario` em outros arquivos para ver onde são registrados e adicionar o novo ao mesmo lugar).

- [ ] **Step 2: Implementar `RedeemCodeScreen`**

Substituir todo o conteúdo de `lib/presentation/screens/redeem_code_screen.dart`:

```dart
// lib/presentation/screens/redeem_code_screen.dart

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/iap_delivery.dart';
import '../../data/models/shop_package.dart';
import '../../data/repositories/gift_code_repository.dart';
import '../widgets/game_background.dart';
import 'onboarding_auth_screen.dart';

class RedeemCodeScreen extends ConsumerStatefulWidget {
  const RedeemCodeScreen({super.key});

  @override
  ConsumerState<RedeemCodeScreen> createState() => _RedeemCodeScreenState();
}

class _RedeemCodeScreenState extends ConsumerState<RedeemCodeScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingAuthScreen(showSkip: false),
        ),
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(giftCodeRepositoryProvider);
      final bundle = await repo.redeemCode(_controller.text, userId);
      if (!mounted) return;
      setState(() => _loading = false);
      deliverRewardBundle(ref, bundle);
      _showSuccessSheet(bundle);
    } on RedeemException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _messageFor(e.error);
      });
    }
  }

  String _messageFor(RedeemError error) => switch (error) {
        RedeemError.notFound => 'Código não encontrado.',
        RedeemError.alreadyRedeemed => 'Este código já foi utilizado.',
        RedeemError.expired => 'Este código expirou.',
        RedeemError.ownCode =>
          'Você não pode resgatar seu próprio presente.',
        RedeemError.offline => 'Sem conexão. Tente novamente.',
      };

  void _showSuccessSheet(RewardBundle bundle) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Presente recebido! 🎁',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3E2723),
              ),
            ),
            const SizedBox(height: 16),
            _BundleRow(bundle: bundle),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context); // close sheet
                  Navigator.pop(context); // back to shop
                },
                child: Text('Ótimo!', style: GoogleFonts.fredoka(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Resgatar Código',
            style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Digite o código do presente',
                  errorText: _error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2E7D32),
                      width: 2,
                    ),
                  ),
                ),
                style: GoogleFonts.nunito(fontSize: 16),
                onSubmitted: (_) => _redeem(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _redeem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Resgatar',
                        style: GoogleFonts.fredoka(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BundleRow extends StatelessWidget {
  final RewardBundle bundle;
  const _BundleRow({required this.bundle});

  @override
  Widget build(BuildContext context) {
    final items = [
      if (bundle.lives > 0) '${bundle.lives} vidas',
      if (bundle.bomb3 > 0) '${bundle.bomb3}× Bomba 3',
      if (bundle.bomb2 > 0) '${bundle.bomb2}× Bomba 2',
      if (bundle.undo3 > 0) '${bundle.undo3}× Desfazer 3',
      if (bundle.undo1 > 0) '${bundle.undo1}× Desfazer 1',
    ];
    return Text(
      items.join(' · '),
      style: GoogleFonts.nunito(fontSize: 15, color: Colors.black87),
      textAlign: TextAlign.center,
    );
  }
}
```

- [ ] **Step 3: Verificar compilação geral**

```bash
flutter analyze lib/
```

Expected: nenhum erro.

- [ ] **Step 4: Executar unit tests**

```bash
flutter test test/unit/gift_code_repository_test.dart
```

Expected: PASS — 6/6.

- [ ] **Step 5: Executar suite Tier 1**

```bash
flutter test test/e2e/ --dart-define=FLAVOR=dev
```

Expected: todos os cenários existentes passando. O novo cenário `flow.shop_redeem_code_navigation` passa se a key `home_btn_loja` existir no HomeScreen (se não existir, o teste vai indicar e você ajusta a key ou usa `find.text('Loja')`).

- [ ] **Step 6: Commit final**

```bash
git add lib/presentation/screens/redeem_code_screen.dart test/e2e/flows/shop_flows.dart
git commit -m "feat(gift): implement RedeemCodeScreen with Firestore validation and success sheet"
```

---

## Notas pós-implementação

### Teste Manual — App Links (requer device físico)
1. Instalar APK dev no device com `flutter run --dart-define=FLAVOR=dev`
2. Aguardar verificação Android (pode levar até 24h — forçar com `adb shell pm set-app-links --package com.catraia.capivara2048.dev 2 bichim-prd.web.app`)
3. Abrir `https://bichim-prd.web.app/invite?ref=testuser123` num browser no device
4. Verificar que o app abre diretamente (não o browser) e que `InviteWelcomeSheet` aparece

### Teste Manual — Gift Code
1. Flavor dev: comprar qualquer pacote na ShopScreen
2. Anotar o código exibido no `PurchaseSuccessSheet`
3. Verificar no Firebase Console que o código foi gravado em `shareCodes/{code}`
4. Tentar resgatar o código com outro userId (usar emulador ou segundo device)
5. Verificar inventário atualizado e sheet de sucesso

### Regras Firestore — deploy
Após Tasks 1–10 estarem implementadas:
```bash
firebase deploy --only firestore:rules
```
