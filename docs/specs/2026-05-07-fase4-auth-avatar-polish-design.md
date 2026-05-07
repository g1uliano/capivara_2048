# Spec — Fase 4: Auth completo, Avatar e Polimento Visual

**Data:** 2026-05-07  
**Status:** Aprovado  
**Escopo:** Completar a Fase 4 com criação de conta por e-mail, avatar de tile, destaque do perfil na Home e correções visuais.

---

## 1. Contexto

A Fase 4 implementou Firebase Auth + Sync Engine, mas ficaram pendentes:
- Criação de conta por e-mail (só havia login)
- Tela de e-mail era um `AlertDialog` simples sem validação
- Logo pequeno na tela de login
- Sem opção de avatar para usuários de e-mail
- Ícone de perfil na Home sem destaque visual
- Textos ilegíveis na tela "Convidar Amigos"

---

## 2. Mudanças

### 2.1 `EmailAuthScreen` (nova tela)

Substitui o `AlertDialog` em `OnboardingAuthScreen`. É uma tela completa com `GameBackground`.

**Modos:** toggle entre **Entrar** e **Criar Conta** na mesma tela (sem navegação, apenas troca de estado).

**Campos:**
- Email (`TextFormField`, `keyboardType: emailAddress`, `autofillHints: [email]`)
- Senha (obscureText, botão mostrar/ocultar)
- Confirmar Senha (só no modo Criar Conta, mesma regra)

**Validações inline (Form + validator):**
- Email: regex `^[^@]+@[^@]+\.[^@]+$`
- Senha: mínimo 8 caracteres + ao menos 1 dígito
- Confirmar Senha: deve ser igual à senha

**Erros do Firebase** (ex: `wrong-password`, `email-already-in-use`) exibidos via `ScaffoldMessenger` com mensagens em português.

**Fluxo Criar Conta:** após `createAccountWithEmail` com sucesso → navega para `AvatarPickerScreen`.  
**Fluxo Entrar:** após `signInWithEmail` com sucesso → navega para `HomeScreen` (removendo a pilha).

**Logo:** `GameTitleImage` com `HomeConstants.titleHeight(scale)` — igual à Home.

---

### 2.2 `AvatarPickerScreen` (nova tela)

Exibida após criação de conta por e-mail. Acessível também pela `ProfileScreen` (botão de editar avatar).

**Layout:**
- Título "Escolha seu avatar" com `outlinedWhiteTextStyle`
- Grid 3 colunas com os 13 tiles: `assets/images/animals/tile/*.png`
- Cada item: `CircleAvatar` com `Image.asset` do tile, borda verde quando selecionado
- Botão primário "Confirmar" (habilitado só com seleção)
- Botão secundário "Pular" (usa padrão: inicial do nome)

**Persistência:** chama `AuthController.updateAvatar("tile:NomeAnimal")`. O valor `null` significa "sem avatar" (usa inicial).

**Lista de tiles disponíveis** (13 animais, ordem do jogo):
```
Tanajura, LoboGuara, Cururu, Tucano, Sagui, Preguica,
MicoLeao, Boto, Onca, Sucuri, Capivara, PeixeBoi, Jacare
```
Cada um mapeado para `assets/images/animals/tile/<Nome>.png`.

---

### 2.3 Avatar na Home (destaque)

O `IconButton` de perfil no topo centro da `HomeScreen` é substituído por um `GestureDetector` + `CircleAvatar`:

| Estado | Aparência |
|---|---|
| Não logado | Círculo verde (`AppColors.primary`) + `Icons.person_outline` branco |
| Logado, sem avatar | Círculo verde + inicial do `displayName` em branco |
| Logado, avatar tile | Círculo verde + `Image.asset` do tile (preenchendo o círculo) |

Tamanho: radius 20 (mesmo espaço do `IconButton` atual). Mantém `tooltip: 'Perfil'` e navega para `ProfileScreen`.

---

### 2.4 `AuthController.updateAvatar()`

Novo método no `AuthController`:

```dart
Future<void> updateAvatar(String? avatarAsset) async {
  // Atualiza state local
  // Persiste via SyncEngine (campo avatarUrl no Firestore)
}
```

`PlayerProfile.avatarUrl` passa a aceitar valores no formato `"tile:NomeAnimal"` além de URLs HTTP (Google/Apple continuam funcionando normalmente). O widget de avatar deve checar o prefixo `"tile:"` para usar `Image.asset` em vez de `NetworkImage`.

---

### 2.5 `ProfileScreen` — editar avatar

Sobre o `CircleAvatar` do perfil, adicionar um `IconButton` pequeno (ícone lápis, fundo verde escuro) que abre a `AvatarPickerScreen`. Disponível para todos os provedores de login.

---

### 2.6 "Convidar Amigos" — legibilidade

Em `InviteFriendsScreen`, substituir:
```dart
// antes
style: GoogleFonts.nunito(fontSize: 14, color: Colors.white70)
// depois
style: outlinedWhiteTextStyle(GoogleFonts.nunito(fontSize: 14))
```
Aplicar a todos os textos sobre o fundo (descrição de recompensa e mensagem de "faça login").

---

## 3. Arquivos afetados

| Arquivo | Mudança |
|---|---|
| `presentation/screens/onboarding_auth_screen.dart` | Logo maior; botão "Entrar com Email" navega para `EmailAuthScreen` |
| `presentation/screens/email_auth_screen.dart` | **NOVO** |
| `presentation/screens/avatar_picker_screen.dart` | **NOVO** |
| `presentation/screens/home_screen.dart` | `IconButton` → `CircleAvatar` com destaque |
| `presentation/screens/profile_screen.dart` | Botão editar avatar sobre o `CircleAvatar` |
| `presentation/screens/invite_friends_screen.dart` | Textos com `outlinedWhiteTextStyle` |
| `presentation/controllers/auth_controller.dart` | Novo método `updateAvatar()` |
| `domain/auth/auth_service.dart` | Assinatura de `updateAvatar()` na interface |
| `data/repositories/firebase_auth_service.dart` | Implementação de `updateAvatar()` via Firestore |

---

## 4. O que não muda

- `PlayerProfile` model: `avatarUrl` já existe como `String?`, sem mudança de tipo
- Nenhum serviço novo no Firebase (sem Storage, sem novas coleções)
- Google Sign-In e Apple Sign-In continuam idênticos
- A lógica do `SyncEngine` não muda — `avatarUrl` já é sincronizado
- Nenhuma mudança de configuração no Firebase Console

---

## 5. Fora de escopo

- Upload de foto da galeria (decidido remover)
- Validação de e-mail por link (email verification da Firebase Auth)
- Recuperação de senha (forgot password) — pode ser Fase 6
