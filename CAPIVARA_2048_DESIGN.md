# 🦫 Capivara 2048 — Design Concept (Consolidado v2)

> Documento de especificação para desenvolvimento. Pensado para ser alimentado em ferramentas como Claude Code para implementação iterativa.
>
> **Status atual:** Fase 2.3.12 concluída ✅ — `LivesIndicator` centralizado, `HostBanner` colado à coluna 1 (sem gap), timer de regen de vidas implementado (`Timer.periodic` + `AppLifecycleListener`), PNGs finais do inventário integrados com ícone no `ConfirmUseDialog`.
>
> **Próximo:** **Fase 2.4 — Áudio e música**.

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
- **Anfitrião dinâmico**: animal correspondente ao maior tile da partida atual aparece acima do tabuleiro (começa pela Tanajura desde o início — ver 4.2)
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
| Áudio | `audioplayers` ou `just_audio` | Sons e música (Fase 4.5) |
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
│   ├── lives_system/       ✅ (regen timer corrigido na 2.3.12)
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
│   │   ├── status_panel.dart            ✅
│   │   ├── game_header.dart             ✅ (gap à esquerda corrigido na 2.3.12)
│   │   ├── host_banner.dart             ✅
│   │   ├── host_artwork.dart            ✅
│   │   ├── game_background.dart         ✅
│   │   ├── lives_indicator.dart         ✅ (centralizado na 2.3.12)
│   │   ├── lives_status_banner.dart     ✅
│   │   ├── pause_button_tile.dart       ✅
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
├── icons/inventory/                  ← 4 PNGs finais ✅
│   ├── bomb_2.png   ← Bomba 2 — tema **Sucuri** (verde)
│   ├── bomb_3.png   ← Bomba 3 — tema **Mico-leão-dourado**
│   ├── undo_1.png   ← Desfazer 1 — tema **Capivara**
│   └── undo_3.png   ← Desfazer 3 — tema **Onça-pintada**
├── sounds/animals/                   ← Fase 4.5
├── sounds/ui/                        ← Fase 4.5
├── music/                            ← Fase 4.5
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
- **Maior nível alcançado:** começa em 1 (Tanajura) e sobe até 11 (Capivara Lendária) conforme o jogador faz merges

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

### 4.2 Anfitrião do jogo (Fase 2.3.10 — 2x2; Fase 2.3.11 — Tanajura inicial; Fase 2.3.12 — colado à coluna 1)
- **Posição (definida em brainstorm anterior; gap à esquerda corrigido na 2.3.12):** acima do tabuleiro, **lado esquerdo, colado à coluna 1** (sem gap entre a borda esquerda do anfitrião e a borda esquerda do tabuleiro), alinhado às **colunas 1 e 2** do tabuleiro
- **Tamanho:** **2 tiles de largura × 2 tiles de altura** (152dp `GameConstants.twoCellWidth`)
- **Conteúdo (de cima pra baixo):**
  - **Nome do animal** (em cima) — Fredoka SemiBold, 16sp, com `OutlinedText` e `maxLines: 2`
  - **PNG do animal** (embaixo) — ocupa o slot 2x2 com `BoxFit.cover`, sem moldura, sem fundo branco
- **Atualização:** muda quando o jogador forma um tile de nível superior ao recorde da partida
- **Animação:** transição suave (fade + scale) ao trocar
- **Estado inicial:** Tanajura é o anfitrião desde o boot (Fase 2.3.11) — `highestLevelReached` começa em 1
- **Lado direito do mesmo nível** (acima das colunas 3 e 4): recebe o **`PauseButtonTile`** abaixo do `StatusPanel`/cronômetro (posição mantida — não muda na 2.3.12)

### 4.3 Fundo do jogo (Fase 2.3.9 — PNG; Fase 2.3.11 — unificado com Home)
- Imagem PNG (`assets/images/fundo.png`) renderizada em tela cheia via `BoxFit.cover`
- Sem variação por animal — fundo é o mesmo em qualquer fase do jogo
- O mesmo `fundo.png` é aplicado também na `HomeScreen`, garantindo consistência visual entre o menu principal e a tela de jogo
- Cor de fallback: `#D4F1DE` (verde-menta) é exibido apenas se o PNG falhar ao carregar

