# 🦫 Capivara 2048 — Design Concept (Consolidado v2)

> Documento de especificação para desenvolvimento. Pensado para ser alimentado em ferramentas como Claude Code para implementação iterativa.
>
> **Status atual:** Fase 2.6 concluída ✅ (v0.9.2) — Home redesenhada, Tela de Coleção, Tela de Configurações. Fases 2.4 (Recompensas Diárias) e 2.5 (Identidade "Olha o Bichim!") também concluídas.
>
> **Próximo:** **Fase 2.7 — Bugfixes visuais de interface** — 4 correções identificadas em uso real pós-2.6: botão de Recompensa Diária com tamanho inconsistente quando badge está visível, textos ilegíveis nos menus sobre fundo dinâmico, Bottom Overflow em telas com fundo do jogo, textos de Configurações ilegíveis sobre fundo dinâmico.
>
> **Renomeação do jogo:** o nome do jogo passa de **"Capivara 2048"** para **"Olha o Bichim!"**. As referências antigas em seções abaixo serão atualizadas progressivamente; durante a transição, considere "Olha o Bichim!" o nome canônico do produto. O *codename* interno do repositório (`capivara_2048`) permanece — apenas o nome de exibição muda.
>
> **Áudio:** segue em **Fase 5**, junto da arte adicional e antes do lançamento; o jogo é desenvolvido sem áudio até lá.

---

## 1. Visão Geral

**Olha o Bichim!** é um puzzle game multiplataforma inspirado na mecânica clássica do 2048, onde os números tradicionais são acompanhados por animais da fauna brasileira. O objetivo final é alcançar a **Capivara Lendária**, o "2048" do jogo, no menor tempo possível ou com o maior número.

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
│   │   ├── collection/     ✅ (Fase 2.6)
│   │   ├── daily_rewards/  ✅ (Fase 2.4)
│   │   ├── invite_friends/
│   │   ├── settings/       ✅ (Fase 2.6)
│   │   └── tutorial/
│   ├── widgets/
│   │   ├── board_widget.dart            ✅
│   │   ├── tile_widget.dart             ✅
│   │   ├── score_panel.dart             ✅
│   │   ├── status_panel.dart            ✅
│   │   ├── game_header.dart             ✅ (flush-left HostBanner + centralizado LivesIndicator, 2.3.12)
│   │   ├── host_banner.dart             ✅
│   │   ├── host_artwork.dart            ✅
│   │   ├── game_background.dart         ✅
│   │   ├── game_title_image.dart        ✅ (Fase 2.5)
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
│   ├── title/title_orange.png        ✅ (Fase 2.5)
│   ├── title/title_brown.png         ✅ (Fase 2.5)
│   ├── icon/app_icon.png             ✅ (Fase 2.5)
│   ├── animals/tile/                 ← 11 PNGs ✅
│   └── animals/host/                 ← 11 PNGs ✅
├── icons/inventory/                  ← 4 PNGs finais ✅
│   ├── bomb_2.png   ← Bomba 2 — tema **Sucuri** (verde)
│   ├── bomb_3.png   ← Bomba 3 — tema **Mico-leão-dourado**
│   ├── undo_1.png   ← Desfazer 1 — tema **Capivara**
│   └── undo_3.png   ← Desfazer 3 — tema **Onça-pintada**
├── sounds/animals/                   ← Fase 5
├── sounds/ui/                        ← Fase 5
├── music/                            ← Fase 5
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

### 4.2 Anfitrião do jogo (Fase 2.3.10 — 2x2; Fase 2.3.11 — Tanajura inicial; Fase 2.3.12 — flush-left sem padding)
- **Posição:** acima do tabuleiro, **lado esquerdo, flush-left** — borda esquerda do `HostBanner` alinhada pixel-perfect com a borda esquerda do header (sem padding nem margin à esquerda), espelhando a simetria do `PauseButtonTile` que é flush-right; alinhado às **colunas 1 e 2** do tabuleiro
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
- **Regra geral (a partir da Fase 2.7):** qualquer texto exibido diretamente sobre o `fundo.png` (sem container branco por trás) deve usar `OutlinedText` — texto branco com contorno preto, 8 sombras radiais blur 0.8–1.0. Textos interativos (controles de configurações) ficam dentro de cards com `Colors.white.withOpacity(0.88)` e `borderRadius: 12`.

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
- **Regen automática:** soma 1 enquanto `current < regenCap`. **Implementação efetiva a partir da Fase 2.3.12** — `Timer.periodic` + `AppLifecycleListener`.
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

