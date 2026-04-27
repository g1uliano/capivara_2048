# 🦫 Capivara 2048 — Design Concept (Consolidado v2)

> Documento de especificação para desenvolvimento. Pensado para ser alimentado em ferramentas como Claude Code para implementação iterativa.
>
> **Status atual:** Fase 2.3.9 concluída ✅ (v0.6.0) — fundo do jogo via PNG (`fundo.png`), `LivesStatusBanner` com 4 estados visuais (Completo/Bônus/Restando/Sem vidas) + animações fade/scale, `PauseButtonTile` tile-sized fixo no cabeçalho, `GameScreen` refatorado para `ConsumerWidget` sem pause flutuante. 143 testes passando.
>
> **Próximo:** **Fase 2.4 — Áudio** — pool de `AudioPlayers`, sons de merge/game-over/vitória, música de fundo.
>
> **Mudanças principais nesta versão (2.3.9):**
> - **Fundo do jogo via PNG** — `GameBackground` usa `DecoratedBox`+`DecorationImage(BoxFit.cover)` com fallback `#D4F1DE`; `precacheImage` no boot
> - **`LivesStatusBanner`** — pill com 4 estados: "Completo" (verde `#66BB6A`), "Bônus" (dourado `#FFD54F`), "Restando MM:SS" (laranja `#FFA726`), "Sem vidas" (vermelho `#EF5350`); fade 300ms + scale positivo 1→1.1→1 (200ms)
> - **`PauseButtonTile`** — botão tile-sized (72dp) com ícone pause + "Pausar", `FittedBox(scaleDown)`, animação tap 0.95
> - **`GameScreen` → `ConsumerWidget`** — removidos `_pauseTop`, `_headerKey`, `_updatePausePosition`; novo cabeçalho `Row([HostBanner, Expanded(StatusPanel), PauseButtonTile])`

---

## 1. Visão Geral

**Capivara 2048** é um puzzle game multiplataforma inspirado na mecânica clássica do 2048, onde os números tradicionais são acompanhados por animais da fauna brasileira. O objetivo final é alcançar a **Capivara Lendária**, o "2048" do jogo, no menor tempo possível ou com o maior número.

### 1.1 Pitch em uma frase
"Combine animais brasileiros em um tabuleiro 4x4, descubra a Capivara Lendária e dispute o ranking global."

### 1.2 Objetivos do jogador
1. **Atingir 2048** (Capivara Lendária) no menor tempo possível
2. **Atingir o maior número possível** — continuar jogando depois do 2048

### 1.3 Diferenciais
- **Identidade brasileira**: fauna nacional como protagonista
- **Apelo visual limpo**: tile branco com animal em marca d'água + número grande, contorno colorido
- **Anfitrião dinâmico**: animal correspondente ao maior tile da partida atual aparece acima do tabuleiro
- **Free-to-play justo**: sistema de vidas, itens, loja, anúncios opcionais, recompensas diárias e convites
- **Competitivo**: ranking global semanal + ranking pessoal vitalício
- **Mascote forte**: a Capivara como ícone do jogo

### 1.4 Público-alvo
- **Primário**: jogadores casuais de puzzle (8–45 anos)
- **Secundário**: crianças (jogo é adequado e ensina sobre fauna brasileira)
- **Terciário**: brasileiros com afinidade cultural, público educacional, turistas

---

## 2. Stack Técnica

### 2.1 Framework principal
**Flutter 3.x** (Dart) — multiplataforma único para iOS, Android, Web e Desktop.

### 2.2 Bibliotecas recomendadas
| Categoria | Biblioteca | Uso |
|---|---|---|
| Estado | `flutter_riverpod` | Gerenciamento de estado |
| ID | `uuid` | IDs dos tiles para animação |
| Animações | `flutter_animate` | Transições suaves |
| Áudio | `audioplayers` ou `just_audio` | Sons e música (Fase 5) |
| Persistência | `hive` + `shared_preferences` | Local |
| Tipografia | `google_fonts` | Fredoka, Nunito |
| Imagens | `Image.asset` (Flutter nativo) | PNGs dos animais e ícones |
| Haptic | `flutter` nativo (HapticFeedback) | Vibração |
| Localização | `flutter_localizations` + `intl` | PT-BR / EN |
| Backend | `firebase_core` + `cloud_firestore` + `firebase_auth` | Ranking, contas |
| Anúncios | `google_mobile_ads` | Recompensados de 30s |
| Compras | `in_app_purchase` | Loja |
| Compartilhamento | `share_plus` + `app_links` | Códigos de resgate |
| Blur (UI) | `flutter` nativo (`BackdropFilter` + `ImageFilter.blur`) | Efeito vidro fosco |

