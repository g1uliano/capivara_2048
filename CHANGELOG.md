# Changelog

All notable changes to Capivara 2048 will be documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

## [1.0.5] - 2026-05-03

### Fixed
- Flash branco entre splash nativa e primeiro frame Flutter eliminado — `NormalTheme` agora usa `#1B3610` como `windowBackground` em vez da cor padrão do sistema
- `SplashScreen` Flutter exibe a arte full-screen corretamente (referência morta a `splash_logo.png` removida)

## [1.0.4] - 2026-05-03

### Fixed
- Android 12+: splash exibe ícone do app centralizado sobre fundo verde-selva `#1B3610` em vez da imagem full-screen cortada com crop arredondado

## [1.0.3] - 2026-05-03

### Changed
- Splash screen full-screen com arte da floresta amazônica e todos os animais do jogo (1080×1920, `scaleAspectFill`)

## [1.0.2] - 2026-05-03

### Fixed
- Usar Bomba 2/3 na `GameOverItemOverlay` agora abre a grade de seleção de tiles corretamente — o item não era mais consumido antes do jogador selecionar os tiles, eliminando o travamento do jogo
- Botões "Comprar" e "Encerrar partida" no `GameOverNoItemsOverlay` agora legíveis sobre o fundo escuro

## [1.0.1] - 2026-05-03

### Fixed
- `GameOverModal` não aparecia mais sobre o `GameOverNoItemsOverlay` — condição legada `|| !hasAnyItem` removida; modal só exibe após o jogador confirmar "Encerrar partida"

## [1.0.0] - 2026-05-02

### Added
- **GameOverNoItemsOverlay** (Fase 2.10-B): quando o tabuleiro trava e o inventário está vazio, oferece 3 opções — ver anúncio (rewarded ad via FakeAdService), comprar item avulso, ou encerrar (consome 1 vida). Botão voltar Android bloqueado. Tabuleiro ao fundo não interativo (AbsorbPointer).
- **Itens avulsos na ShopScreen** (Fase 2.10-C): seção "Itens avulsos" abaixo dos 6 pacotes; 4 cards compactos (ícone + nome + preço) para compra individual de Bomba 3 (R$ 1,99), Desfazer 3 (R$ 0,99), Bomba 2 (R$ 1,19) e Desfazer 1 (R$ 0,49). Preços ~2× o valor por unidade nos pacotes para incentivar compra do pacote.
- **`kItemUnitPrices`** em `shop_data.dart`: mapa de preços unitários para os 4 tipos de item.

### Changed
- **GameOverItemOverlay** (Fase 2.10-A): ícone do item em destaque pisca em loop (opacidade 1.0→0.4→1.0, 800ms easeInOut via `flutter_animate`). Haptic sincronizado com cada ciclo (`AnimationController` separado, respeita `hapticEnabled`). Animação e haptic param ao tocar "Usar item"; reiniciam ao trocar de item. `WillPopScope` substituído por `PopScope`.

## [0.9.9.5] - 2026-05-02

### Fixed
- Regen de vida não reseta mais imediatamente quando perdida no cap: `applyConsume` agora reseta `lastRegenAt` para `DateTime.now()` quando `lives >= regenCap`, garantindo que o countdown de 30 minutos comece do zero

## [0.9.9.4] - 2026-05-02

### Fixed
- Countdown "Restando MM:SS" agora decrementa a cada segundo — o banner tinha `_timerText()` calculado corretamente mas sem `Timer.periodic(1s)` para forçar rebuild do widget

## [0.9.9.3] - 2026-05-02

### Fixed
- Splash screen no Android 12+: removida animação de saída (rotação/zoom) que distorcia a imagem antes do Flutter carregar
- confirmBomb limpa isContinuingWithItem e reseta isGameOver para desbloquear o jogo após usar bomba no fluxo game-over

## [0.9.9.1] - 2026-05-02

### Fixed
- GameOverItemOverlay não aparece mais quando inventário está vazio
- Cancelar bomba durante fluxo "Usar item" volta para o overlay em vez de ir direto para Game Over