**Visual do botão (Fase 2.3.12):** o PNG ocupa o slot 56×56 inteiro — o PNG **é** o botão. Sem fundo verde nem `Material`. Fallback automático para `Material(#4CAF50)` + `Icon` branco se o asset falhar ao carregar.

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
*(Implementação na Fase 5 — depois de toda a arte e polimento visual, antes do lançamento)*

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
- `GameTitleImage` alternando entre variante laranja e marrom por sessão (Fase 2.5)
- **Indicador de vidas** centralizado no topo (coração + faixa "Completo/Bônus/Restando/Sem vidas")
- Botão grande **"Jogar"** (Novo jogo / Continuar partida salva)
- Cards: Loja, Ranking, Recompensa Diária (com badge vermelho quando disponível), Convidar
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

> **Nota de layout (Fase 2.3.12):** o cabeçalho tem 3 linhas distintas empilhadas:
> - Linha A: `LivesIndicator` (`Center`) — horizontalmente centralizado
> - Linha B: `StatusPanel` (largura total, sem pause integrado)
> - Linha C: `Row(HostBanner flush-left | Spacer | Column(StatusPanel+PauseButtonTile) flush-right)` — sem padding à esquerda, `HostBanner` colado à borda esquerda do header

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

### 12.6 Tela: Recompensas Diárias (Fase 2.4 — concluída)
- Grid 7 dias (1–7) com recompensa de cada dia
- 4 estados: available / alreadyClaimed / streakBroken / cycleCompleted
- Countdown até meia-noite
- Botão "Coletar" no dia atual
- Após coletar: overlay "dobrar via anúncio" (`FakeAdService` em dev)
- Diálogo de cap de vidas quando aplicável
- `DailyRewardEntryTile` na `HomeScreen` com badge vermelho + toast na primeira sessão do dia

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

### ✅ Fase 2.3.12 — Bugfixes de layout, regen e ícones do inventário (v0.8.4)
- **A** — `LivesIndicator` centralizado horizontalmente (`Center`) em `GameHeader` e `HomeScreen`
- **B** — `HostBanner` flush-left no `GameHeader` (sem padding à esquerda) — simetria com `PauseButtonTile` flush-right; `Row(HostBanner, Spacer(), Column(StatusPanel+Pause))`
- **C** — Timer de regeneração de vidas implementado: `Timer.periodic(30s)` em `LivesNotifier` + `AppLifecycleListener` para recálculo offline ao retornar do background
- **D** — PNGs finais do inventário integrados: PNG ocupa slot 56×56 inteiro (**o PNG é o botão**, sem fundo verde); fallback `Material`+`Icon` se asset falhar; `ConfirmUseDialog` exibe ícone 40×40 no título

---

> **Nota histórica:** a antiga **Fase 2.4 — Áudio** foi reposicionada pra perto do final do desenvolvimento, antes do lançamento. Ver **Fase 5 — Áudio** mais abaixo. As fases seguintes deste bloco foram renumeradas (antiga 2.5 → 2.4, antiga 2.6 → 2.5, antiga 2.7 → 2.6).
>
> **Por que foi movida:** os sons dos animais e UI dependem da identidade visual final, e o sound design ainda não foi feito. Implementar antes da arte final corre risco de retrabalho. O jogo é desenvolvido **sem áudio** até a Fase 5 — todos os controles de volume nas Configurações (Fase 2.6) ficam desabilitados/ocultos até lá.

### ✅ Fase 2.4 — Recompensas diárias (v0.9.0)
- `DailyRewardsState` (Hive typeId=3): `currentDay` (1–7), `lastClaimedDate`, `claimedThisCycle`
- Engine puro `daily_rewards_engine.dart`: `computeDailyRewardStatus`, `applyClaim`, `applyStreakReset`, `rewardForDay`, `kDailyRewards` (7 dias)
- `DailyRewardsNotifier`: `claim()` (trata available/streakBroken/cycleCompleted), `claimDouble()`, integrado com `livesProvider`+`inventoryProvider`
- `DailyRewardsScreen`: grid 7 dias, 4 estados UI, countdown até meia-noite, diálogo de cap de vidas, overlay "dobrar via anúncio" (`FakeAdService`)
- `DailyRewardEntryTile` na `HomeScreen` com badge vermelho + toast na primeira sessão do dia
- 193 testes passando (14 engine, 6 notifier, 4 widget, 3 repositório)

