# 🦫 Capivara 2048 — Design Concept (Consolidado v2)

> Documento de especificação para desenvolvimento. Pensado para ser alimentado em ferramentas como Claude Code para implementação iterativa.
>
> **Status atual:** Fase 2.3.8 concluída ✅ (v0.5.0) — migração SVG→PNG, ConfirmUseDialog universal, anfitrião tile-sized com nome em cima, fundo fixo `#D4F1DE`, LivesIndicator redesenhado (coração + número + badge "Bônus ⭐"), `regenCap`/`earnedCap` no LivesState, badge 99+ e tooltip no inventário. 125 testes passando.
>
> **Próximo:** **Fase 2.4 — Sons + Música ambiente** — sons dos 11 animais (~50KB cada), sons de UI completos, música de fundo em loop, integração `audioplayers`, pool de AudioPlayers, mixer nas Configurações.
>
> **Mudanças principais nesta versão:**
> - **Assets PNG em vez de SVG** (performance) — todos os 11 animais e os 4 ícones do inventário migram pra PNG
> - **Anfitrião redesenhado** — tile-sized (mesmas dimensões de um tile do tabuleiro), posicionado acima do primeiro tile (canto superior esquerdo), nome em cima, sem moldura
> - **Fundo fixo** — sem variação de cor/textura por animal anfitrião (remove `backgroundBaseColor` do uso ativo, simplifica o `GameBackground`)
> - **Indicador de vidas centralizado no topo** — coração único com número dentro + badge "Completo" quando 5/5; visualização compacta que escala pra qualquer quantidade armazenada
> - **Confirmação universal** pra uso de itens do inventário
> - **Sem cap de inventário pra bombas e desfazer** — apenas vidas têm cap (15 ganhas / ilimitado compradas)

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
| Áudio | `audioplayers` ou `just_audio` | Sons e música |
| Persistência | `hive` + `shared_preferences` | Local |
| Tipografia | `google_fonts` | Fredoka, Nunito |
| Imagens | `Image.asset` (Flutter nativo) | PNGs dos animais e ícones (Fase 2.3.8) |
| ~~SVG~~ | ~~`flutter_svg`~~ | **Removido na Fase 2.3.8 (gargalo de performance)** |
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
│   │   ├── tile_widget.dart             ✅ (PNG na 2.3.8)
│   │   ├── score_panel.dart             ✅
│   │   ├── status_panel.dart            ✅
│   │   ├── host_banner.dart             ✅ (redesenhado tile-sized na 2.3.8)
│   │   ├── host_artwork.dart            ✅ (PNG na 2.3.8)
│   │   ├── game_background.dart         ✅ (simplificado pra fundo fixo na 2.3.8)
│   │   ├── lives_indicator.dart         ✅ (redesenhado coração+número na 2.3.8)
│   │   ├── outlined_text.dart           ✅
│   │   ├── pause_overlay.dart           ✅
│   │   ├── inventory_bar.dart           ✅
│   │   ├── inventory_item_button.dart   ✅ (PNG na 2.3.8)
│   │   ├── confirm_use_dialog.dart      ✅ (Fase 2.3.8)
│   │   ├── bomb_selection_overlay.dart  ✅
│   │   └── animal_card.dart
│   └── controllers/
└── assets_manifest.dart
assets/
├── images/animals/tile/        ← PNGs dos tiles (Fase 2.3.8 — substituem SVGs)
│   ├── Tanajura.png
│   ├── LoboGuara.png
│   ├── Cururu.png
│   ├── Tucano.png
│   ├── Sagui.png
│   ├── Preguica.png
│   ├── MicoLeao.png
│   ├── Boto.png
│   ├── Onca.png
│   ├── Sucuri.png
│   └── Capivara.png
├── images/animals/host/        ← PNGs do anfitrião (Fase 2.3.8 — substituem SVGs)
│   ├── Tanajura.png
│   ├── LoboGuara.png
│   ├── Cururu.png
│   ├── Tucano.png
│   ├── Sagui.png
│   ├── Preguica.png
│   ├── MicoLeao.png
│   ├── Boto.png
│   ├── Onca.png
│   ├── Sucuri.png
│   └── Capivara.png
├── icons/inventory/            ← PNGs dos ícones do inventário (Fase 2.3.8 — substituem SVGs)
│   ├── bomb_2.png
│   ├── bomb_3.png
│   ├── undo_1.png
│   └── undo_3.png
├── sounds/animals/             ← Fase 2.4
├── sounds/ui/                  ← Fase 2.4
├── music/                      ← Fase 2.4
└── fonts/
```

> **Nota sobre os PNGs:** os arquivos PNG já estão nos diretórios corretos com os mesmos nomes dos SVGs (só muda a extensão). Os SVGs serão removidos na Fase 2.3.8.

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

#### `backgroundBaseColor` — DEPRECADO na 2.3.8
A partir da Fase 2.3.8, o fundo do jogo é **fixo** (não varia por animal). O campo `backgroundBaseColor` no model `Animal` permanece pra retrocompatibilidade da Coleção (Fase 2.6), mas **não é mais usado pelo `GameBackground`**.

### 4.1 Visual do tile
- **Fundo:** branco (`#FFFFFF`)
- **Contorno:** cor da tabela (3px, arredondado)
- **Marca d'água:** PNG do animal centralizado, opacidade ~28%, ocupa ~80% do tile
- **Número:** sobreposto, Fredoka Bold, cor `#3E2723`
- **Sombra:** suave abaixo
- **Animação idle:** respiração lenta + piscar aleatório (futuro)

