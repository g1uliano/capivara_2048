# Changelog

All notable changes to Capivara 2048 will be documented here.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

## [Unreleased]

## [1.9.8] — 2026-05-17

### Added

- **Modo de Performance**: sistema completo de detecção de capacidade de dispositivo e controle granular de qualidade gráfica
  - Detecção heurística automática por modelo/SDK no startup (via `device_info_plus`) — exibe dialog de sugestão uma vez por instalação
  - Monitor de FPS em runtime (`SchedulerBinding.addTimingsCallback`, janela de 30 frames, threshold 45 fps) — exibe dialog na primeira sessão com queda detectada
  - Dialog de sugestão com estilo consistente ao restante da UI (borda laranja, Fredoka, dois botões: "Agora não" / "Ativar")
  - Três variantes de qualidade dos tiles: **Completo** (imagem + opacidade 0.27), **Sem opacidade** (imagem sem Opacity wrapper), **Simples** (cor sólida + nome do animal)
  - Toggle de efeitos de blur (substitui o `reduceEffectsProvider` removido)
  - Toggle de animações decorativas (bob da capivara-mascote, pulse/sparkles da trilha de recompensas, animação de claim)
  - Seção "Performance" completa na tela de Configurações: switch modo, switch detecção automática, `SegmentedButton` de qualidade dos tiles, switches blur e animações (sub-itens desabilitados com opacity 0.4 + `IgnorePointer` quando modo desligado)
  - Persistência em `SharedPreferences` com JSON + defaults seguros

### Fixed

- **Swipe — movimentos ignorados em dispositivos lentos**: threshold de velocidade reduzido de 100 px/s para 50 px/s — resolve o principal sintoma de lag de input relatado no Redmi Note 9s

## [1.9.7] — 2026-05-16

### Fixed

- **Resgatar Código — mensagens de erro ilegíveis**: `errorText` do `InputDecoration` renderizava texto vermelho diretamente sobre o fundo do jogo; substituído por `Text` com `outlinedWhiteTextStyle(fredoka(14))` para legibilidade
- **GameNotifier — `debugSetState` cancelava apenas timer de jogo**: `_firestoreSaveTimer` agora também é cancelado, evitando salvamentos fantasma no Firestore durante injeção de estado em testes

## [1.9.6] — 2026-05-15

### Added

- **Jogo em progresso — sincronização com Firestore**: estado atual do tabuleiro (board, score, maxLevel, elapsedMs) é persistido em SharedPreferences a cada movimento válido e sincronizado com Firestore com debounce de 10s; ao fazer login após apagar os dados do app, `syncProfile()` restaura o estado remoto e a `HomeScreen` exibe "Continuar Jogo" automaticamente
- **Tela Resgatar Código — painel explicativo**: `GlassPanel` com ícone de presente e texto explicativo adicionado acima do campo de código

### Fixed

- **Loja — botão "Resgatar código de presente" ilegível**: `OutlinedButton` branco substituído por `ElevatedButton` laranja (`#FF8C42`), mesma cor dos botões de compra de itens avulsos
- **Deep link de convite — fluxo para usuários não logados**: `SplashScreen._navigate()` agora verifica `pendingInviteRefProvider`; quando há convite pendente e o usuário não está logado, navega para `HomeScreen` (que exibe o `InviteWelcomeSheet`) em vez de ir direto para `OnboardingAuthScreen`

## [1.9.5] — 2026-05-15

### Fixed

- **Haptic — vibração forte ao trocar animal anfitrião**: `HapticIntensity.heavy` adicionado quando `maxLevel` sobe (troca de animal anfitrião), que estava sem haptic desde a implementação
- **Ranking — recorde registrado ao atingir 2048**: pontuação e tempo agora submetidos ao ranking no momento em que o milestone é detectado (`onSwipe`), sem precisar encerrar o jogo; extraído `_submitToRanking()` reutilizado por `_saveGameRecord()`
- **Loja — "Você não possui mais itens" comprava item errado**: botão "Comprar Desfazer 1" sempre disparava IAP de "4× Desfazer 3" (package hardcoded); corrigido para usar `kUnitPackageByType[_drawnItem]`, comprando e entregando o item exibido
- **Loja — Combo Mata Atlântica continha Bomba 2**: `p5` corrigido para `bomb3: 2` em `contents` e `giftContents`; description atualizada para "2 Bomba 3"

## [1.9.4] — 2026-05-14

### Changed

- **Loja — cards de pacotes substituídos por imagens WebP**: os seis cards de pacotes (`p1`–`p6`) na `ShopScreen` e no `ShopOverlay` agora exibem as imagens promocionais `shop_pack_01–06.webp` em vez do layout textual anterior; os assets foram adicionados ao `pubspec.yaml`
- **Loja — efeito de press nos cards de imagem**: ao toque, o card aplica scale 0.97 + sombra reduzida + overlay escuro semitransparente (80 ms), dando feedback visual de seleção

## [1.9.3] — 2026-05-13

### Added

- **Perfil — Editar nome visível**: `ListTile` "Editar nome" adicionado no card de ações do `ProfileScreen`, exclusivo para usuários com conta e-mail (ao lado de "Trocar senha"). O ícone inline de 18px que era o único ponto de entrada anterior foi removido por ser praticamente invisível sobre o fundo da floresta

### Changed

- **Assets: PNG → WebP** — todos os assets de imagem migrados para WebP com redimensionamento (tile animals → 512×512, host animals → 1024×1024, home/inventory/title → 512×512); ~96% de redução no tamanho total de imagens (~72 MB → ~2,5 MB)
- **Recompensas Diárias — novo visual dos tiles**: gift boxes e baú substituídos pelas 7 imagens WebP `reward_day_01–07.webp` (sapos em nenúfares, progressão 1→6 sapos nos dias 1–6; imagem panorâmica no Dia 7)
- **Recompensas Diárias — fundo exclusivo**: `GameBackground` (floresta) substituído por gradiente verde-floresta escuro (`#071812` → `#0D2B1C`), exclusivo desta tela; `GlassPanel` substituído por `_DailyPanel` sólido otimizado para fundo sólido
- **Ranking — mensagem estado vazio**: "Jogue sua primeira partida para aparecer aqui!" → "Forme o 2048 para aparecer aqui!" (reflete a condição real de entrada no ranking)