## [0.9.9] - 2026-05-02

### Added
- Splash screen: native splash + animated logo (Fase 2.9-A)
- GameOverItemOverlay: "Continuar?" dialog when game ends, lets player use an inventory item (Fase 2.9-B)

### Changed
- Inventory icons enlarged from 56dp to 72dp (Fase 2.9-C)
- Board-to-inventory spacing reduced from 12dp to 4dp (Fase 2.9-C)
- App locked to portrait-only orientation (Fase 2.9-D)

### Fixed
- Bomba: taps na grade de seleção não respondiam — BombDimOverlay envolvia tudo com
  IgnorePointer(ignoring: false), bloqueando todos os eventos antes de chegarem ao grid.
  Dim e label agora são IgnorePointer; apenas o botão Cancelar absorve eventos.
- Bomba: células da grade agora são branco opaco (100%) nas não selecionadas e
  vermelho sólido nas selecionadas, eliminando o problema de visibilidade.

## [0.9.8] — 2026-05-02

### Fixed
- Bomba: células do overlay invisíveis sobre o tabuleiro — reescrita do BombGridOverlay
  usando exatamente o mesmo layout do BoardWidget (Column/Row/Expanded com mesmos paddings),
  garantindo alinhamento pixel-a-pixel. Fundo branco 60% opaco para contraste real;
  selecionadas ficam vermelho 65% com borda grossa.

## [0.9.7] — 2026-05-02

### Fixed
- Bomba: células da grade de seleção estavam transparentes, impossível ver sobre os tiles.
  Adicionado fundo branco semi-transparente (25%) e borda branca mais visível nas células
  não selecionadas; selecionadas ficam vermelho 55%.

## [0.9.6] — 2026-05-02

### Fixed
- Bomba: grade de seleção desalinhada com o tabuleiro — reescrita da arquitetura do overlay.
  A grade (`BombGridOverlay`) agora vive dentro do Stack que envolve exatamente o BoardWidget,
  eliminando qualquer cálculo de altura de header. `BombDimOverlay` cuida apenas do dim/label/cancelar.

## [0.9.5] — 2026-05-02

### Fixed
- Bomba 3: grade de seleção desalinhada com o tabuleiro — overlay agora espelha a estrutura exata do GameScreen (LayoutBuilder + heights fixas de header/inventory)
- Recompensa Diária: coletar Dia 1 marcava Dia 2 como coletado — condição `isClaimed` corrigida para exigir `claimedThisCycle=true`

### Changed
- Recompensa Diária: cards dos dias agora responsivos, ocupam toda a largura disponível da tela

## [0.9.4] — 2026-05-02

### Added
- ShopScreen com 6 pacotes compráveis (Fase 2.8)
- Compra simulada entrega itens localmente sem IAP real
- Bottom sheet "Código para presentear" com UUID truncado e botão copiar
- ShareCode persistido em SharedPreferences (migração Firestore na Fase 3)

## [0.9.3] — 2026-05-02

### Fixed
- Tabuleiro 4×4 cortado em telas pequenas (360×640) — `LayoutBuilder` no `GameScreen`
- Badge de Recompensa Diária desalinhava o grid da Home — `SizedBox.expand` + badge "!"
- Textos ilegíveis sobre fundo dinâmico (`CollectionScreen`, `SettingsScreen`) — `OutlinedText`
- Controles de `SettingsScreen` ilegíveis — cards brancos semi-opacos por seção

## [0.9.2] — 2026-05-01

