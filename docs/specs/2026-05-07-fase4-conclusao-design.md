# Design — Fase 4 Conclusão: Gestão de Conta, Avatar e Auth Gates

**Data:** 2026-05-07  
**Versão alvo:** v1.6.0  
**Status:** Aprovado

---

## Contexto

A Fase 4 (Firebase + Auth + Sync) foi implementada, mas 10 requisitos ficaram em aberto. Este documento especifica o design para fechá-los, agrupados em 3 blocos funcionais:

- **Bloco A** — Gestão de conta (exclusão, nome, senha)
- **Bloco B** — Persistência de avatar (bug de sync)
- **Bloco C** — Auth gates (startup, shop, ranking, recompensas)

O Bloco D (inventário sem login) não requer implementação: o paradoxo resolve sozinho — sem login não há como adquirir itens, então o inventário de um usuário não-logado nunca cresce.

---

## Bloco A — Gestão de conta

### A1 — Exclusão de conta (LGPD)

**Requisito:** usuário pode deletar conta e todos os dados associados. Conta Google e conta e-mail são ambas suportadas.

**Fluxo UX:**

1. `ProfileScreen` → novo `ListTile` no final da lista: ícone `delete_forever`, texto "Excluir conta", cor vermelha
2. Toque → `AlertDialog` de primeiro aviso:
   - Título: "Excluir conta?"
   - Corpo: "Todos os seus dados serão apagados permanentemente: progresso, inventário, histórico e ranking."
   - Botões: "Cancelar" | "Continuar →"
3. Confirma → segundo diálogo:
   - Corpo: "Para confirmar, digite **EXCLUIR** no campo abaixo."
   - `TextField` — botão "Excluir conta" habilitado somente quando o texto for exatamente `"EXCLUIR"`
4. Confirma → re-autenticação (requisito Firebase para operações sensíveis):
   - **Conta Google:** re-auth silenciosa via `GoogleSignIn.instance.authenticate()` → `user.reauthenticateWithCredential()`
   - **Conta e-mail:** diálogo intermediário pedindo a senha atual → `EmailAuthProvider.credential()` → `user.reauthenticateWithCredential()`
5. Re-auth bem-sucedida → sequência de deleção:
   - `SyncEngine.deleteUserData()` → deleta `users/{uid}` no Firestore
   - Limpa todos os boxes Hive locais (`inventory`, `lives_state`, `personal_records`, `pending_events`, `daily_rewards`, `invite_refs`)
   - `user.delete()` no Firebase Auth
   - Navega para `HomeScreen` (pushAndRemoveUntil)

**Novos contratos:**

```dart
// AuthService — param 'senha' obrigatório só para AuthProvider.email
Future<void> deleteAccount({String? senha});

// FirebaseAuthService
// email: re-auth com credencial EmailAuthProvider.credential(email, senha)
// Google: re-auth silenciosa via GoogleSignIn.instance.authenticate()
Future<void> deleteAccount({String? senha});

// SyncEngine (abstract)
Future<void> deleteUserData();

// FirebaseSyncEngine
Future<void> deleteUserData(); // deleta users/{uid} no Firestore

// AuthController — 'senha' obtida pelo diálogo na ProfileScreen e repassada aqui
Future<void> deleteAccount({String? senha}); // orquestra tudo + limpa state
```

**Tratamento de erros:**

- Re-auth falhou (senha errada / token Google expirado): SnackBar com mensagem amigável, fluxo cancelado
- Firestore delete falhou: logar erro, continuar com `user.delete()` (dados órfãos são aceitáveis vs. conta presa)

---

### A2 — Campo de nome no cadastro + edição de nome

**Cadastro (`EmailAuthScreen`, modo `_isSignUp == true`):**

- Novo campo "Nome" logo acima do campo de e-mail
- Validação: obrigatório, mínimo 2 caracteres, máximo 30 caracteres
- Passado para `createAccountWithEmail(email, password, displayName)` → `user.updateDisplayName(name)` no Firebase Auth + gravado no Firestore via `SyncEngine.updateDisplayName()`

**Edição de nome (`ProfileScreen`):**

- Ícone de lápis pequeno ao lado do `displayName` exibido — visível **apenas** para `AuthProvider.email`
- Toque → `AlertDialog` com `TextField` pré-preenchido com nome atual
- Mesma validação do cadastro
- Salva via `AuthController.updateDisplayName(name)` → atualiza `state`, Firebase Auth e Firestore

**Novos contratos:**

```dart
// AuthService
Future<void> updateDisplayName(String name);
Future<PlayerProfile> createAccountWithEmail(String email, String password, String displayName); // assinatura atualizada

// FirebaseAuthService
Future<void> updateDisplayName(String name); // user.updateDisplayName() + Firestore set merge

// SyncEngine (abstract)
Future<void> updateDisplayName(String name);

// FirebaseSyncEngine
Future<void> updateDisplayName(String name); // users/{uid}.displayName

// AuthController
Future<void> updateDisplayName(String name); // atualiza state + sync
```

---

### A3+A4 — Trocar senha / Esqueci minha senha