### Fixed

- **reward_day_05.webp**: padding transparente de 32 px nas bordas direita/inferior removido por crop + resize para 512×512, igualando visualmente o tile do Dia 5 aos demais
- **Recompensas Diárias — labels "Dia X"**: `Positioned(left:0, right:0)` + `textAlign: center` adicionados nos tiles claimed e future, corrigindo desalinhamento do texto

## [1.9.1] — 2026-05-11

### Fixed

- **Sync pós-login: inventário não restaurado** — inventário IAP nunca era escrito no documento Firestore do usuário; após limpar armazenamento e fazer login, `_mergeRemoteInventory` recebia `null` e retornava sem restaurar nada. Corrigido: `syncInventory(Inventory)` adicionado ao `SyncEngine`; chamado em `InventoryNotifier.add()` e `consume()`, garantindo persistência no Firestore a cada mudança
- **Sync pós-login: coleção/recordes pessoais desatualizados** — `highestLevelEver`, `bestTimeMs2048`, `rewardCollected*` e `firstReached*At` só eram escritos no Firestore na criação do documento (nunca nas atualizações subsequentes). Corrigido: `syncPersonalRecords(PersonalRecords)` chamado em `PersonalRecordsNotifier._save()` a cada atualização
- **Sync pós-login: `PersonalRecordsNotifier` não recarregado após merge remoto** — `_mergeRemotePersonalRecords` escrevia no Hive mas o notifier Riverpod não tinha watcher; UI mostrava dados antigos. Corrigido: `AuthController._reloadSyncedNotifiers()` chama `.load()` em `personalRecordsProvider` e `dailyRewardsProvider` após `syncProfile()` em todos os 4 caminhos de login
- **Sync pós-login: progresso de recompensas diárias perdido** — `DailyRewardsState` não tinha nenhuma sincronização com cloud. Corrigido: `syncDailyRewards(DailyRewardsState)` adicionado ao `SyncEngine`; chamado após `claim()`; restaurado em `syncProfile()` com lógica de merge (estado mais recente por `lastClaimedDate` vence)
- **`SyncConflictResolver.mergePersonalRecords`**: `bestTimeMs2048` agora incluso no merge (min não-zero — menor tempo é melhor); campo também adicionado em `_personalRecordsFromMap`, `_writeLocalProfileToFirestore` e `syncPersonalRecords`

## [1.9.0] — 2026-05-11

### Added

- **Recompensas diárias — trilha serpentina**: nova UI estilo jogo de tabuleiro com 6 caixas de presente coloridas (paleta variada por dia) + baú dourado no Dia 7, substituindo o grid 4×2 anterior
- **CapivaraMascot**: mascote animado que navega até o tile do dia atual na trilha, com `AnimatedPositioned`
- **`legendsRankingRepositoryProvider`**: provider dedicado para ranking de lendas — funciona sem login (userId vazio para usuários anônimos)
- **Firebase/Firestore**: `firestore.rules` e `firestore.indexes.json` adicionados e referenciados em `firebase.json`
- **IAP — produtos unitários**: 4 novos produtos avulsos (`u_bomb3`, `u_undo3`, `u_bomb2`, `u_undo1`) documentados em `IAP.md`

### Changed

- **Ranking Global**: migrado de `StreamProvider` (gerava loop de reinicialização em erros transitórios) para `FutureProvider` com botão "Tentar novamente"
- **`_LegendsCard`**: convertido para `ConsumerStatefulWidget` com `_retry()` correto — elimina bug onde `animal`/`title`/etc. eram referenciados sem `widget.` em `ConsumerWidget`
- **`FakeAuthService`**: inicializado com `PlayerProfile` completo (tutorialCompleted=true) para facilitar testes no flavor `tst`
- **IAP.md**: tabela de builds reescrita separando `--flavor` Android de `--dart-define=FLAVOR=`; guia sandbox atualizado; 10 produtos totais documentados

### Fixed

- **Timer do jogo**: timer reinicia corretamente quando o jogador continua após game over com um item power-up (era `null` após `_stopTimer()`)

## [1.8.1] — 2026-05-10

### Fixed

- **Home — botões Coleção e Configurações**: `Configuracao.png` tem 9.5% de transparência no topo e conteúdo visível de apenas 80.6% da altura do canvas (vs 99.4% do `Colecao.png`), fazendo o círculo de Configurações parecer ~23% menor. Corrigido aumentando `sizeConfiguracao` por fator 1.233× e ajustando `topConfiguracao` para compensar a transparência e alinhar visualmente os dois círculos.

## [1.8.0] — 2026-05-10

### Added

- **Ícones da Home redesenhados**: novos assets para Coleção, Como Jogar, Configuração, Loja, Ranking e Recompensas (`assets/images/home/`)
- **Haptic feedback graduado**: vibração leve em level-up (troca de anfitrião), média ao atingir 2048/4096/8192, forte em game over — respeitando o toggle de Configurações
- **Produtos IAP unitários** (`u_bomb3`, `u_undo3`, `u_bomb2`, `u_undo1`): itens avulsos agora têm produtos reais registráveis nas lojas com preços individuais
- **`docs/IAP.md`**: guia completo de configuração dos produtos IAP no Google Play Console e App Store Connect
- **`deliverIAPItems` helper** (`lib/core/utils/iap_delivery.dart`): entrega local de itens IAP compartilhada entre ShopScreen, ShopUnitItemCard e ShopOverlay (DRY)
- **Tutorial wizard interativo** (`TutorialScreen`): substitui o `_HowToPlaySheet` por um wizard de 5 telas com navegação passo-a-passo, 2 telas interativas (mini-boards onde o jogador faz swipe), animações com `flutter_animate` e persistência de `tutorialCompleted` no perfil
- **`TutorialMiniBoard`**: widget independente do `GameEngine` que renderiza tiles reais e detecta swipe
- **`PlayerProfile.tutorialCompleted`**: novo campo persistido no Firestore (logados) ou `SharedPreferences` (anônimos)
- **`TutorialController`**: Riverpod Notifier com `markCompleted()` — persiste nas duas fontes conforme estado de auth

### Changed