### 2.3 Estrutura de pastas
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
├── data/
│   ├── models/
│   ├── repositories/
│   ├── animals_data.dart
│   └── shop_data.dart
├── domain/
│   ├── game_engine/        ✅
│   ├── lives_system/       ✅
│   ├── inventory_system/   ✅
│   ├── ranking/
│   ├── rewards/
│   └── codes/
├── presentation/
│   ├── screens/
│   │   ├── home/           ✅
│   │   ├── game/           ✅
│   │   ├── debug/          ✅ (galeria de animais)
│   │   ├── shop/
│   │   ├── ranking/
│   │   ├── collection/
│   │   ├── daily_rewards/
│   │   ├── invite_friends/
│   │   ├── settings/
│   │   └── tutorial/
│   ├── widgets/
│   │   ├── board_widget.dart            ✅
│   │   ├── tile_widget.dart             ✅
│   │   ├── score_panel.dart             ✅
│   │   ├── status_panel.dart            ✅ (refatorado pra acomodar pause tile-sized na 2.3.9)
│   │   ├── host_banner.dart             ✅
│   │   ├── host_artwork.dart            ✅
│   │   ├── game_background.dart         ✅ (PNG na 2.3.9)
│   │   ├── lives_indicator.dart         ✅ (faixa estilizada na 2.3.9)
│   │   ├── lives_status_banner.dart     ← Fase 2.3.9 (faixa "Completo/Bônus/Restando")
│   │   ├── pause_button_tile.dart       ← Fase 2.3.9 (botão tile-sized)
│   │   ├── outlined_text.dart           ✅
│   │   ├── pause_overlay.dart           ✅
│   │   ├── inventory_bar.dart           ✅
│   │   ├── inventory_item_button.dart   ✅
│   │   ├── confirm_use_dialog.dart      ✅
│   │   ├── bomb_selection_overlay.dart  ✅
│   │   └── animal_card.dart
│   └── controllers/
└── assets_manifest.dart
assets/
├── images/
│   ├── fundo.png                     ← Fase 2.3.9 (fundo do jogo, substitui cor sólida)
│   ├── animals/tile/                 ← PNGs dos tiles ✅
│   │   ├── Tanajura.png ... Capivara.png (11 arquivos)
│   ├── animals/host/                 ← PNGs do anfitrião ✅
│   │   ├── Tanajura.png ... Capivara.png (11 arquivos)
├── icons/inventory/                  ← PNGs dos ícones do inventário ✅
│   ├── bomb_2.png, bomb_3.png, undo_1.png, undo_3.png
├── sounds/animals/                   ← Fase 5
├── sounds/ui/                        ← Fase 5
├── music/                            ← Fase 5
└── fonts/
```

> **Nota sobre `fundo.png`:** o arquivo já está disponível em `assets/images/fundo.png`. A integração efetiva é feita na Fase 2.3.9 item C.

---

## 3. Mecânica de Jogo

### 3.1 Regras básicas
- Tabuleiro **4x4** com 16 células
- Swipe nas 4 direções: ↑ ↓ ← →
- Peças iguais que colidem se fundem em uma de nível superior
- Nova peça a cada movimento válido (90% nível 1, 10% nível 2)
- **Game Over:** tabuleiro cheio sem movimentos — consome 1 vida (ver 3.4)
- **Vitória:** Capivara Lendária (nível 11) formada — pode continuar

### 3.2 Pontuação e tempo
- Cada merge soma o valor da peça resultante à pontuação
- Tabela de valores: nível 1 = 2 pts ... nível 11 = 2048
- **Cronômetro:** começa na primeira peça, para ao formar 2048
- **High score pessoal**: maior pontuação alcançada
- **Maior nível alcançado**: nível mais alto formado (1–11)

### 3.3 Algoritmo de movimento (Fase 1)
1. Para cada linha/coluna na direção do swipe:
   - Filtrar células não-vazias mantendo ordem
   - Fundir pares iguais consecutivos
   - Preencher restante com células vazias
2. Se mudou: gerar nova peça
3. Verificar game over e vitória

### 3.4 Regra crítica: quando uma vida é consumida
**A vida é consumida APENAS no momento do Game Over.**

| Ação | Consome vida? |
|---|---|
| Iniciar nova partida | ❌ Não |
| Sair pro menu durante partida | ❌ Não |
| Continuar partida salva | ❌ Não |
| Reiniciar partida em andamento | ❌ Não |
| **Tabuleiro tranca (Game Over)** | ✅ **Sim, 1 vida** |
| Atingir 2048 (vitória) | ❌ Não |

> **Limite pra iniciar:** ≥1 vida disponível.

---

## 4. Os Animais (Tiles)

| Nível | Valor | Animal | Justificativa | Cor (contorno) | PNG tile | PNG host |
|---|---|---|---|---|---|---|
| 1 | 2 | **Tanajura** | A famosa rainha alada que anuncia as chuvas | `#C0392B` | `tile/Tanajura.png` | `host/Tanajura.png` |
| 2 | 4 | **Lobo-guará** | Ícone do cerrado, estrela da nota de R$ 200 | `#E67E22` | `tile/LoboGuara.png` | `host/LoboGuara.png` |
| 3 | 8 | **Sapo-cururu** | Guardião noturno, figura clássica do folclore | `#8D6E63` | `tile/Cururu.png` | `host/Cururu.png` |
| 4 | 16 | **Tucano** | Embaixador visual das matas brasileiras | `#FFB300` | `tile/Tucano.png` | `host/Tucano.png` |
| 5 | 32 | **Sagui** | Pequeno primata curioso, ágil e expressivo | `#A0826D` | `tile/Sagui.png` | `host/Sagui.png` |
| 6 | 64 | **Preguiça** | Mestre zen da copa das árvores | `#BCAAA4` | `tile/Preguica.png` | `host/Preguica.png` |
| 7 | 128 | **Mico-leão-dourado** | Ícone absoluto da conservação brasileira | `#FF8F00` | `tile/MicoLeao.png` | `host/MicoLeao.png` |
| 8 | 256 | **Boto-cor-de-rosa** | Misticismo dos rios, paleta única | `#F48FB1` | `tile/Boto.png` | `host/Boto.png` |
| 9 | 512 | **Onça-pintada** | Predador alfa supremo | `#FBC02D` | `tile/Onca.png` | `host/Onca.png` |
| 10 | 1024 | **Sucuri** | Gigante das águas profundas | `#2E7D32` | `tile/Sucuri.png` | `host/Sucuri.png` |
| 11 | 2048 | **🏆 Capivara Lendária** | "Diplomata da natureza" — fofura suprema | `#FFD54F` | `tile/Capivara.png` | `host/Capivara.png` |

> Caminhos relativos a `assets/images/animals/`. Nível 5 = Sagui (substituiu Arara-azul na Fase 2.3.7).

#### `backgroundBaseColor` — DEPRECADO desde a 2.3.8
A partir da Fase 2.3.8, o fundo do jogo é fixo (não varia por animal). O campo `backgroundBaseColor` no model `Animal` permanece pra retrocompatibilidade da Coleção (Fase 2.6), mas não é mais usado pelo `GameBackground`.

### 4.1 Visual do tile
- **Fundo:** branco (`#FFFFFF`)
- **Contorno:** cor da tabela (3px, arredondado)
- **Marca d'água:** PNG do animal centralizado, opacidade ~28%, ocupa ~80% do tile
- **Número:** sobreposto, Fredoka Bold, cor `#3E2723`
- **Sombra:** suave abaixo
- **Animação idle:** respiração lenta + piscar aleatório (futuro)

### 4.2 Anfitrião do jogo
- **Posição:** acima do tabuleiro, alinhado com o **primeiro tile da primeira linha** (canto superior esquerdo do tabuleiro)
- **Tamanho:** **igual ao de um tile** — mesmas dimensões (largura e altura) que uma célula do tabuleiro 4x4
- **Conteúdo (de cima pra baixo):**
  - **Nome do animal** (em cima) — Fredoka SemiBold, com `OutlinedText`
  - **PNG do animal** (embaixo) — ocupa o slot tile-sized, sem moldura, sem fundo branco
- **Atualização:** muda quando o jogador forma um tile de nível superior ao recorde da partida
- **Animação:** transição suave (fade + scale) ao trocar
- **Sem placeholder antes do primeiro tile** — o slot do anfitrião fica vazio até o primeiro animal aparecer (decidido na Fase 2.3.6 item B)
- **Espaço à direita do anfitrião** (acima das colunas 2-4 do tabuleiro): recebe o `StatusPanel` (cronômetro/score/recorde) e o **botão de pause tile-sized** (Fase 2.3.9 item B)

### 4.3 Fundo do jogo (atualizado na Fase 2.3.9 — PNG)
- **A partir da Fase 2.3.9:** fundo é uma imagem PNG (`assets/images/fundo.png`) renderizada em tela cheia
- **Configuração de renderização:**
  - `BoxFit.cover` (preenche a tela toda, pode cortar bordas) — preserva proporção
  - Alternativa em telas largas/estreitas onde `cover` corta demais: `BoxFit.fill` (estica) — decidir no brainstorm
- **Sem variação por animal** — fundo é o mesmo em qualquer fase do jogo (mantém a regra da Fase 2.3.8)
- **Cor de fallback:** `#D4F1DE` (verde-menta) é exibido **apenas se o PNG falhar** ao carregar

### 4.4 Texto sobre cor — legibilidade
- Textos brancos importantes têm contorno preto sutil (1–1.5px) com anti-aliasing suave (Fase 2.3.6 item A)
- Aplicado em: nome do anfitrião, cronômetro, pontuação, recorde, todos os textos do `PauseOverlay`
- **Atenção (Fase 2.3.9):** com fundo PNG variado, alguns textos podem ficar ilegíveis em regiões claras/escuras da imagem. Avaliar se reforça contornos ou aplica gradient overlay no fundo

### 4.5 Indicador de vidas (refinado na Fase 2.3.9)
- **Posição:** **topo central** da tela (acima do anfitrião e do tabuleiro)
- **Visual atualizado na 2.3.9:**
  - **Coração único** (ícone, ~36x36dp) com **número de vidas dentro** (Fredoka Bold, sobreposto, com `OutlinedText`)
  - **Faixa estilizada à direita do coração** (retângulo arredondado tipo banner/pill, com gradiente ou cor sólida + sombra) com texto interno mudando conforme o estado:
    - **Vidas = 5:** texto **"Completo"** (cor verde-folha `#66BB6A`)
    - **Vidas > 5 e ≤ 15:** texto **"Bônus"** (cor dourada `#FFD54F`)
    - **Vidas < 5:** texto **"Restando"** seguido do timer regressivo MM:SS (cor cinza neutra ou laranja-aviso)
  - Texto da faixa em Fredoka SemiBold, ~13sp, com `OutlinedText` pra legibilidade sobre o fundo PNG