### 4.4 Texto sobre cor — legibilidade
- Textos brancos importantes têm contorno preto sutil (1–1.5px) com anti-aliasing suave (Fase 2.3.6 item A)
- Aplicado em: nome do anfitrião, cronômetro, pontuação, recorde, todos os textos do `PauseOverlay`

### 4.5 Indicador de vidas (Fase 2.3.9; Fase 2.3.12 — centralizado)
- **Posição:** topo da tela, **horizontalmente centralizado** (a partir da Fase 2.3.12)
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

> **Atenção (a partir da Fase 2.3.12):** o timer regressivo MM:SS depende da regeneração estar funcionando. Até a 2.3.11 inclusive, a faixa "Restando" mostrava o texto mas o número não decrementava porque o regen timer não estava implementado de fato — corrigido na Fase 2.3.12 item C.

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
- **Regen automática:** soma 1 enquanto `current < regenCap`. **Implementação efetiva a partir da Fase 2.3.12** — antes disso o `nextRegenAt` era populado mas o ticker que dispara o ganho não estava em loop.
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
PNGs finais (1024×1024, fundo transparente) em `assets/icons/inventory/`:
- `bomb_2.png` — Bomba 2 casas, tema **Sucuri** (verde, com pavio aceso)
- `bomb_3.png` — Bomba 3 casas, tema **Mico-leão-dourado**
- `undo_1.png` — Desfazer 1, tema **Capivara** (segurando relógio com seta de retorno)
- `undo_3.png` — Desfazer 3, tema **Onça-pintada**

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
- **Nome do anfitrião 2x2**: `Fredoka SemiBold`, 16sp (definido na 2.3.10), com `OutlinedText` e `maxLines: 2`
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
*(Implementação na Fase 4.5 — depois de toda a arte e polimento visual, antes do lançamento)*

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
   │      ├── (vidas centralizadas no topo — coração + faixa estilizada)
   │      ├── (StatusPanel: cronômetro + pontuação + recorde — sem pause)
   │      ├── (linha intermediária: Anfitrião 2x2 à esquerda colado, PauseButtonTile à direita)
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
- **Fundo:** mesmo `assets/images/fundo.png` da `GameScreen` (Fase 2.3.11) — `BoxFit.cover`, fallback `#D4F1DE`
- Logo grande com a Capivara mascote ao centro
- **Indicador de vidas** centralizado no topo (coração + faixa "Completo/Bônus/Restando/Sem vidas")
- Botão grande **"Jogar"** (Novo jogo / Continuar partida salva)
- Cards: Loja, Ranking, Recompensa Diária (com badge), Convidar
- Ícones menores: Coleção, Configurações, Como Jogar

### 12.3 Tela: Jogo (Fase 2.3.10; reordenada na 2.3.12)
**Layout (de cima pra baixo):**

1. **Topo:** `LivesIndicator` (coração + faixa estilizada) — **horizontalmente centralizado** (Fase 2.3.12)
2. **Abaixo:** `StatusPanel` (cronômetro + pontuação + recorde) — sem o pause
3. **Linha intermediária (entre StatusPanel e tabuleiro), a partir da Fase 2.3.12:**
   - **Lado esquerdo (sobre colunas 1-2), colado à coluna 1:** `HostBanner` 2x2 com Tanajura desde o início
   - **Lado direito (sobre colunas 3-4):** `PauseButtonTile` (1 tile, alinhado à direita em slot 152×72dp via `Align(centerRight)`)
4. **Centro:** tabuleiro 4x4
5. **Rodapé:** `InventoryBar` (4 itens com ícones PNG + badges de contador)

> **Nota de layout (Fase 2.3.12):** o cabeçalho continua dividido em 3 linhas distintas empilhadas (mesmo padrão estabelecido em brainstorm anterior). A correção da 2.3.12 é **eliminar o gap entre o `HostBanner` e a borda esquerda do tabuleiro** — o anfitrião já estava à esquerda, mas com padding/margin que afastava ele da coluna 1.
> - Linha A: `LivesIndicator` (centralizado horizontalmente — correção da 2.3.12)
> - Linha B: `StatusPanel` (largura total, sem pause integrado)
> - Linha C: `Row(HostBanner 2×2 esquerda colado à coluna 1 | Spacer | PauseButtonTile direita)` — anfitrião colado pixel-perfect à borda esquerda do tabuleiro, pause permanece à direita (sem mudança)