- **Bomba 3**: desabilitada quando há menos de 5 peças no tabuleiro; exibe aviso "São necessárias pelo menos 5 peças..." (mesmo padrão visual do Desfazer 3)
- **Loja principal — itens avulsos**: compra agora usa fluxo IAP real (`IAPConfirmationSheet` + `iapService.buyPackage`) em vez de adicionar direto ao inventário
- **Shop overlay**: compra de combos e itens avulsos agora usa fluxo IAP real
- **Recompensa dobrada**: botão de dismiss muda de "Não, obrigado" para "Ok" após assistir o anúncio
- **Botão "Como Jogar"** na Home abre tela cheia `TutorialScreen` em vez de `BottomSheet`; `semanticLabel` renomeado para `"Tutorial"`

### Fixed

- `ShopScreen._deliverItemsLocally` substituído pelo helper compartilhado `deliverIAPItems`
- Haptic de milestone agora dispara corretamente dentro do loop de detecção de milestone (era dead code antes)

### Removed

- `_HowToPlaySheet` (substituído pelo `TutorialScreen`)

## [Unreleased — 4.4]

### Added

- **Tutorial wizard interativo** (`TutorialScreen`): substitui o `_HowToPlaySheet` por um wizard de 5 telas com navegação passo-a-passo, 2 telas interativas (mini-boards onde o jogador faz swipe), animações com `flutter_animate` e persistência de `tutorialCompleted` no perfil
- **`TutorialMiniBoard`**: widget independente do `GameEngine` que renderiza tiles reais e detecta swipe
- **`PlayerProfile.tutorialCompleted`**: novo campo persistido no Firestore (logados) ou `SharedPreferences` (anônimos)
- **`TutorialController`**: Riverpod Notifier com `markCompleted()` — persiste nas duas fontes conforme estado de auth

### Changed

- Botão "Como Jogar" na Home agora abre tela cheia `TutorialScreen` em vez de `BottomSheet`; `semanticLabel` renomeado para `"Tutorial"`

### Removed

- `_HowToPlaySheet` (substituído pelo `TutorialScreen`)

## [1.7.0] — 2026-05-08

### Added

- **Ranking Global:** aba "Global" no `RankingScreen` com ranking semanal de menor tempo até 2048 (`watchWeeklyTop globalTime`)
- **MilestoneRankingDialog:** diálogo pós-milestone (2048 / 4096 / 8192) exibindo posição do jogador no ranking global semanal
- **PostGameController:** detecta recordes pessoais pós-partida, concede combo de recompensas e consulta posição no ranking global
- **`bestTimeMs2048` em `PersonalRecords`:** campo para rastrear recorde de tempo até 2048 e detectar melhoras
- **maxTile tiebreaker:** desempate por maior tile na submissão do ranking global de tempo
- **Recompensa ao convidador:** quem convida recebe 1 combo (vida + bomba 3×3 + desfazer) quando o convidado completa a primeira partida
- **Tabela de recompensas semanais revisada:** prêmios para posições 1–10 no ranking semanal
- **`InviteFriendsScreen` redesenhada:** layout scrollável, `_HeroCard` glassmorphism, lista de recompensas, estado vazio estilizado
- **`ProfileScreen` refatorada:** ações agrupadas em card branco semi-transparente; acesso direto a "Convidar Amigos", troca de senha e restaurar compras
- **`OnboardingAuthScreen` renovada:** painéis frosted-glass (`_ContentPanel`), bloco de benefícios (`_BenefitsBlock`), layout mais responsivo

### Fixed

- **`GlobalRankingTab`:** `StreamProvider` movido para top-level, evitando recriação em rebuilds; estilos de texto corrigidos com `outlinedWhiteTextStyle`
- **Exibição de rank globalTime:** posição calculada corretamente com tiebreaker de maxTile
- **`_mergeRemoteInventory`:** usava chave Hive errada `'inventory'`; corrigido para `'data'`
- **Fake\* providers:** `FakeRankingService`, `FakeAuthService` etc. exclusivos do flavor `tst`; `dev` usa serviços reais
- **Cold start avatar:** tile e displayName do avatar restaurados corretamente no arranque frio
- **`RankingScreen`:** todos os textos sobre o fundo usam `outlinedWhiteTextStyle(GoogleFonts.fredoka(...))`
- **`BombSelectionOverlay` / `InventoryBar`:** ajustes menores de estilo e tipografia

## [1.6.0] — 2026-05-07

### Added

- **Exclusão de conta (LGPD):** fluxo de 2 etapas na `ProfileScreen` (aviso + digitar "EXCLUIR" + senha para conta e-mail); remove dados do Firestore, Hive local e Firebase Auth com re-autenticação
- **Campo nome no cadastro:** `EmailAuthScreen` agora exige nome no signup; nome é salvo no Firebase Auth e Firestore
- **Editar nome de perfil:** botão lápis ao lado do nome na `ProfileScreen` (somente contas e-mail)
- **Trocar senha:** ListTile na `ProfileScreen` envia e-mail de redefinição (somente contas e-mail)
- **Esqueci minha senha:** link na `EmailAuthScreen` (modo login) envia e-mail de redefinição
- **Persistência de avatar tile:** avatar de animal escolhido por contas e-mail agora persiste entre sessões via Firestore
- **Auth gate no startup:** `SplashScreen` redireciona para `OnboardingAuthScreen` quando não logado
- **`OnboardingAuthScreen` dual-mode:** modo startup (`showSkip: true`) com bloco de benefícios e botão "Jogar sem conta →"; modo mid-app com AppBar e pop após login
- **`AuthGateOverlay`:** novo widget para gates de auth em overlays do jogo (ShopOverlay)
- **Auth gate na Loja (overlay):** `ShopOverlay` exibe `AuthGateOverlay` quando não logado
- **Auth guard na Home:** navegação para `DailyRewardsScreen` e `ShopScreen` requer login
- **Banner na aba Lendas:** informação não-bloqueante no `RankingScreen` quando não logado
- **Sync ranking pessoal:** partidas salvas no Firestore quando logado; merge com dados locais no login
- **Sync game records:** após fim de partida, registro enviado ao Firestore quando logado
- **`GameRecord.toJson/fromJson`:** serialização para persistência no Firestore

### Fixed