### 4.2 Anfitrião do jogo (redesenhado na Fase 2.3.8)
- **Posição:** acima do tabuleiro, alinhado com o **primeiro tile da primeira linha** (canto superior esquerdo do tabuleiro)
- **Tamanho:** **igual ao de um tile** — mesmas dimensões (largura e altura) que uma célula do tabuleiro 4x4
- **Conteúdo (de cima pra baixo):**
  - **Nome do animal** (em cima) — Fredoka SemiBold, com `OutlinedText`
  - **PNG do animal** (embaixo) — ocupa o slot tile-sized, sem moldura, sem fundo branco
- **Atualização:** muda quando o jogador forma um tile de nível superior ao recorde da partida
- **Animação:** transição suave (fade + scale) ao trocar
- **Sem placeholder antes do primeiro tile** — o slot do anfitrião fica vazio até o primeiro animal aparecer (decidido na Fase 2.3.6 item B)
- **Espaço à direita do anfitrião** (onde antes ficava o `StatusPanel` ao lado): pode ficar livre ou receber elementos da UI a critério do `LayoutBuilder`. As vidas vão pro topo central agora — ver 4.5

### 4.3 Fundo do jogo — fixo (a partir da Fase 2.3.8)
- **Cor base:** verde-menta claro (`#D4F1DE`) ou outra cor neutra padrão definida em 10.2
- **Sem textura geométrica por animal** (placeholder removido)
- **Sem transição de cor** ao mudar anfitrião (não há mais variação)
- O `GameBackground` widget é simplificado pra um `Container` com cor única
- Decisão de design: simplifica o jogo, melhora performance (sem `AnimatedContainer` constante), e foca a atenção do jogador no tabuleiro e no anfitrião

### 4.4 Texto sobre cor — legibilidade
- Textos brancos importantes têm contorno preto sutil (1–1.5px) com anti-aliasing suave (Fase 2.3.6 item A)
- Aplicado em: nome do anfitrião, cronômetro, pontuação, recorde, todos os textos do `PauseOverlay`

### 4.5 Indicador de vidas (redesenhado na Fase 2.3.8)
- **Posição:** **topo central** da tela (acima do anfitrião e do tabuleiro)
- **Visual:**
  - **Coração único** (ícone, ~36x36dp) com **o número de vidas dentro** (Fredoka Bold, sobreposto ao coração)
  - **Badge à direita do coração** com texto:
    - Se vidas = 5/5: badge "Completo" (verde-folha, indica banco cheio sem ter que processar regen)
    - Se vidas < 5: badge com **timer regressivo** pra próxima vida (formato MM:SS) — substitui o "Completo"
    - Se vidas > 5 (compradas, ou recém-recebidas como recompensa): apenas o número dentro do coração; badge ausente ou ainda mostrando "Completo" (banco está acima do cap de regen)
- **Comportamento de tap:** abre painel/dialog explicando o sistema de vidas e mostrando opções (ex: assistir anúncio se ≤4 vidas, link pra loja)
- **Visualização escala bem:** o jogador pode ter 3, 5, 10, 50 vidas armazenadas — sempre 1 ícone com número, nunca uma fileira de corações que estoure a tela

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

### 5.3 Vidas zeradas
1. Diálogo: "Você ficou sem vidas! Quer assistir um anúncio de 30s pra ganhar +1 vida?"
2. Aceita: anúncio recompensado → +1 vida
3. **Limite diário:** até 40 anúncios recompensados de vida por dia
4. Após o limite: opção bloqueada até a meia-noite (timezone do dispositivo)

### 5.4 Modelo de dados
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

### 5.5 Lógica de adicionar vidas
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
- Mostra cada item com **ícone PNG** (Fase 2.3.8), **contador (badge)** e **estado**
- Itens com contador 0 ficam **acinzentados e desabilitados**, mas continuam visíveis

#### Ícones do inventário
PNGs em `assets/icons/inventory/`:
- `bomb_2.png`, `bomb_3.png`, `undo_1.png`, `undo_3.png`

#### Confirmação universal antes do uso (NOVO na Fase 2.3.8)
**TODOS os itens do inventário exigem confirmação antes de serem usados.** Não há mais ação imediata em nenhum tap de item.