### ✅ Fase 2.5 — Identidade do Jogo: rebranding "Olha o Bichim!" + título na Home + ícone do app
- Substituição de todas as strings de exibição "Capivara 2048" por "Olha o Bichim!" (codename interno mantido)
- `GameTitleImage` widget: escolha aleatória por sessão entre `title_orange.png` e `title_brown.png`; `pickAsset({Random?})` para testes determinísticos
- `flutter_launcher_icons`: ícone do app em Android (adaptive, background `#D4F1DE`), iOS, Web, Windows
- Nome do launcher: "Olha o Bichim!" em `AndroidManifest.xml`, `Info.plist`, `web/index.html`, `web/manifest.json`
- Package name técnico (`com.example.capivara_2048`) inalterado

### ✅ Fase 2.6 — Tela Home + Coleção + Configurações (v0.9.2)
- Home redesenhada com grid 2×N de cards e `GameTitleImage`
- Tela de Coleção: grid 2 colunas, 11 animais (silhueta para não desbloqueados, card detalhado com `backgroundBaseColor` para desbloqueados), bottom sheet detalhado
- Configurações: haptic toggle, dropdown de idioma, sliders de áudio desabilitados/ocultos até Fase 5
- Stubs de navegação criados: `ShopScreen`, `InviteFriendsScreen`, `RedeemCodeScreen`

---

### ✅ Fase 2.7 — Bugfixes visuais de interface (v0.9.3)

**Objetivo:** quatro correções de legibilidade e layout identificadas em uso real pós-2.6. Nenhuma mudança de lógica de jogo — só UI.

**Estimativa:** 1–2 dias.

#### A — Botão "Recompensa Diária" com tamanho inconsistente quando badge está visível

**Bug atual:** o card/botão de Recompensa Diária na `HomeScreen` muda de tamanho (ou desalinha) quando o badge vermelho de "recompensa disponível" aparece no canto superior direito. Os outros cards do grid permanecem com tamanho fixo, mas este cresce ou encolhe.

**Causa provável:** o `Stack` que contém o botão e o badge não tem tamanho fixo — quando o badge é adicionado, o `Stack` expande pra acomodar o badge que extrapola as bordas, aumentando o bounding box do widget e quebrando o alinhamento do grid.

**Mudanças:**
- Auditar o widget do card de Recompensa Diária (provavelmente em `home_screen.dart` ou `daily_reward_entry_tile.dart`)
- Garantir que o `Stack` que contém o botão + badge usa `clipBehavior: Clip.none` com tamanho fixado via `SizedBox` ou `ConstrainedBox` — o badge pode extrapolar visualmente sem afetar o tamanho do pai
- Estrutura recomendada:
  ```dart
  SizedBox(
    width: kCardWidth,   // mesmo tamanho dos outros cards
    height: kCardHeight,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        _CardButton(...),
        if (hasReward)
          Positioned(top: -6, right: -6, child: _RedBadge()),
      ],
    ),
  )
  ```
- Validar que o grid da Home mantém alinhamento uniforme com e sem badge visível
- Validar em telas 360px, 412px e tablet

**Casos de teste obrigatórios:**
- Snapshot test da Home com badge visível: card de Recompensa tem mesma largura/altura dos outros cards
- Snapshot test da Home sem badge: idem
- Tap no card de Recompensa navega corretamente pra `/daily_rewards` em ambos os estados

#### B — Textos ilegíveis nos menus sobre fundo dinâmico

**Bug atual:** textos de labels, títulos e descrições em telas como Coleção (`CollectionScreen`) aparecem com cor padrão (preto ou cinza escuro) diretamente sobre o `fundo.png`, ficando ilegíveis porque o fundo tem tonalidades escuras e variadas.