- **`signOut()`:** `GoogleSignIn.instance.signOut()` agora é chamado apenas para contas Google (antes chamava incondicionalmente)
- **`syncEngineProvider`:** usa `FirebaseSyncEngine` para `dev`, `tst` e `prd` (antes só `prd`)
- **Avatar Google:** botão de editar avatar ocultado na `ProfileScreen` para contas Google
- **Harness de testes e2e:** `GameTestHarness` inicializa com usuário logado; golden tests da `HomeScreen` atualizados

## [1.5.3] — 2026-05-07

### Fixed

- **Tipografia consistente (Fase 4.1.1):** todo texto exibido diretamente sobre fundos não-sólidos (fundo do jogo, dark overlay) migrado de `GoogleFonts.nunito()` para `GoogleFonts.fredoka()` em todas as telas e widgets:
  - Telas: `ProfileScreen`, `OnboardingAuthScreen`, `EmailAuthScreen`, `InviteFriendsScreen`, `AvatarPickerScreen`, `RankingScreen`, `HomeScreen`, `ShopScreen`, `RedeemCodeScreen`, `NoLivesScreen`, `DailyRewardsScreen`
  - Widgets: `ScorePanel`, `StatusPanel`, `PauseOverlay`, `AuthBanner`, `DailyRewardOverlay`, `GameOverNoItemsOverlay`
- **CLAUDE.md / AGENTS.md:** atualizados com regras obrigatórias de tipografia (tabela de contextos, Fredoka no fundo, Nunito em cards/dialogs/sheets) e fase atual sincronizada

## [1.5.2] — 2026-05-07

### Added

- **EmailAuthScreen:** tela dedicada de e-mail/senha com toggle Entrar/Criar Conta, validação inline (formato de e-mail, mínimo 8 caracteres + 1 número, confirmação de senha), mostrar/ocultar senha e mensagens de erro em português
- **AvatarPickerScreen:** tela de seleção de avatar com grid dos 13 animais do jogo (tiles); acessível após cadastro e pela ProfileScreen
- **AvatarWidget:** widget reutilizável de avatar com suporte a tile animal, URL HTTP (Google/Apple) e inicial do nome sobre fundo verde
- **updateAvatar()** no SyncEngine e AuthController — persiste escolha de avatar no Firestore (otimista: atualiza local primeiro)
- Avatar com círculo verde de destaque na Home (topo centro)
- Botão de editar avatar (ícone lápis) na ProfileScreen

### Fixed

- Logo na tela de login (`OnboardingAuthScreen`) agora usa `HomeConstants.titleHeight(scale)` — mesmo tamanho responsivo da Home
- Textos sobre o fundo em `InviteFriendsScreen` agora usam `outlinedWhiteTextStyle` (legíveis)

## [1.5.1] — 2026-05-07

### Fixed

- **Auth:** `authServiceProvider` retornava `FakeAuthService` para os flavors `dev` e `tst`, fazendo o login com Google simular uma conta teste em vez de abrir o seletor de contas real. Agora `FirebaseAuthService` é usado para `prd`, `dev` e `tst`; `FakeAuthService` permanece apenas em contextos sem flavor definido (testes unitários/widget)

## [1.5.0] - 2026-05-07

### Changed

- Upgraded 47 packages to latest versions
- Bumped Firebase suite: firebase_core v4, firebase_auth v6, cloud_firestore v6
- Bumped Android Gradle Plugin to 8.12.1, google-services plugin to 4.4.2
- Migrated 11 StateNotifier → Notifier/AsyncNotifier (Riverpod 3)
- Rewrote Google Sign-In flow for google_sign_in 7.x (singleton + authenticate() API)
- Migrated Share.share() → SharePlus.instance.share() (share_plus 13)
- Bumped google_mobile_ads to 8.0.0, google_fonts 8.1, plus plugins to latest
- Fixed LivesNotifier.\_ready to complete after Hive box subscription (eliminates race in tests)
- Updated all test overrides from StateNotifier pattern to Riverpod 3 Notifier pattern
- Updated google_fonts font-cache seed hashes for google_fonts 8.1.0 in test config

## [1.4.7] — 2026-05-06

### Fixed

- **Bug crítico:** `IAPServiceImpl`, `FirestoreInviteRepository` e `FirestoreRankingRepository` escreviam itens no Hive com key `'inventory'` em vez de `'data'` — inventário nunca era atualizado por entregas externas (IAP, convites, recompensas de ranking)
- `IAPServiceImpl`: `PurchaseStatus.restored` agora entrega itens idempotentemente via Firestore; `PurchaseStatus.pending` não encerra a subscription, aguarda status final
- `InventoryNotifier`: `Box.watch(key: 'data')` recarrega estado automaticamente quando IAP ou ranking entregam itens diretamente no Hive — UI atualiza sem restart
- `LivesNotifier`: idem com `Box.watch(key: 'state')` para vidas recebidas via IAP ou ranking

### Added

- `IAPStartupService`: subscription permanente no `purchaseStream` inicializada pelo `AuthController` após login; processa compras pendentes de sessões anteriores de forma idempotente (`pending_orphan` no Firestore para auditoria)
- `iapServiceProvider`: aceita `--dart-define=USE_REAL_IAP=true` no flavor `tst` para ativar `IAPServiceImpl` real no sandbox das lojas
- `IAP.md`: guia completo para cadastrar produtos no Google Play Console e App Store Connect, configurar contas de teste sandbox, StoreKit Configuration e builds por ambiente
- `README.md`: tabela de builds com variantes IAP

## [1.4.6] — 2026-05-06

### Fixed — Fase 4 gaps

- `AuthController`: `registerInvite` chamado após cada login — lê `pending_ref` do Hive e registra convite no Firestore; corrige fluxo Sub-D onde `completeInviteReward` sempre retornava `false`
- `ProfileScreen`: adicionado botão "Convidar Amigos" que navega para `InviteFriendsScreen`
- `ProfileScreen`: "Restaurar compras" agora chama `iapService.restorePurchases()` (real em prd, no-op em dev) em vez de Snackbar stub

## [1.4.5] — 2026-05-06

### Added — Fase 4C: Convites + Anúncios Reais + IAP Real

#### Sub-D — Sistema de Convites