- **Comportamento de tap:** abre dialog explicando o sistema de vidas e mostrando opções
- **Visualização escala bem:** o jogador pode ter 3, 5, 10, 50 vidas — sempre 1 ícone com número, nunca uma fileira que estoure

---

## 5. Sistema de Vidas

### 5.1 Regras
- **Vidas iniciais:** 5 (ao instalar/criar conta)
- **Cap de regeneração:** 5 — quando o jogador tem ≥5 vidas, a regeneração é interrompida
- **Cap de armazenamento (vidas GANHAS):** 15 — vidas obtidas via recompensas (ranking, recorde, convite, diária) não passam de 15
- **Cap de armazenamento (vidas COMPRADAS):** **ilimitado** — compras na loja se acumulam mesmo se já tiver 15 ou mais vidas
- **Regeneração:** +1 vida a cada **30 minutos**, parando ao atingir 5
- **Consumo:** 1 vida só no Game Over (ver 3.4)
- **Mínimo pra jogar:** 1 vida disponível

### 5.2 Resumo visual (caps de armazenamento)
| Origem | Cap de armazenamento |
|---|---|
| Iniciais (instalação) | 5 |
| Regeneração automática | até 5 (não excede) |
| Recompensas (diárias, ranking, recorde, convite) | até 15 |
| **Compras (loja)** | **ilimitado** |

> **Atenção (única limitação de inventário):** apenas vidas têm cap de armazenamento. Bombas e desfazer **não têm cap** — o jogador pode acumular quantos quiser.

### 5.3 Estados visuais da faixa do `LivesIndicator` (Fase 2.3.9)
| Faixa | Condição | Cor sugerida |
|---|---|---|
| **"Completo"** | `current == 5` | Verde-folha `#66BB6A` |
| **"Bônus"** | `5 < current ≤ 15` | Dourado `#FFD54F` |
| **"Restando MM:SS"** | `current < 5` | Cinza neutro `#9E9E9E` ou laranja-aviso `#FF8C42` |

> **Caso especial — `current > 15`** (raro, só com compras massivas): tratar como "Bônus" também. O texto da faixa não distingue entre 16 e 99 — quem quiser ver o número exato, lê o número dentro do coração.

### 5.4 Vidas zeradas
1. Diálogo: "Você ficou sem vidas! Quer assistir um anúncio de 30s pra ganhar +1 vida?"
2. Aceita: anúncio recompensado → +1 vida
3. **Limite diário:** até 40 anúncios recompensados de vida por dia
4. Após o limite: opção bloqueada até a meia-noite (timezone do dispositivo)

### 5.5 Modelo de dados
```dart
class LivesState {
  final int current;              // pode ser > 15 se houver compras
  final int regenCap;             // 5 (constante)
  final int earnedCap;            // 15 (cap de vidas ganhas)
  final DateTime? nextRegenAt;    // null se current >= regenCap
  final int adWatchesToday;       // 0..40
  final DateTime adCounterDate;
}
```

### 5.6 Lógica de adicionar vidas
- **Regen automática:** soma 1 enquanto `current < regenCap`
- **Recompensa:** soma N, mas resultado fica clamped em `min(current + N, earnedCap)` — se já tem 14 e ganha 5, vai pra 15 (não 19)
- **Compra:** soma N **sem cap** — se tem 14 e compra 10, vai pra 24

---

## 6. Itens e Power-ups

### 6.1 Tipos
| Item | Efeito | Origem |
|---|---|---|
| **Bomba 2** | Explode 2 casas adjacentes escolhidas | Loja, recompensas |
| **Bomba 3** | Explode 3 casas escolhidas (categoria separada) | Apenas loja |
| **Desfazer 1** | Desfaz a última jogada | Loja, recompensas |
| **Desfazer 3** | Desfaz as últimas 3 jogadas (categoria separada) | Apenas loja |

> **Sem cap de armazenamento:** bombas e desfazer podem ser acumulados sem limite. Apenas vidas têm cap (ver 5.2).

### 6.2 Visualização e uso

#### Localização
- **`InventoryBar`** no rodapé da tela de jogo, abaixo do tabuleiro
- Mostra cada item com **ícone PNG**, **contador (badge)** e **estado**
- Itens com contador 0 ficam **acinzentados e desabilitados**, mas continuam visíveis

#### Ícones do inventário
PNGs em `assets/icons/inventory/`:
- `bomb_2.png`, `bomb_3.png`, `undo_1.png`, `undo_3.png`

#### Confirmação universal antes do uso (Fase 2.3.8)
**TODOS os itens do inventário exigem confirmação antes de serem usados.** Não há mais ação imediata em nenhum tap de item.

**Fluxo unificado:**
1. Tap no ícone do item → abre `ConfirmUseDialog` com:
   - Ícone grande do item
   - Texto: "Usar [nome do item]?" (ex: "Usar Bomba 2?")
   - Sub-texto explicativo do efeito
   - Contador atual (ex: "Você tem 3 deste item")
   - Botão **"Cancelar"** e botão **"Usar"** (destacado)
2. Cancelar → fecha dialog, nada muda
3. Usar:
   - **Desfazer:** executa `gameNotifier.undo(steps)`, animação reversa (300ms), decrementa contador
   - **Bomba:** entra em modo seleção (`BombSelectionOverlay`); jogador escolhe casas; depois confirma "Explodir" no overlay → animação de explosão (500ms), tiles removidos, decrementa contador

> **Por que confirmar até pra Desfazer:** evita uso acidental, respeita o valor escasso do item, padroniza o comportamento da `InventoryBar`.

#### Regras de bombas
- **Bomba 2:** 2 casas adjacentes (compartilhar uma borda — 4-vizinhos)
- **Bomba 3:** 3 casas, livre escolha
- Não pode explodir células vazias: feedback "Selecione um tile"
- Cancelar no `BombSelectionOverlay` não consome o item

### 6.3 Game over com itens disponíveis
1. Modal de Game Over checa `Inventory`
2. Se desfazer ≥1: oferece "Desfazer última jogada" (passa pelo `ConfirmUseDialog`)
3. Se bomba ≥1: oferece "Usar bomba" (passa pelo `ConfirmUseDialog`)
4. Se sem itens: oferece anúncio recompensado pra item grátis
5. Sempre oferece link pra loja

### 6.4 Modelo de dados
```dart
class Inventory {
  final int bomb2;
  final int bomb3;
  final int undo1;
  final int undo3;
  // sem cap — qualquer valor não-negativo é válido
}
```

### 6.5 Ganhar itens iniciais (modo dev / mock)
- Botão "Ganhar 5 de cada item" nas Configurações (modo dev, removido em release)
- Cada game over sem itens mostra "Receber 1 item de mock-anúncio"

---

## 7. Loja de Itens