**Fluxo unificado:**
1. Tap no ícone do item → abre `ConfirmUseDialog` com:
   - Ícone grande do item
   - Texto: "Usar [nome do item]?" (ex: "Usar Bomba 2?")
   - Sub-texto explicativo do efeito (ex: "Explode 2 casas adjacentes escolhidas")
   - Contador atual (ex: "Você tem 3 deste item")
   - Botão **"Cancelar"** e botão **"Usar"** (destacado)
2. Cancelar → fecha dialog, nada muda
3. Usar:
   - **Desfazer:** executa `gameNotifier.undo(steps)`, animação reversa (300ms), decrementa contador
   - **Bomba:** entra em modo seleção (`BombSelectionOverlay`); jogador escolhe casas; depois confirma "Explodir" no overlay → animação de explosão (500ms), tiles removidos, decrementa contador

> **Por que confirmar até pra Desfazer:** evita uso acidental (tap fora do tabuleiro durante swipe), respeita o valor escasso do item, e padroniza o comportamento da `InventoryBar`.

#### Regras de bombas
- **Bomba 2:** 2 casas adjacentes (compartilhar uma borda — 4-vizinhos: cima/baixo/esquerda/direita)
- **Bomba 3:** 3 casas, livre escolha (sem restrição de adjacência)
- Não pode explodir células vazias: feedback "Selecione um tile"
- Cancelar no `BombSelectionOverlay` não consome o item

### 6.3 Game over com itens disponíveis
1. Modal de Game Over checa `Inventory`
2. Se desfazer ≥1: oferece "Desfazer última jogada" (ressuscita) — passa pelo `ConfirmUseDialog`
3. Se bomba ≥1: oferece "Usar bomba" (entra em modo seleção) — passa pelo `ConfirmUseDialog`
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
| **Fundo do jogo (fixo, Fase 2.3.8)** | **Verde-menta claro** | **`#D4F1DE`** |
| Fundo (folhagem alternativa) | Verde-floresta médio | `#3FA968` |
| Tabuleiro | Madeira clara | `#E8D5B7` |
| Célula vazia | Madeira sombreada | `#C9B79C` |
| Tile preenchido | Branco | `#FFFFFF` |
| Acento (UI) | Laranja-tucano | `#FF8C42` |
| Texto principal | Marrom escuro | `#3E2723` |
| Texto sobre cor | Branco-creme | `#FFF8E7` |
| Contorno de texto | Preto | `#000000` |
| Sucesso / "Completo" | Verde-folha | `#66BB6A` |
| Alerta | Vermelho-açaí | `#C0392B` |
| Coração de vidas | Vermelho-coração | `#E53935` |
| Premium/dourado | Dourado | `#FFD54F` |

### 10.3 Tipografia
- **Títulos**: `Fredoka` (arredondada, divertida)
- **Texto/UI**: `Nunito` (legível, amigável)
- **Pontuação e número do tile**: `Fredoka Bold`
- **Número dentro do coração de vidas**: `Fredoka Bold`, branco com `OutlinedText`
- **Texto branco sobre fundo dinâmico**: contorno preto 1–1.5px com anti-aliasing (ver 4.4 e Fase 2.3.6 item A)

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
| ~~Mudança de fundo~~ | **Removido — fundo agora é fixo** |
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
| `ConfirmUseDialog` (entrada) | Fade + slide-up, 200ms |

---

## 11. Sons e Música

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
   │      ├── (vidas no topo central)
   │      ├── (anfitrião acima do primeiro tile, com nome em cima e PNG embaixo)
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
- **Indicador de vidas** no topo central (coração único + número + badge "Completo"/timer — ver 4.5)
- Botão grande **"Jogar"** (Novo jogo / Continuar partida salva)
- Cards: Loja, Ranking, Recompensa Diária (com badge), Convidar
- Ícones menores: Coleção, Configurações, Como Jogar
- Background: cena da floresta com paralaxe leve

### 12.3 Tela: Jogo (redesenhada na Fase 2.3.8)
**Layout (de cima pra baixo):**

1. **Topo central:** `LivesIndicator` (coração + número + badge "Completo"/timer)
2. **Acima do tabuleiro, lado esquerdo (sobre a 1ª coluna):** `HostBanner` tile-sized
   - Nome do animal em cima (com `OutlinedText`)
   - PNG do animal embaixo, ocupando o slot tile-sized
3. **Acima do tabuleiro, lado direito:** `StatusPanel` (cronômetro + pontuação + recorde + pause integrado)
4. **Centro:** tabuleiro 4x4
5. **Rodapé:** `InventoryBar` (4 itens com ícones PNG + badges de contador)

> **Nota de layout:** removida a regra antiga de "anfitrião alinhado às 2 primeiras colunas". Agora o anfitrião ocupa apenas a largura de **1 tile** (a primeira coluna). O lado direito do cabeçalho fica disponível pro `StatusPanel`.

#### 12.3.1 Posicionamento do botão pause
Integrado ao `StatusPanel` (canto direito) ou flutuante com `LayoutBuilder` garantindo margem de segurança ≥12dp.

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

