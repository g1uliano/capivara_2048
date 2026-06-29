# Tutorial interativo — sandbox 4×4 que ensina as regras de verdade

**Data:** 2026-06-29
**Fase:** 6 (polimento, l10n, acessibilidade, lançamento)
**Status:** aprovado, pronto para plano de implementação

## Problema

Filhos de usuários jogaram e disseram simplesmente que "não entenderam o jogo".
Não ficou claro que:

1. ao deslizar o dedo, **todas** as peças do tabuleiro se movem juntas naquela
   direção;
2. só peças de **valor igual** se juntam para evoluir.

O tutorial atual (`TutorialScreen`, 5 páginas) tem duas páginas "interativas"
(`tutorial_movement_page.dart` e `tutorial_fusion_page.dart`) que usam o widget
`tutorial_mini_board.dart` — uma **tirinha 1D de 2 células numa única linha**.
Essa tirinha é a raiz do problema: com no máximo 2 peças numa linha, ela não
consegue demonstrar nem "tudo desliza junto" nem "só os iguais se fundem",
porque nunca há um tabuleiro com várias peças diferentes ao mesmo tempo.

Pedido complementar do usuário: o tutorial **também** deve demonstrar as
ferramentas existentes (bomba, desfazer, vidas) e o que dá pra fazer com elas —
não só listá-las em cards de texto.

## Objetivo

Substituir as páginas interativas fracas por um **sandbox guiado num tabuleiro
4×4 real** (mesmo tamanho do jogo) onde a criança aprende as regras jogando de
verdade, e transformar a página de ferramentas numa **demonstração interativa**
(toca-e-vê). Critério de sucesso: uma criança que nunca jogou consegue, ao final
do tutorial, mover o tabuleiro, fundir dois iguais e entender as três
ferramentas — sem depender de um adulto explicando.

## Decisão de arquitetura

Toda a lógica real do jogo já vive no `GameEngine` puro
(`lib/domain/game_engine/game_engine.dart`):

- `move(GameState, Direction)` — desliza tudo, funde só iguais, nasce peça nova,
  empilha estado anterior em `undoStack`;
- `removeTiles(GameState, positions)` — efeito da bomba;
- `undoStack` no `GameState` — base do desfazer.

**Cada página interativa do tutorial cria sua própria instância local de
`GameEngine` + `GameState`** (com `Random` semeado para nascimentos
previsíveis) e dirige o motor de verdade, **sem tocar no `gameProvider`
global**. Assim o tutorial nunca diverge das regras reais e não duplica lógica.

**Alternativa descartada:** board scriptado próprio, sem o engine. Rejeitada
porque duplicaria as regras e poderia divergir do jogo real. Reusar o engine é
menos código **e** mais fiel.

### Reuso de widgets

- `BoardWidget` (`lib/presentation/widgets/board_widget.dart`) hoje lê
  `ref.watch(gameProvider).board` direto. Adicionar um **parâmetro `board`
  opcional** (`List<List<Tile?>>? board`): se vier, usa; senão, mantém o
  comportamento atual de assistir o provider global. Mudança de ~3 linhas, sem
  efeito no jogo. O tutorial passa seu board local e fica pixel-idêntico ao
  jogo.
- `TileWidget` já é standalone — reusado direto.
- A lógica de resolver a direção da swipe a partir da velocidade do gesto
  (`_resolveDirection` em `tutorial_mini_board.dart`) é puxada para o novo
  `tutorial_board.dart` antes da mini-board ser deletada.

## Fluxo novo

São **4 páginas** (era 5). `TutorialScreen` mantém o formato de wizard com
PageView, dots e botões Voltar/Próximo/Pular.

```
1. Bem-vindo          (inalterada)
2. Sandbox guiado 4×4 (NOVO — substitui Mover + Juntar)
3. Ferramentas        (REESCRITA — demo interativa, era cards estáticos)
4. Final              (inalterada)
```

`_totalPages` muda de 5 para 4. O gating de "Próximo" travado em página
interativa segue o padrão atual (`_page1Done`/`_page2Done` → adaptar para as
páginas 1 e 2, 0-indexadas: sandbox e ferramentas).

### Página 2 — Sandbox guiado 4×4

