# Design — Tutorial Wizard Interativo

**Data:** 2026-05-08
**Status:** Aprovado — aguardando implementação
**Fase:** 4.4

---

## 1. Contexto e motivação

A funcionalidade atual "Como Jogar" é um `BottomSheet` com 5 bullets de texto puro. Não é cativante, não usa o capricho visual do resto do jogo e não ensina pela prática. Queremos substituí-la por um **Tutorial wizard interativo de 5 telas**, com mini-boards reais onde o jogador faz as ações, alinhado à identidade cartoon-amazônica do app.

### 1.1 Objetivos

- Substituir o nome **"Como Jogar"** por **"Tutorial"** em toda a UX
- Wizard de **5 telas** em `PageView`, com navegação Próximo/Voltar/Pular
- **2 telas interativas** (jogador faz swipe em mini-boards) + 3 telas estáticas/ilustradas
- Reutilizar widgets reais do jogo (`TileWidget`) para coerência visual
- Persistir `tutorialCompleted` no perfil (Firestore + local)
- Acionado **só sob demanda** pelo botão `ComoJogar.png` na home (não auto-launch)

### 1.2 Não-objetivos

- Não auto-disparar tutorial no primeiro launch
- Sem l10n (apenas PT-BR)
- Sem testes E2E novos (apenas widget tests)
- Não trocar o asset do botão na home (`ComoJogar.png` permanece)
- Não introduzir Lottie nem novos assets de imagem (usa apenas tiles existentes)

---

## 2. Estrutura das 5 telas

| #   | Tela                    | Tipo       | Conteúdo principal                                                                                                                    |
| --- | ----------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **Boas-vindas**         | Estática   | Logo `GameTitleImage` + tagline + intro narrativa curta ("Bem-vindo à floresta amazônica…")                                           |
| 2   | **Movimento**           | Interativa | Mini-board 1×2 com 1 tile de Tanajura na esquerda. Hint "← deslize →". Avança quando jogador desliza pra direita                      |
| 3   | **Fusão**               | Interativa | Mini-board 1×2 com duas Tanajuras. Avança quando jogador desliza (esquerda OU direita) — tiles fundem com animação e viram Lobo-guará |
| 4   | **Itens & Vidas**       | Ilustrada  | 3 cards brancos (Bomba, Desfazer, Vidas) com ícone do `assets/images/inventory/` + texto curto                                        |
| 5   | **A Lenda da Capivara** | CTA final  | Imagem grande da Capivara (`assets/images/animals/tile/Capivara.png`) + copy de fechamento + botão "Começar a aventura"               |

### 2.1 Copy proposto (PT-BR, tom cativante)

**Tela 1 — Boas-vindas**

> Título: "Olha o Bichim!"
> Corpo: "Bem-vindo à floresta amazônica. Aqui moram bichos de todo tipo — e cabe a você ajudá-los a evoluir até descobrir a lendária Capivara. Bora aprender?"

**Tela 2 — Movimento**

> Título: "Deslize pra mover"
> Corpo: "Arraste o dedo em qualquer direção pra mover todos os bichos do tabuleiro de uma vez."
> Hint inferior: "👉 Tente deslizar pra direita"

**Tela 3 — Fusão**

> Título: "Iguais se fundem!"
> Corpo: "Quando dois bichos do mesmo tipo se encontram, eles se transformam num bicho mais raro. Tente fundir as duas tanajuras."
> Hint inferior: "👉 Deslize em qualquer direção"

**Tela 4 — Itens & Vidas**

> Título: "Suas ferramentas"
> 3 cards:
>
> - **🧨 Bombas** — "Apaga uma área do tabuleiro quando você se enrosca"
> - **↩️ Desfazer** — "Volta a última jogada se rolou um arrependimento"
> - **❤️ Vidas** — "Cada partida custa uma vida. Elas se regeneram com o tempo"

**Tela 5 — A Lenda da Capivara**

> Título: "A Capivara Lendária te espera"
> Corpo: "Funda animais, evolua a floresta e chegue até ela. Boa sorte, explorador!"
> Botão: "Começar a aventura"

---

## 3. Arquitetura

### 3.1 Árvore de arquivos novos

```
lib/presentation/screens/tutorial/
├── tutorial_screen.dart              # Wrapper PageView + Skip + dots + nav
├── widgets/
│   ├── tutorial_scaffold.dart        # AppBar + GameBackground + dots + bottom nav (DRY)
│   ├── tutorial_dots_indicator.dart  # 5 dots, current highlighted
│   └── tutorial_mini_board.dart      # Mini-board 1×N interativo (NÃO usa GameEngine)
└── pages/
    ├── tutorial_welcome_page.dart
    ├── tutorial_movement_page.dart
    ├── tutorial_fusion_page.dart
    ├── tutorial_items_page.dart
    └── tutorial_finale_page.dart
```