Ambos usam `FirebaseAuth.sendPasswordResetEmail(email)`. Dois pontos de entrada:

**"Trocar senha" (ProfileScreen):**

- Novo `ListTile` visível apenas para `AuthProvider.email`
- Ícone `lock_reset`, texto "Trocar senha"
- Toque → envia reset automático para `profile.email` → SnackBar: "E-mail de redefinição enviado para [email]"

**"Esqueci minha senha" (EmailAuthScreen, modo login):**

- Link/`TextButton` abaixo do botão "Entrar"
- Se campo e-mail preenchido: envia reset e exibe SnackBar
- Se campo e-mail vazio: foca no campo com `errorText: 'Informe o e-mail para redefinir a senha'`

**Novo contrato:**

```dart
// AuthService
Future<void> sendPasswordReset(String email);

// FirebaseAuthService
Future<void> sendPasswordReset(String email); // _auth.sendPasswordResetEmail(email: email)
```

---

## Bloco B — Persistência de avatar (bug de sync)

**Problema:** `updateAvatar('tile:NomeAnimal')` salva no Firestore, mas no próximo login `_toProfile(user)` usa `user.photoURL` (Firebase Auth), que nunca contém `tile:*`. O `syncProfile()` não lê `avatarUrl` do Firestore.

**Regras de negócio:**

- Conta **e-mail**: avatar é um animal local (`tile:NomeAnimal`), selecionado via `AvatarPickerScreen`. Persiste via Firestore
- Conta **Google**: avatar é sempre `user.photoURL` (foto do Google). `AvatarPickerScreen` **não** é acessível para contas Google (botão de editar avatar na `ProfileScreen` oculto para `AuthProvider.google`)

**Correção:**

1. `SyncEngine` (abstract) ganha getter:

   ```dart
   String? get remoteAvatarUrl;
   ```

2. `FirebaseSyncEngine.syncProfile()` lê `doc.data()?['avatarUrl']` e armazena em `_remoteAvatarUrl` (campo privado). O getter expõe esse valor

3. `FakeSyncEngine` implementa `remoteAvatarUrl` retornando `null`

4. `AuthController` — nos flows de login com e-mail (`signInWithEmail`, `createAccountWithEmail`), após `syncProfile()`:
   ```dart
   final tileAvatar = ref.read(syncEngineProvider).remoteAvatarUrl;
   if (tileAvatar != null) {
     state = state!.copyWith(avatarUrl: tileAvatar);
   }
   ```
   Contas Google não executam esse bloco (mantêm `user.photoURL`)

---

## Bloco C — Auth Gates

### C1 — SplashScreen como portão de entrada

Após inicialização, `SplashScreen` verifica `authControllerProvider`:

- **Logado →** `HomeScreen` (comportamento atual mantido)
- **Não logado →** `OnboardingAuthScreen(showSkip: true)` via `pushReplacement`

Isso garante que **toda vez** que o app abre sem usuário logado, o onboarding é exibido.

---

### C2 — OnboardingAuthScreen — dois modos

**Parâmetro novo:** `showSkip: bool` (default `false`)

**Modo startup** (`showSkip: true`):

- Sem AppBar / sem botão voltar
- Bloco de benefícios exibido acima dos botões de login:
  ```
  Por que fazer login?
  📊  Progresso salvo em todos os dispositivos
  🏆  Ranking global semanal
  🎁  Recompensas diárias com itens do inventário
  🛒  Acesso à loja de itens
  ```
- Botão "Jogar sem conta →" abaixo dos botões de login (estilo `TextButton`, cor branca com outline)
- Após login bem-sucedido: `pushAndRemoveUntil → HomeScreen` (comportamento atual)
- "Jogar sem conta →": `pushAndRemoveUntil → HomeScreen`

**Modo mid-app** (`showSkip: false`):

- AppBar com botão voltar (`Navigator.pop()`) — sem botão "Jogar sem conta"
- Sem bloco de benefícios
- Após login bem-sucedido: `Navigator.pop()` (retorna ao contexto anterior)

---

### C3 — `AuthGateOverlay` — widget para overlays do jogo

**Arquivo:** `lib/presentation/widgets/auth_gate_overlay.dart`

Usado exclusivamente para **overlays sobre o jogo** (ex: `ShopOverlay`).

```dart
class AuthGateOverlay extends ConsumerWidget {
  const AuthGateOverlay({
    required this.child,    // conteúdo exibido se logado
    required this.reason,   // ex: "Para acessar a Loja..."
    required this.onClose,  // callback do botão "Agora não"
  });

  final Widget child;
  final String reason;
  final VoidCallback onClose;
}
```

**Comportamento:**

- Se **logado** → renderiza `child` diretamente
- Se **não logado** → exibe overlay com:
  - Fundo: `Colors.black.withOpacity(0.85)` (mesmo padrão dos outros overlays)
  - `GameTitleImage` pequeno no topo
  - Texto `reason` (Fredoka, outline branco)
  - Lista compacta de benefícios (4 itens com ícones)
  - Botão primário "Fazer login" (laranja) → push `OnboardingAuthScreen(showSkip: false)`
  - Botão secundário "Agora não" (TextButton branco) → `onClose()`