#### 12.3.1 Posicionamento do botão pause (Fase 2.3.10; sem mudança na 2.3.12)
- **Tile-sized 1×1, fixo, separado do StatusPanel**
- Posicionado na linha intermediária do cabeçalho, alinhado à **direita** do tabuleiro (posição definida em brainstorm anterior — sem mudança na 2.3.12)
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
Tela acessível apenas em build de debug (via `kDebugMode`). Mostra os 11 animais lado a lado em 3 modos: tile, host 1x1 (legado da 2.3.7) e host 2x2 (atualizada na 2.3.10).

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
  final int highestLevelReached;     // a partir da 2.3.11: inicializa em 1 (Tanajura)
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
- 143 testes passando

### ✅ Fase 2.3.10 — Reorganização do cabeçalho + Anfitrião 2×2 (v0.7.0)
- A — `GameHeader` extraído da `GameScreen`
- B — `HostBanner` fixado em 152dp
- C — `HostArtwork`: `BoxFit.cover`, `size` recebido direto
- D — `StatusPanel`: fontes 18sp/24sp/13sp
- E — `PauseButtonTile` separado do `StatusPanel` (à esquerda na 2.3.10)
- F — Galeria debug com coluna Host 2×2
- 152 testes passando

### ✅ Fase 2.3.11 — Anfitrião inicial Tanajura + Fundo unificado
- A — `highestLevelReached` inicia em 1 (em vez de 0)
- B — `_Placeholder` removido do `HostBanner`
- C — Galeria de debug com nota explicativa sobre Tanajura
- D — Fundo unificado: `fundo.png` aplicado também na `HomeScreen`

### 🚧 Fase 2.3.12 — Bugfixes de layout, regen e ícones do inventário (PRÓXIMA)
**Objetivo:** quatro correções identificadas em uso real após a 2.3.11 — `LivesIndicator` está desalinhado (precisa ser centralizado), `HostBanner` 2x2 está à esquerda mas com gap visível à esquerda dele (precisa colar na coluna 1 do tabuleiro), cronômetro de regeneração de vidas não está funcionando (texto "Restando MM:SS" aparece mas o número não decrementa), e os PNGs finais dos ícones do inventário (com temas Sucuri/Mico-leão/Capivara/Onça) ainda não foram integrados ao código — estão na pasta `assets/icons/inventory/` mas o `InventoryItemButton` continua renderizando os ícones antigos/placeholder.

**Estimativa:** 2–3 dias.

#### A — Centralizar `LivesIndicator` no topo
**Bug atual:** o `LivesIndicator` aparece no topo da tela mas não está horizontalmente centralizado (provavelmente alinhado à esquerda ou desalinhado por causa do `Row` que o contém).

**Mudanças:**
- Investigar `game_screen.dart` (e `home_screen.dart`) pra identificar como o `LivesIndicator` está sendo posicionado atualmente
- Garantir que o widget está dentro de um `Row` com `mainAxisAlignment: MainAxisAlignment.center`, ou envolvido em um `Center`, ou (se estiver dentro de uma `Column`) com `crossAxisAlignment: CrossAxisAlignment.center`
- Aplicar a mesma correção na `HomeScreen` (mesmo `LivesIndicator` aparece nas duas telas)
- Validar que a centralização funciona em diferentes tamanhos de tela (360px, 412px, tablets)

**Casos de teste obrigatórios:**
- Snapshot test da `GameScreen`: `LivesIndicator` está horizontalmente centralizado no topo
- Snapshot test da `HomeScreen`: idem
- Em tela 360px (smartphone pequeno): `LivesIndicator` continua centralizado, sem overflow lateral
- Em tela 412px (smartphone padrão): centralizado
- Em tela 768px+ (tablet): centralizado (não fica colado à esquerda nem estica até as bordas)
- Quando a faixa muda de "Completo" (mais curta) pra "Restando MM:SS" (mais longa): permanece centralizado (não desloca pro lado conforme o texto cresce)