### 3.2 Por que `TutorialMiniBoard` não usa o `GameEngine`?

O `BoardWidget` atual é fixo em 4×4 (usa `GameConstants.boardSize` e `gameProvider`). O `GameEngine` opera em estado global compartilhado com a partida real. Reutilizá-lo no tutorial:

- Conflitaria com partida em andamento (sobrescreveria estado)
- Exigiria refatorar engine pra aceitar boards arbitrários
- Não traria valor — o tutorial só precisa de **2 tiles + animação simples**

**Solução:** `TutorialMiniBoard` é um widget independente que:

- Renderiza N células fixas usando o **`TileWidget` existente** (mantém visual idêntico)
- Detecta `GestureDetector` com `onPanEnd` pra reconhecer swipe
- Gerencia estado interno (lista de `Tile?`) com `setState`
- Emite `onCorrectSwipe()` quando o jogador faz o gesto esperado
- Roda animação hardcoded de fusão (scale + opacity) via `flutter_animate`

### 3.3 API do `TutorialMiniBoard`

```dart
class TutorialMiniBoard extends StatefulWidget {
  /// Tiles iniciais. Tamanho da lista define o número de células.
  /// Exemplo movimento: [Tile(tanajura), null]
  /// Exemplo fusão:     [Tile(tanajura), Tile(tanajura)]
  final List<Tile?> initialTiles;

  /// Direções aceitas como "swipe correto".
  /// Movimento: {Direction.right}
  /// Fusão:     {Direction.left, Direction.right}
  final Set<Direction> acceptedDirections;

  /// Tile resultante após swipe correto (se houver fusão).
  /// null = só move sem fundir (caso movimento).
  final Tile? mergedResult;

  /// Posição final do tile resultante após o swipe.
  /// Movimento: tile vai pro índice 1
  /// Fusão (right): tiles fundem no índice 1
  /// Fusão (left): tiles fundem no índice 0
  final int Function(Direction)? finalIndexResolver;

  final VoidCallback onCorrectSwipe;
}
```

### 3.4 Fluxo de interação (telas 2 e 3)

```
[estado inicial: 2 tiles renderizados]
       ↓
jogador faz swipe (onPanEnd)
       ↓
direção é resolvida via delta.dx/delta.dy
       ↓
direção ∈ acceptedDirections?
   ├── não → animação shake leve, sem mudança de estado
   └── sim → animação:
              - movimento: tile slide até finalIndex
              - fusão: dois tiles colapsam no centro, escalonam down,
                       tile resultante aparece com scale 0.5→1.2→1.0 + glow
              ↓
        delay 600ms (jogador vê o resultado)
              ↓
        chama onCorrectSwipe() → wizard avança automaticamente pra próxima página
```

### 3.5 `TutorialScreen` — comportamento

- `StatefulWidget` com `PageController`
- 5 páginas em `PageView` com `physics: NeverScrollableScrollPhysics()` (avanço só por botão ou auto após interação)
- AppBar com:
  - Título: `"Tutorial"` (Fredoka 22, branco)
  - Action: botão "Pular" (TextButton, branco70) que chama `_complete()` e dá pop
- Bottom bar com:
  - Botão "Voltar" (visível em páginas 2-5)
  - `TutorialDotsIndicator` no centro
  - Botão "Próximo" / "Começar a aventura" (texto muda na última)
- Páginas interativas (2 e 3): botão "Próximo" começa **desabilitado**, habilita após `onCorrectSwipe`
- `_complete()` chama `tutorialControllerProvider.markCompleted()` e faz `Navigator.pop()`

---

## 4. Persistência

### 4.1 `PlayerProfile` — novo campo

```dart
final bool tutorialCompleted; // default false
```

Adicionado ao `copyWith`, `toJson`, `fromJson`. `fromJson` retorna `false` se o campo não existir (compatibilidade com perfis antigos).

### 4.2 `FirebaseSyncEngine.syncProfile()`

Quando `tutorialCompleted == true`, persistir no documento `users/{uid}` com merge. O método `markTutorialCompleted()` (no `AuthController`) faz update otimista local + chamada `syncEngine.updateTutorialCompleted(true)`.

### 4.3 Usuários anônimos

Para jogadores sem login, persistir em `SharedPreferences` com chave `tutorial_completed: bool`. `TutorialController` consulta a fonte adequada conforme estado de auth.

### 4.4 Quando marcar como completo

`tutorialCompleted = true` é setado em **qualquer um** destes eventos:

- Jogador clica "Pular" em qualquer tela
- Jogador chega na tela 5 (a navegação até lá conta como "viu")
- Jogador clica "Começar a aventura" na tela 5

> **Nota:** o flag não controla se o tutorial é exibido — ele só é referência futura para features que possam querer saber se o jogador já viu (ex: badge "novo" em outras telas, recompensa de onboarding numa Fase posterior). Por ora, o botão `ComoJogar.png` na home sempre abre o tutorial, independentemente do flag.