Uma única página com **3 passos encadeados**. O texto de instrução/dica troca
conforme o passo avança. "Próximo" fica travado até o passo C graduar.
Tabuleiro renderizado com `BoardWidget(board: estadoLocal.board)`.

**Passo A — "Deslize pra mover tudo"**
- Board semeado com ~4 bichos, **todos de níveis diferentes** (nenhuma fusão
  possível), espalhados de modo que um swipe os faça deslizar visivelmente.
- Dica com seta animada.
- Qualquer swipe válido → `engine.move(...)` → todas as peças deslizam juntas
  para a parede.
- **Conclui** no primeiro movimento que muda o board (`anyChanged`).
- Mensagem de reforço: *"Viu? Todos foram juntos!"* → avança para o passo B.

**Passo B — "Junte dois iguais"**
- Board semeado com **duas tanajuras na mesma linha/coluna** + ao menos um bicho
  **diferente** ao lado (para a criança ver que ele **não** se funde).
- Dica: *"Deslize pra juntar as duas tanajuras."*
- **Conclui** quando ocorre uma fusão (detectada por aumento de `maxLevel` ou
  ganho de score após o move).
- Mensagem: *"Você criou um bicho novo! 🎉"* (e, opcional, callout curto de que o
  bicho diferente continuou inteiro). → avança para o passo C.

**Passo C — "Agora é com você"**
- Jogo livre real: a cada jogada nasce peça nova (engine normal).
- Dica de meta: *"Junte mais alguns bichos!"*
- **Gradua** após ~2 fusões (ou ao alcançar nível 3) → mensagem *"Você pegou o
  jeito! 🌿"* destrava o botão "Próximo".

### Página 3 — Ferramentas (demo guiada toca-e-vê)

Reescreve `tutorial_items_page.dart`. Usa engine/estado local próprio e
**reusa os widgets de overlay reais do jogo** para que o visual e o fluxo sejam
idênticos aos da partida real (requisito do usuário).

**Reuso dos overlays reais.** O `GameNotifier` é acoplado (áudio, persistência
em prefs, gravação de recordes, sync Firestore, dedução de inventário), então
dirigir o `gameProvider` real corromperia o jogo salvo do jogador — descartado.
Em vez disso, o tutorial mantém `GameState`/`GameEngine` locais e reusa só os
widgets visuais:

- `BombExplosionOverlay` e `VhsRewindOverlay` já são **standalone** (recebem
  `positions`/`isBomb3`/`isUndo3` + `onComplete`, sem provider) → reuso
  **verbatim**, são literalmente o efeito da partida real.
- `BombGridOverlay` e `BombDimOverlay` hoje leem `gameProvider`/`notifier`.
  Ganham **params opcionais** (`board`, `selected`, `maxTiles`, `onTapCell`,
  `onCancel`), com default mantendo o comportamento atual de provider — mesmo
  padrão do `BoardWidget`. O tutorial passa o estado local e usa **os mesmos
  widgets**, mesmos pixels, mesmo fluxo de seleção.

A única lógica nova é a maquininha de estado local da bomba — espelha
`enterBombMode`/`selectBombTile`/`confirmBomb` do `GameNotifier` em poucas
linhas sobre o `GameState` local, **sem** áudio/persistência/sync.

**Bomba**
- Board montado meio enroscado. Botão de bomba do tutorial com a dica
  *"Encrencou? Toque na bomba 💣"*.