#### B — Colar `HostBanner` à coluna 1 (eliminar gap à esquerda)
**Estado atual:** o anfitrião **já está à esquerda** desde decisão tomada em brainstorm — `HostBanner` 2x2 nas colunas 1-2, `PauseButtonTile` à direita (abaixo do cronômetro/StatusPanel). **O bug é só que o `HostBanner` não está colado à coluna 1** — existe um padding/margin/`Spacer` à esquerda dele que cria um gap visual entre a borda esquerda do tabuleiro e a borda esquerda do anfitrião.

**Investigação necessária:**
- Auditar `game_header.dart` pra identificar a fonte do gap:
  - Padding interno do `Row` da Linha C?
  - Margin/padding do próprio `HostBanner`?
  - `mainAxisAlignment: spaceBetween` numa `Row` que tem só 2 filhos (anfitrião e pause)? Isso colaria os filhos nas extremidades, então provavelmente NÃO é isso
  - Algum `Center` ou `Align(centerLeft)` errado que centraliza o anfitrião num espaço maior em vez de colar à esquerda?
  - O `GameHeader` inteiro tem padding horizontal externo que faz o anfitrião não bater com a borda do tabuleiro?

**Mudanças:**
- Refatorar `game_header.dart`:
  - Garantir que o `HostBanner` está alinhado à esquerda colado, sem nenhum `padding`/`margin` lateral antes dele
  - Estrutura sugerida: `Row(children: [HostBanner(...), Spacer(), PauseButtonTile(...)])` — o `Spacer` empurra o pause pra direita, e o anfitrião fica naturalmente colado à esquerda
  - Se houver padding horizontal externo do `GameHeader`, garantir que ele bate exatamente com o padding/margin do tabuleiro (pra que a "coluna 1" do anfitrião alinhe pixel-perfect com a "coluna 1" do tabuleiro)
- Validar visualmente que a borda esquerda do `HostBanner` e a borda esquerda do tabuleiro formam uma linha vertical contínua (sem desalinhamento de 1-4px)
- O `PauseButtonTile` permanece à direita (sem alteração de posição) — só o anfitrião precisa ser ajustado

**Casos de teste obrigatórios:**
- Snapshot test: borda esquerda do `HostBanner` está alinhada à borda esquerda do tabuleiro (offset = 0px)
- Pixel-perfect test: medir `HostBanner.left` e `BoardWidget.left` na renderização — devem ser idênticos
- Em tela 360px: alinhamento mantido sem overflow
- Em tela 412px: idem
- O `PauseButtonTile` continua na posição atual (à direita) — regressão
- Tap no pause continua funcionando — regressão
- Animação de troca de anfitrião continua funcionando — regressão
- Galeria `/debug/animals_gallery` não é afetada (independente do layout do `GameHeader`)

#### C — Implementar cronômetro de regeneração de vidas
**Bug atual:** o `LivesStatusBanner` mostra "Restando MM:SS" quando `current < 5`, mas o número MM:SS é estático ou não decrementa visualmente. Quando os 30 minutos completam (em teoria), a vida não é adicionada automaticamente. O sistema só funciona "passivamente" (se o jogador fechar e reabrir o app depois de 30min, a vida está lá), mas não em tempo real durante a sessão.

**Investigação necessária:**
- Auditar `lives_notifier.dart` (ou equivalente) pra entender como `nextRegenAt` é populado e quando `current` é incrementado
- Verificar se existe um `Timer.periodic` ou `Stream<DateTime>` ativo enquanto o app está aberto que dispara `regenerate()` quando `DateTime.now() >= nextRegenAt`
- Verificar se o `LivesStatusBanner` está consultando `nextRegenAt` em loop pra atualizar o texto MM:SS a cada segundo

**Mudanças:**
- **No domínio (`lives_system/lives_notifier.dart`):**
  - Adicionar um `Timer.periodic(Duration(seconds: 1), ...)` no `LivesNotifier` (ou usar `Stream.periodic`)
  - A cada tick: se `current < regenCap` E `DateTime.now() >= nextRegenAt`, chamar `regenerate()` que soma 1 vida e recalcula `nextRegenAt = now + 30min` (ou null se atingiu o cap)
  - Garantir que o `Timer` é cancelado quando o `LivesNotifier` é descartado (lifecycle)
  - Lidar com app em background: ao retornar do background, recalcular quantas vidas deveriam ter sido adicionadas com base no tempo decorrido (não confiar só no Timer enquanto estava em background)