- Como é `ConsumerWidget` que observa `authControllerProvider`: quando o usuário faz login e retorna (pop de `OnboardingAuthScreen`), o widget reconstrói automaticamente e exibe `child`

---

### C4 — ShopOverlay com auth gate

O conteúdo atual de `ShopOverlay` é envolvido em `AuthGateOverlay`:

```dart
AuthGateOverlay(
  reason: 'Para acessar a Loja você precisa estar conectado.',
  onClose: () => Navigator.of(context).pop(),
  child: /* conteúdo atual da ShopOverlay */,
)
```

Nenhuma outra mudança na `ShopOverlay`.

---

### C5 — DailyRewardsScreen com auth gate

O ponto de navegação para `DailyRewardsScreen` (na `HomeScreen`) verifica auth antes de navegar:

```dart
// No handler de navegação da HomeScreen
if (!ref.read(authControllerProvider.notifier).isLoggedIn) {
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => const OnboardingAuthScreen(showSkip: false),
  ));
  return;
}
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const DailyRewardsScreen(),
));
```

Após login (pop de `OnboardingAuthScreen`), o usuário está de volta à Home e pode tentar novamente. A `DailyRewardsScreen` em si não muda.

---

### C6 — RankingScreen — aba Lendas

A aba "Lendas" é **sempre visível**, logado ou não — qualquer pessoa pode ver o ranking.

A restrição é na **submissão**: pontuações só são enviadas ao Ranking de Lendas quando o usuário está logado. Usuários não-logados submetem apenas ao ranking pessoal local.

- **Visualização →** sem restrição de auth
- **Submissão →** verificada no ponto de envio de pontuação (repositório de ranking): se não logado, skipa a gravação no Firestore e registra apenas localmente

Banner informativo não-bloqueante no topo da aba Lendas quando não logado:

```
  ℹ️  Faça login para aparecer neste ranking.  [ Entrar ]
```

(estilo banner compacto, não substitui o conteúdo da aba)

A aba "Pessoal" permanece inalterada.

---

### C7 — ShopScreen (tela completa)

O ponto de navegação para `ShopScreen` (onde quer que exista na Home/AppBar) verifica auth antes de navegar, mesmo padrão do C5:

```dart
if (!ref.read(authControllerProvider.notifier).isLoggedIn) {
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => const OnboardingAuthScreen(showSkip: false),
  ));
  return;
}
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const ShopScreen(),
));
```

---

## Sumário de novos artefatos

| Arquivo                                            | Tipo      | Mudança                                                                                                             |
| -------------------------------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------- |
| `domain/auth/auth_service.dart`                    | Existente | +`deleteAccount()`, +`updateDisplayName()`, +`sendPasswordReset()`, atualizar assinatura `createAccountWithEmail()` |
| `data/repositories/firebase_auth_service.dart`     | Existente | Implementar novos métodos acima                                                                                     |
| `domain/sync/sync_engine.dart`                     | Existente | +`deleteUserData()`, +`updateDisplayName()`, +`remoteAvatarUrl` getter                                              |
| `data/repositories/firebase_sync_engine.dart`      | Existente | Implementar novos métodos + ler `avatarUrl` em `syncProfile()`                                                      |
| `presentation/controllers/auth_controller.dart`    | Existente | +`deleteAccount()`, +`updateDisplayName()`, aplicar `remoteAvatarUrl` no login por e-mail                           |
| `presentation/screens/profile_screen.dart`         | Existente | +exclusão, +editar nome (só email), +trocar senha (só email), ocultar botão avatar para Google                      |
| `presentation/screens/email_auth_screen.dart`      | Existente | +campo nome no signup, +link esqueci senha                                                                          |
| `presentation/screens/onboarding_auth_screen.dart` | Existente | +`showSkip` param, +bloco de benefícios, +botão "Jogar sem conta", ajustar navegação pós-login                      |
| `presentation/screens/splash_screen.dart`          | Existente | Redirecionar para `OnboardingAuthScreen` se não logado                                                              |
| `presentation/screens/ranking_screen.dart`         | Existente | +banner informativo não-bloqueante na aba Lendas quando não logado                                                 |
| `data/repositories/firestore_ranking_repository.dart` | Existente | Verificar auth antes de submeter; se não logado, skipa gravação remota                                            |
| `presentation/screens/home_screen.dart`            | Existente | Auth check antes de navegar para DailyRewards e ShopScreen                                                          |
| `presentation/widgets/auth_gate_overlay.dart`      | **Novo**  | Widget `AuthGateOverlay` para overlays sobre o jogo                                                                 |
| `presentation/widgets/shop_overlay.dart`           | Existente | Envolver conteúdo em `AuthGateOverlay`                                                                              |

---

## Fora de escopo

- Apple Sign-In (já marcado como `UnimplementedError`)
- Áudio (Fase 6)
- Testes unitários/widget para os novos fluxos (podem ser adicionados em tarefa separada)