### 7.1 Pacotes
| # | Nome | Conteúdo | De | Por | Desconto |
|---|---|---|---|---|---|
| 01 | **4× Bomba 3** | 4 bombas que explodem 3 casas | R$ 7,99 | **R$ 3,99** | 50% |
| 02 | **4× Desfazer 3** | 4 desfazer de 3 jogadas | R$ 3,99 | **R$ 1,99** | 50% |
| 03 | **6 vidas** | Direto no inventário (sem cap por ser compra) | R$ 9,99 | **R$ 2,49** | 75% |
| 04 | **10 vidas** | Direto no inventário (sem cap por ser compra) | R$ 19,99 | **R$ 4,99** | 75% |
| 05 | **Combo Mata Atlântica** | 6 vidas + 2 bombas + 2 desfazer | R$ 10,99 | **R$ 4,99** | 50% |
| 06 | **Combo Floresta Amazônica** | 10 vidas + 4 bombas + 4 desfazer | R$ 31,99 | **R$ 9,99** | 50% |

### 7.2 Compartilhamento com amigos
Toda compra gera código único; amigo recebe metade. Código vale 1× pra 1 jogador. Resgate oferece dobrar via anúncio.

```
shareCodes/{code}
  - buyerId, packageId, giftContents
  - status: pending | redeemed | expired
  - redeemedBy, redeemedAt, createdAt
```

---

## 8. Recompensas

### 8.1 Diárias (ciclo 7 dias)
| Dia | Recompensa |
|---|---|
| 1 | 1× Desfazer 1 |
| 2 | 1× Bomba 2 |
| 3 | 1 vida |
| 4 | 2× Desfazer 1 |
| 5 | 2× Bomba 2 |
| 6 | 2 vidas |
| 7 | 2× Desfazer 1 + 2× Bomba 2 + 2 vidas |

- Ao receber: oferta de **dobrar** assistindo 30s de anúncio (opcional)
- **Streak quebrada:** se o jogador perde um dia, volta ao Dia 1
- Recompensa entregue na primeira abertura do jogo após meia-noite
- **Vidas recebidas aqui contam como "ganhas"** — entram no cap de 15

### 8.2 Ranking global (cada 7 dias)
| Posição | Recompensa |
|---|---|
| 1º | 10 vidas + 10 desfazer + 10 bombas |
| 2º | 5 vidas + 5 desfazer + 5 bombas |
| 3º | 3 vidas + 3 desfazer + 3 bombas |
| 4º | 3 vidas + 3 bombas |
| 5º | 3 vidas + 3 bombas |
| 6º | 3 vidas + 3 bombas |
| 7º | 3 vidas + 3 desfazer |
| 8º | 3 vidas + 3 desfazer |
| 9º | 3 vidas + 3 desfazer |
| 10º | 3 vidas |

- Ao receber: oferta de **dobrar** via anúncio (opcional)
- Vidas recebidas aqui contam como "ganhas" (cap de 15)

### 8.3 Recorde pessoal
A cada **recorde pessoal quebrado** (tempo ou número):
- **Combo:** 1 vida + 1 bomba + 1 desfazer
- Vida recebida conta como "ganha" (cap de 15)

### 8.4 Convite de amigo
A cada amigo convidado que **criar conta E jogar pelo menos 1 partida**:
- **1 combo** (1 vida + 1 bomba + 1 desfazer)
- Vida recebida conta como "ganha" (cap de 15)

#### Mecânica de convite
- Jogador gera link de convite na seção "Convidar amigos"
- Link contém ID do convidante (deep link via `app_links`)
- Quando o convidado se registra usando o link, vínculo é registrado
- Quando o convidado conclui a 1ª partida, recompensa é entregue ao convidante via push/notificação

---

## 9. Ranking

### 9.1 Tipos
| Tipo | Métrica | Persistência |
|---|---|---|
| **Pessoal** | Melhores tempos para chegar ao 2048 | Histórico vitalício |
| **Pessoal (alt)** | Maior número alcançado | Histórico vitalício |
| **Global** | Melhores tempos para o 2048 entre todos | **Reseta a cada 7 dias** |
| **Global (alt)** | Maior número alcançado entre todos | **Reseta a cada 7 dias** |

### 9.2 Marco zero do ranking global
- **Reset toda semana, sábado às 18:00 (horário de Brasília)**
- Ao abrir o jogo após o reset, o jogador recebe seu **resultado da semana anterior** (modal com posição e recompensas, se houver)

### 9.3 Modelo de dados (Firestore)
```
rankings/{week_id}/entries/{userId}
  - userId: string
  - displayName: string
  - bestTimeMs: int
  - bestNumber: int
  - completedAt: timestamp
  - country: string?

users/{userId}/personalRecords
  - bestTimeMs: int
  - bestNumber: int
  - totalGames: int
  - totalWins: int
```

### 9.4 Anti-cheat (consideração futura)
- Validação server-side dos tempos (mínimo razoável: ~30s)
- Limite de submissões por hora
- Idealmente, replay do jogo serializado (lista de movimentos)

---

## 10. Identidade Visual

### 10.1 Direção de arte
**Cartoon fofo (Pokémon Café Mix / Animal Crossing / Suika Game)**:
- Formas arredondadas
- Paleta vibrante mas harmônica
- Iluminação suave com sombras coloridas (não pretas)
- Outline opcional fino e escuro

### 10.2 Paleta principal
| Uso | Cor | Hex |
|---|---|---|
| **Fundo do jogo (Fase 2.3.9)** | **`assets/images/fundo.png`** | — (PNG) |
| Fundo (fallback se PNG falhar) | Verde-menta claro | `#D4F1DE` |
| Fundo (folhagem alternativa) | Verde-floresta médio | `#3FA968` |
| Tabuleiro | Madeira clara | `#E8D5B7` |
| Célula vazia | Madeira sombreada | `#C9B79C` |
| Tile preenchido | Branco | `#FFFFFF` |
| Acento (UI) | Laranja-tucano | `#FF8C42` |
| Texto principal | Marrom escuro | `#3E2723` |
| Texto sobre cor | Branco-creme | `#FFF8E7` |
| Contorno de texto | Preto | `#000000` |
| Sucesso / "Completo" | Verde-folha | `#66BB6A` |
| **"Bônus" (faixa de vidas)** | **Dourado** | **`#FFD54F`** |
| **"Restando" (faixa de vidas)** | **Cinza neutro** ou laranja-aviso | **`#9E9E9E`** ou `#FF8C42` |
| Alerta | Vermelho-açaí | `#C0392B` |
| Coração de vidas | Vermelho-coração | `#E53935` |
| Premium/dourado | Dourado | `#FFD54F` |

### 10.3 Tipografia
- **Títulos**: `Fredoka` (arredondada, divertida)
- **Texto/UI**: `Nunito` (legível, amigável)
- **Pontuação e número do tile**: `Fredoka Bold`
- **Número dentro do coração de vidas**: `Fredoka Bold`, branco com `OutlinedText`
- **Texto da faixa de vidas (Completo/Bônus/Restando)**: `Fredoka SemiBold`, ~13sp, com `OutlinedText`
- **Texto branco sobre fundo dinâmico**: contorno preto 1–1.5px com anti-aliasing (ver 4.4)

### 10.4 Iconografia
- Ícones com traço arredondado (Phosphor/Lucide "duotone")
- Botões grandes (≥48x48dp) com sombra inferior