- **Na UI (`lives_status_banner.dart`):**
  - Quando estado é "Restando", consumir um `StreamProvider<DateTime>` (ou `Timer.periodic` próprio) que atualiza o texto MM:SS a cada segundo
  - Calcular `remaining = nextRegenAt - DateTime.now()` e formatar como `MM:SS`
  - Cuidar do edge case: se `remaining <= 0`, não mostrar "00:00" travado — disparar a regeneração no notifier e a UI atualiza naturalmente
- **Persistência (Hive):**
  - Confirmar que `nextRegenAt` continua sendo persistido no Hive (já é, desde a Fase 2.3.8)
  - Ao boot do app: ler o `LivesState` salvo, calcular se houve regeneração offline (várias vidas podem ter sido geradas se o app ficou fechado por horas), e atualizar `current` antes de iniciar o Timer

**Casos de teste obrigatórios:**
- `LivesNotifier`: com `current = 4` e `nextRegenAt = now + 30min`, esperar 30min simulados → `current` vira 5, `nextRegenAt` vira null (atingiu regenCap)
- `LivesNotifier`: com `current = 3` e `nextRegenAt = now + 30min`, esperar 60min simulados → `current` vira 5, `nextRegenAt` vira null (regen rodou 2 vezes)
- `LivesNotifier`: com `current = 1` e `nextRegenAt = now + 30min`, esperar 30min simulados → `current` vira 2, `nextRegenAt` recalculado pra now + 30min
- App em background: fechar app com `current = 2` e `nextRegenAt = now + 10min`, abrir 90min depois → `current` vira 5 (3 regenerações offline), `nextRegenAt` null
- `LivesStatusBanner`: com `current = 4` e `nextRegenAt = now + 12min`, texto exibido é "Restando 12:00" e decrementa a cada segundo até "00:00"
- `LivesStatusBanner`: ao chegar em "00:00", o estado muda pra "Completo" automaticamente (regen disparada + UI atualiza)
- Game over com `current = 5` (estava completo): após game over, `current = 4`, `nextRegenAt = now + 30min`, faixa muda pra "Restando 30:00" decrementando
- Comprar 10 vidas com `current = 4`: vai pra 14 (sem cap por ser compra), faixa muda pra "Bônus" (current > 5), `nextRegenAt = null` (parou regen porque já passou do cap)

#### D — Integrar PNGs finais dos ícones do inventário
**Bug atual:** os PNGs finais dos 4 ícones de inventário (com temas dos animais — Sucuri pra Bomba 2, Mico-leão pra Bomba 3, Capivara pra Desfazer 1, Onça pra Desfazer 3) já estão em `assets/icons/inventory/` (1024×1024, fundo transparente, gerados pelo pipeline `cache/remove_bg.sh` + `cache/square_icons.sh`). Mas o `InventoryItemButton` continua renderizando os ícones antigos/placeholder (Material/Lucide ou versões anteriores). A integração desses assets é trivial mas nunca foi feita explicitamente como entrega numa fase.

**Mudanças:**
- Auditar `inventory_item_button.dart` pra confirmar como os ícones estão sendo renderizados atualmente (provavelmente `Icon(IconData)` ou `Image.asset` com path antigo)
- Atualizar `inventory_bar.dart` (ou onde os 4 botões são instanciados) pra apontar pros PNGs finais:
  - Bomba 2 → `assets/icons/inventory/bomb_2.png`
  - Bomba 3 → `assets/icons/inventory/bomb_3.png`
  - Desfazer 1 → `assets/icons/inventory/undo_1.png`
  - Desfazer 3 → `assets/icons/inventory/undo_3.png`
- Confirmar que `pubspec.yaml` declara `assets/icons/inventory/` (provavelmente já declara desde a Fase 2.3.8)
- Adicionar os 4 ícones ao `precacheImage` do boot (já tem fundo.png + 22 PNGs de animais; agora vão 26 PNGs precacheados)
- Validar visualmente:
  - Cada ícone PNG ocupa o slot do `InventoryItemButton` com `BoxFit.contain` (evita corte das bordas dos animais)
  - Estado disabled (contador 0): aplicar `Opacity(0.4)` ou `ColorFilter.matrix` pra acinzentar — confirmar que funciona com PNG colorido (alguns blends podem ficar estranhos com transparência)
  - Badge de contador continua bem posicionado (canto superior direito) sobre o novo ícone
  - Estado "99+" continua funcionando com os novos ícones
