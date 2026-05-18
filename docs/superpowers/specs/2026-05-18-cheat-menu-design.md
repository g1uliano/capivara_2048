# Cheat Menu (Debug) — Design Spec

**Data:** 2026-05-18  
**Fase:** 5 (polimento visual) — ferramenta de suporte ao desenvolvimento  
**Versão alvo:** próximo commit em `main`

---

## 1. Contexto

O jogo possui um menu de debug acessível via botão "Debug" no `PauseOverlay` (visível apenas em `kDebugMode`). Atualmente exibe uma galeria de animais com tiles, host artwork e cores — útil para revisão visual, mas sem utilidade para testar fluxos de jogo.

O objetivo é substituir esse menu por um **Cheat Menu** que permita ao desenvolvedor manipular o estado de jogo (vidas, itens, nível atual) sem precisar jogar manualmente para atingir condições específicas de teste.

---

## 2. Escopo

### Incluído

- Ajustar quantidade de **vidas** (aumentar / diminuir)
- Ajustar quantidade de **itens** por tipo (bomb2, bomb3, undo1, undo3)
- **Pular para um nível** (1–13): injeta no tabuleiro um estado realista com tiles condizentes ao nível alvo

### Excluído

- Galeria de animais (descartada)
- Acesso fora de `kDebugMode`
- Acesso por gesto secreto em builds de release
- Manipulação do timer, score, highScore, undo stack

---

## 3. Arquivos

| Ação | Arquivo |
|------|---------|
| Criar | `lib/presentation/screens/debug/cheat_menu_screen.dart` |
| Deletar | `lib/presentation/screens/debug/animals_gallery_screen.dart` |
| Modificar | `lib/presentation/widgets/pause_overlay.dart` |
| Modificar | `lib/presentation/controllers/game_notifier.dart` |
| Modificar | `lib/domain/lives/lives_notifier.dart` |

---

## 4. UI — CheatMenuScreen

`Scaffold` padrão (sem `GameBackground`) com `AppBar` simples e `ListView` com três seções separadas por `Divider`.

### 4.1 Seção Vidas

```
Vidas: 3   [−]   [+]
```

- Exibe `livesState.lives` atual
- `[+]` → `livesNotifier.addPurchased(1)` (sem teto, método já existente)
- `[−]` → `livesNotifier.debugSetLives(max(0, current − 1))`
- `[−]` desabilitado quando `lives == 0`

### 4.2 Seção Itens

Uma linha por tipo:

```
Bomba 2×2    [−]   5   [+]
Bomba 3×3    [−]   3   [+]
Desfazer ×1  [−]   5   [+]
Desfazer ×3  [−]   2   [+]

[Dar 5 de cada]
```

- `[+]` → `inventoryNotifier.add(type, 1)`
- `[−]` → `inventoryNotifier.consume(type)` (decrementa 1, persiste e sincroniza — comportamento idêntico ao consumo normal em jogo)
- `[−]` desabilitado quando `count == 0`
- "Dar 5 de cada" → `inventoryNotifier.addDebugItems()` (já existente)

### 4.3 Seção Pular para Nível

```
[1 Tanajura]  [2 Lobo-guará]  [3 Sapo-cururu]  [4 Tucano]
[5 Sagui]     [6 Preguiça]    [7 Mico-leão]    [8 Boto]
[9 Onça]      [10 Sucuri]     [11 Capivara]    [12 Peixe-boi]
[13 Jacaré]

[▶ Ir para Nível 7 — Mico-leão-dourado]
```

- `Wrap` com 13 `ChoiceChip` (seleção simples); mostra nível + nome abreviado
- Botão "Ir para Nível N" → `gameNotifier.debugJumpToLevel(N)` → `Navigator.pop()` (fecha o menu; o `PauseOverlay` já terá sido fechado antes de abrir o cheat menu, ver §5)
- Nível inicial selecionado ao abrir: `state.maxLevel.clamp(1, 13)`

---

## 5. PauseOverlay — alteração

Substituir o `TextButton("Debug")` atual por `TextButton("Cheats")` que navega para `CheatMenuScreen` via `Navigator.push` **sem** chamar `resume()`.

O jogo permanece pausado enquanto o usuário manipula vidas/itens. Ao retornar com o botão de voltar, o `PauseOverlay` ainda está visível e o jogador pode pressionar "Continuar" normalmente.

Para o fluxo de **Pular para Nível**: `debugJumpToLevel` cria o novo `GameState` com `isPaused: false`, o que faz o `PauseOverlay` desaparecer automaticamente quando o `Navigator.pop()` exibe a `GameScreen` por baixo.

---

## 6. GameNotifier — `debugJumpToLevel`

```dart
void debugJumpToLevel(int targetLevel) {
  if (!kDebugMode) return;

  const uuid = Uuid();
  Tile tile(int level) => Tile(id: uuid.v4(), level: level);
  int lvl(int delta) => max(1, targetLevel - delta);

  // Tabuleiro 4×4 com 6 tiles distribuídos
  final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
  board[0][3] = tile(targetLevel);
  board[0][2] = tile(lvl(1));
  board[1][3] = tile(lvl(2));
  board[3][0] = tile(lvl(3));
  board[3][2] = tile(1);
  board[3][3] = tile(1);

  final score = board
      .expand((row) => row)
      .whereType<Tile>()
      .fold(0, (sum, t) => sum + (1 << t.level));

  _stopTimer();
  _firestoreSaveTimer?.cancel();
  state = GameState(
    board: board,
    score: score,
    highScore: max(state.highScore, score),
    maxLevel: targetLevel,
    hasWon: false,
    isGameOver: false,
    isPaused: false,
  );
}
```

**Comportamento de milestones:** `_reachedMilestones` não é pré-populado. O jogo trata o estado injetado como qualquer outro — se `maxLevel >= 11`, os dialogs de marco disparam normalmente na primeira jogada após o jump (um por movimento, protegidos pelo guard `pendingMilestone == null`). Isso é o comportamento correto: o cheat não contorna mecânicas do jogo.

---

## 7. LivesNotifier — `debugSetLives`

```dart
void debugSetLives(int n) {
  if (!kDebugMode) return;
  state = state.copyWith(lives: n.clamp(0, state.earnedCap));
}
```

Altera apenas o estado em memória — sem persistir em Hive, sem sincronizar com Firestore.

---

## 8. Critérios de aceitação

- [ ] Botão "Cheats" visível no `PauseOverlay` apenas em `kDebugMode`
- [ ] `[+]` / `[−]` de vidas refletem imediatamente no contador da `HomeScreen` e `GameScreen`
- [ ] `[+]` / `[−]` de itens refletem no `InventoryBar` dentro do jogo
- [ ] Pular para nível N fecha o menu e exibe tabuleiro com tile de nível N visível
- [ ] `maxLevel` atualizado reflete no anfitrião (host animal) acima do tabuleiro
- [ ] Dialog de marco dispara normalmente na primeira jogada após jump para nível >= 11
- [ ] Nenhuma das funcionalidades acima compila ou é acessível em builds `--release`