> Os campos `hostAspectRatio`, `backgroundTexturePath` e `texturePattern` foram removidos na 2.3.8 — o anfitrião agora é tile-sized (proporção fixa 1:1) e o fundo é fixo.

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
- **Identificado:** processamento de SVG em runtime causa lentidão — motiva a Fase 2.3.8

### ✅ Fase 2.3.8 — Otimização de Assets + Refinamentos de UI (v0.5.0)
**Objetivo:** corrigir gargalo de performance (SVG → PNG) e fazer 7 ajustes de UI/UX que melhoram a experiência de jogo. Os PNGs já estão nos diretórios corretos com os mesmos nomes dos SVGs (só muda a extensão).

**Entregues:** A (SVG→PNG + precache), B (ConfirmUseDialog universal), C (anfitrião tile-sized, nome em cima), D (fundo fixo `#D4F1DE`), E (LivesIndicator: coração+número+badge "Bônus ⭐"), F (regenCap/earnedCap, addEarned/addPurchased), G (badge 99+, tooltip long-press). 125 testes, 0 falhas.

**Estimativa:** ~~4–6 dias.~~

#### A — Migrar todos os assets de SVG para PNG (entrega central)
**Bug atual:** o jogo está lento porque `flutter_svg` processa cada SVG em runtime. Com 11 animais (×2 versões: tile + host) e 4 ícones do inventário, são até 26 SVGs sendo decodificados — gargalo perceptível especialmente em devices Android medianos.

**Mudanças:**
- **Remover** dependência `flutter_svg` do `pubspec.yaml`
- Atualizar `pubspec.yaml` declarando os mesmos diretórios mas confirmando que apontam pra PNGs (nada muda no caminho — só a extensão dos arquivos)
- Refatorar `tile_widget.dart`:
  - Trocar `SvgPicture.asset(animal.svgPath)` por `Image.asset(animal.tilePngPath)`
  - Manter `Opacity(opacity: 0.28)` da marca d'água
  - Manter `BoxFit.contain` (Image.asset suporta direto)
  - Pré-cache via `precacheImage(AssetImage(...), context)` em vez de `precachePicture`
- Refatorar `host_artwork.dart`:
  - Trocar `SvgPicture.asset(animal.hostSvgPath)` por `Image.asset(animal.hostPngPath)`
  - Sem moldura, sem fundo branco, ocupando o slot tile-sized (ver item C)
- Refatorar `inventory_item_button.dart`:
  - Trocar `SvgPicture.asset(svgPath, ...)` por `Image.asset(pngPath, width: 32, height: 32)`
  - Manter `colorFilter` se já estava aplicado pra estado disabled (`Image.asset` aceita via `color` + `colorBlendMode`)
- Atualizar `animals_data.dart`: renomear campos `svgPath` → `tilePngPath` e `hostSvgPath` → `hostPngPath`; mudar extensões em todos os 11 entries
- Apagar arquivos `.svg` dos diretórios `assets/images/animals/tile/`, `assets/images/animals/host/`, `assets/icons/inventory/` (manter só PNGs)

**Casos de teste obrigatórios:**
- Cada um dos 11 níveis renderiza com PNG correto na tile (snapshot test)
- Anfitrião renderiza PNG correto pra cada animal
- Itens do inventário renderizam PNGs (`bomb_2`, `bomb_3`, `undo_1`, `undo_3`)
- **Performance:** medir FPS médio em 60s de gameplay vs versão 0.4.0 (SVG) — deve melhorar visivelmente em devices fracos
- App startup mais rápido (sem decodificação de SVGs em sequência)
- Pré-cache de PNGs via `precacheImage` no boot não causa lag visível
- Sem dependência residual de `flutter_svg` (lint: import deve falhar se alguém tentar usar)

#### B — Confirmação universal pra TODOS os itens do inventário
**Bug atual:** Desfazer já tinha confirmação, mas Bomba abre direto o modo de seleção. Comportamento inconsistente.

**Mudanças:**
- Criar widget `confirm_use_dialog.dart`:
  - Recebe: `String itemName`, `String description`, `int currentCount`, `IconData icon` (ou `String pngPath`), `VoidCallback onConfirm`
  - Layout: ícone grande, título "Usar [itemName]?", sub-texto descritivo, contador atual, botões Cancelar/Usar
- Refatorar `InventoryItemButton.onTap`:
  - Sempre abre `ConfirmUseDialog` antes de qualquer ação
  - Se confirma:
    - **Desfazer:** chama `gameNotifier.undo(steps)`, decrementa contador
    - **Bomba:** abre `BombSelectionOverlay` (que tem sua própria confirmação no botão "Explodir" — esse passo continua)
- Garantir que o dialog usa as mesmas convenções de UI (botões grandes, cores do tema, sombra inferior)
- Som específico de confirmação ao tocar "Usar" (ver 11.2)