- `InviteService` — interface abstrata + `FakeInviteService` (in-memory, testável)
- `FirestoreInviteRepository` — convites persistidos no Firestore; recompensa de 2 vidas + 1× Bomba 2 para convidante e convidado
- `InviteController` — Riverpod notifier para geração de link; `inviteServiceProvider` usa Firestore em prd
- `InviteFriendsScreen` — implementação real com geração de link, botões Copiar e Compartilhar; `AuthBanner` para usuários não logados
- Deep link `olhabichim://invite?ref={userId}` capturado via `app_links` em cold start e foreground (AndroidManifest intent-filter + iOS URL scheme)
- Hook no `game_notifier`: convite completado automaticamente na 1ª partida do convidado

#### Sub-E — Anúncios Reais (Google Mobile Ads)

- `GoogleMobileAdsService` — substitui `FakeAdService` em prd; pré-carrega o próximo anúncio após cada exibição
- `adServiceProvider` usa `GoogleMobileAdsService` em prd, `FakeAdService` em dev/testes
- AdMob inicializado prd-only com `tagForChildDirectedTreatment=yes`, `maxAdContentRating=G`
- AndroidManifest: `com.google.android.gms.ads.APPLICATION_ID` (test App ID para dev)
- iOS Info.plist: `GADApplicationIdentifier` (test App ID para dev)

#### Sub-F — IAP Real (in_app_purchase)

- `IAPService` — interface abstrata + `FakeIAPService` (retorna `PurchaseResult.succeeded` com shareCode fake)
- `IAPServiceImpl` — purchase stream com `in_app_purchase`; entrega idempotente via Firestore (`purchases/{userId}/items/{purchaseId}`); gera ShareCode no Firestore (`shareCodes/{code}`)
- `IAPConfirmationSheet` — bottom sheet mostra nome do pacote, conteúdo (❤️🧨💣↩️), presente para amigo e preço; substitui `AlertDialog` simples
- `PurchaseSuccessSheet` — exibe ShareCode com botões Copiar e Compartilhar; `share_plus` integrado
- `ShopScreen` e `GameOverNoItemsOverlay` usam `IAPConfirmationSheet` + `IAPService` (Fake em dev)
- `iapServiceProvider` usa `IAPServiceImpl` em prd quando usuário logado

### Dependencies Added

- `app_links: ^6.1.1`
- `google_mobile_ads: ^5.1.0`
- `in_app_purchase: ^3.2.0`

## [1.4.4] — 2026-05-06

### Added — Fase 4B: Ranking Global Semanal + Ranking Lendas

- `WeekId` — cálculo determinístico de weekId ISO 8601 com reset sábado 21h UTC; testado em boundary de virada de ano
- `WeeklyRewardResult` — model imutável com tabela de recompensas por posição (1º–50º)
- `FirestoreRankingRepository` — ranking global semanal (globalTime, globalScore) e Ranking Lendas (4096, 8192) via Firestore; direct doc lookup com count query para rank; reward delivery ao inventário Hive
- `WeeklyRewardModal` — dialog de recompensa semanal com itens recebidos e botão Continuar
- `RankingController` — notifier Riverpod para verificação de recompensa semanal no startup

### Changed

- `RankingRepository` — novos métodos `checkAndClaimWeeklyReward`, `watchWeeklyTop`; `RankingEntry` ganha `userId` opcional; `submitScore` aceita `displayName` nomeado
- `rankingRepositoryProvider` — usa `FirestoreRankingRepository` no flavor `prd`; fallback para `FakeRankingService` em dev/debug
- `game_notifier` — submete `globalScore` (sempre) e `globalTime` (apenas em vitória) ao ranking após game over
- `SyncEngine.init()` — aceita `displayName` opcional; `FirebaseSyncEngine` usa displayName real do perfil nos entries de legendReached no Firestore

## [1.4.3] — 2026-05-06

### Fixed

- `ProfileScreen._NotLoggedIn`: ícone avatar `white54` sem fundo substituído por `CircleAvatar` com fundo `AppColors.primary`
- `ProfileScreen._LoggedIn`: texto "Sair" ganhou sombra de contorno via `outlinedWhiteTextStyle().copyWith(color: Colors.redAccent)`; ícone "Restaurar compras" de `white70` para `white`
- Flavor `tst` agora exibe **"Bichim TEST"** no launcher; `AndroidManifest.xml` corrigido para usar `@string/app_name` em vez de nome hardcoded

## [1.4.2] — 2026-05-06

### Fixed

- `OnboardingAuthScreen`: texto 'Olha o Bichim!' substituído pela `GameTitleImage` (logo); textos sobre fundo corrigidos com `outlinedWhiteTextStyle`
- `ProfileScreen`: textos sobre `GameBackground` corrigidos com `outlinedWhiteTextStyle` (eram ilegíveis sobre o `fundo.png`)

### Changed

- `AGENTS.md` e `CLAUDE.md`: adicionada regra obrigatória de legibilidade — todo texto sobre `GameBackground` deve usar `outlinedWhiteTextStyle()` ou `OutlinedText`

## [1.4.1] — 2026-05-06

### Fixed

- `PendingEvent.hiveTypeId` conflitava com `GameRecord.hiveTypeId` (ambos = 11) → app travava na splash screen com `HiveError: There is already a TypeAdapter for typeId 11`; corrigido para `12`
- Emulador Firebase ativado automaticamente com `FLAVOR=dev`, causando travamento em dispositivos físicos sem emulador rodando; agora requer `--dart-define=USE_EMULATOR=true` explícito
- Flavors Android inconsistentes: `prod` sem `applicationId` explícito, `src/prd/` nunca lido pelo Gradle (flavor chama `prod`), `defaultConfig.applicationId` com underscore divergindo do Firebase Console; tudo corrigido e `src/prod/google-services.json` criado
- `pubspec.yaml` com versão `1.2.10+1` divergindo do CHANGELOG; corrigido para `1.4.0+1`

### Changed

- README: seção de flavors/Firebase atualizada com tabela `prod`/`tst`, novos cenários de execução e flag `USE_EMULATOR`

## [1.4.0] — 2026-05-06

### Added (Fase 4A — Firebase + Auth + Sync Engine)