**Decisão de design:** todos os textos exibidos diretamente sobre `fundo.png` (sem container branco por trás) devem usar `OutlinedText` — texto branco com contorno preto sutil, 8 sombras radiais blur 0.8–1.0 — o mesmo padrão já aplicado na `GameScreen`.

**Mudanças:**
- Auditar `CollectionScreen` e identificar todos os textos que estão sobre o fundo sem container (título da tela, nome de cada animal no grid, subtítulos soltos)
- Substituir `Text(...)` solto por `OutlinedText(...)` (widget já existe em `outlined_text.dart`) com:
  - `style: TextStyle(color: Colors.white, fontSize: ..., fontFamily: 'Fredoka')`
  - `outlineColor: Colors.black`
  - `outlineWidth: 1.2`
- Textos que já estão dentro de cards com fundo branco **não precisam mudar**
- Verificar `HomeScreen`: labels de cards soltos fora de containers opacos também precisam de `OutlinedText`
- **Não alterar** textos dentro de `AlertDialog`, `BottomSheet` ou qualquer container com fundo sólido

**Casos de teste obrigatórios:**
- Snapshot tests da `CollectionScreen` após a correção (regenerar)
- Snapshot tests da `HomeScreen` se labels forem ajustados
- Verificação manual: abrir Coleção sobre `fundo.png` e confirmar legibilidade

#### C — Bottom Overflow em telas com fundo do jogo

**Bug atual:** em algumas telas, ao renderizar com `fundo.png` como fundo, aparece a área amarela listrada com "Bottom Overflow by N pixels". O conteúdo da tela ultrapassa a altura disponível e não está em um widget scrollável.

**Causa provável:** `Column` raiz da tela tem altura fixa (ou não tem `Expanded`/`Flexible`) e o conteúdo total excede a tela.

**Mudanças:**
- Auditar todas as telas que usam `GameBackground` e identificar quais apresentam overflow (`CollectionScreen`, `SettingsScreen`, `DailyRewardsScreen`, `HomeScreen` são candidatas)
- Para cada tela com overflow:
  - Se conteúdo é naturalmente scrollável: envolver em `SingleChildScrollView` ou usar `ListView`/`CustomScrollView`
  - Se é tela com poucos elementos fixos: usar `Column` com `Expanded` no widget que deve crescer
- **Padrão recomendado** para telas com `GameBackground`:
  ```dart
  Scaffold(
    body: Stack(
      children: [
        GameBackground(),
        SafeArea(
          child: Column(
            children: [
              // header fixo
              Expanded(
                child: SingleChildScrollView(
                  child: /* conteúdo */,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  )
  ```
- Testar em telas pequenas (360×640dp)

**Casos de teste obrigatórios:**
- Telas afetadas renderizam sem erro de overflow em telas 360×640dp
- `flutter test` não lança `RenderFlex overflowed` em nenhum widget test
- Verificação manual em emulador pequeno

#### D — Textos de Configurações ilegíveis sobre fundo dinâmico

**Bug atual:** a `SettingsScreen` renderiza seus controles (toggles, sliders desabilitados, labels de idioma) diretamente sobre o `fundo.png`, sem container de fundo, tornando os labels ilegíveis.

**Decisão de design:** os itens de configurações devem ser renderizados dentro de **cards com fundo branco semi-opaco** (`Colors.white.withOpacity(0.88)`, borderRadius 12, sombra suave). Este padrão é mais adequado para controles interativos do que `OutlinedText` isolado, pois garante contraste também para os widgets `Switch` e `DropdownButton`.

**Estrutura recomendada:**
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.88),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
  ),
  child: Column(
    children: [
      // SwitchListTile, ListTile, DropdownButton, etc.
    ],
  ),
)
```

**Mudanças:**
- Auditar `settings_screen.dart` e identificar todos os controles/labels sem container
- Agrupar controles em seções lógicas (ex: "Gameplay", "Idioma", "Áudio") — cada seção num card
- Dentro dos cards: `SwitchListTile` para toggles, `ListTile` com trailing `DropdownButton` para idioma
- Títulos de seção fora dos cards: `OutlinedText` branco (padrão do item B)
- Sliders de áudio: manter visíveis mas `enabled: false`, com label "Disponível na Fase 5" dentro do card
- Cor de texto dentro dos cards: `#3E2723` (marrom escuro — cor padrão de texto do app)

