# 🦫 Capivara 2048 — Design Concept (Consolidado v2)

> Documento de especificação para desenvolvimento. Pensado para ser alimentado em ferramentas como Claude Code para implementação iterativa.
>
> **Status atual:** Fase 2.3.10 concluída ✅ (v0.7.0) — `GameHeader` extraído, `HostBanner` 2×2 (152dp), `StatusPanel` reescalonado (18/24/13sp), `PauseButtonTile` separado do StatusPanel. 152 testes passando.
>
> **Próximo:** **Fase 2.4 — Áudio** — sons dos 11 animais e UI + música ambiente.

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
| Áudio | `audioplayers` ou `just_audio` | Sons e música (Fase 2.4) |
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
│   │   ├── status_panel.dart            ✅ (ajustado pra remover pause na 2.3.10)
│   │   ├── host_banner.dart             ✅ (expandido pra 2x2 na 2.3.10)
│   │   ├── host_artwork.dart            ✅ (escala pro novo tamanho 2x2 na 2.3.10)
│   │   ├── game_background.dart         ✅
│   │   ├── lives_indicator.dart         ✅
│   │   ├── lives_status_banner.dart     ✅
│   │   ├── pause_button_tile.dart       ✅ (reposicionado na 2.3.10)
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
│   ├── fundo.png                     ✅
│   ├── animals/tile/                 ← 11 PNGs ✅
│   └── animals/host/                 ← 11 PNGs ✅
├── icons/inventory/                  ← 4 PNGs ✅ (bomb_2, bomb_3, undo_1, undo_3)
├── sounds/animals/                   ← Fase 2.4
├── sounds/ui/                        ← Fase 2.4
├── music/                            ← Fase 2.4
└── fonts/
```

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

### 4.1 Visual do tile
- **Fundo:** branco (`#FFFFFF`)
- **Contorno:** cor da tabela (3px, arredondado)
- **Marca d'água:** PNG do animal centralizado, opacidade ~28%, ocupa ~80% do tile
- **Número:** sobreposto, Fredoka Bold, cor `#3E2723`
- **Sombra:** suave abaixo
- **Animação idle:** respiração lenta + piscar aleatório (futuro)

### 4.2 Anfitrião do jogo (atualizado na Fase 2.3.10 — 2x2)
- **Posição:** acima do tabuleiro, **lado direito**, alinhado às **colunas 3 e 4** do tabuleiro
- **Tamanho:** **2 tiles de largura × 2 tiles de altura** (área de 2×2 = 4 tiles do tabuleiro)
  - Largura calculada: `2 × tileWidth + 1 × tileSpacing`
  - Altura calculada: `2 × tileHeight + 1 × tileSpacing`
- **Conteúdo (de cima pra baixo):**
  - **Nome do animal** (em cima) — Fredoka SemiBold, ~16sp (cabe melhor agora com largura 2x), com `OutlinedText`
  - **PNG do animal** (embaixo) — ocupa o slot 2x2 com `BoxFit.contain`, sem moldura, sem fundo branco
- **Atualização:** muda quando o jogador forma um tile de nível superior ao recorde da partida
- **Animação:** transição suave (fade + scale) ao trocar
- **Sem placeholder antes do primeiro tile** — o slot do anfitrião fica vazio até o primeiro animal aparecer
- **Lado esquerdo do mesmo nível** (acima das colunas 1 e 2): recebe o **`PauseButtonTile`** alinhado pela base, com espaço vazio acima dele (porque é só 1x1, mas a linha tem altura 2x)

### 4.3 Fundo do jogo (Fase 2.3.9 — PNG)
- Imagem PNG (`assets/images/fundo.png`) renderizada em tela cheia via `BoxFit.cover`
- Sem variação por animal — fundo é o mesmo em qualquer fase do jogo
- Cor de fallback: `#D4F1DE` (verde-menta) é exibido apenas se o PNG falhar ao carregar

### 4.4 Texto sobre cor — legibilidade
- Textos brancos importantes têm contorno preto sutil (1–1.5px) com anti-aliasing suave (Fase 2.3.6 item A)
- Aplicado em: nome do anfitrião, cronômetro, pontuação, recorde, todos os textos do `PauseOverlay`

