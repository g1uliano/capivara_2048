# Changelog

All notable changes to Capivara 2048 will be documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

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