**Casos de teste obrigatórios:**
- Tap em Desfazer 1 → abre `ConfirmUseDialog`; cancela → nada muda; confirma → desfaz e decrementa
- Tap em Desfazer 3 → mesma coisa
- Tap em Bomba 2 → abre `ConfirmUseDialog`; cancela → nada muda; confirma → entra em modo seleção
- Tap em Bomba 3 → mesma coisa
- Item desabilitado (contador 0): tap não abre dialog (visual já é acinzentado)
- Snapshot test do `ConfirmUseDialog` pra cada um dos 4 itens

#### C — Anfitrião redesenhado: tile-sized, posicionado sobre o 1º tile, nome em cima
**Bug atual:** o anfitrião ocupa 2 colunas e tem o nome embaixo do PNG. Decisão é diminuir pra 1 tile e inverter a ordem (nome em cima).

**Mudanças:**
- Refatorar `host_banner.dart`:
  - Layout vertical: `Column` com `Text` (nome) em cima, `HostArtwork` (PNG tile-sized) embaixo
  - Largura total = largura de 1 tile + nada de margem extra (alinha ao 1º tile da 1ª coluna do tabuleiro)
  - Altura = altura do tile + altura do texto + spacing (~4dp)
- Refatorar `host_artwork.dart`:
  - Container quadrado (1:1) com largura/altura dinâmica calculada via `LayoutBuilder` baseada na largura do tabuleiro
  - `Image.asset(animal.hostPngPath, fit: BoxFit.contain)` ocupando o slot inteiro
  - Sem moldura, sem borda, sem fundo branco
- Atualizar layout da `GameScreen`:
  - Remover regra antiga de "anfitrião alinhado às 2 primeiras colunas"
  - Posicionar `HostBanner` sobre a 1ª coluna do tabuleiro (canto superior esquerdo)
  - O espaço acima das colunas 2-4 fica disponível pro `StatusPanel` (cronômetro/score/pause)
- Nome do animal usa `OutlinedText` (Fredoka SemiBold, ~14sp pra caber na largura de 1 tile)

**Casos de teste obrigatórios:**
- Snapshot test: `HostBanner` ocupa exatamente largura de 1 tile, alinhado ao 1º tile do tabuleiro
- Nome do animal aparece em cima do PNG, não embaixo
- PNG ocupa o slot quadrado sem distorção (`BoxFit.contain`)
- Para cada um dos 11 animais: nome cabe na largura sem overflow (testar com "Mico-leão-dourado" — nome longo)
- `LayoutBuilder` ajusta o tamanho do tile do anfitrião proporcional ao tabuleiro (em telas estreitas e largas)

#### D — Fundo fixo (sem variação por animal)
**Bug atual:** o fundo muda de cor/textura conforme o animal anfitrião — adiciona complexidade e pode atrapalhar a leitura do tabuleiro.

**Mudanças:**
- Refatorar `game_background.dart`:
  - Reduzir a um `Container(color: AppColors.menta)` (`#D4F1DE`)
  - Remover toda lógica de `AnimatedContainer`, `Tween<Color>`, textura, crossfade
  - Remover dependência de `backgroundBaseColor` do `Animal` (manter o campo no model pra retrocompatibilidade da Coleção, mas não usar aqui)
- Atualizar `pubspec.yaml`: pasta `assets/images/textures/` pode ser removida ou mantida vazia (decidir no brainstorm — provavelmente remover, junto com a Fase 2.3.8.A antiga que não vai mais existir)
- Atualizar `animations_table` em 10.5: remover entrada "Mudança de fundo"
- Atualizar seção 4.3 do doc (já feito)

**Casos de teste obrigatórios:**
- `GameBackground` renderiza cor única (`#D4F1DE`) independente do anfitrião
- Trocar de Tanajura pra Capivara: fundo NÃO muda (assert direto)
- Performance: nenhum `AnimatedContainer` em loop no fundo (verificar com debug paint que o widget não está rebuildando)
- Tabuleiro continua bem visível no fundo menta (contraste adequado)

#### E — Indicador de vidas: topo central, coração único + número + badge "Completo"/timer
**Bug atual:** o indicador atual mostra vários corações em fileira; não escala bem se o jogador tem muitas vidas (compradas).

**Mudanças:**
- Refatorar `lives_indicator.dart`:
  - Layout horizontal: `Row` com `[Heart com número dentro] [Badge]`
  - **Heart com número:**
    - `Stack` com ícone de coração (`Icon(Icons.favorite, size: 36, color: AppColors.heartRed)`) por baixo
    - `OutlinedText` por cima (`Fredoka Bold`, branco, ~16sp) com o número de vidas
    - Centralizado dentro do coração
  - **Badge à direita:**
    - Se `current >= 5`: pill verde com texto "Completo" (Nunito SemiBold, ~12sp, branco)
    - Se `current < 5`: pill cinza com timer regressivo MM:SS pra próxima vida (calculado a partir de `nextRegenAt`)
  - Tap no indicador → abre dialog explicativo (ou navega pra Loja)