- Atualizar `confirm_use_dialog.dart` (Fase 2.3.8 item B) pra usar o mesmo PNG no ícone grande — assim o jogador vê o mesmo asset no botão e na confirmação

**Casos de teste obrigatórios:**
- `InventoryItemButton` renderiza PNG correto pra cada um dos 4 itens (snapshot test)
- Estado habilitado (contador ≥1): PNG colorido, totalmente visível
- Estado disabled (contador 0): PNG acinzentado/com opacity reduzida, ainda reconhecível
- Badge de contador (incluindo "99+") continua legível sobre o novo ícone
- `ConfirmUseDialog` mostra o mesmo PNG do botão (consistência visual)
- Performance: `precacheImage` dos 4 PNGs no boot não causa lag visível
- Sem dependências residuais aos ícones antigos (lint/grep: `Icons.dangerous`, `Icons.undo`, paths SVG antigos não devem aparecer mais)

#### Ordem de execução recomendada
1. **A primeiro** (centralizar `LivesIndicator`) — mudança mais simples, isolada visualmente
2. **B depois** (colar `HostBanner` à coluna 1) — ajuste de padding/margin contido em `game_header.dart`
3. **D** (integrar PNGs do inventário) — independente, pode rodar em paralelo com A/B/C; entrega visual rápida
4. **C por último** (cronômetro de regen) — mudança lógica + UI, mais arriscada e merece atenção dedicada

---

### 🔀 Fase 2.4 — Áudio (movida para Fase 4.5)
**Esta fase foi movida pra perto do final do desenvolvimento, antes do lançamento.** Ver **Fase 4.5** logo abaixo no roadmap pra detalhes da implementação.

**Por que foi movida:** os sons dos animais e UI dependem da identidade visual final. Implementar antes da Fase 4 (arte adicional) corre risco de retrabalho se a paleta/tom do jogo mudar. A posição na Fase 4.5 garante que o áudio seja a última camada de polimento antes do lançamento.

> O slot **2.4** é mantido aqui pra preservar a numeração histórica do roadmap e deixar explícito que a fase foi reposicionada (não removida).

### 🔜 Fase 2.5 — Recompensas diárias (3 dias)
- Tela de recompensas com grid 7 dias
- Lógica de streak (reseta se pular dia)
- Coleta com confirmação
- Mock do "dobrar via anúncio"
- Persistência local

### 🔜 Fase 2.6 — Tela Home + Coleção + Configurações (1 semana)
- Home com todos os botões e indicadores
- Tela de Coleção (silhuetas para não desbloqueados, card detalhado para desbloqueados — usa `backgroundBaseColor` do Animal)
- Configurações (volume SFX, volume música, haptic, idioma) — sliders de áudio ficam desabilitados/ocultos até a Fase 4.5

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

### 🔜 Fase 4.5 — Áudio (1–2 semanas)
**Sons dos 11 animais e UI + música ambiente.** Esta fase entra **depois** de toda a arte e polimento visual e **antes** do lançamento — quando todos os assets visuais finais estão consolidados, os sons casarão exatamente com os elementos.

- Sons dos 11 animais (~50KB cada, OGG/M4A/MP3) — ver tabela 11.1
- Sons de UI completos — ver lista 11.2
- Música ambiente: loop de floresta com flautas + marimba
- Integrar com `audioplayers` ou `just_audio` (decidir qual)
- Pool de AudioPlayers (evita latência no merge)
- Mixer simples nas Configurações (slider SFX + slider música + mute persistente) — habilitar os controles que ficaram desabilitados na Fase 2.6
- Pré-carregar tudo no início do app

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
- Pool de AudioPlayers (Fase 4.5)
- 60fps em Snapdragon 660+ / iPhone 8+
- `RepaintBoundary` no `GameBackground`
- `BackdropFilter` no `PauseOverlay` é o único custo significativo de UI — fallback se ficar < 50fps
- **Timer de regeneração de vidas (Fase 2.3.12 item C):** `Timer.periodic` rodando a cada segundo é leve, mas garantir que o widget é desmontado corretamente (`dispose`) pra não vazar timers entre navegações

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