- `PlayerProfile` model com `AuthProvider` enum (google, apple, email)
- `PendingEvent` model + Hive adapter para eventos offline (Lendas, etc.)
- `AuthService` interface + `FakeAuthService` + `FirebaseAuthService` (prd)
- `SyncEngine` interface + `FakeSyncEngine` + `FirebaseSyncEngine` (prd)
- `SyncConflictResolver`: lógica de merge campo a campo (best value wins)
- `AuthController` Riverpod notifier com sign-in, sign-out e sync
- `OnboardingAuthScreen`: tela de login no primeiro launch (Google, Apple, Email)
- `ProfileScreen`: perfil do jogador acessível via avatar na HomeScreen
- `AuthBanner`: banner persistente para usuários sem conta
- Ícone de avatar na HomeScreen → navega para ProfileScreen
- Firebase inicializado em `main.dart` com flavors dev/prd
- Conexão ao emulador Firebase local no flavor dev (Auth 9099, Firestore 8080)
- `EMULATOR_HOST` configurável via `--dart-define` (Genymotion, WiFi, USB)
- `AdConfig`: constantes de anúncios com IDs de teste como default
- `FIREBASE.md`: guia completo de configuração Firebase
- Workflow de release CI (`.github/workflows/release.yml`) com injeção de secrets
- Security Rules de produção para Firestore

### Changed

- `README.md`: instruções de build/run por cenário (Genymotion, USB, produção)
- `.gitignore`: `firebase_options_*.dart` adicionado (contém API keys)

## [1.3.7] — 2026-05-05

### Added (Fase 3.8 — Documentação do framework de testes)

- `docs/TESTING.md`: guia completo de testes — Tier 1, APK Tier 2, como adicionar novo cenário (<5 min), troubleshooting de golden tests flaky
- Fase 3 marcada como concluída (subfases 3.0–3.8)

### Changed

- `README.md`: roadmap corrigido (Fase 3 era E2E Test Framework, não backend); seção de testes simplificada com link para `docs/TESTING.md`

## [1.3.6] — 2026-05-05

### Added

- CI GitHub Actions workflow (Fase 3.7): roda suite Tier 1 em todo PR/push para main
- Upload automático de golden diffs como artefato em caso de falha
- Badge de status CI no README

## [1.3.5] — 2026-05-05

### Added

- Fase 3.6: APK Tier 2 com `TestRunnerScreen` visual
  - `integration_test/tier2_runner.dart` — entry point do APK de testes (flavor `tst`)
  - `lib/testing/` — TestRunnerApp, TestRunnerScreen, TestResultsStore, share_results
  - Android flavor `tst` com `applicationIdSuffix .test` (instala em paralelo ao app prod)
  - Share button (📤) exporta JSON + PNG via share_plus
  - Demo mode (🎬) via `--dart-define=DEMO_MODE=true` suprime assertions
  - 6 cenários taggeados com `ScenarioTag.demo`
  - `lib/main_test.dart` stub documentando entry point alternativo

## [v1.3.4] — Fase 3.5 — Golden Tests

### Added

- 15 golden tests com `alchemist` (5 telas × 3 viewports: 360×640, 414×894, 800×1280)
- Telas cobertas: `HomeScreen`, `GameScreen`, `PauseOverlay`, `CollectionScreen`, `DailyRewardsScreen`
- `test/flutter_test_config.dart`: configura alchemist CI mode globalmente (fonteless, sem shadows, sem platform goldens)
- `test/e2e/golden/golden_tests.dart`: 15 `goldenTest()` organizados em grupos por viewport via `runGoldenTests()`
- 15 PNGs baseline em `test/e2e/goldens/ci/`
- Suite total: 95 testes (80 E2EScenarios + 15 golden)

## [1.3.3] - 2026-05-05

### Added (Fase 3.4 — Collection, Accessibility, Regression E2E)

- **14 novos cenários E2E** (total: 80 no Tier 1)
  - `collection.*` (6): count, locked cards "???", detail sheet, scientific name, funFact, progress bar
  - `accessibility.*` (4): home buttons Semantics labels, board Semantics, contrast score panel, overflow 360×640
  - `regression.*` (4): v1.2.7 header scale, v1.2.8 no progressive load, v1.2.9 continuar unpause, v1.2.10 collection persists
- Anotações `Semantics` adicionadas: `_HomeButton` (6 labels) e tabuleiro (`'Tabuleiro do jogo'`)

## [1.3.2] - 2026-05-04

### Added (Fase 3.3 — Persistence, Pause, Daily, Settings)

- **18 novos cenários E2E** (total: 66 no Tier 1)
  - `persistence.*` (8): inventário, vidas, recompensas, personal records, settings, game records, jogo em andamento
  - `pause.*` (4): botão pausar, reiniciar, system back, timer pausado
  - `daily.*` (2): streak incrementa, ciclo reseta após streak break
  - `settings.*` (4): reduce effects toggle+persist, blur desabilitado, haptics persist, locale PT-BR
- Infraestrutura: `LivesNotifier.awaitReady()` `@visibleForTesting` + guards em `AppLifecycleListener` para contexto de testes

## [1.3.1] - 2026-05-04

### Added (Fase 3.2 — Engine, Items e Nav)

- **25 novos cenários E2E** (total: 48 no Tier 1)
  - `engine.*` (10): swipe ↑↓←→, no-op, score, highscore, merge chain, spawn, gameover
  - `items.*` (8): bomb2/3 seleção, cancelamento, undo desabilitado, dim overlay, persistência, shop routing
  - `nav.*` (7 restantes): ranking, loja, recompensas, tutorial bottom sheet, back de coleção/configurações/jogo

## [1.3.0] - 2026-05-04

### Added (Fase 3.1 — E2E Flow Scenarios)

- **23 cenários E2E** cobrindo todos os flows principais do jogo (Tier 1 headless)
  - Pause / Resume / Back (regressão v1.2.9 protegida)
  - Game Over overlays — com e sem itens no inventário
  - Itens de inventário — undo1, bomb2, bomb3
  - Loja (ShopOverlay) — abertura e compra
  - Vitórias — milestones 2048, 4096, 8192 + continue after win
  - Recompensas diárias — claim e bloqueio same-day
  - Vidas — consumo, tela sem vidas, regeneração

### Changed

- `GameNotifier.debugSetState` agora chama `_stopTimer()` para evitar timers órfãos nos testes
- `GameTestHarness.boot()` desabilita Google Fonts runtime fetching (evita timeout 23s em testes headless)
- `GameTestHarness.teardown()` usa timeout em `Hive.close()` para tolerar writes async não-aguardados
- Adicionados `Key('inventory_bomb2')`, `Key('inventory_bomb3')`, `Key('inventory_undo1')`, `Key('inventory_undo3')` em `inventory_bar.dart`