### 10.5 Animações
| Evento | Animação |
|---|---|
| Spawn de tile | Scale 0 → 1.1 → 1, bounce, 200ms |
| Movimento | Translate suave, easing cubicOut, 150ms |
| Merge | Pop (scale 1 → 1.2 → 1), 250ms |
| Merge da Capivara | Flash dourado, partículas de folhas, zoom out, 1500ms |
| Troca de anfitrião | Fade + scale, 400ms |
| Game Over | Tabuleiro escurece, modal slide+fade |
| Botão pressionado | Scale 1 → 0.95 → 1, 100ms |
| Pause overlay (entrada) | Fade do blur 0 → max + scale do conteúdo, 250ms |
| Pause overlay (saída) | Reverso, 200ms |
| Bomba explodindo | Onda + partículas, 500ms |
| Desfazer | Reversão suave, 300ms |
| Bomba — modo seleção (entrada) | Pulse no tabuleiro + dim no resto, 200ms |
| Bomba — célula selecionada | Pulsa loop infinito, opacidade 0.7 ↔ 1.0, 600ms |
| `LivesIndicator` — vida ganha | Coração pulsa (scale 1 → 1.15 → 1), 300ms |
| `LivesIndicator` — vida perdida | Coração tremula (rotate ±5°), 200ms |
| **Faixa de vidas — transição entre estados** | **Fade entre cores (300ms)** quando muda de "Restando" pra "Completo" ou de "Completo" pra "Bônus" |
| `ConfirmUseDialog` (entrada) | Fade + slide-up, 200ms |
| **Botão pause tile-sized — pressionado** | **Scale 1 → 0.95 → 1, 100ms** |

---

## 11. Sons e Música
*(Implementação adiada para a Fase 5 — junto com polimento e lançamento)*

### 11.1 Sons dos animais
| Animal | Som sugerido |
|---|---|
| **Tanajura** | Zumbido leve + "tlec" |
| **Lobo-guará** | Uivo curto agudo |
| **Sapo-cururu** | "Croac" grave característico |
| **Tucano** | "Tac-tac" do bico + assobio |
| **Sagui** | Trinado curto agudo (chamado típico do sagui) |
| **Preguiça** | Bocejo lento e fofo |
| **Mico-leão-dourado** | Guincho agudo / piado |
| **Boto-cor-de-rosa** | Sopro d'água + assobio místico |
| **Onça-pintada** | Rosnado curto |
| **Sucuri** | Chiado grave |
| **🏆 Capivara Lendária** | "Wheek" característico + fanfarra dourada |

### 11.2 Sons de UI
- Botão clicado: pop suave
- Swipe inválido: thud abafado
- Novo recorde: jingle ascendente
- Game over: nota descendente melancólica
- Vitória: fanfarra triunfal de ~3s
- Bomba: explosão cartoon
- Desfazer: rewind/whoosh
- Vida ganha: tilim mágico
- Compra concluída: cha-ching
- Tap em ícone do inventário: click metálico curto
- `ConfirmUseDialog` — confirmar: clique grave decisivo
- `ConfirmUseDialog` — cancelar: clique neutro
- Bomba — entrar em modo seleção: "tic-tac" tenso
- Bomba — célula selecionada: click + leve pulso
- Pause overlay — abrir: whoosh suave (efeito vidro)
- Pause overlay — fechar: whoosh reverso

### 11.3 Música ambiente
- Loop suave de floresta (pássaros, água, vento)
- Instrumental: flautas, marimba, percussão suave
- Volume separado de SFX (slider individual)
- Mute persistente nas configurações

### 11.4 Considerações técnicas
- Pré-carregar todos os sons no início
- Pool de AudioPlayers
- Formatos: OGG (Android/Web), M4A/AAC (iOS), MP3 universal
- Tamanho alvo: < 50KB por som de animal

---

## 12. Telas e Fluxos

### 12.1 Mapa de telas
```
[Splash]
   ↓
[Login/Cadastro]  (apenas primeira vez ou se quiser ranking global)
   ↓
[Home/Menu Principal]
   ├── [Jogo Clássico]
   │      ├── (vidas no topo central — coração + faixa "Completo/Bônus/Restando")
   │      ├── (anfitrião acima do primeiro tile, com nome em cima e PNG embaixo)
   │      ├── (botão pause tile-sized fixo, ao lado direito do anfitrião)
   │      ├── (tabuleiro 4x4)
   │      ├── (inventário no rodapé)
   │      └── [Game Over Modal]
   │              ├── Usar item (com ConfirmUseDialog)
   │              ├── Anúncio para item grátis
   │              ├── Loja
   │              └── Voltar ao Menu
   ├── [Loja]
   │      └── [Tela de Compra] → [Código de Compartilhamento]
   ├── [Ranking]
   │      ├── Global semanal
   │      └── Pessoal vitalício
   ├── [Recompensas Diárias]
   ├── [Convidar Amigos]
   ├── [Resgatar Código]
   ├── [Coleção de Animais]
   ├── [Configurações]
   └── [Como Jogar]
```

### 12.2 Tela: Home
- Logo grande com a Capivara mascote ao centro
- **Indicador de vidas** no topo central (coração + faixa "Completo/Bônus/Restando" — ver 4.5)
- Botão grande **"Jogar"** (Novo jogo / Continuar partida salva)
- Cards: Loja, Ranking, Recompensa Diária (com badge), Convidar
- Ícones menores: Coleção, Configurações, Como Jogar
- Background: cena da floresta com paralaxe leve

### 12.3 Tela: Jogo (refinada na Fase 2.3.9)
**Layout (de cima pra baixo):**

1. **Topo central:** `LivesIndicator` (coração + faixa estilizada)
2. **Acima do tabuleiro, lado esquerdo (sobre a 1ª coluna):** `HostBanner` tile-sized (nome em cima, PNG embaixo)
3. **Acima do tabuleiro, lado direito (sobre a 4ª coluna):** **`PauseButtonTile`** — botão de pause tile-sized fixo (Fase 2.3.9 item B)
4. **Acima do tabuleiro, espaço entre anfitrião e botão pause (sobre colunas 2-3):** `StatusPanel` (cronômetro + pontuação + recorde)
5. **Centro:** tabuleiro 4x4
6. **Rodapé:** `InventoryBar` (4 itens com ícones PNG + badges de contador)

> **Nota de layout:** o cabeçalho acima do tabuleiro agora é dividido em 3 zonas alinhadas às 4 colunas:
> - Coluna 1: anfitrião tile-sized
> - Colunas 2 e 3: `StatusPanel` (cronômetro/score/recorde)
> - Coluna 4: botão de pause tile-sized

#### 12.3.1 Posicionamento do botão pause (atualizado na Fase 2.3.9)
- **Tile-sized e fixo** — ocupa o espaço da 4ª coluna do tabuleiro, acima dela
- **NÃO é mais flutuante** — substitui completamente o pause flutuante anterior
- Ícone de pausa centralizado (Material `Icons.pause_circle` ou similar) com texto "Pausar" embaixo
- Mesmas dimensões de um tile do tabuleiro (largura e altura)
- Animação de tap: scale 1 → 0.95 → 1 (100ms)

#### 12.3.2 Pause overlay — vidro fosco cobrindo o tabuleiro
**Regra crítica:** quando o jogo está pausado, o jogador não pode estudar o tabuleiro.

- **Cobertura:** overlay cobre 100% do tabuleiro + 80–90% da tela útil (mantém visíveis o `LivesIndicator` no topo e o `InventoryBar` no rodapé)
- **Efeito visual:** vidro fosco via `BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12))` + tint semi-transparente
- **Layout:** logo centralizado + botões "Continuar / Reiniciar / Menu"
- **Sem reposicionamento do tabuleiro** quando o overlay aparece/desaparece
- **Animação:** entrada com fade+scale (250ms), saída reverso (200ms)
- **Texto:** TODOS os textos brancos do overlay usam `OutlinedText`

### 12.4 Tela: Loja
- Lista dos 6 pacotes em cards grandes
- Cada card: imagem, conteúdo, "De R$X" (riscado) "Por R$Y" (destaque), badge de desconto
- Após compra: tela de "Código para presentear amigo" com botão de compartilhar