**Casos de teste obrigatórios:**
- Snapshot test da `SettingsScreen` após a correção (regenerar)
- Todos os labels têm contraste AA (texto escuro em fundo branco dentro dos cards)
- Toggle de haptic funciona (regressão)
- Dropdown de idioma funciona (regressão)
- Sliders de áudio desabilitados com label explicativo visível
- Sem overflow na `SettingsScreen` (regressão do item C)

#### Ordem de execução recomendada
1. **C primeiro** (overflow) — bloqueia visualização das outras telas; resolver antes de validar B e D
2. **A** (badge inconsistente) — isolado, rápido, não depende de C
3. **B** (textos menus) — aplicar `OutlinedText` nas telas afetadas
4. **D por último** (cards de Configurações) — mais trabalhoso, depende do padrão estabelecido em B

---

### ✅ Fase 2.8 — Loja mock (3 dias)

**Objetivo:** implementar a `ShopScreen` com os 6 pacotes da §7.1, cards com preços De/Por e badge de desconto, botão "Comprar" simulado que entrega os itens localmente, e tela de "Código para presentear" gerada após a compra simulada. Sem integração real de pagamento (IAP real entra na Fase 3).

#### Sub-entregas

**A — ShopScreen (conteúdo)**

Substituir o stub criado na Fase 2.6 pelo conteúdo real.

Arquivos:
- `lib/presentation/screens/shop_screen.dart` — reescrever
- `lib/data/shop_data.dart` — criar (lista dos 6 `ShopPackage`)
- `lib/presentation/controllers/shop_notifier.dart` — criar

Layout:
```
Scaffold
└── GameBackground()
    └── Column
        ├── AppBar("Loja", Fredoka 22, #3FA968, BackButton)
        └── Expanded
            └── ListView
                // 6 _ShopPackageCard, ordem da tabela §7.1
```

**`_ShopPackageCard`**
```dart
_ShopPackageCard({required ShopPackage package})
// Container: borderRadius 16, sombra inferior, fundo branco leve
// Conteúdo:
//   Row: nome (Fredoka 18) + badge desconto (círculo laranja #FF8C42: "50%" ou "75%")
//   Text(description, Nunito 14, cor cinza)
//   Row: Text("De R$ X,XX", Nunito 14, riscado, cinza) + Text("Por R$ X,XX", Fredoka 20, #3FA968)
//   ElevatedButton("Comprar", onTap: _onBuy)
```

**`_onBuy` — fluxo de compra simulada**
1. Mostrar `AlertDialog` de confirmação: "Comprar [nome] por R$ X,XX?"
2. Ao confirmar: `inventoryProvider.add(package.contents)` + `livesProvider.add(package.contents.lives)`
3. Mostrar `_GiftCodeSheet` com o código gerado (`ShareCode` local, sem backend)
4. `ShareCode` gerado localmente com UUID, status `pending`, armazenado em `SharedPreferences`

**B — `_GiftCodeSheet` (bottom sheet)**

```dart
// DraggableScrollableSheet, initialChildSize: 0.5
// Conteúdo:
//   Text("Presente gerado!", Fredoka 24)
//   Text("Compartilhe este código com um amigo:", Nunito 14)
//   Container com código em Fredoka Bold 28
//   IconButton(Icons.copy) — copia para clipboard
//   Text("Seu amigo recebe: [conteúdo do giftContents]", Nunito 14)
//   ElevatedButton("Fechar")
```

**C — Dados `shop_data.dart`**

```dart
// Lista dos 6 ShopPackage conforme §7.1:
// [01] 4× Bomba 3 — De R$7,99 / Por R$3,99 / 50%
// [02] 4× Desfazer 3 — De R$3,99 / Por R$1,99 / 50%
// [03] 6 vidas — De R$9,99 / Por R$2,49 / 75%
// [04] 10 vidas — De R$19,99 / Por R$4,99 / 75%
// [05] Combo Mata Atlântica (6v+2b+2d) — De R$10,99 / Por R$4,99 / 50%
// [06] Combo Floresta Amazônica (10v+4b+4d) — De R$31,99 / Por R$9,99 / 50%
```

**D — Persistência local de `ShareCode`**