## [1.2.10] - 2026-05-04

### Fixed

- **Coleção resetava ao fechar e reabrir o app** — mesmo tendo desbloqueado animais em níveis altos, ao reabrir o app a tela de Coleção mostrava todos os animais bloqueados (`0/13 animais descobertos`). Causa-raiz: `main.dart` chamava `.load()` em `reduceEffectsProvider`, `inventoryProvider` e `dailyRewardsProvider` no boot, mas **não chamava em `personalRecordsProvider`**. Como `PersonalRecordsNotifier()` inicializa com `const PersonalRecords()` (`highestLevelEver = 0`), o estado em memória ficava zerado a cada cold start mesmo com o Hive populado — `updateHighestLevel()` salvava certinho, mas ninguém lia de volta. Como a tela de Coleção deriva o desbloqueio direto de `highestLevelEver`, todos os animais voltavam a aparecer como `???`. Fix: adicionar `await container.read(personalRecordsProvider.notifier).load()` em `main.dart`, seguindo o mesmo padrão dos outros notifiers persistidos.

### Tests

- Novo teste de regressão em `personal_records_notifier_test.dart` que verifica round-trip de `highestLevelEver` através de duas instâncias do `ProviderContainer` (simulando reinicialização do app). 340/340 passing.

## [1.2.9] - 2026-05-04

### Fixed

- **"Continuar Jogo" na Home não despausava o jogo quando o jogador voltava via botão back do Android** — ao pausar o jogo e usar o back do sistema para voltar à Home (em vez do botão "Menu" no overlay, que já chamava `resume()`), o `gameProvider` global ficava com `isPaused = true`. Como `GameScreen` não tinha `PopScope`, o pop default não despausava. Resultado: ao clicar "Continuar Jogo", o jogador caia novamente no `PauseOverlay` e precisava clicar "Continuar" pela segunda vez. Fix: `_continueGame()` agora chama `gameProvider.notifier.resume()` antes de navegar — semântica clara: clicar "Continuar" continua o jogo.

## [1.2.8] - 2026-05-04

### Fixed

- **Splashscreen e Home carregando progressivamente em emuladores (Genymotion)** — após a splash nativa do Android 12+ (ícone do app), a `splashscreen.png` sumia rápido demais e a Home aparecia com os 6 ícones e a logo do título carregando um por um, com vários segundos de delay entre eles. Causa-raiz: as chamadas `precacheImage` em `app.dart` eram fire-and-forget (sem `await`/`Future.wait`), o timer fixo de 1500ms da `SplashScreen` navegava sem aguardar o precache, a própria `splashscreen.png` (3.5 MB) não estava na lista de precache (decodificava on-the-spot, podia exceder os 1500ms), e os títulos do jogo (`title_brown.png`/`title_orange.png`) não eram precacheados. Em devices físicos rápidos o problema passava despercebido, mas no Genymotion ficava muito visível.

### Changed

- Lista de assets críticos extraída para `lib/core/asset_precache.dart` com função `criticalAssetPaths()` (testável) e `precacheCriticalAssets(context)` que decodifica a `splashscreen.png` primeiro (await) e o resto em paralelo (Future.wait).
- `SplashScreen` agora aceita uma `precacheFuture` opcional e aguarda ela completar (com timeout-cap de 4s e duração mínima de 1500ms) antes de navegar para a Home, garantindo que tudo esteja decodificado quando a Home aparecer.
- Adicionados ao precache: `splashscreen.png`, `title_brown.png`, `title_orange.png` (que estavam ausentes).
- Timer de navegação refatorado para `Timer` cancelável no `dispose` (evita pending timers em testes).

## [1.2.7] - 2026-05-04

### Changed

- **Header cresce mais agressivamente quando há folga vertical** — a função de cap horizontal do header foi recalibrada com base na medida real do `StatusPanel` (~146dp) e na constraint correta do `Row` (`host + max(status, pause) ≤ boardSide`, já que o `Spacer` absorve folga). Antes a fórmula reservava 130dp para status+pause juntos e usava divisor 230, o que limitava o header a ~1.13× mesmo com espaço sobrando. Agora o divisor é 152 (só o host) e a reserva é 160dp (status com margem), permitindo o header crescer até ~1.31× em telas com folga vertical (ex: 414×894dp). Header e inventário agora usam escalas independentes (`headerScale`/`invScale`).

## [1.2.6] - 2026-05-04

### Changed

- **Game screen: elementos crescem além de 1.0× quando há folga vertical** — em dispositivos onde o tabuleiro (limitado pela largura) não consome toda a altura disponível, o anfitrião, indicador de vidas, botão pausar, ícones do inventário e demais elementos do header crescem proporcionalmente para preencher o espaço (até 1.5× do tamanho de design). Antes o scale era clampado em 1.0, deixando grandes faixas vazias acima e abaixo do tabuleiro em telas com mais de ~844dp de altura útil. A escala respeita também a largura disponível para o header (host + status + pause) e a fileira do inventário, evitando overflow.

## [1.2.5] - 2026-05-04

### Changed

- **Layout adaptativo: `vmin` em vez de `vheight`** — tanto `HomeScreen` quanto `GameScreen` agora calculam `scale = min(width/390, height/844)` (equivalente ao `vmin` do CSS). Isso garante que elementos não transbordem horizontalmente em tablets ou telas largas. Antes o scale usava apenas a altura, o que podia gerar elementos grandes demais em paisagem.

## [1.2.4] - 2026-05-04

### Changed

- **Layout adaptativo da tela de jogo**: todos os elementos (animal, coração/vidas, botão pausar, ícones do inventário) agora escalam proporcionalmente à altura disponível usando `scale = availableHeight / 844` (844dp = altura de design base), com clamp no tamanho máximo original. O tabuleiro recebe o espaço restante via `AspectRatio(1.0)` e sempre é quadrado. Em telas compactas (~640dp) o tabuleiro passa de ~234dp para ~360dp; em telas normais (~844dp) o layout permanece idêntico ao anterior.

## [1.2.3] - 2026-05-04

### Fixed