### Added
- Home redesenhada: grid 2×3 de cards (Loja, Ranking, Recompensa Diária, Coleção, Configurações, Como Jogar)
- Animação de entrada do logo (`flutter_animate` fade + scale 400ms)
- `CollectionScreen`: grid 2 colunas, 11 animais, cards desbloqueados/bloqueados, bottom sheet detalhado
- `SettingsScreen`: toggle haptic (persistente), seleção de idioma (placeholder), sliders de áudio desabilitados, versão do app, "Olha o Bichim! © Catraia Aplicativos"
- Stubs navegáveis: `ShopScreen`, `InviteFriendsScreen`, `RedeemCodeScreen`
- `SettingsNotifier` com `SharedPreferences`; `maybeHaptic()` utilitário
- `funFact` e `scientificName` preenchidos para todos os 11 animais
- `package_info_plus` adicionado às dependências

## [0.9.1] — 2026-05-01

### Fase 2.5 — Identidade "Olha o Bichim!"
- Rebranding: strings de exibição "Capivara 2048" → "Olha o Bichim!" (app title, Info.plist, README)
- Novo widget `GameTitleImage` com sorteio por sessão entre variante orange e brown
- Logo na HomeScreen substituindo placeholder SizedBox(height: 220)
- Launcher name "Olha o Bichim!" em Android, iOS, Web
- Ícone do app gerado via flutter_launcher_icons com adaptive icon background #D4F1DE

## [0.8.4] — 2026-04-30

### Changed
- Botões do inventário: PNG ocupa 56×56 inteiro — o PNG é o botão (sem fundo verde)

## [0.8.3] — 2026-04-30

### Fixed
- `HostBanner` colado à esquerda do header sem padding — simetria com `PauseButtonTile` à direita

## [0.8.2] — 2026-04-30

### Fixed
- `HostBanner` alinhado com a coluna 1 do tabuleiro (offset `tileSpacing * 1.5` corrigido)
- Botões do inventário sem label de texto — apenas PNG centralizado no slot

## [0.8.1] — 2026-04-30

### Fixed
- `LivesIndicator` centralizado horizontalmente em `GameScreen` e `HomeScreen` (era esquerda/direita)
- `HostBanner` colado à borda esquerda do tabuleiro — gap eliminado com `Spacer()` (Fase 2.3.12-B)
- Timer de regen de vidas implementado em `LivesNotifier` — vidas agora incrementam durante sessão ativa (Fase 2.3.12-C)
- Recálculo offline de vidas ao retornar do background via `AppLifecycleListener` (Fase 2.3.12-C)

### Changed
- Ícones do inventário agora usam PNGs finais temáticos (Sucuri, Mico-leão, Capivara, Onça) (Fase 2.3.12-D)
- `ConfirmUseDialog` exibe ícone 40×40 do item no título (Fase 2.3.12-D)

## [0.8.0] - 2026-04-28

### Added
- `HostBanner`: Tanajura exibida desde o boot como anfitrião inicial (sem placeholder "Comece!")
- `HomeScreen`: mesmo `fundo.png` da `GameScreen` — fundo visual unificado entre as telas
- Galeria de debug: nota informativa sobre Tanajura ser o anfitrião inicial (Fase 2.3.11)

### Changed
- `maxLevel` inicia em 1 em `GameEngine.newGame()` e `GameNotifier.restart()`
- `hasSave` na `HomeScreen` usa `score > 0` (corrige falso-positivo causado pelo novo `maxLevel = 1`)
- `GameBackground`: parâmetro `animal` removido (dead code)

### Removed
- `_Placeholder` widget do `HostBanner`

## [0.7.5] - 2026-04-27

### Changed
- `LivesIndicator`: espaço entre coração e texto reduzido de 6→2dp

## [0.7.4] - 2026-04-27

### Changed
- `GameHeader`: bloco direito (StatusPanel + PauseButtonTile) alinhado à direita (`CrossAxisAlignment.end`)

## [0.7.3] - 2026-04-27

### Changed
- `HostBanner` placeholder: Capivara visível em tamanho cheio (sem opacidade); "Comece!" no lugar do nome (Fredoka 16sp), mesmo layout de `_AnimalHost`

## [0.7.2] - 2026-04-27

### Changed
- `StatusPanel`: conteúdo alinhado à direita (`CrossAxisAlignment.end`)

## [0.7.1] - 2026-04-27