### 12.5 Tela: Ranking
- Tabs: **Global Semanal** | **Pessoal**
- Pódio (1º, 2º, 3º) destacado no topo
- Lista paginada
- Tempo até reset (se Global): contador regressivo até sábado 18h

### 12.6 Tela: Recompensas Diárias
- Grid 7 dias (1–7) com recompensa de cada dia
- Dia atual destacado, dias anteriores marcados como recebidos
- Botão "Coletar" no dia atual
- Após coletar: oferta de dobrar via anúncio

### 12.7 Tela: Convidar Amigos
- Botão "Gerar link de convite" → compartilha via `share_plus`
- Lista de amigos convidados (status: pendente / completo / recompensa entregue)
- Total de combos ganhos por convites

### 12.8 Tela: Resgatar Código
- Campo de texto para código
- Botão "Resgatar"
- Após resgate: oferta de dobrar via anúncio

### 12.9 Tela: Debug — Galeria de Animais (Fase 2.3.7)
Tela acessível apenas em build de debug (via `kDebugMode`). Mostra os 11 animais lado a lado em 2 modos (tile + host com tamanho tile-sized). Atualizada na 2.3.8 pra usar PNGs.

---

## 13. Modelo de Dados

### 13.1 Animal
```dart
class Animal {
  final int level;
  final int value;
  final String name;
  final String? scientificName;
  final String tilePngPath;             // assets/images/animals/tile/Tanajura.png
  final String hostPngPath;             // assets/images/animals/host/Tanajura.png
  final String soundPath;
  final Color borderColor;
  final String? funFact;
  final Color backgroundBaseColor;      // usado apenas na Coleção (fase 2.6); ignorado no jogo
}
```

### 13.2 Tile
```dart
class Tile {
  final String id;
  final int level;
  final int row;
  final int col;
  final bool isNew;
  final bool justMerged;
}
```

### 13.3 GameState
```dart
class GameState {
  final List<List<Tile?>> board;
  final int score;
  final int highScore;
  final int highestLevelReached;
  final bool isGameOver;
  final bool hasWon;
  final DateTime? startedAt;
  final Duration elapsed;
  final List<GameState> undoStack;   // últimos N estados (N=3 atende Desfazer 3)
}
```

### 13.4 LivesState (Hive, typeId: 1)
| Campo | Tipo | Descrição |
|---|---|---|
| current | int | vidas atuais (0..∞ — pode passar de 15 com compras) |
| regenCap | int | 5 (constante, regen para neste valor) |
| earnedCap | int | 15 (cap das vidas ganhas via recompensa) |
| nextRegenAt | DateTime? | timestamp da próxima vida por regen; null se current ≥ regenCap |
| adWatchesToday | int | contador diário de anúncios mock (0..40) |
| adCounterDate | DateTime | data do contador (reset à meia-noite local) |
| userId | String? | null = local; preenchido na fase de backend |
| lastSyncedAt | DateTime? | null = nunca sincronizado |

### 13.5 Inventory (Hive, typeId: 2)
```dart
class Inventory {
  final int bomb2;
  final int bomb3;
  final int undo1;
  final int undo3;
  // sem cap — qualquer int não-negativo é válido
}
```

### 13.6 PlayerProfile
```dart
class PlayerProfile {
  final String userId;
  final String displayName;
  final LivesState lives;
  final Inventory inventory;
  final int dailyStreak;
  final DateTime? lastDailyClaim;
  final List<String> invitedFriends;
  final PersonalRecords records;
}

class PersonalRecords {
  final int? bestTimeMs;
  final int bestNumber;
  final int totalGames;
  final int totalWins;
}
```

### 13.7 ShopPackage
```dart
class ShopPackage {
  final String id;
  final String name;
  final String description;
  final double originalPrice;
  final double currentPrice;
  final int discountPercent;
  final RewardBundle contents;
  final RewardBundle giftContents;
}

class RewardBundle {
  final int lives;
  final int bomb2;
  final int bomb3;
  final int undo1;
  final int undo3;
}
```

### 13.8 ShareCode
```dart
class ShareCode {
  final String code;
  final String buyerId;
  final String packageId;
  final RewardBundle giftContents;
  final ShareCodeStatus status;
  final String? redeemedBy;
  final DateTime? redeemedAt;
  final DateTime createdAt;
}
```

---

## 14. Persistência (Hive + Firestore)

### 14.1 Hive (local)
| Chave | Conteúdo |
|---|---|
| `current_game` | GameState serializado (auto-save) |
| `lives_state` | LivesState |
| `inventory` | Inventory |
| `personal_records` | PersonalRecords |
| `daily_streak` | int + lastClaimDate |
| `unlocked_animals` | List<int> (níveis vistos) |
| `settings.sound_volume` | double 0–1 |
| `settings.music_volume` | double 0–1 |
| `settings.haptic_enabled` | bool |
| `settings.locale` | String "pt_BR" \| "en_US" |
| `ad_counter` | { date, count } |

### 14.2 Firestore (remoto, requer login)
| Coleção | Conteúdo |
|---|---|
| `users/{userId}` | PlayerProfile (sincronizado) |
| `rankings/{weekId}/entries/{userId}` | Entrada de ranking semanal |
| `shareCodes/{code}` | Códigos de compartilhamento |
| `invites/{inviterId}` | Lista de convidados e status |
| `purchases/{userId}/{purchaseId}` | Histórico de compras |

---

## 15. Roadmap de Implementação

### ✅ Fase 1 — MVP do tabuleiro
- Setup do projeto Flutter
- Game engine puro com testes unitários
- Tela de jogo básica com tiles placeholders (cor + nível)
- Swipe nas 4 direções
- Spawn, merge, game over
- Pontuação local

### ✅ Fase 2.1 — Visual base
- Aplicar paleta de cores definida
- Adicionar Fredoka e Nunito via `google_fonts`
- Refazer `tile_widget.dart` com novo conceito
- Animações de movimento, spawn e merge
- Splash screen, tema do app

### ✅ Fase 2.2 — Cronômetro + Anfitrião (versão inicial)
- Cronômetro MM:SS começa na primeira peça
- `HostBanner` no topo com nome do animal
- Atualizar anfitrião quando `highestLevelReached` aumenta
- Animação de transição entre anfitriões
- Sistema de pausa completo (PauseOverlay + Continuar/Reiniciar/Menu)

### ✅ Fase 2.3 — HomeScreen + Vidas + Anfitrião refatorado + Fundo dinâmico
- HomeScreen
- Sistema de vidas com Hive (regen offline, mock-anúncio, limite 40/dia)
- LivesIndicator (versão antiga: vários corações)
- HostArtwork com fallback
- StatusPanel HH:MM:SS
- Pause flutuante
- GameBackground com textura geométrica por animal (depreciado na 2.3.8)

### ✅ Fase 2.3.5 — Refinamento e Bugfixes (5 correções)
- A — Vida só consome no Game Over
- B — Transição de fundo sem flicker
- C — Botão pause não sobrepõe StatusPanel
- D — `OutlinedText` widget com contorno preto
- E — Cores explícitas por animal via `backgroundBaseColor`

### ✅ Fase 2.3.6 — Polimento UX + Inventário (v0.3.6)
- 5 bugs visuais corrigidos (anti-aliasing, placeholder do anfitrião, BackdropFilter, Stack/Positioned, OutlinedText parcial no PauseOverlay)
- Inventário completo: Model + Hive + Notifier, InventoryBar, Desfazer 1/3, Bomba 2/3 com BombSelectionOverlay, Game Over modal
- Ícones placeholder Material/Lucide