- **Tabuleiro retangular em telas compactas** (ex: 640dp): substituído `SizedBox(boardSide×boardSide)` — cujo cálculo usava `headerH=72` muito abaixo da altura real do `GameHeader` (~238dp) — por `AspectRatio(1.0)` + `LayoutBuilder` interno. O tabuleiro agora é sempre quadrado em qualquer tamanho de tela, usando todo o espaço disponível entre o header e o inventário.

## [1.2.2] - 2026-05-04

### Changed

- **Estilo dos botões de ação** ("Novo jogo" / "Continuar Jogo"): fundo laranja `#FF8C42`, bordas `radius 12`, texto branco com contorno preto via `OutlinedText` + Nunito bold — igualado aos botões da tela de pausa
- **Layout compacto corrigido** (telas ≤640dp, ex: Genymotion 768×1280): título reduzido de 200dp para 130dp, alinhamento vertical ajustado de `-0.2` para `-0.5` e gap de 20dp para 16dp — elimina a sobreposição dos botões Recompensas/Ranking sobre os botões de jogo
- Telas normais (>700dp): alinhamento vertical ajustado de `-0.2` para `-0.3` para garantir folga acima dos botões inferiores

## [1.2.1] - 2026-05-04

### Changed

- **Polimento da HomeScreen**: logo e botões de ação movidos levemente para cima (`Align(0, -0.2)` em vez de `Center`), deixando o logo acima do pássaro conforme referência visual
- Botões inferiores com mais respiro: `edgePad` 8→12px, `rowBaseBottom` 8→24px, `rowTopBottom` 120→148px (telas normais) — elimina o encostamento nas bordas e entre as fileiras

## [1.2.0] - 2026-05-04

### Added

- **Redesign da HomeScreen** (Fase 2.13): 6 botões ilustrados PNG posicionados nos cantos e base da tela via `Stack + Positioned`, conforme referência visual `menu.jpeg`
- `HomeConstants`: constantes de layout responsivas com breakpoint 700dp (suporte a 360×640 e 390×844)
- Contorno branco nos botões PNG via `ColorFiltered + Transform.scale(1.06)` — sem editar assets
- Badge vermelho condicional no botão Recompensas Diárias quando há recompensa disponível
- Botões de ação centrais `Continuar Jogo` / `Novo jogo` estilo cápsula semi-transparente (Fredoka 20dp)
- `debugSetState` com `@visibleForTesting` no `GameNotifier` para testes de widget

### Changed

- `HomeScreen` removeu `LivesIndicator` — indicador de vidas permanece apenas na `GameScreen`
- `_HomeCard` (grid de ícones Material) substituído pelos botões ilustrados PNG
- `_PlayButton` substituído pelos `_ActionButton` separados por estado de partida salva

### Chore

- Assets de inventário movidos de `assets/icons/inventory/` para `assets/images/inventory/`
- Pasta `assets/icons/` removida; todos os assets consolidados sob `assets/images/`
- 6 PNGs de `assets/images/home/` registrados no `pubspec.yaml` e adicionados ao `precacheImage`

## [1.1.4] - 2026-05-04

### Fixed

- Itens de Desfazer podem ser usados consecutivamente sem precisar fazer uma jogada entre os usos
- Desfazer 3 pode ser usado várias vezes seguidas, voltando 3 jogadas a cada uso (desde que haja histórico suficiente)
- Histórico de undo agora é ilimitado (antes era limitado a 3 entradas)
- Desfazer 1 e Desfazer 3 ficam desabilitados (cinza) quando não há jogadas suficientes para o item
- Ao tentar usar um item de Desfazer desabilitado, exibe dialog explicativo em vez de abrir a loja

## [1.1.3] - 2026-05-03

### Fixed

- RankingScreen: TabBar "Por Tempo / Por Pontuação" agora tem fundo verde com texto branco — legível sobre o GameBackground
- RankingScreen: texto de estado vazio substituído por OutlinedText (branco + contorno preto)

## [1.1.2] - 2026-05-03

### Fixed

- ShopOverlay agora exibe a seção "Itens avulsos" igual à loja principal
- Item avulso correspondente ao ícone tocado é destacado com borda laranja no ShopOverlay
- Assistir anúncio para ganhar item no game over não entrega mais vida extra

## [1.1.1] - 2026-05-03

### Fixed

- Assistir anúncio para ganhar item no game over não entrega mais uma vida extra — o fluxo de item agora apenas contabiliza o anúncio no limite diário

## [1.1.0] - 2026-05-03

### Added

- Dois novos animais: **Peixe-boi** (nível 12, 4096) e **Jacaré** (nível 13, 8192)
- `VictoryChoiceDialog` — ao atingir 2048/4096/8192 o jogador escolhe Continuar ou Encerrar; cronômetro pausa enquanto decide
- Recompensas ao continuar além do 4096: 5 vidas + 2×Bomba2 + 1×Bomba3 + 2×Desfazer1 + 1×Desfazer3
- `PersonalRecords` — contagem de vezes que cada marco foi atingido, com data da primeira vez
- `GameRecord` — histórico local das últimas 20 partidas (tempo, pontuação, nível máximo)
- `RankingScreen` — exibe recordes pessoais (Por Tempo / Por Pontuação) e tabela Lendas (mock)
- Ranking acessível pela Home (card "Ranking" agora navega para a tela)
- `ShopOverlay` acessível pelos ícones desabilitados do inventário (Fase 2.11 integrada neste release)

### Changed

- `GameConstants.maxLevel` atualizado de 11 → 13
- `CollectionScreen` exibe `X/13 animais descobertos` (era `/11`)
- Configuração "Reduzir Efeitos Visuais" movida para a aba Gameplay da `SettingsScreen` (removida do `PauseOverlay`)
- Seletor de idioma (PT-BR/EN) removido da `SettingsScreen` (não implementado)

## [1.0.7] - 2026-05-03

### Fixed

- Cards de itens avulsos na loja agora têm espaçamento reduzido — removida `Padding` duplicada e margem interna excessiva
- Último item ("Desfazer 3") não é mais cortado: `ListView` agora tem `padding` inferior de 32 dp

## [1.0.6] - 2026-05-03

### Fixed

- "Itens avulsos" agora usa `OutlinedText` (branco com contorno preto) — legível sobre o fundo de floresta
- Último card de item avulso ("Desfazer 1") não é mais cortado na borda inferior da tela

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