- Posicionar no **topo central** da `GameScreen` e da `HomeScreen` (acima do `HostBanner` e do tabuleiro)
- Animação:
  - Vida ganha: coração pulsa (300ms) + badge atualiza
  - Vida perdida (game over): coração tremula (200ms) + número decrementa

**Casos de teste obrigatórios:**
- `LivesIndicator` com 1 vida → coração com "1" + timer regressivo
- `LivesIndicator` com 4 vidas → coração com "4" + timer
- `LivesIndicator` com 5 vidas → coração com "5" + badge "Completo"
- `LivesIndicator` com 10 vidas (compradas) → coração com "10" + badge "Completo" (banco está acima do cap de regen)
- `LivesIndicator` com 99 vidas → coração com "99" + badge "Completo" (não estoura layout)
- Timer regressivo atualiza a cada segundo
- Tap abre dialog/painel
- Snapshot test pra cada estado (1, 4, 5, 10, 99)

#### F — Sistema de vidas: confirmar regras de armazenamento (5/15/ilimitado)
As regras já estão na seção 5, mas precisam ser refletidas no código:

**Mudanças:**
- Atualizar `LivesState` model:
  - Adicionar campo `regenCap` (= 5, constante) e `earnedCap` (= 15, constante)
  - Manter `current` como `int` sem upper bound (pode ser 100, 1000)
- Atualizar `LivesNotifier`:
  - Método `regenerate()`: só roda se `current < regenCap`; soma 1; atualiza `nextRegenAt`
  - Método `addEarned(int amount)`: `current = min(current + amount, earnedCap)` — pra recompensas
  - Método `addPurchased(int amount)`: `current = current + amount` — sem cap
  - Método `consume()`: decrementa 1, agenda regen se `current < regenCap`
- Verificar que recompensas (diárias, ranking, recorde, convite) chamam `addEarned` e compras chamam `addPurchased`

**Casos de teste obrigatórios:**
- Estado inicial: `current = 5`, `regenCap = 5`, `earnedCap = 15`, `nextRegenAt = null`
- Game over: `current` decrementa pra 4, `nextRegenAt` é agendado pra +30min
- Após 30min de regen: `current` volta pra 5, `nextRegenAt` vira null
- Receber recompensa de 5 vidas com `current = 14`: vai pra 15 (não 19) — clamp em earnedCap
- Receber recompensa de 5 vidas com `current = 15`: fica em 15 (clamp)
- Comprar 10 vidas com `current = 14`: vai pra 24 (sem cap)
- Comprar 10 vidas com `current = 50`: vai pra 60 (sem cap)
- Após game over com `current = 24`: vai pra 23, `nextRegenAt = null` (porque ainda > regenCap)
- Após game over com `current = 6`: vai pra 5, `nextRegenAt = null`
- Após game over com `current = 5`: vai pra 4, `nextRegenAt = +30min` (regen ativa abaixo do cap)

#### G — Inventário sem cap pra bombas e desfazer
**Bug atual:** doc anterior mencionava cap de 15 pra inventário. Decisão é remover — só vidas têm cap.

**Mudanças:**
- Atualizar `Inventory` model: remover qualquer constante `MAX_INVENTORY` ou similar
- `InventoryNotifier.add(ItemType, int)`: soma sem clamp
- Badges de contador no `InventoryBar`: se passar de 99, mostrar "99+" (texto curto pra não estourar layout)
- Documentação na seção 6.1: explicitar "sem cap" pros 4 itens

**Casos de teste obrigatórios:**
- Comprar 4 bombas com `bomb3 = 100`: fica em 104
- Receber recompensa com `undo1 = 50`: soma normalmente
- Badge no botão mostra "99+" quando contador > 99
- Sem clamp/cap em nenhum item do `Inventory`

---

### 🔜 Fase 2.4 — Sons + Música ambiente (1–2 semanas)
- Sons dos 11 animais (~50KB cada, OGG/M4A/MP3)
- Sons de UI completos
- Música ambiente: loop de floresta com flautas + marimba
- Integrar com `audioplayers` ou `just_audio`
- Pool de AudioPlayers
- Mixer simples nas Configurações
- Pré-carregar tudo no início do app

> **Nota:** texturas de fundo (que estavam previstas na antiga 2.3.8.A) foram removidas — fundo é fixo agora.

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

### 🔜 Fase 5 — Polimento e Lançamento
- Localização PT-BR / EN
- Acessibilidade
- Modo escuro (opcional)
- Testes em dispositivos reais
- Build para iOS, Android, Web
- Submissão App Store / Play Store

---

## 16. Considerações Especiais

### 16.1 Acessibilidade
- WCAG AA
- Forma + cor + número + nome
- `Semantics` pra leitor de tela
- Pause overlay anunciado ao leitor de tela ("Jogo pausado")
- `LivesIndicator` anunciado: "5 vidas, banco completo" ou "3 vidas, próxima em 12 minutos"
- Modo "alta visibilidade"
- Tamanho de fonte ajustável

