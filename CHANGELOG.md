# Changelog

All notable changes to Capivara 2048 will be documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

## [0.3.6] — 2026-04-26

### Added
- **Inventory system** — Hive-persisted `Inventory` model with Bomb 2, Bomb 3, Undo 1, Undo 3 items
- **InventoryBar widget** — 4 item buttons with grayscale when count == 0, red badge for count
- **Undo 1 and Undo 3** — `undoStack` (max 3 snapshots) in `GameState`, undo action in `GameNotifier`
- **Bomb 2/3** — `BombMode` enum, `BombSelectionOverlay` with reactive tile selection highlights, consume-on-confirm (not on tap)
- **Frosted-glass PauseOverlay** — `BackdropFilter` blur + `AnimatedOpacity` fade-in, with "Reduzir efeitos visuais" toggle (SharedPreferences persisted)
- **GameOverModal** — full implementation with lives check, `restart()` or navigate to `NoLivesScreen`

### Changed
- **Refactored GameScreen** to full Stack layout — all overlays as `Positioned.fill`, `Column` never has conditional children
- **Fixed OutlinedText** — 8-shadow radial technique replaces Stack/stroke approach, better anti-aliasing
- **Fixed HostBanner placeholder** — uses `outlinedWhiteTextStyle` consistently

## [0.3.5] — 2026-04-26

### Fixed
- Vidas agora só são consumidas no game over (não ao iniciar nova partida)
- Transição de cor de fundo entre animais sem flicker (TweenAnimationBuilder)
- Botão de pause reposicionado dinamicamente abaixo do StatusPanel (GlobalKey)
- Texto branco com contorno preto em StatusPanel e HostBanner para legibilidade

### Changed
- Cores de fundo dos animais agora são explícitas por animal (backgroundBaseColor)
- Boto-cor-de-rosa exibe fundo rosa correto (#FBD0DD) em vez de bege derivado

### Migration
- Primeira abertura pós-update reseta vidas para 5 (goodwill adjustment)

## [0.3.0] — 2026-04-25

### Added
- `HomeScreen` como tela inicial: botões Novo Jogo / Continuar / Ranking (placeholder) / Sair; SVG ensemble dos animais
- Sistema de vidas completo: regen offline (1 vida a cada 30 min), `LivesState` persistido via Hive, `LivesIndicator` com corações, `NoLivesScreen` com mock-anúncio
- `LivesNotifier` com `consume()`, `rewardFromAd()`, `canWatchAd`, `canPlay`; limite de 40 anúncios/dia com reset à meia-noite
- `HostArtwork`: renderiza `hostSvgPath` se disponível, fallback automático para tile SVG
- `StatusPanel`: cronômetro `HH:MM:SS`, pontuação atual e recorde — alinhado às colunas 3–4 do tabuleiro
- Botão de pause flutuante (`Positioned`) sempre visível durante o jogo; funciona como toggle pause/resume
- `GameBackground`: fundo dinâmico com `Color.lerp(borderColor, mint, 0.65)` + textura geométrica com 10–15% de opacidade
- `TexturePainter`: 7 padrões geométricos por animal (pontilhado, hachura diagonal, grade, ondas, manchas, escamas, radial) via `dart:math`
- `AnimatedSwitcher` 400 ms ao trocar animal anfitrião no fundo
- `RepaintBoundary` isolando `BoardWidget` de repaints do fundo
- `AppColors.primary` e `AppColors.mint` centralizando as cores de fundo
- `GameConstants.twoCellWidth` para largura alinhada às colunas

### Changed
- `app.dart`: rota inicial alterada de `GameScreen` para `HomeScreen`
- `HostBanner` refatorado para usar `HostArtwork` e `GameConstants.twoCellWidth`
- `ScorePanel` simplificado (cronômetro extraído para `StatusPanel`)
- Reorganização de assets: SVGs de tile em `assets/images/animals/tile/`, texturas em `assets/images/textures/`, host em `assets/images/animals/host/`
- Modelo `Animal` estendido: `hostSvgPath`, `hostAspectRatio`, `backgroundTexturePath`, `texturePattern`

## [0.2.0] — 2026-04-25

### Added
- Identidade visual base: paleta verde-amazônica (`#3FA968`), tipografia Fredoka + Nunito via Google Fonts
- `AppTheme.light()` centraliza cores e estilos da aplicação
- `TileWidget` redesenhado: fundo branco, borda colorida por animal, slot para imagem com opacidade (watermark)
- `HostBanner`: exibe o animal de maior nível alcançado na partida com transição AnimatedSwitcher (fade + scale)
- Cronômetro MM:SS no `ScorePanel` — inicia no primeiro swipe válido, exibe `--:--` antes disso
- Sistema de pausa completo: botão de pausa no `ScorePanel`, overlay sobre o tabuleiro com opções Continuar / Reiniciar / Menu
- `GameState` ganha campos `maxLevel`, `elapsedMs` e `isPaused`
- `GameNotifier` gerencia `Timer.periodic(100ms)` com ciclo de vida correto (inicia, pausa, retoma, descarta)
- `GameEngine.move()` rastreia `maxLevel` a cada jogada

### Changed
- `Animal.tileColor` renomeado para `borderColor`; campo `assetPath` adicionado para futuros SVGs

## [0.1.1] — 2026-04-25

### Fixed
- Tiles exibiam o nível (1, 2, 3…) em vez do valor correto (2, 4, 8…) — display corrigido em `tile_widget.dart`

## [0.1.0] — Em desenvolvimento

### Added
- `CAPIVARA_2048_DESIGN.md` — full game design specification
- `README.md` — project overview and roadmap
- `CLAUDE.md` — development guidelines
- Flutter project setup com Riverpod e uuid
- Pure Dart game engine com mecânica 2048 completa
- 11 animais amazônicos definidos (`animals_data.dart`)
- Tela de jogo com tabuleiro 4x4, swipe, pontuação e game over
- Testes unitários do game engine (merge, score, direções, game over, vitória)