### Changed
- `PauseButtonTile`: alinhamento `centerLeft` → `centerRight` dentro do slot 2×1

## [0.7.0] - 2026-04-27

### Added
- `GameHeader` widget: extrai cabeçalho da `GameScreen` em componente isolado (`StatelessWidget`)
- `StatusPanelTest`: testes de regressão para ausência de `PauseButtonTile` na subárvore
- Galeria de debug: coluna "Host 2×2" mostrando `HostArtwork` no tamanho real (152dp)

### Changed
- `GameScreen`: usa `GameHeader()`; `Padding(horizontal: 12)` compartilhado entre header e board
- `HostBanner`: slot fixo 2×2 (152dp); `_Placeholder` com silhueta Capivara (opacity 0.15) + "Comece!"; nome em Fredoka 16sp
- `HostArtwork`: `BoxFit.cover` (era `contain`) — PNGs são quadrados, sem risco de corte
- `StatusPanel`: fontes cronômetro 18sp, pontuação 24sp, recorde 13sp; `CrossAxisAlignment.center`
- `PauseButtonTile`: separado do `StatusPanel` — agora empilhado abaixo com espaço de 6dp

## [0.5.0] - 2026-04-27

### Added
- Confirmation dialog for all inventory item uses
- LivesIndicator redesign: single heart with number overlay, bonus badge when lives exceed regen cap
- Lives system: `regenCap` (5) and `earnedCap` (15) caps; purchased lives have no cap; `addEarned`/`addPurchased` methods
- Inventory 99+ badge when count exceeds 99; long-press tooltip shows exact count

### Changed
- Migrated all 22 animal assets from SVG to PNG; removed `flutter_svg` dependency
- `Animal` model: `assetPath`/`hostSvgPath` renamed to `tilePngPath`/`hostPngPath`; removed `texturePattern`, `hostAspectRatio`, `backgroundTexturePath`
- Fixed game background to solid `#D4F1DE`; removed animated texture system
- Host banner: animal name moves to top (2 lines), artwork in 2×2 tile slot below
- Game screen header: LivesIndicator + StatusPanel in top row; HostBanner in second row
- PNG images precached with `ResizeImage` on app startup

### Migration
- Hive data reset to initial state (v2.3.8 migration)

## [0.4.0] — 2026-04-26

### Added
- **SVG watermarks nos tiles** — `SvgPicture.asset` com `Opacity(0.27)` e padding `size * 0.08`, substituindo `Image.asset` que era silenciosamente vazio
- **Host artwork ativo** — `hostSvgPath` populado em todos os 11 animais, `HostArtwork` agora renderiza o SVG correto para cada animal
- **Sagui no nível 5** — substitui Arara-azul; cor `#A0826D`, `scientificName`, `funFact`
- **Campos `scientificName` e `funFact` no model `Animal`** — nullable, preparando para tela de Coleção (Fase 5)
- **Tint escuro no PauseOverlay** — `Container(Colors.black.withOpacity(0.25))` garante legibilidade sobre tiles amarelos/dourados
- **`OutlinedText` em todos os textos do PauseOverlay** — "Pausado", botões, "Reduzir efeitos visuais", "Debug"
- **Ícone de pausa emoji** — `Text('⏸')` com 4 sombras diagonais substitui `Icon(Icons.pause...)`
- **`svgPath` opcional em `InventoryItemButton`** — suporte a SVG com fallback para `IconData`; grayscale `ColorFiltered` existente cobre ambos
- **4 SVGs de ícones de inventário** — `bomb_2.svg`, `bomb_3.svg`, `undo_1.svg`, `undo_3.svg` em `assets/icons/inventory/`
- **Galeria de debug** — `AnimalsGalleryScreen` acessível via PauseOverlay → "Debug" (apenas em `kDebugMode`); mostra tile, host livre e host com fundo para todos os 11 animais
- **Relatório de auditoria SVG** — `docs/svg_audit_2_3_7.md` (template; preencher após inspeção visual na galeria)

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