```dart
// SharedPreferences key: 'generated_share_codes'
// Valor: List<String> de JSON serializado dos ShareCode gerados
// Fase 3 migra para Firestore (mesma estrutura ShareCode)
```

**E — Documentação**
- `CHANGELOG.md`: entrada v0.9.3
- `README.md`: Fase 2.8 ✅
- `CLAUDE.md`: fase atual → "Fase 2.8 concluída — próximo: Fase 3"
- `CAPIVARA_2048_DESIGN.md` §15: marcar Fase 2.8 ✅
- `CAPIVARA_2048_DESIGN.md` §17: substituir pelo prompt da Fase 3

#### Providers

| Provider | Tipo | Novo? |
|---|---|---|
| `shopPackagesProvider` | `Provider<List<ShopPackage>>` | Sim — lista estática de `shop_data.dart` |
| `generatedShareCodesProvider` | `StateNotifierProvider<...>` | Sim — lista local de `ShareCode` gerados, persistida em `SharedPreferences` |
| `inventoryProvider` | já existe | Reusar — `add()` com `package.contents` |
| `livesProvider` | já existe | Reusar — `add(package.contents.lives)` |

#### Testes obrigatórios

```dart
// shop_screen_test.dart
testWidgets('6 cards de pacotes presentes no widget tree', ...)
testWidgets('cada card exibe nome, preço De, preço Por, badge desconto', ...)
testWidgets('tap Comprar → AlertDialog de confirmação', ...)
testWidgets('confirmar compra → inventoryProvider atualizado', ...)
testWidgets('confirmar compra → _GiftCodeSheet aparece com código', ...)
testWidgets('botão copiar → código no clipboard', ...)
```

#### Critérios de aceite
- 6 pacotes visíveis em scroll sem overflow
- Badge de desconto correto (50% / 75%) em cada card
- Preço "De" riscado, preço "Por" em destaque verde
- Compra simulada entrega itens no inventário imediatamente
- Código de presente gerado e copiável
- Sem integração IAP real (Fase 3)

#### Sincronização com Fase 3

| Slot criado na 2.7 | O que a Fase 3 faz |
|---|---|
| `_onBuy` mock (entrega local) | Substituir por `in_app_purchase` real |
| `ShareCode` em SharedPreferences | Migrar para Firestore |
| `_GiftCodeSheet` com código local | Conectar ao backend para validação |
| `RedeemCodeScreen` (stub criado na 2.6) | Recebe conteúdo na Fase 3 |

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

### 🔜 Fase 5 — Áudio (1–2 semanas)
**Sons dos 11 animais e UI + música ambiente.** Esta fase entra **depois** de toda a arte e polimento visual e **antes** do lançamento — quando todos os assets visuais finais estão consolidados, os sons casarão exatamente com os elementos. O sound design dos 11 animais ainda precisa ser feito; até esta fase, o jogo roda sem áudio.

- Sound design dos 11 animais (definir tom/duração/estilo) e produção dos clipes
- Sons dos 11 animais (~50KB cada, OGG/M4A/MP3) — ver tabela 11.1
- Sons de UI completos — ver lista 11.2
- Música ambiente: loop de floresta com flautas + marimba
- Integrar com `audioplayers` ou `just_audio` (decidir qual)
- Pool de AudioPlayers (evita latência no merge)
- Mixer simples nas Configurações (slider SFX + slider música + mute persistente) — habilitar os controles que ficaram desabilitados na Fase 2.6
- Pré-carregar tudo no início do app

### 🔜 Fase 6 — Polimento + Lançamento
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
- **Cards de Configurações (Fase 2.7):** `SwitchListTile` e `ListTile` anunciam estado automaticamente — nenhuma alteração necessária em `Semantics`