### 4.5 Indicador de vidas (Fase 2.3.9)
- **Posição:** topo da tela (acima de tudo)
- **Visual:** coração único (~36x36dp) com número dentro + faixa estilizada à direita com 4 estados (ver 5.3)
- **Comportamento de tap:** abre dialog explicando o sistema de vidas

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
| Faixa | Condição | Cor |
|---|---|---|
| **"Completo"** | `current == 5` | Verde-folha `#66BB6A` |
| **"Bônus"** | `current > 5` | Dourado `#FFD54F` |
| **"Restando MM:SS"** | `0 < current < 5` | Laranja-aviso `#FFA726` |
| **"Sem vidas"** | `current == 0` | Vermelho `#EF5350` |

Animações: fade 300ms entre estados + scale 1→1.1→1 (200ms) em transições positivas (vida ganha).

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
**TODOS os itens do inventário exigem confirmação antes de serem usados.**

**Fluxo unificado:**
1. Tap no ícone do item → abre `ConfirmUseDialog` com:
   - Ícone grande do item
   - Texto: "Usar [nome do item]?"
   - Sub-texto explicativo do efeito
   - Contador atual ("Você tem 3 deste item")
   - Botão **"Cancelar"** e botão **"Usar"** (destacado)
2. Cancelar → fecha dialog, nada muda
3. Usar:
   - **Desfazer:** executa `gameNotifier.undo(steps)`, animação reversa (300ms), decrementa contador
   - **Bomba:** entra em modo seleção (`BombSelectionOverlay`); jogador escolhe casas; depois confirma "Explodir" → animação de explosão (500ms), tiles removidos, decrementa contador

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
| "Bônus" (faixa de vidas) | Dourado | `#FFD54F` |
| "Restando" (faixa de vidas) | Laranja-aviso | `#FFA726` |
| "Sem vidas" (faixa de vidas) | Vermelho | `#EF5350` |
| Alerta | Vermelho-açaí | `#C0392B` |
| Coração de vidas | Vermelho-coração | `#E53935` |
| Premium/dourado | Dourado | `#FFD54F` |

### 10.3 Tipografia
- **Títulos**: `Fredoka` (arredondada, divertida)
- **Texto/UI**: `Nunito` (legível, amigável)
- **Pontuação e número do tile**: `Fredoka Bold`
- **Número dentro do coração de vidas**: `Fredoka Bold`, branco com `OutlinedText`
- **Texto da faixa de vidas (Completo/Bônus/Restando/Sem vidas)**: `Fredoka SemiBold`, ~13sp, com `OutlinedText`
- **Nome do anfitrião 2x2**: `Fredoka SemiBold`, ~16sp (a partir da 2.3.10), com `OutlinedText`
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
| Faixa de vidas — transição entre estados | Fade entre cores 300ms + scale 1→1.1→1 (200ms) em transições positivas |
| `ConfirmUseDialog` (entrada) | Fade + slide-up, 200ms |
| Botão pause tile-sized — pressionado | Scale 1 → 0.95 → 1, 100ms |

---

## 11. Sons e Música
*(Implementação na Fase 2.4 — depois das fases visuais e antes do backend)*

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
   │      ├── (vidas no topo central — coração + faixa estilizada)
   │      ├── (StatusPanel: cronômetro + pontuação + recorde — sem pause)
   │      ├── (linha intermediária: PauseButtonTile à esquerda, Anfitrião 2x2 à direita)
   │      ├── (tabuleiro 4x4)
   │      ├── (inventário no rodapé)
   │      └── [Game Over Modal]
   │              ├── Usar item (com ConfirmUseDialog)
   │              ├── Anúncio para item grátis
   │              ├── Loja
   │              └── Voltar ao Menu
   ├── [Loja]
   ├── [Ranking]
   ├── [Recompensas Diárias]
   ├── [Convidar Amigos]
   ├── [Resgatar Código]
   ├── [Coleção de Animais]
   ├── [Configurações]
   └── [Como Jogar]
