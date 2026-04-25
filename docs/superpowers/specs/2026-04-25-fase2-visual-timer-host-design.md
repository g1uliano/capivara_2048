# Fase 2.1 + 2.2 — Visual Base, Cronômetro, Anfitrião e Pausa

## Escopo

Implementar identidade visual base (tema, paleta, fontes), novo `TileWidget` com fundo branco + contorno colorido + slot para marca d'água, cronômetro no `ScorePanel`, `HostBanner` com anfitrião dinâmico e sistema de pausa completo — tudo sem depender dos SVGs finais dos animais.

---

## 1. Mudanças de Modelo

### `Animal` (`lib/data/models/animal.dart`)
Renomeia `tileColor` → `borderColor`. Adiciona `assetPath` (slot para SVG futuro).

```dart
class Animal {
  final int level;
  final int value;
  final String name;
  final Color borderColor;
  final String assetPath; // ex: 'assets/images/animals/tanajura.svg'
}
```

`animals_data.dart` atualizado com `borderColor` (mesmas cores) e `assetPath` para cada animal.

### `GameState` (`lib/data/models/game_state.dart`)
Adiciona três campos:

```dart
int maxLevel      // maior nível formado na partida (começa em 0)
int elapsedMs     // tempo acumulado em ms (cronômetro)
bool isPaused     // pausa ativa
```

`copyWith` atualizado para os três campos.

### `GameNotifier` (`lib/presentation/controllers/game_notifier.dart`)
- Mantém `Timer? _timer` interno (`Timer.periodic(100ms)`)
- Timer emite `tick(100)` → incrementa `elapsedMs` no estado
- Timer para em: `pause()`, game over, vitória
- Timer inicia/retoma em: primeiro swipe válido, `resume()`
- `restart()` reseta `elapsedMs = 0`, `maxLevel = 0`, `isPaused = false`, reinicia timer
- `onSwipe` atualiza `maxLevel` se o move gerou tile de nível maior
- `pause()` e `resume()` públicos

---

## 2. Tema (`lib/core/theme/app_theme.dart`)

`AppTheme.light()` retorna `ThemeData` com:

| Token | Valor |
|---|---|
| `scaffoldBackgroundColor` | `#3FA968` |
| `cardColor` (tabuleiro) | `#E8D5B7` |
| `primaryColor` | `#FF8C42` |
| `textTheme.displayLarge` | Fredoka Bold |
| `textTheme.bodyMedium` | Nunito |

Google Fonts: `fredoka` e `nunito` via `pubspec.yaml` (pacote `google_fonts`).

Aplicado em `app.dart`: `MaterialApp(theme: AppTheme.light(), ...)`.

---

## 3. `TileWidget` (refeito)

**Arquivo:** `lib/presentation/widgets/tile_widget.dart`

Célula vazia: `Container` cor `#C9B79C`, `BorderRadius.circular(12)`.

Tile preenchido — `Stack` dentro de `Container`:
- `Container`: fundo `#FFFFFF`, borda `Border.all(color: animal.borderColor, width: 3)`, `BorderRadius.circular(12)`, `BoxShadow` suave
- Camada 1 (marca d'água): `Image.asset(animal.assetPath, opacity: 0.27, fit: BoxFit.contain)` envolto em `Positioned.fill` + `Padding(8)`. Se asset não existe em `pubspec.yaml`, usa `SizedBox.shrink()` — sem erro em runtime
- Camada 2 (número): `Center(child: Text('${1 << tile.level}'))` com Fredoka Bold, cor `#3E2723`, tamanho `size * 0.35`

---

## 4. `HostBanner` (novo)

**Arquivo:** `lib/presentation/widgets/host_banner.dart`

- Lê `state.maxLevel` via `ref.watch(gameProvider.select((s) => s.maxLevel))`
- Se `maxLevel == 0`: exibe placeholder neutro ("Comece a jogar!")
- Se `maxLevel >= 1`: `animal = animalForLevel(maxLevel)` → slot imagem + `Text(animal.name)` em Nunito
- `AnimatedSwitcher(duration: 400ms)` envolve o conteúdo — troca com fade+scale
- Posição: widget próprio acima do `BoardWidget` no `GameScreen`

---

## 5. `ScorePanel` (modificado)

**Arquivo:** `lib/presentation/widgets/score_panel.dart`

Layout `Row`:
- Esquerda: score + high score (existente)
- Centro: cronômetro `MM:SS` lendo `elapsedMs` — exibe `--:--` antes do primeiro swipe
- Direita: `IconButton(Icons.pause_rounded)` → chama `ref.read(gameProvider.notifier).pause()`

Cronômetro para de atualizar quando `isPaused == true` ou `isGameOver == true` (estado não muda, widget simplesmente não recebe novos ticks).

---

## 6. `PauseOverlay` (novo)

**Arquivo:** `lib/presentation/widgets/pause_overlay.dart`

`Container` com `color: Color(0xFF2D7A4F)` (floresta escurecida), ocupa `Positioned.fill` sobre o tabuleiro.

Conteúdo centralizado:
- Ícone de pausa grande
- Texto "Pausado" em Fredoka
- 3 botões (Nunito, mínimo 48dp de altura):
  - **Continuar** → `notifier.resume()`
  - **Reiniciar** → `notifier.restart()`
  - **Menu** → `Navigator.pop(context)` (volta para HomeScreen — a ser criada; por ora fecha o jogo ou vai para placeholder)

Visível somente quando `state.isPaused == true`.

---

## 7. `GameScreen` (modificado)

**Arquivo:** `lib/presentation/screens/game/game_screen.dart`

Estrutura:

```
Scaffold
└── SafeArea
    └── GestureDetector (swipe — bloqueado se isPaused || isGameOver)
        └── Column
            ├── ScorePanel
            ├── HostBanner
            ├── Spacer
            ├── Stack
            │   ├── BoardWidget
            │   └── PauseOverlay (se isPaused)
            ├── Spacer
            └── GameOver overlay (se isGameOver)
```

---

## 8. Assets e `pubspec.yaml`

Adicionar seção de assets para imagens (caminho preparado, arquivos não precisam existir ainda):

```yaml
flutter:
  assets:
    - assets/images/animals/
  fonts:  # apenas se não usar google_fonts online
```

Pacote a adicionar: `google_fonts: ^6.x`.

---

## 9. Ordem de commits (incremental)

| # | Commit | Jogo jogável? |
|---|---|---|
| 1 | `feat: add AppTheme, Google Fonts — paleta e tipografia base` | ✅ |
| 2 | `feat: update Animal model (borderColor + assetPath), animals_data` | ✅ |
| 3 | `feat: rewrite TileWidget — white bg, colored border, watermark slot` | ✅ |
| 4 | `feat: add maxLevel + elapsedMs + isPaused to GameState/GameNotifier` | ✅ |
| 5 | `feat: add HostBanner with AnimatedSwitcher` | ✅ |
| 6 | `feat: update ScorePanel — timer display + pause button` | ✅ |
| 7 | `feat: add PauseOverlay — hide board, resume/restart/menu` | ✅ |
| 8 | `feat: wire GameScreen — HostBanner, PauseOverlay, swipe guard` | ✅ |

---

## 10. Fora de escopo (Fase 3+)

- SVGs reais dos animais
- Animações de spawn/merge/merge-capivara
- Sistema de vidas, loja, ranking
- HomeScreen real (Menu button por ora faz `Navigator.pop`)
