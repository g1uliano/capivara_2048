# Fase 4 — Gaps: registerInvite + ProfileScreen (Convidar + Restaurar)

> **For agentic workers:** Execute task by task per subagent-driven-development.

**Data:** 2026-05-06  
**Versão alvo:** v1.4.6  
**Status:** Aguardando execução  
**Base:** v1.4.5 (main)

---

## Gaps a corrigir

| # | Arquivo | Gap | Severidade |
|---|---------|-----|-----------|
| 1 | `AuthController` + `OnboardingAuthScreen` | `registerInvite` nunca chamado após login — convite não é registrado no Firestore | 🔴 Bug funcional |
| 2 | `ProfileScreen` | Falta botão "Convidar Amigos" → `InviteFriendsScreen` | 🟡 Feature ausente |
| 3 | `ProfileScreen` | "Restaurar compras" mostra stub Snackbar em vez de `iapService.restorePurchases()` | 🟡 Feature ausente |

---

## Task 1 — `AuthController`: chamar `registerInvite` após login

**Files:**
- Modify: `lib/presentation/controllers/auth_controller.dart`

### Lógica

Após cada login bem-sucedido (todos os 4 métodos: signInWithGoogle, signInWithApple, signInWithEmail, createAccountWithEmail), verificar se existe `pending_ref` no Hive e chamar `registerInvite`:

```dart
// Método privado a adicionar em AuthController:
Future<void> _registerPendingInvite(PlayerProfile profile) async {
  try {
    final box = await Hive.openBox<String>('invite_refs');
    final inviterId = box.get('pending_ref');
    if (inviterId != null && inviterId.isNotEmpty) {
      final inviteService = _ref.read(inviteServiceProvider);
      await inviteService.registerInvite(
        inviterId: inviterId,
        inviteeId: profile.userId,
        inviteeDisplayName: profile.displayName,
      );
      // NÃO limpar o pending_ref aqui — ele é limpado pelo completeInviteReward
      // após a 1ª partida concluída
    }
  } catch (_) {
    // Não bloquear o login por falha no convite
  }
}
```

Adicionar chamada `unawaited(_registerPendingInvite(profile));` ao final de cada `try {}` nos 4 métodos de login, após `drainPendingEvents()`.

Para `createAccountWithEmail` (que não tem `syncProfile`/`drainPendingEvents`):
```dart
await _syncEngine.init(profile.userId, displayName: profile.displayName);
unawaited(_registerPendingInvite(profile)); // ← adicionar aqui
```

### `AuthController` precisa de acesso a `inviteServiceProvider`

Injetar `Ref` no `AuthController` (se ainda não tem) ou ler via provider no construtor. Verificar se `AuthController` já tem `Ref` — se não, adicionar.

Atual construtor:
```dart
AuthController(this._authService, this._syncEngine) : super(null)
```

Atualizar para:
```dart
AuthController(this._authService, this._syncEngine, this._ref) : super(null)
```
E adicionar `final Ref _ref;` como campo.

Atualizar `authControllerProvider`:
```dart
final authControllerProvider = StateNotifierProvider<AuthController, PlayerProfile?>((ref) {
  return AuthController(
    ref.watch(authServiceProvider),
    ref.watch(syncEngineProvider),
    ref,  // ← adicionar
  );
});
```

Imports a adicionar no topo de `auth_controller.dart`:
```dart
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/invites/invite_service.dart';
```

### Steps

- [ ] Ler `lib/presentation/controllers/auth_controller.dart` antes de editar
- [ ] Adicionar campo `_ref`, atualizar construtor e provider
- [ ] Adicionar método `_registerPendingInvite`
- [ ] Chamar `unawaited(_registerPendingInvite(profile))` nos 4 métodos de login
- [ ] Compilação: `flutter analyze lib/presentation/controllers/auth_controller.dart 2>&1 | grep error | head -5`
- [ ] Suite completa: `flutter test --reporter=compact 2>&1 | tail -4`
- [ ] Commit: `fix(invites): call registerInvite after login to wire invite in Firestore`

---

## Task 2 — `ProfileScreen`: "Convidar Amigos" + "Restaurar compras" real

**Files:**
- Modify: `lib/presentation/screens/profile_screen.dart`

### Gap 2: Botão "Convidar Amigos"

Adicionar `ListTile` entre "Restaurar compras" e "Sair" na classe `_LoggedIn`:

```dart
ListTile(
  leading: const Icon(Icons.person_add, color: Colors.white),
  title: Text(
    'Convidar Amigos',
    style: outlinedWhiteTextStyle(GoogleFonts.nunito()),
  ),
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const InviteFriendsScreen()),
  ),
),
const SizedBox(height: 8),
```

Import a adicionar:
```dart
import 'invite_friends_screen.dart';
```

### Gap 3: "Restaurar compras" real

Substituir o `onTap` do ListTile "Restaurar compras":

```dart
// Antes:
onTap: () {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Disponível na Fase 4F (IAP)')),
  );
},

// Depois:
onTap: () async {
  final iapService = ref.read(iapServiceProvider);
  await iapService.restorePurchases();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compras restauradas!')),
    );
  }
},
```

Import a adicionar:
```dart
import '../../domain/shop/iap_service.dart';
```

**Atenção:** `_LoggedIn` é `StatelessWidget` com `BuildContext context` — mas precisa de `WidgetRef ref` para ler `iapServiceProvider`. Converter `_LoggedIn` para `ConsumerWidget` ou passar `ref` como parâmetro. A opção mais simples: adicionar `final WidgetRef ref;` como campo e passar de `ProfileScreen.build`.

### Steps

- [ ] Ler `lib/presentation/screens/profile_screen.dart` antes de editar
- [ ] Verificar como `_LoggedIn` está construído e como obter acesso ao `ref`
- [ ] Adicionar botão "Convidar Amigos"
- [ ] Substituir stub "Restaurar compras" por `iapService.restorePurchases()`
- [ ] Compilação: `flutter analyze lib/presentation/screens/profile_screen.dart 2>&1 | grep error | head -5`
- [ ] Suite completa: `flutter test --reporter=compact 2>&1 | tail -4`
- [ ] Commit: `fix(profile): add Convidar Amigos button and wire Restaurar Compras to IAPService`

---

## Task 3 — Release v1.4.6

- [ ] `pubspec.yaml`: `1.4.5+1` → `1.4.6+1`
- [ ] `CHANGELOG.md`: adicionar entrada v1.4.6 com os 3 fixes
- [ ] `AGENTS.md`: atualizar para `v1.4.6` nos dois pontos onde aparece `v1.4.5`
- [ ] Suite completa passa
- [ ] Commit: `chore: release v1.4.6 — corrige gaps Sub-D/F da Fase 4`
- [ ] Merge em main + push

---

## Critérios de aceite

- [ ] `registerInvite` é chamado em todos os 4 caminhos de login do `AuthController`
- [ ] Hive `pending_ref` é lido mas **não apagado** no `registerInvite` (apagado só em `completeInviteReward`)
- [ ] `ProfileScreen` exibe botão "Convidar Amigos" quando logado
- [ ] "Restaurar compras" chama `iapService.restorePurchases()` (Fake no-op em dev, real em prd)
- [ ] Suite completa passa sem regressões