```

### 12.2 Tela: Home
- Logo grande com a Capivara mascote ao centro
- **Indicador de vidas** no topo central (coração + faixa "Completo/Bônus/Restando/Sem vidas")
- Botão grande **"Jogar"** (Novo jogo / Continuar partida salva)
- Cards: Loja, Ranking, Recompensa Diária (com badge), Convidar
- Ícones menores: Coleção, Configurações, Como Jogar
- Background: cena da floresta com paralaxe leve

### 12.3 Tela: Jogo (atualizada na Fase 2.3.10)
**Layout (de cima pra baixo):**

1. **Topo:** `LivesIndicator` (coração + faixa estilizada)
2. **Abaixo:** `StatusPanel` (cronômetro + pontuação + recorde) — **sem o pause** (separado na 2.3.10)
3. **Linha intermediária (entre StatusPanel e tabuleiro):**
   - **Lado esquerdo (sobre colunas 1-2):** `PauseButtonTile` (1 tile, alinhado à base da linha)
   - **Lado direito (sobre colunas 3-4):** `HostBanner` 2x2 (nome em cima, PNG embaixo)
4. **Centro:** tabuleiro 4x4
5. **Rodapé:** `InventoryBar` (4 itens com ícones PNG + badges de contador)

> **Nota de layout:** o cabeçalho não é mais uma única `Row` com 3 zonas (como na 2.3.9). Agora são **3 linhas distintas empilhadas**:
> - Linha A: `LivesIndicator` (centralizado)
> - Linha B: `StatusPanel` (largura total, sem pause integrado)
> - Linha C: `Row([PauseButtonTile, HostBanner 2x2])` — pause à esquerda, anfitrião à direita ocupando 2 colunas em largura e 2 tiles de altura
>
> A altura da Linha C é dominada pela altura do anfitrião (2 tiles + 1 spacing). O `PauseButtonTile` tem altura de apenas 1 tile, então o `Align` deixa ele alinhado pela base (próximo do tabuleiro), ou pelo topo, ou centralizado — decidir no brainstorm.

#### 12.3.1 Posicionamento do botão pause (atualizado na Fase 2.3.10)
- **Tile-sized 1×1, fixo, separado do StatusPanel**
- Posicionado na **linha intermediária do cabeçalho**, alinhado à esquerda do tabuleiro (sobre as 2 primeiras colunas — porque o anfitrião ocupa as 2 últimas)
- **NÃO é mais flutuante** (regra mantida desde a 2.3.9)
- **NÃO é mais grudado ao recorde/pontuação/timer** (correção da 2.3.10)
- Ícone de pausa centralizado + texto "Pausar" embaixo
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

### 12.9 Tela: Debug — Galeria de Animais
Tela acessível apenas em build de debug (via `kDebugMode`). Mostra os 11 animais lado a lado em 2 modos (tile + host). Atualizada na 2.3.10 pra mostrar host no novo tamanho 2x2.

---

## 13. Modelo de Dados

### 13.1 Animal
```dart
class Animal {
  final int level;
  final int value;
  final String name;
  final String? scientificName;
  final String tilePngPath;
  final String hostPngPath;
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
- 5 bugs visuais corrigidos
- Inventário completo: Model + Hive + Notifier, InventoryBar, Desfazer 1/3, Bomba 2/3, Game Over modal
- Ícones placeholder Material/Lucide

### ✅ Fase 2.3.7 — Integração de Assets dos Animais + Refinamentos (v0.4.0)
- A — SVGs dos 11 animais integrados
- B — Sagui no nível 5 (substituiu Arara-azul)
- C — `OutlinedText` completo no `PauseOverlay`
- D — Ícones SVG do inventário
- E — Tela debug `AnimalsGalleryScreen`
- **Identificado:** processamento de SVG em runtime causa lentidão

### ✅ Fase 2.3.8 — Otimização de Assets + Refinamentos de UI (v0.5.0)
- A — Migração SVG → PNG
- B — `ConfirmUseDialog` universal
- C — Anfitrião redesenhado: tile-sized, nome em cima
- D — Fundo fixo `#D4F1DE`
- E — `LivesIndicator`: coração único + número + badge
- F — `LivesState` com `regenCap`/`earnedCap`
- G — Inventário sem cap pra bombas e desfazer
- 125 testes passando

### ✅ Fase 2.3.9 — Refinamentos visuais (v0.6.0)
- A — `LivesStatusBanner` com 4 estados (Completo/Bônus/Restando/Sem vidas)
- B — `PauseButtonTile` tile-sized fixo
- C — Fundo do jogo via PNG (`fundo.png`)
- `GameScreen` refatorado pra `ConsumerWidget` (removidos `_pauseTop`/`_headerKey`/`_updatePausePosition`)
- 143 testes passando

### ✅ Fase 2.3.10 — Reorganização do cabeçalho + Anfitrião 2×2 (v0.7.0)
- A — `GameHeader` (`StatelessWidget`) extraído da `GameScreen`; layout: `LivesIndicator` → `Row(HostBanner 2×2 | Column(StatusPanel + PauseButtonTile))`
- B — `HostBanner` fixado em 152dp (`GameConstants.twoCellWidth`); `_Placeholder` com silhueta Capivara (opacity 0.15) + "Comece!"; nome Fredoka 16sp com `maxLines:2`
- C — `HostArtwork`: `BoxFit.cover` (era `contain`); `size` recebido direto (sem `LayoutBuilder`)
- D — `StatusPanel`: fontes 18sp/24sp/13sp; `CrossAxisAlignment.center`
- E — `PauseButtonTile` separado do `StatusPanel`; alinhado à esquerda em slot 152×72dp via `Align(centerLeft)`
- F — Galeria debug: coluna "Host 2×2" mostrando `HostArtwork` em 152dp para todos os 11 animais
- 152 testes passando

---

### 🔜 Fase 2.4 — Áudio (1–2 semanas)
**Sons dos 11 animais e UI + música ambiente.**

- Sons dos 11 animais (~50KB cada, OGG/M4A/MP3) — ver tabela 11.1
- Sons de UI completos — ver lista 11.2
- Música ambiente: loop de floresta com flautas + marimba
- Integrar com `audioplayers` ou `just_audio` (decidir qual)
- Pool de AudioPlayers (evita latência no merge)
- Mixer simples nas Configurações (slider SFX + slider música + mute persistente)
- Pré-carregar tudo no início do app

> **Posicionamento desta fase:** o áudio entra **depois** do polimento visual (2.3.x) e **antes** das próximas features de gameplay (recompensas, coleção, loja). Ele não bloqueia gameplay, mas a essa altura a UI estará estabilizada e os sons casarão com os elementos visuais finais.

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

### 🔜 Fase 5 — Polimento + Lançamento
- Localização PT-BR / EN
- Acessibilidade (contraste, leitor de tela, fonte ajustável)
- Modo escuro (opcional)
- Testes em dispositivos reais
- Build para iOS, Android, Web
- Submissão App Store / Play Store / Web hosting
- Política de privacidade e termos de uso
- LGPD/COPPA compliance

---

## 16. Considerações Especiais

### 16.1 Acessibilidade
- WCAG AA
- Forma + cor + número + nome
- `Semantics` pra leitor de tela
- Pause overlay anunciado ao leitor de tela ("Jogo pausado")
- `LivesIndicator` anunciado: "5 vidas, banco completo" / "8 vidas, bônus" / "3 vidas, próxima em 12 minutos" / "Sem vidas — aguarde 30 minutos"
- `PauseButtonTile` anunciado: "Botão Pausar"
- `HostBanner` anunciado: "Anfitrião: [nome do animal]"
- Modo "alta visibilidade"
- Tamanho de fonte ajustável

### 16.2 Performance
- `const` e Riverpod selectors
- PNGs em vez de SVGs (Fase 2.3.8 item A) — gargalo removido
- `precacheImage` pra os 22 PNGs dos animais + 4 do inventário + `fundo.png` no boot
- Pool de AudioPlayers (Fase 2.4)
- 60fps em Snapdragon 660+ / iPhone 8+
- `RepaintBoundary` no `GameBackground`
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

## 17. Prompt Sugerido para o Claude Code (Fase 2.3.10 — via skill superpowers)

> O prompt abaixo entra no fluxo do **superpowers/brainstorming**. O resultado esperado é uma **spec detalhada da Fase 2.3.10** (refinada via brainstorm), que depois alimenta o **superpowers/writing-plans** pra gerar o plano executável. Nada de código nesta etapa — apenas elicitação, refinamento de design e plano.

---

> Use a skill `superpowers/brainstorming` pra refinar o design da próxima fase do projeto **Capivara 2048** (Flutter).
>
> **Contexto:** Estamos no projeto Capivara 2048. Use `CAPIVARA_2048_DESIGN.md` como spec geral (especialmente seções 4.2, 12.3, 12.3.1 e 15 — Fase 2.3.10).
>
> **Fases concluídas:**
> - Fase 1 a 2.3.8
> - **Fase 2.3.9 (v0.6.0)** — fundo PNG, `LivesStatusBanner` 4 estados, `PauseButtonTile` tile-sized fixo, `GameScreen` como `ConsumerWidget`. 143 testes passando.
>
> **Tópico do brainstorm:** desenhar a **Fase 2.3.10 — Reorganização do cabeçalho + Anfitrião 2x2**. Dois ajustes de layout identificados em uso real:
>
> **A — Separar pause do StatusPanel:** atualmente o `PauseButtonTile` está na mesma `Row` que o `StatusPanel` (cronômetro/pontuação/recorde), parecendo "grudado" no recorde. A correção é refatorar o cabeçalho em **3 linhas distintas**:
> - Linha A: `LivesIndicator` (já existente)
> - Linha B: `StatusPanel` largura total — só cronômetro + pontuação + recorde, sem pause
> - Linha C (entre StatusPanel e tabuleiro): `Row([PauseButtonTile, HostBanner 2x2])`
>
> **B — Anfitrião 2x2 no lado direito:** o anfitrião 1x1 ficou pequeno demais. Expandir pra ocupar 2 tiles de largura (colunas 3-4) e 2 tiles de altura. PNG ocupa todo o slot 2x2 com `BoxFit.contain`. Nome em cima pode ser maior (~16sp) porque tem mais largura. `HostArtwork` recalcula dimensões via `LayoutBuilder`.
>
> **Pontos abertos pra explorar no brainstorm (elicitação esperada):**
>
> Sobre o item A (cabeçalho em 3 linhas):
> - Spacing vertical entre as 3 linhas — 8dp uniforme, ou hierarquia (mais espaço entre Linha A e B, menos entre B e C)?
> - O `StatusPanel` agora ocupa largura total — vale aumentar o tamanho da fonte do cronômetro/pontuação/recorde já que tem mais espaço, ou manter? Como afeta a hierarquia visual?
> - Visualmente, ter pause + anfitrião na mesma linha (Linha C) faz sentido, ou seria melhor separar em mais uma linha (Linha C: pause; Linha D: anfitrião)? Tradeoff de altura total do cabeçalho vs clareza.
> - Quando o jogo recém-iniciado e o anfitrião está vazio (Fase 2.3.6 item B): o slot 2x2 fica em branco. Isso parece estranho? Ou tudo bem porque a área é maior? Vale silhueta da Capivara em opacity baixa enquanto não tem nada?
>
> Sobre o item B (anfitrião 2x2):
> - Alinhamento vertical do `PauseButtonTile` na Linha C (já que tem altura menor que o anfitrião 2x2): base, topo, ou centro? Qual fica melhor visualmente — pause "ancorado" no tabuleiro (base), "subindo" junto com o nome (topo), ou flutuando no meio?
> - Os PNGs do anfitrião foram desenhados pensando num slot 1x1 (tile-sized) na Fase 2.3.7. Agora num slot 2x2, vão ficar maiores — algum animal pode ficar visualmente desproporcional (ex: muito alto, ou com bordas vazias)? Vale revalidar todos na galeria de debug?
> - O `BoxFit.contain` no slot 2x2 quadrado preserva proporção mas pode deixar barras nas laterais/topo/base se o PNG não for quadrado. Faz sentido manter `contain`, ou vale `BoxFit.cover` (preenche tudo, corta bordas)?
> - Tamanho do nome do animal (~16sp foi sugerido) — vale fazer maior já que tem 2x a largura? Ex: 18sp, 20sp? Considerar legibilidade vs hierarquia (não pode competir com o número do tile).
> - Fronteira: o slot 2x2 do anfitrião e os tiles do tabuleiro abaixo têm exatamente o mesmo grid de colunas (3-4)? Ou tem leve offset? Importante pra bater visualmente.
>
> Sobre integração:
> - Ordem das 2 entregas: A primeiro (refatoração estrutural do cabeçalho), B depois (preenche um lado da Linha C criada no A). Confirma a sequência?
> - A Galeria `/debug/animals_gallery` atualmente mostra host no tamanho 1x1 — atualizar pra mostrar 2x2 também na 2.3.10?
> - Snapshot tests existentes da `GameScreen` (Fase 2.3.9) precisam ser regenerados — ambos os itens A e B mudam a árvore de widgets significativamente.
> - Acessibilidade: o `Semantics` do `HostBanner` precisa anunciar "Anfitrião: [nome do animal]"?
>
> **Output esperado do brainstorm:**
> Uma **spec detalhada da Fase 2.3.10** (markdown, tipo `FASE_2_3_10_SPEC.md`) com:
> - Decisões tomadas em cada ponto aberto
> - Para cada uma das 2 sub-entregas: arquivos a criar/modificar, mudança exata, casos de teste obrigatórios, critérios de aceite
> - Ordem de execução recomendada (A → B)
> - Cobertura de testes existentes que precisa ser atualizada (especialmente snapshots da Fase 2.3.9)
> - Estratégia de validação visual após cada entrega (screenshots/golden tests, galeria atualizada)
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