---

## 5. Integração com a Home

### 5.1 Modificações em `home_screen.dart`

- `_HowToPlaySheet` (classe inteira) → **remover**
- Botão `home_btn_comojogar`:
  - `semanticLabel: 'Como Jogar'` → `'Tutorial'`
  - `onTap: showModalBottomSheet(...)` → `onTap: () => Navigator.push(MaterialPageRoute(builder: (_) => const TutorialScreen()))`
  - Asset `ComoJogar.png` permanece
- `Key('home_btn_comojogar')` permanece (não quebra testes existentes que dependam dela)

---

## 6. Tipografia (segue AGENTS.md)

| Contexto                            | Estilo                                             |
| ----------------------------------- | -------------------------------------------------- |
| AppBar "Tutorial"                   | `GoogleFonts.fredoka(22, white)` (sem outline)     |
| Título de cada página               | `OutlinedText` com `fredoka(28, w600)`             |
| Corpo das páginas                   | `outlinedWhiteTextStyle(fredoka(16, height: 1.5))` |
| Hint sob mini-board                 | `outlinedWhiteTextStyle(fredoka(14, w500))`        |
| Cards de itens (tela 4) — title     | `fredoka(18, w600, Color(0xFF3E2723))`             |
| Cards de itens (tela 4) — body      | `nunito(14, Colors.black87)`                       |
| Botões nav (Próximo/Voltar/Começar) | `outlinedWhiteTextStyle(fredoka(16, w600))`        |

---

## 7. Animações (flutter_animate)

| Elemento                                    | Animação                                                                                                          |
| ------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| Entrada de cada página (transição PageView) | fade(300ms) + slideY(20→0, 300ms)                                                                                 |
| Mini-board tela 2 (tile inativo)            | pulse infinito sutil (scale 1.0↔1.05, 1.5s)                                                                       |
| Mini-board tela 2 (após swipe correto)      | tile slideX até posição final (300ms ease-out)                                                                    |
| Mini-board tela 3 (fusão)                   | tiles convergem (200ms) → scale-down (100ms) → resultante aparece scale(0.5→1.2→1.0) + glow shimmer (400ms total) |
| Tela 5 (Capivara)                           | bounce contínuo leve (scale 1.0↔1.03, 2s, infinito)                                                               |

---

## 8. Testes

### 8.1 Widget tests

`test/presentation/screens/tutorial/tutorial_screen_test.dart`:

- Renderiza tela 1 ao abrir
- "Próximo" avança da tela 1 → 2
- Em telas interativas, "Próximo" começa desabilitado
- Botão "Pular" no AppBar fecha o tutorial e marca completo
- Botão "Começar a aventura" na tela 5 fecha e marca completo

`test/presentation/screens/tutorial/widgets/tutorial_mini_board_test.dart`:

- Renderiza N células conforme `initialTiles.length`
- Swipe na direção aceita → chama `onCorrectSwipe` após delay
- Swipe em direção rejeitada → não chama `onCorrectSwipe`

### 8.2 Model tests

`test/data/models/player_profile_test.dart` (atualizar se existir, ou criar):

- `tutorialCompleted` default `false`
- `copyWith(tutorialCompleted: true)` preserva outros campos
- `toJson/fromJson` round-trip preserva o flag
- `fromJson` sem o campo retorna `false`

### 8.3 Não-testado

- Animações concretas (visual; cobertas por inspeção manual)
- Sync Firestore (testado em fases anteriores)

---

## 9. Riscos e mitigações

| Risco                                                                    | Mitigação                                                                                                |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| `TutorialMiniBoard` swipe detection pode não funcionar bem em emulador   | Threshold permissivo (delta > 30px); testar em dispositivo real                                          |
| Animação de fusão complexa pode ficar travada                            | Usar `flutter_animate` com efeitos simples; evitar combinações pesadas                                   |
| `PlayerProfile` mudança quebra perfis antigos no Firestore               | `fromJson` defaulta `tutorialCompleted: false` se ausente                                                |
| Testes existentes que dependem do `_HowToPlaySheet`                      | Verificar `grep _HowToPlaySheet` em `test/`; nenhum esperado, mas confirmar                              |
| Wizard sobre `GameBackground` pode ter contraste ruim em algumas páginas | Usar painéis frosted-glass (BackdropFilter) onde necessário, padrão `OnboardingAuthScreen._ContentPanel` |

---

## 10. Fora de escopo (futuro)

- Auto-launch no primeiro login (decidido: só sob demanda)
- Tutorial avançado (combos de bomba, estratégia)
- Vídeo embedded
- Tradução EN
- Tutorial gamificado (recompensa por completar) — pode ser Fase 4.5+