### ✅ Fase 2.3.7 — Integração de Assets dos Animais + Refinamentos (v0.4.0)
- A — SVGs dos 11 animais integrados em tiles e anfitrião
- B — Sagui no nível 5 (substituiu Arara-azul)
- C — `OutlinedText` completo no `PauseOverlay`
- D — Ícones SVG do inventário (bomb 2/3, undo 1/3)
- E — Tela debug `AnimalsGalleryScreen`
- **Identificado:** processamento de SVG em runtime causa lentidão — motivou a Fase 2.3.8

### ✅ Fase 2.3.8 — Otimização de Assets + Refinamentos de UI (v0.5.0)
- A — Migração SVG → PNG (remove `flutter_svg`, troca por `Image.asset`)
- B — `ConfirmUseDialog` universal pra todos os 4 itens do inventário
- C — Anfitrião redesenhado: tile-sized, posicionado sobre o 1º tile, nome em cima
- D — Fundo fixo `#D4F1DE` (sem variação por animal)
- E — `LivesIndicator`: coração único + número + badge "Bônus ⭐"
- F — `LivesState` com `regenCap`/`earnedCap`, `addEarned`/`addPurchased`
- G — Inventário sem cap pra bombas e desfazer (badge 99+ + tooltip)
- 125 testes passando

### ✅ Fase 2.3.9 — Refinamentos visuais (v0.6.0)
**Objetivo:** três ajustes de UI identificados em uso real após a 2.3.8 — fundo do jogo via PNG, faixa do `LivesIndicator` com 4 estados visuais distintos, botão de pause tile-sized fixo no cabeçalho.

- C — `GameBackground` com `fundo.png` via `DecoratedBox`+`DecorationImage(BoxFit.cover)`, fallback `#D4F1DE`, `precacheImage` no boot
- A — `LivesStatusBanner` (pill 120dp): "Completo" verde `#66BB6A`, "Bônus" dourado `#FFD54F`, "Restando MM:SS" laranja `#FFA726`, "Sem vidas" vermelho `#EF5350`; `AnimatedSwitcher` fade 300ms + `ScaleTransition` 1→1.1→1 (200ms) em transições positivas
- B — `PauseButtonTile` (72dp tile-sized): branco, borda laranja 3px, ícone + "Pausar", `FittedBox(scaleDown)`, tap scale 0.95; `GameScreen` refatorado pra `ConsumerWidget` — removidos `_pauseTop`/`_headerKey`/`_updatePausePosition`; cabeçalho `Row([HostBanner, Expanded(StatusPanel), PauseButtonTile])`
- 143 testes passando
- Tiles brancos têm contraste adequado
- Textos com `OutlinedText` permanecem legíveis (especialmente sobre regiões claras/escuras do PNG)
- Performance: medir FPS em 60s de gameplay vs versão 0.5.0 (cor sólida) — `BoxFit.cover` num PNG estático não deve impactar (cache nativo do Flutter)

---

### 🔜 Fase 2.5 — Recompensas diárias (3 dias)
- Tela de recompensas com grid 7 dias
- Lógica de streak (reseta se pular dia)
- Coleta com confirmação
- Mock do "dobrar via anúncio"
- Persistência local

### 🔜 Fase 2.6 — Tela Home + Coleção + Configurações (1 semana)
- Home com todos os botões e indicadores
- Tela de Coleção (silhuetas para não desbloqueados, card detalhado para desbloqueados — usa `backgroundBaseColor` do Animal)
- Configurações (volume SFX, volume música, haptic, idioma)

### 🔜 Fase 2.7 — Loja mock (3 dias)
- Tela com os 6 pacotes
- Cards com "De/Por" e badges de desconto
- Botão "Comprar" simulado
- Tela de "Código para presentear" gerada após compra simulada

### 🔜 Fase 3 — Backend, ranking e monetização (3–4 semanas)
- Setup Firebase (Auth, Firestore)
- Login (Google, Apple, anônimo)
- Sincronização de PlayerProfile
- Ranking global semanal
- Sistema de convites com deep links
- Sistema de códigos de compartilhamento
- Recompensas de ranking
- Integração Google Mobile Ads
- Integração `in_app_purchase`

### 🔜 Fase 4 — Arte adicional e polimento visual
- Background de floresta na Home
- Logo do jogo
- Ícone do app
- Splash screen final
- Validação visual completa

### 🔜 Fase 5 — Áudio + Polimento + Lançamento
**Áudio (parte 1 — adiada de fases anteriores):**
- Sons dos 11 animais (~50KB cada, OGG/M4A/MP3)
- Sons de UI completos
- Música ambiente: loop de floresta com flautas + marimba
- Integrar com `audioplayers` ou `just_audio`
- Pool de AudioPlayers
- Mixer simples nas Configurações
- Pré-carregar tudo no início do app

**Polimento e lançamento (parte 2):**
- Localização PT-BR / EN
- Acessibilidade (contraste, leitor de tela, fonte ajustável)
- Modo escuro (opcional)
- Testes em dispositivos reais
- Build para iOS, Android, Web
- Submissão App Store / Play Store / Web hosting
- Política de privacidade e termos de uso
- LGPD/COPPA compliance

> **Por que áudio foi adiado:** o foco até aqui foi mecânica + UI visual. Áudio adiciona polish significativo mas não é bloqueador pra validar gameplay. Implementar perto do lançamento garante que os sons casem com a versão final do jogo (sem retrabalho se a UI mudar de novo).

---

## 16. Considerações Especiais

### 16.1 Acessibilidade
- WCAG AA
- Forma + cor + número + nome
- `Semantics` pra leitor de tela
- Pause overlay anunciado ao leitor de tela ("Jogo pausado")
- `LivesIndicator` anunciado: "5 vidas, banco completo" / "8 vidas, bônus" / "3 vidas, próxima em 12 minutos"
- `PauseButtonTile` anunciado: "Botão Pausar"
- Modo "alta visibilidade"
- Tamanho de fonte ajustável

### 16.2 Performance
- `const` e Riverpod selectors
- PNGs em vez de SVGs (Fase 2.3.8 item A) — gargalo removido
- `precacheImage` pra os 22 PNGs dos animais + 4 do inventário + `fundo.png` no boot
- Pool de AudioPlayers (Fase 5)
- 60fps em Snapdragon 660+ / iPhone 8+
- `RepaintBoundary` no `GameBackground` (cor única na 2.3.8 / PNG estático na 2.3.9 — ambos leves)
- `BackdropFilter` no `PauseOverlay` é o único custo significativo de UI — fallback se ficar < 50fps

### 16.3 LGPD / COPPA / Crianças
- Conformidade COPPA (US) e LGPD (BR)
- Login não obrigatório
- Consentimento parental se < 13 anos
- Anúncios com flag `tagForChildDirectedTreatment`
- Dados coletados: mínimos necessários

### 16.4 Aspectos legais
- Verificar nomes científicos com IUCN/ICMBio
- Considerar parceria com WWF Brasil ou ICMBio
- Atenção à apropriação cultural

### 16.5 SEO e App Store
- Nome: "Capivara 2048" (BR) / "Brazil Animals 2048" (EN)
- Keywords: 2048, puzzle, capivara, animais, brasil, fofo, casual, fauna
- Screenshots destacando a Capivara
- Vídeo de gameplay de 30s

---

## 17. Prompt Sugerido para o Claude Code (Fase 2.3.9 — via skill superpowers)

> O prompt abaixo entra no fluxo do **superpowers/brainstorming**. O resultado esperado é uma **spec detalhada da Fase 2.3.9** (refinada via brainstorm), que depois alimenta o **superpowers/writing-plans** pra gerar o plano executável. Nada de código nesta etapa — apenas elicitação, refinamento de design e plano.

