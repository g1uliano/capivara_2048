# Design Spec — Fase 1: MVP do Tabuleiro

**Data:** 2026-04-25
**Projeto:** Capivara 2048
**Escopo:** Setup, game engine puro, tela básica com placeholders

---

## 1. Objetivo

Entregar um jogo 2048 funcional em Flutter com:
- Game engine puro e testável (sem dependência de Flutter)
- Tela de jogo com tabuleiro 4x4 e tiles como `Container` colorido + número do nível
- Swipe nas 4 direções
- Pontuação local em memória
- Sem assets, sem sons, sem persistência

---

## 2. Setup do projeto

- `flutter create` com `--org work.cardoso` no diretório atual (`capivara_2048/`)
- Plataformas-alvo iniciais: Android, iOS, Web
- Dependências em `pubspec.yaml`:
  - `flutter_riverpod: ^2.x`
  - `uuid: ^4.x`
- Dev: `flutter_test` (incluso por padrão)

---

## 3. Estrutura de pastas

```
lib/
├── main.dart
├── app.dart
├── core/
│   └── constants/
│       └── game_constants.dart   # boardSize=4, tileSpacing, etc.
├── data/
│   ├── models/
│   │   ├── animal.dart
│   │   ├── tile.dart
│   │   └── game_state.dart
│   └── animals_data.dart         # lista dos 11 animais com cor
├── domain/
│   └── game_engine/
│       ├── game_engine.dart
│       └── direction.dart        # enum Direction { up, down, left, right }
└── presentation/
    ├── controllers/
    │   └── game_notifier.dart    # Riverpod StateNotifier
    ├── screens/
    │   └── game/
    │       └── game_screen.dart
    └── widgets/
        ├── board_widget.dart
        ├── tile_widget.dart
        └── score_panel.dart

test/
└── domain/
    └── game_engine_test.dart
```

---

## 4. Models

### `Animal`
```dart
class Animal {
  final int level;       // 1–11
  final int value;       // 2^level
  final String name;
  final Color tileColor;
}
```

### `Tile`
```dart
class Tile {
  final String id;        // UUID
  final int level;
  final int row;
  final int col;
  final bool isNew;
  final bool justMerged;
}
```

### `GameState`
```dart
class GameState {
  final List<List<Tile?>> board;   // 4x4, null = vazio
  final int score;
  final int highScore;
  final bool isGameOver;
  final bool hasWon;
}
```

Models são imutáveis; todos têm `copyWith`.

---

## 5. Game Engine

Localizado em `lib/domain/game_engine/game_engine.dart`. Zero import de Flutter.

### Interface pública
```dart
class GameEngine {
  GameState newGame();
  GameState move(GameState state, Direction dir);
}
```

### Algoritmo `move`
1. Rotacionar board para que o movimento seja sempre "para a esquerda"
2. Para cada linha: `compactAndMerge`
3. Rotacionar de volta
4. Se board mudou: `spawnNewTile`
5. Verificar `isGameOver` e `hasWon`

### `compactAndMerge(List<Tile?> row)`
1. Filtrar nulos, manter ordem
2. Percorrer: se `row[i].level == row[i+1].level` → merge (nível+1, `justMerged=true`, ganho de pontos)
3. Cada tile só pode participar de um merge por movimento
4. Preencher com nulos até length 4
5. Retornar `(List<Tile?> result, int gained, bool changed)`

### `spawnNewTile`
- Sorteia célula vazia aleatória
- 90% level 1, 10% level 2

### Condições
- **Game over:** sem células vazias E sem merges possíveis em nenhuma direção
- **Vitória:** qualquer tile atingir level 11

---

## 6. Testes unitários

Arquivo: `test/domain/game_engine_test.dart`

Casos obrigatórios:
| Caso | Descrição |
|------|-----------|
| merge básico | dois tiles level 1 adjacentes → um tile level 2 |
| sem merge | tiles diferentes não fundem |
| merge em cadeia | não ocorre na mesma jogada (ex: 1,1,1 → 2,1, não 2 vazio) |
| pontuação | merge level 2 → soma 4 ao score |
| spawn | nova peça aparece após movimento válido |
| sem mudança | movimento sem efeito não gera spawn |
| game over | tabuleiro cheio sem merges possíveis |
| vitória | tile level 11 detectado |
| direções | left, right, up, down funcionam corretamente |

---

## 7. `animals_data.dart`

Lista estática dos 11 animais com nome e cor conforme o design spec. Sem assets — cor é usada como fundo do tile placeholder.

---

## 8. Riverpod Controller

```dart
class GameNotifier extends StateNotifier<GameState> {
  final GameEngine _engine;

  GameNotifier(this._engine) : super(_engine.newGame());

  void onSwipe(Direction dir) => state = _engine.move(state, dir);
  void restart() => state = _engine.newGame();
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>(...);
```

---

## 9. Tela de jogo

### `GameScreen`
- `ConsumerWidget`
- `GestureDetector` cobrindo tela inteira: detecta swipe por delta X/Y (threshold 20px)
- Coluna: `ScorePanel` + `BoardWidget`

### `ScorePanel`
- Score atual + "Recorde: X"
- Botão restart

### `BoardWidget`
- `GridView` 4x4 ou `Stack` de `Positioned` tiles
- Background cor `#C9B79C` (célula vazia)

### `TileWidget`
- `Container` com `BorderRadius.circular(8)`
- Cor de fundo = `animal.tileColor` (da `animals_data`)
- Texto centralizado: nível do tile (ex: "3")
- Tamanho fixo calculado por `boardSize / 4 - spacing`

---

## 10. `main.dart` / `app.dart`

- `main.dart`: `runApp(ProviderScope(child: CapivaraApp()))`
- `app.dart`: `MaterialApp` com rota inicial `GameScreen`
- Tema mínimo (sem Fredoka/Nunito ainda — Fase 2)

---

## 11. Fora do escopo da Fase 1

- Assets (imagens, sons, fontes)
- Persistência (Hive/SharedPreferences)
- Home screen, tela de coleção, desafio diário
- Animações de merge/spawn
- Localização
- Modo escuro