## 17. Prompt Sugerido para o Claude Code (Fase 2.3.12 — via skill superpowers)

> O prompt abaixo entra no fluxo do **superpowers/brainstorming**. O resultado esperado é uma **spec detalhada da Fase 2.3.12** (refinada via brainstorm), que depois alimenta o **superpowers/writing-plans** pra gerar o plano executável. Nada de código nesta etapa — apenas elicitação, refinamento de design e plano.

---

> Use a skill `superpowers/brainstorming` pra refinar o design da próxima fase do projeto **Capivara 2048** (Flutter).
>
> **Contexto:** Estamos no projeto Capivara 2048. Use `CAPIVARA_2048_DESIGN.md` como spec geral (especialmente seções 4.2, 4.5, 5.6, 12.3 e 15 — Fase 2.3.12).
>
> **Fases concluídas:**
> - Fase 1 a 2.3.10
> - **Fase 2.3.11** — Tanajura como anfitrião desde o boot (`highestLevelReached` inicia em 1), `_Placeholder` removido, `fundo.png` aplicado também na `HomeScreen`.
>
> **Tópico do brainstorm:** desenhar a **Fase 2.3.12 — Bugfixes de layout, regen e ícones do inventário**. Quatro correções identificadas em uso real após a 2.3.11:
>
> **A — Centralizar `LivesIndicator` no topo:** atualmente está desalinhado (provavelmente à esquerda). Ajustar `game_screen.dart` e `home_screen.dart` pra garantir centralização horizontal usando `Row` com `mainAxisAlignment: center` ou `Center` widget.
>
> **B — Colar `HostBanner` à coluna 1 (eliminar gap à esquerda):** o anfitrião **já está à esquerda** desde decisão tomada em brainstorm anterior, e o `PauseButtonTile` já está à direita abaixo do cronômetro. Mas o `HostBanner` não está colado à borda esquerda — existe um gap visível entre a borda esquerda do tabuleiro e a borda esquerda do anfitrião. Investigar `game_header.dart` pra identificar a fonte do gap (padding interno do `Row`, margin do widget, ou padding externo do `GameHeader` que não bate com o tabuleiro) e ajustar pra que as duas bordas formem uma linha vertical contínua.
>
> **C — Implementar cronômetro de regeneração de vidas:** o `LivesStatusBanner` mostra "Restando MM:SS" mas o número não decrementa visualmente. Auditar `LivesNotifier` pra confirmar se há `Timer.periodic` ativo, implementar se não tiver. UI consome `StreamProvider<DateTime>` ou Timer próprio pra atualizar a cada segundo. Lidar com app em background (recalcular vidas geradas offline ao retornar).
>
> **D — Integrar PNGs finais dos ícones do inventário:** os 4 PNGs (temas Sucuri/Mico-leão/Capivara/Onça) já estão em `assets/icons/inventory/` mas o `InventoryItemButton` continua usando ícones antigos/placeholder. Atualizar paths, adicionar ao `precacheImage` do boot, validar estado disabled (acinzentado) e badge de contador sobre o novo ícone. Sincronizar com `ConfirmUseDialog` pra mostrar o mesmo asset.
>
> **Pontos abertos pra explorar no brainstorm (elicitação esperada):**
>
> Sobre o item A (centralizar LivesIndicator):
> - Verificar se o problema é técnico (faltou `mainAxisAlignment`) ou de design (`LivesIndicator` está dentro de um container com `padding` assimétrico)?
> - A correção vale só pra `GameScreen` ou também pra `HomeScreen`? Provavelmente as duas, mas confirmar.
> - Se o `LivesIndicator` continuar desalinhado em alguma tela, vale adicionar regression test que falha se ele sair do centro?
>
> Sobre o item B (colar HostBanner à coluna 1):
> - Diagnóstico do gap: o problema é (a) padding interno do `Row` da Linha C, (b) margin do `HostBanner` widget, (c) `mainAxisAlignment` errado da `Row`, (d) padding externo do `GameHeader` que não bate com o tabuleiro, ou (e) algum `Center`/`Align` indevido? Vale investigar antes de propor solução.
> - Pixel-perfect: a borda esquerda do `HostBanner` deve ficar exatamente alinhada com a borda esquerda da coluna 1 do tabuleiro? Ou pode haver tolerância de 1-2px? Como medir/testar isso de forma confiável?
> - Se o `GameHeader` e o `BoardWidget` estão ambos dentro de um container com padding horizontal externo, basta garantir que ambos consomem o mesmo padding. Se estiverem em containers diferentes, vale unificar?
> - O `PauseButtonTile` à direita continua na posição atual (sem mudança) — confirmar que a correção do anfitrião não desloca acidentalmente o pause.
>
> Sobre o item C (regen timer):
> - Tradeoff `Timer.periodic` vs `Stream.periodic`: qual encaixa melhor no padrão Riverpod do projeto? Vale usar `StreamProvider`?
> - Frequência do tick: 1 segundo é o ideal, ou 1 minuto seria suficiente (já que o display é MM:SS, mas o usuário pode olhar e esperar a transição da contagem)?
> - Recálculo offline: ao voltar do background, calcular `min(elapsedTime / 30min, regenCap - current)` vidas adicionadas. Edge case: se o jogador ficou 6 horas fora, com `current = 0`, deve voltar com 5 (regenCap atingido) e `nextRegenAt = null`.
> - O `LivesNotifier` precisa ter um método `pauseRegen()`/`resumeRegen()` pra lifecycle do app (em background → pausa Timer; em foreground → retoma e recalcula)?
> - A faixa "Restando" exibe MM:SS — quando faltam ≥60min (ex: jogador comprou pacote enorme e perdeu várias vidas), mostrar HH:MM:SS, ou continua MM:SS truncando? Edge case raro, mas vale decidir.
> - Animação ao chegar em "00:00" e a regen disparar: a faixa muda pra "Completo" (ou "Restando MM:SS" se ainda < 5) com animação fade+scale (já existente da 2.3.9 item A) — confirmar que continua funcionando.
>
> Sobre o item D (PNGs do inventário):
> - Os PNGs novos têm fundo transparente e tema dos animais (Sucuri/Mico-leão/Capivara/Onça). Vão competir com o número/badge de contador que fica em cima? Vale revisar contraste em estado disabled (com Opacity 0.4)?
> - Os ícones antigos (placeholder Material/Lucide ou versões anteriores) — vale apagar de vez do código, ou manter como fallback (similar ao que foi feito com SVGs antigos no inventário)?
> - O `BoxFit.contain` no slot do `InventoryItemButton` preserva proporção mas pode deixar barras laterais. Faz sentido ou vale `BoxFit.cover` (consistente com `HostArtwork` da 2.3.10)?
> - Sincronização visual com `ConfirmUseDialog`: o ícone grande do dialog também passa a usar o PNG novo? Tamanho diferente (ex: 64x64) — o PNG 1024x1024 vai ser redimensionado automaticamente pelo Flutter, ou vale forçar `cacheWidth: 64`?
> - Estado disabled (contador 0): `Opacity(0.4)` simples, ou `ColorFilter.matrix` pra dessaturar pra escala de cinza? Qual fica mais reconhecível com PNG colorido?
>
> Sobre integração:
> - Ordem das entregas: A primeiro (mais simples), B depois (refator de layout), C por último (mais complexo) — confirma a sequência?
> - Testes existentes: snapshots da `GameScreen` e `HomeScreen` (pelo menos 5-10 testes) precisam ser regenerados depois de A e B. Refazer ou ajustar?
> - Vale tirar screenshots/vídeo do antes/depois pra validar visualmente?
> - Sobre o item C: vale escrever um teste de integração que simula 30 minutos passando (com `FakeAsync` ou similar) pra validar regen end-to-end?
>
> **Output esperado do brainstorm:**
> Uma **spec detalhada da Fase 2.3.12** (markdown, tipo `FASE_2_3_12_SPEC.md`) com:
> - Decisões tomadas em cada ponto aberto
> - Para cada uma das 4 sub-entregas: arquivos a criar/modificar, mudança exata, casos de teste obrigatórios, critérios de aceite
> - Estratégia de implementação do regen timer (item C — Timer vs Stream, lifecycle, offline recalc)
> - Lista de testes existentes que precisam ser ajustados (snapshots de layout)
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