### 16.2 Performance
- `const` e Riverpod selectors
- **PNGs em vez de SVGs (Fase 2.3.8 item A)** — gargalo de processamento removido
- `precacheImage` pra os 22 PNGs dos animais + 4 do inventário no boot
- Pool de AudioPlayers
- 60fps em Snapdragon 660+ / iPhone 8+
- `RepaintBoundary` no `GameBackground` (agora muito mais leve por ser cor única)
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

## 17. Prompt Sugerido para o Claude Code (Fase 2.3.8 — via skill superpowers)

> O prompt abaixo entra no fluxo do **superpowers/brainstorming**. O resultado esperado é uma **spec detalhada da Fase 2.3.8** (refinada via brainstorm), que depois alimenta o **superpowers/writing-plans** pra gerar o plano executável. Nada de código nesta etapa — apenas elicitação, refinamento de design e plano.

---

> Use a skill `superpowers/brainstorming` pra refinar o design da próxima fase do projeto **Capivara 2048** (Flutter).
>
> **Contexto:** Estamos no projeto Capivara 2048. Use `CAPIVARA_2048_DESIGN.md` como spec geral (especialmente seções 4.2, 4.3, 4.5, 5, 6.2, 12.3, 13.1, 13.4, 13.5 e 15 — Fase 2.3.8).
>
> **Fases concluídas:**
> - Fase 1, 2.1, 2.2, 2.3, 2.3.5, 2.3.6
> - **Fase 2.3.7 (v0.4.0)** — SVGs dos 11 animais integrados em tiles e anfitrião, Sagui no nível 5, PauseOverlay com OutlinedText completo, ícones SVG do inventário, galeria de debug `AnimalsGalleryScreen`
> - **Identificado em uso real:** processamento de SVG em runtime causa lentidão perceptível, especialmente em devices Android medianos
>
> **Tópico do brainstorm:** desenhar a **Fase 2.3.8 — Otimização de Assets + Refinamentos de UI**. Sete entregas que podem rodar em paralelo após o item A:
>
> **A — Migrar SVGs para PNGs (entrega central, desbloqueia performance):** remover `flutter_svg`, trocar `SvgPicture.asset` por `Image.asset` em `tile_widget.dart`, `host_artwork.dart`, `inventory_item_button.dart`. Renomear campos em `animals_data.dart` (`svgPath` → `tilePngPath`, `hostSvgPath` → `hostPngPath`). Apagar arquivos SVG, manter só PNGs (que já estão nos diretórios com mesmo nome, só muda extensão). Pré-cache via `precacheImage` no boot.
>
> **B — Confirmação universal pra TODOS os itens do inventário:** criar `confirm_use_dialog.dart` reutilizável. Refatorar `InventoryItemButton.onTap` pra abrir o dialog antes de qualquer ação (Desfazer já tinha; Bomba não tinha — agora terá). Manter o passo de confirmação no `BombSelectionOverlay` ("Explodir") como segunda confirmação contextual.
>
> **C — Anfitrião redesenhado: tile-sized, posicionado sobre o 1º tile, nome em cima:** refatorar `host_banner.dart` (Column: nome em cima, PNG embaixo) e `host_artwork.dart` (slot quadrado 1:1 dimensionado pelo `LayoutBuilder` baseado no tabuleiro). Anfitrião agora ocupa largura de 1 tile (não 2). Nome em cima usa `OutlinedText` Fredoka SemiBold ~14sp.
>
> **D — Fundo fixo (sem variação por animal):** simplificar `game_background.dart` pra `Container(color: #D4F1DE)`. Remover `AnimatedContainer`, `Tween<Color>`, textura geométrica, crossfade. Manter `backgroundBaseColor` no model `Animal` apenas pra Coleção (Fase 2.6).
>
> **E — Indicador de vidas: topo central, coração único + número + badge "Completo"/timer:** redesenhar `lives_indicator.dart` pra `Row` com [coração (Icon) com número dentro (OutlinedText)] + [badge "Completo" verde se ≥5, ou timer MM:SS regressivo se <5]. Tap abre dialog explicativo ou navega pra loja. Escala bem pra qualquer quantidade armazenada (1, 5, 50, 99+).
>
> **F — Sistema de vidas: confirmar regras 5/15/ilimitado:** atualizar `LivesState` (campos `regenCap=5`, `earnedCap=15`, `current` sem upper bound), `LivesNotifier` com métodos `regenerate()`, `addEarned(N)` (clamp em 15), `addPurchased(N)` (sem cap), `consume()`. Recompensas chamam `addEarned`, loja chama `addPurchased`.
>
> **G — Inventário sem cap pra bombas e desfazer:** remover qualquer cap residual no `Inventory`. Badge no `InventoryBar` mostra "99+" se contador > 99.
>
> **Pontos abertos pra explorar no brainstorm (elicitação esperada):**
>
> Sobre o item A (PNGs):
> - Tamanhos ideais dos PNGs: tiles costumam ser 200x200 ou 256x256? Hosts podem ser maiores (ex: 384x384) já que aparecem em destaque. Custo de memória vs nitidez em telas Retina.
> - `precacheImage` no boot — todos os 26 PNGs (22 animais + 4 inventário), ou priorizar os primeiros 5 níveis (mais comuns)?
> - Caches do Flutter: `Image.asset` usa cache automaticamente. Vale forçar tamanho via `cacheWidth`/`cacheHeight` pra reduzir RAM em devices fracos?
> - Estratégia de teste de regressão visual: já tinha snapshot tests com SVG (Fase 2.3.7 item E). Esses snapshots vão precisar ser regenerados pra PNG — vale aproveitar pra atualizar o `golden_toolkit`/`alchemist`?
>
> Sobre o item B (confirmação universal):
> - O `ConfirmUseDialog` deve ter uma opção "Não perguntar de novo" (preferência salva)? Ou confirmação universal é firme (vale mais que conveniência)?
> - Animação de entrada do dialog — quanto tempo? 200ms é padrão Material; vale algo mais lento pra dar peso à decisão?
> - Som de confirmação: clique decisivo só pro botão "Usar" (Cancelar é neutro)?
>
> Sobre o item C (anfitrião tile-sized):
> - Texto do nome do animal acima do PNG: 1 linha sempre, com `FittedBox` se for longo? Ou permitir 2 linhas pra "Mico-leão-dourado"?
> - Espaço acima da coluna 2 (à direita do anfitrião) — fica vazio ou recebe `StatusPanel` reposicionado? Como afeta a hierarquia visual?
> - Tamanho do tile do anfitrião — exatamente igual ao do tile do tabuleiro, ou ligeiramente maior pra dar destaque (ex: 110% do tamanho do tile)?
>
> Sobre o item D (fundo fixo):
> - Cor `#D4F1DE` (verde-menta) é a melhor escolha, ou vale considerar outras (cinza muito claro neutro, ou a paleta da Home)?
> - O slot vazio do anfitrião antes do primeiro tile fica com a mesma cor do fundo, sumindo visualmente — tudo bem ou precisa de algum marcador?
>
> Sobre o item E (LivesIndicator):
> - O timer regressivo atualiza a cada segundo via `Timer.periodic`? Ou via `StreamBuilder<DateTime>` mais limpo?
> - Quando o jogador tem ≥6 vidas (acima do regen cap), o badge mostra "Completo" verde, mas o jogador pode ter conquistado isso. Vale um badge alternativo tipo "Bônus" amarelo pra distinguir 5/5 (regen completa) de >5 (extra comprado/recompensado)? Ou mantém "Completo" pra simplificar?
> - Tap no indicador na `HomeScreen` abre dialog explicativo. Tap na `GameScreen` durante uma partida — abre o mesmo dialog ou pausa o jogo?
> - Tamanho do coração: 36x36dp é bom em smartphones, mas pode ficar pequeno em tablets — usar `MediaQuery` pra escalar?
>
> Sobre o item F (regras de vidas):
> - Migração de jogadores existentes (v0.4.0 → 2.3.8): se algum jogador já tem `current = 15` por compras antigas, isso continua funcionando? Schema do Hive precisa de versão e migration?
> - O que acontece se o jogador comprar 100 vidas e nunca jogar? Game over depois de 30 dias — `regenerate` deve ser chamada quantas vezes? Resposta: nenhuma, porque `current > regenCap`. Vale documentar isso explicitamente.
>
> Sobre o item G (inventário sem cap):
> - Badge "99+" — quando o número exato importa? Ex: jogador quer saber se tem 100 ou 200 bombas. Vale tap no botão mostrar contador exato em tooltip?
>
> Sobre integração:
> - Ordem das 7 entregas: A primeiro (desbloqueia performance), depois B/C/D/E em paralelo, F/G como cleanup final?
> - Vale tirar screenshots/vídeo do app rodando antes/depois da migração SVG→PNG pra documentar o ganho de performance?
> - Testes de regressão: a galeria de debug `AnimalsGalleryScreen` (Fase 2.3.7 item E) precisa ser atualizada pra usar PNGs também? Ela é o lugar ideal pra validar a migração visualmente.
>
> **Output esperado do brainstorm:**
> Uma **spec detalhada da Fase 2.3.8** (markdown, tipo `FASE_2_3_8_SPEC.md`) com:
> - Decisões tomadas em cada ponto aberto
> - Para cada uma das 7 sub-entregas: arquivos a criar/modificar, mudança exata, casos de teste obrigatórios, critérios de aceite
> - Ordem de execução recomendada e dependências entre as 7 entregas
> - Estratégia de migração de schema do Hive se necessário (item F)
> - Cobertura de testes existentes que precisa ser atualizada (especialmente snapshot tests com SVGs)
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