---

> Use a skill `superpowers/brainstorming` pra refinar o design da próxima fase do projeto **Capivara 2048** (Flutter).
>
> **Contexto:** Estamos no projeto Capivara 2048. Use `CAPIVARA_2048_DESIGN.md` como spec geral (especialmente seções 4.3, 4.5, 5.3, 12.3, 12.3.1 e 15 — Fase 2.3.9).
>
> **Fases concluídas:**
> - Fase 1 a 2.3.7
> - **Fase 2.3.8 (v0.5.0)** — migração SVG→PNG, ConfirmUseDialog universal, anfitrião tile-sized com nome em cima, fundo fixo `#D4F1DE`, LivesIndicator com coração + número + badge "Bônus ⭐", regenCap/earnedCap, badge 99+ no inventário. 125 testes passando.
>
> **Tópico do brainstorm:** desenhar a **Fase 2.3.9 — Refinamentos visuais**. Três ajustes de UI identificados em uso real:
>
> **A — `LivesIndicator` com faixa estilizada (Completo / Bônus / Restando):** criar `lives_status_banner.dart` (pill/banner arredondado) com 3 estados visuais distintos: "Completo" verde se `current == 5`, "Bônus" dourado se `current > 5`, "Restando MM:SS" cinza/laranja se `current < 5`. Texto Fredoka SemiBold ~13sp com `OutlinedText`. Refatorar `lives_indicator.dart` pra usar o novo banner. Animação fade 300ms na transição entre estados.
>
> **B — Botão de pause tile-sized fixo (substitui pause flutuante):** criar `pause_button_tile.dart` com mesmas dimensões de um tile do tabuleiro, posicionado fixo na 4ª coluna do cabeçalho (acima da coluna 4 do tabuleiro). Refatorar layout da `GameScreen` pra ter 3 zonas no cabeçalho (anfitrião | StatusPanel 2 cols | PauseButtonTile). Remover toda lógica de `Positioned`/`LayoutBuilder` que evitava sobreposição.
>
> **C — Fundo do jogo via PNG (`assets/images/fundo.png`):** o arquivo já está em `assets/images/fundo.png`. Refatorar `game_background.dart` pra usar `DecorationImage` com `BoxFit.cover`. Pré-cache via `precacheImage` no boot. Fallback pra cor `#D4F1DE` se asset falhar. Avaliar legibilidade dos textos sobre o novo fundo e considerar gradient overlay se necessário.
>
> **Pontos abertos pra explorar no brainstorm (elicitação esperada):**
>
> Sobre o item A (faixa de vidas):
> - Cor da faixa "Restando" — cinza neutro `#9E9E9E` (passivo, "esperando") ou laranja-aviso `#FF8C42` (chama atenção pro tempo)? Qual psicologicamente faz o jogador querer voltar pra ver as vidas?
> - O timer regressivo MM:SS dentro da faixa — atualiza a cada segundo via `StreamBuilder` ou `Timer.periodic`? Tradeoff de rebuild vs simplicidade.
> - A faixa deve ter shadow/elevation pra destacar do fundo PNG (item C), ou fica plana? Como balanceia com o coração ao lado?
> - Quando `current` cruza um threshold (4→5, 5→6), a faixa muda. Animação de fade 300ms é suficiente, ou vale uma micro-celebração (scale leve, partículas)?
> - Caso de borda — `current = 0` (sem vidas): a faixa mostra "Restando" mesmo? Ou texto especial tipo "Sem vidas — aguarde"? Como o jogador entende que precisa esperar 30min ou ver anúncio?
> - Largura da faixa — mínima fixa pra acomodar "Restando MM:SS" (~120dp) ou flexível (cresce conforme texto)? Qual é mais consistente visualmente?
>
> Sobre o item B (botão de pause tile-sized):
> - Conteúdo do botão: ícone + texto "Pausar" embaixo, ou só ícone grande centralizado? Texto ajuda crianças (público secundário).
> - Cor do ícone — laranja-tucano `#FF8C42` combina com a borda? Ou usar cor neutra mais escura (cinza/marrom)?
> - Ao pausar o jogo, o botão muda de aparência (ex: vira "Continuar" com ícone play)? Ou continua como "Pausar" e o overlay é onde o jogador interage?
> - Tap acidental — o botão é grande agora (tile-sized = ~80x80dp em smartphones). Vale ter delay/long-press pra evitar pause acidental durante swipe rápido?
>
> Sobre o item C (fundo PNG):
> - `BoxFit.cover` corta as bordas da imagem em telas com aspect diferente. `BoxFit.fill` estica (perde proporção). `BoxFit.contain` deixa borda lateral. Qual é o tradeoff aceitável dado o conteúdo da `fundo.png`?
> - O `fundo.png` provavelmente tem regiões com gradiente/cor variando — algum texto branco com `OutlinedText` pode ficar ilegível? Vale aplicar gradient overlay sutil (ex: gradient preto top→bottom 0→15% opacity) pra reforçar contraste?
> - Aplicar o mesmo `fundo.png` na `HomeScreen` ou ela mantém visual próprio? Se aplicar agora, evita inconsistência futura.
> - Performance: `precacheImage` pra `fundo.png` (provavelmente arquivo grande) — vale comprimir antes de bundlar (TinyPNG ou similar)? Tamanho ideal pra mobile?
>
> Sobre integração:
> - Ordem das 3 entregas: A primeiro (faixa nova), C depois (fundo, vai impactar legibilidade da faixa), B por último (refator do layout do cabeçalho)?
> - Vale fazer screenshots/vídeo do app antes/depois da 2.3.9 pra documentar as 3 mudanças visuais?
> - Testes de regressão visual: snapshot tests existentes do `LivesIndicator` (Fase 2.3.8) precisam ser regenerados com a nova faixa. Idem pros snapshots da `GameScreen` com novo botão de pause e novo fundo.
> - Sobre acessibilidade: o `Semantics` do `LivesIndicator` precisa anunciar o estado da faixa (ex: "5 vidas, banco completo" / "8 vidas, bônus" / "3 vidas, próxima em 12 minutos") — atualizar conforme.
>
> **Output esperado do brainstorm:**
> Uma **spec detalhada da Fase 2.3.9** (markdown, tipo `FASE_2_3_9_SPEC.md`) com:
> - Decisões tomadas em cada ponto aberto
> - Para cada uma das 3 sub-entregas: arquivos a criar/modificar, mudança exata, casos de teste obrigatórios, critérios de aceite
> - Ordem de execução recomendada (dependências entre as 3 entregas)
> - Cobertura de testes existentes que precisa ser atualizada (especialmente snapshots da Fase 2.3.8)
> - Estratégia de validação visual após cada entrega (screenshots/golden tests)
>
> Esse documento será depois consumido pela skill `superpowers/writing-plans` pra gerar o plano executável (TDD-friendly, com checkpoints).
>
> **Não escreva código nesta etapa.** Foque em refinar o design, fazer perguntas críticas e produzir a spec.

---

## 18. Anexo — Lista de Referências

- **2048** original (Gabriele Cirulli) — mecânica base
- **Suika Game** — fofura
- **Animal Crossing** — paleta e tipografia
- **Pokémon Café Mix** — estilo cartoon
- **Threes!** — predecessor do 2048
- **Royal Match / Candy Crush** — referência de monetização (vidas, loja, recompensas)
- **Folclore brasileiro** — pesquisa para futuras expansões (Boto, Curupira, Iara, Saci)

---

*Documento vivo — atualize conforme o desenvolvimento evolui.*