### 16.2 Performance
- `const` e Riverpod selectors
- PNGs em vez de SVGs (Fase 2.3.8 item A) — gargalo removido
- `precacheImage` pra os 22 PNGs dos animais + 4 do inventário + `fundo.png` + 2 title PNGs no boot
- Pool de AudioPlayers (Fase 5)
- 60fps em Snapdragon 660+ / iPhone 8+
- `RepaintBoundary` no `GameBackground`
- `BackdropFilter` no `PauseOverlay` é o único custo significativo de UI — fallback se ficar < 50fps
- **Timer de regeneração de vidas (Fase 2.3.12 item C):** `Timer.periodic` rodando a cada segundo é leve, mas garantir que o widget é desmontado corretamente (`dispose`) pra não vazar timers entre navegações
- **Fase 2.7 item C:** overflow resolvido com `SingleChildScrollView` — leve, sem impacto de performance

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
- Nome: "Olha o Bichim!" (BR) / "Olha o Bichim! — Brazil Animals 2048" (EN, fallback descritivo)
- Keywords: 2048, puzzle, capivara, animais, brasil, fofo, casual, fauna, bichim
- Screenshots destacando a Capivara
- Vídeo de gameplay de 30s

---

## 17. Prompt Sugerido para o Claude Code (Fase 2.8 — via skill superpowers)

> O prompt abaixo entra no fluxo do **superpowers/brainstorming**. O resultado esperado é uma **spec detalhada da Fase 2.8** (refinada via brainstorm), que depois alimenta o **superpowers/writing-plans** pra gerar o plano executável. Nada de código nesta etapa — apenas elicitação, refinamento de design e plano.

---

> Use a skill `superpowers/brainstorming` pra refinar o design da próxima fase do projeto **Olha o Bichim!** (Flutter, codename `capivara_2048`).
>
> **Contexto:** Fase 2.7 concluída (v0.9.3). Use `CAPIVARA_2048_DESIGN.md` como spec geral (especialmente §7.1, §12.3 e §15 — Fase 2.8).
>
> **Fases concluídas:** 1 a 2.7 (v0.9.3). Áudio na Fase 5. Backend na Fase 3.
>
> **Tópico do brainstorm:** **Fase 2.8 — Loja Mock**. Implementar `ShopScreen` com os 6 pacotes da §7.1, cards com preços De/Por e badge de desconto, botão "Comprar" simulado que entrega os itens localmente, tela de "Código para presentear" gerada após compra simulada. Sem integração real de pagamento (IAP real entra na Fase 3).
>
> **Quatro sub-entregas:**
>
> **A — ShopScreen:** substituir stub da Fase 2.6 com ListView de 6 `_ShopPackageCard`. Cada card: nome + badge desconto (círculo laranja `#FF8C42`), descrição, preço De (riscado) / Por (destaque verde), botão "Comprar".
>
> **B — `_GiftCodeSheet`:** bottom sheet exibido após compra com código UUID local, botão de copiar para clipboard, descrição do conteúdo do presente.
>
> **C — `shop_data.dart`:** lista estática dos 6 pacotes com preços e conteúdos conforme §7.1.
>
> **D — Persistência local:** `ShareCode` em `SharedPreferences` (migração para Firestore na Fase 3).
>
> **Pontos abertos pra explorar no brainstorm:**
>
> - `ShopPackage` model: quais campos? (`id`, `name`, `description`, `originalPrice`, `salePrice`, `discountPercent`, `contents: PackageContents`, `giftContents: PackageContents`) — confirmar estrutura antes de criar `shop_data.dart`.
> - `PackageContents`: `lives`, `bombs2`, `bombs3`, `undos1`, `undos3` — esses são os campos corretos baseado nos items existentes?
> - `shop_notifier.dart`: precisa de estado próprio ou `_onBuy` pode ser função local na screen com acesso direto a `inventoryProvider` e `livesProvider`?
> - `generatedShareCodesProvider`: `StateNotifierProvider` com persistência em `SharedPreferences` — o padrão já usado em `DailyRewardsNotifier` serve de referência?
> - Bomba nos combos: são Bomba 2 ou Bomba 3? Confirmar no §7.1 ("2 bombas" — qual tipo?).
> - Validação manual: rodar em 360×640 para garantir que os 6 cards scrollam sem overflow.
>
> **Output esperado do brainstorm:**
> Uma **spec detalhada da Fase 2.8** (`docs/superpowers/specs/YYYY-MM-DD-fase-2-8-design.md`) com:
> - Decisões tomadas em cada ponto aberto
> - Para cada sub-entrega: arquivos a modificar, mudança exata, casos de teste obrigatórios, critérios de aceite
> - Plano de validação manual
> - Ao final: **prompt de brainstorm da Fase 3** (Backend — próxima após a Loja Mock) seguindo este mesmo padrão de cascata
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