- Toque na bomba → entra em modo seleção: `BombDimOverlay` ("Selecione N peças
  para destruir") + `BombGridOverlay` (células tocáveis), idênticos ao jogo.
- Ao selecionar as N peças → `BombExplosionOverlay` toca → `GameEngine.removeTiles`
  limpa as células. Mesmo fluxo visual da partida real.
- Trava até a explosão completar.

**Desfazer**
- O tutorial faz/mostra uma jogada e então: *"Errou? Toque em desfazer ↩"* →
  toque → `VhsRewindOverlay` (efeito VHS real) toca e, ao completar, restaura o
  estado anterior via `undoStack`.
- Trava até o toque acontecer.

**Vidas**
- Mostra o medidor de corações (`LivesIndicator`) + texto curto explicando que
  cada partida custa uma vida e elas se regeneram com o tempo.
- **Não-interativo** — vidas é um recurso, não um toque no tabuleiro.

> O **disparo** da bomba/desfazer no tutorial é um botão simples do tutorial, não
> a `InventoryBar` completa (acoplada a `inventoryProvider`/contagens). Tudo que a
> criança vê **depois** de tocar — dim, grade de seleção, explosão, rewind VHS —
> são os widgets reais.

### Páginas 1 e 4 — Bem-vindo e Final

Inalteradas (`tutorial_welcome_page.dart`, `tutorial_finale_page.dart`).

## Arquivos afetados

| Ação | Arquivo |
|------|---------|
| **Novo** | `presentation/screens/tutorial/pages/tutorial_sandbox_page.dart` (passos A/B/C, engine local) |
| **Novo** | `presentation/screens/tutorial/widgets/tutorial_board.dart` (swipe + tap, dirige engine local, usa `BoardWidget`) |
| **Reescrever** | `presentation/screens/tutorial/pages/tutorial_items_page.dart` → demo interativa de ferramentas (reusa overlays reais) |
| **Editar (~3 linhas)** | `presentation/widgets/board_widget.dart` → parâmetro `board` opcional |
| **Editar** | `presentation/widgets/bomb_grid_overlay.dart` → params opcionais (`board`/`selected`/`onTapCell`), default = provider |
| **Editar** | `presentation/widgets/bomb_selection_overlay.dart` (`BombDimOverlay`) → params opcionais (`maxTiles`/`onCancel`), default = provider |
| **Reuso verbatim (sem editar)** | `presentation/widgets/bomb_explosion_overlay.dart`, `presentation/widgets/vhs_rewind_overlay.dart` (já standalone) |
| **Editar** | `presentation/screens/tutorial/tutorial_screen.dart` → lista de páginas (4), `_totalPages`, gating das páginas interativas |
| **Deletar** | `presentation/screens/tutorial/widgets/tutorial_mini_board.dart` |
| **Deletar** | `presentation/screens/tutorial/pages/tutorial_movement_page.dart` |
| **Deletar** | `presentation/screens/tutorial/pages/tutorial_fusion_page.dart` |

`tutorial_controller.dart`, `tutorial_scaffold.dart` e `tutorial_dots_indicator.dart`
não mudam (o controller só persiste o flag de conclusão; o scaffold e os dots já
recebem `totalPages` por parâmetro).

## Testes

- **Widget test** novo: simula uma swipe no `tutorial_board` e confirma que o
  passo avança (gating do sandbox) — o menor teste que falha se o gating
  quebrar.
- `GameEngine` já tem cobertura unitária (regras de move/merge/remove) — não
  precisa de teste novo de regras.
- **Goldens:** os goldens do tutorial (Fase 3.5, `alchemist`) precisarão ser
  regenerados no CI após a mudança de páginas. Conforme memória do projeto,
  goldens falham localmente por design e o CI os regenera — não é bug.

## Simplificações deliberadas (ponytail)

- **Strings PT-BR hardcoded** nas páginas do tutorial, seguindo o padrão atual
  (as páginas existentes não usam `intl`). Migrar para `intl` fica fora de
  escopo aqui; se desejado, é um passo separado que cobre o tutorial inteiro.
- **Disparo das ferramentas é um botão simples do tutorial**, não a `InventoryBar`
  completa (acoplada a `inventoryProvider`). Os efeitos visíveis (dim, grade de
  seleção, explosão, rewind VHS) usam os widgets reais. (`// ponytail:` onde o
  botão de disparo vive.)
- O tutorial dirige `GameEngine`/`GameState` locais — **não** integra com vidas,
  inventário, sync ou score reais. É um ambiente isolado só para ensinar; os
  overlays reais são reusados só pela camada visual.

## Tipografia / UI (regras obrigatórias do projeto)

- Texto sobre o fundo do jogo: `GoogleFonts.fredoka()` + `OutlinedText` /
  `GlassPanel` (blocos título+parágrafo). Sem `Colors.white` puro sem outline.
- Reusar `GlassPanel` para os blocos de instrução, como nas páginas atuais.
- Tudo em português simples, sem termos em inglês na UI ("deslize", "junte",
  "desfazer", "peça/bicho" — nunca "swipe", "merge", "tile", "undo").
