# 🦫 Capivara 2048 — Design Concept (Consolidado v2)

> Documento de especificação para desenvolvimento. Pensado para ser alimentado em ferramentas como Claude Code para implementação iterativa.
>
> **Status atual:** Fase 2.3.6 concluída ✅ (v0.3.6) — polimento UX + inventário completo (Bomba 2/3, Desfazer 1/3), PauseOverlay frosted-glass, GameOverModal com vidas, assets SVG dos 11 animais integrados.
>
> **Próximo:** **Fase 3 — Arte final** — integrar SVGs definitivos nos tiles e no anfitrião (assets placeholder já no lugar, ver seção 4.2).
>
> **Mudanças principais nesta versão:**
> - Lista de animais atualizada (Tanajura, Lobo-guará, Sapo-cururu, Mico-leão-dourado, Sucuri)
> - Visual dos tiles redefinido: fundo branco com animal em marca d'água + número
> - Adicionado sistema de **anfitrião** (animal correspondente ao maior tile já formado)
> - Adicionado sistema de **vidas, itens e loja** (free-to-play com anúncios e compras)
> - Adicionado sistema de **recompensas diárias**, **ranking global e pessoal**, **convites**
> - Adicionado sistema de **compartilhamento de itens** com códigos de resgate

---

## 1. Visão Geral

**Capivara 2048** é um puzzle game multiplataforma inspirado na mecânica clássica do 2048, onde os números tradicionais são acompanhados por animais da fauna brasileira. O objetivo final é alcançar a **Capivara Lendária**, o "2048" do jogo, no menor tempo possível ou com o maior número.

### 1.1 Pitch em uma frase
"Combine animais brasileiros em um tabuleiro 4x4, descubra a Capivara Lendária e dispute o ranking global."

### 1.2 Objetivos do jogador
1. **Atingir 2048** (Capivara Lendária) no menor tempo possível
2. **Atingir o maior número possível** — continuar jogando depois do 2048

### 1.3 Diferenciais
- **Identidade brasileira**: fauna nacional como protagonista (não só amazônica — inclui ícones de outros biomas)
- **Apelo visual limpo**: tile branco com animal em marca d'água + número grande, contorno colorido
- **Anfitrião dinâmico**: animal correspondente ao maior tile da partida atual aparece no topo
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
| Ícones/SVG | `flutter_svg` | Ilustrações vetoriais |
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
│   ├── inventory_system/   (Fase 2.3.6)
│   ├── ranking/
│   ├── rewards/
│   └── codes/
├── presentation/
│   ├── screens/
│   │   ├── home/           ✅
│   │   ├── game/           ✅
│   │   ├── shop/
│   │   ├── ranking/
│   │   ├── collection/
│   │   ├── daily_rewards/
│   │   ├── invite_friends/
│   │   ├── settings/
│   │   └── tutorial/
│   ├── widgets/
│   │   ├── board_widget.dart        ✅
│   │   ├── tile_widget.dart         ✅
│   │   ├── score_panel.dart         ✅
│   │   ├── status_panel.dart        ✅
│   │   ├── host_banner.dart         ✅
│   │   ├── host_artwork.dart        ✅
│   │   ├── game_background.dart     ✅
│   │   ├── lives_indicator.dart     ✅
│   │   ├── outlined_text.dart       ✅ (Fase 2.3.5, refinado em 2.3.6)
│   │   ├── pause_overlay.dart       ✅ (refatorado em 2.3.6)
│   │   ├── inventory_bar.dart       (Fase 2.3.6)
│   │   ├── inventory_item_button.dart (Fase 2.3.6)
│   │   ├── bomb_selection_overlay.dart (Fase 2.3.6)
│   │   └── animal_card.dart
│   └── controllers/
└── assets_manifest.dart
assets/
├── images/animals/tile/        ← SVGs dos tiles (11 arquivos, v0.3.6 ✅)
│   ├── Tanajura.svg
│   ├── LoboGuara.svg
│   ├── Cururu.svg
│   ├── Tucano.svg
│   ├── Sagui.svg               (placeholder — Arara-azul ainda não produzida)
│   ├── Preguica.svg
│   ├── MicoLeao.svg
│   ├── Boto.svg
│   ├── Onca.svg
│   ├── Sucuri.svg
│   └── Capivara.svg
├── images/animals/host/        ← SVGs do anfitrião (11 arquivos, v0.3.6 ✅)
│   ├── Tanajura.svg
│   ├── LoboGuara.svg
│   ├── Cururu.svg
│   ├── Tucano.svg
│   ├── Sagui.svg               (placeholder — Arara-azul ainda não produzida)
│   ├── Preguica.svg
│   ├── MicoLeao.svg
│   ├── Boto.svg
│   ├── Onca.svg
│   ├── Sucuri.svg
│   └── Capivara.svg
├── images/textures/
├── icons/                      (Fase 2.3.6 — ícones placeholder do inventário)
├── sounds/animals/
├── sounds/ui/
├── music/
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

| Nível | Valor | Animal | Justificativa | Cor (contorno) | SVG tile | SVG host |
|---|---|---|---|---|---|---|
| 1 | 2 | **Tanajura** | A famosa rainha alada que anuncia as chuvas | `#C0392B` | `tile/Tanajura.svg` ✅ | `host/Tanajura.svg` ✅ |
| 2 | 4 | **Lobo-guará** | Ícone do cerrado, estrela da nota de R$ 200 | `#E67E22` | `tile/LoboGuara.svg` ✅ | `host/LoboGuara.svg` ✅ |
| 3 | 8 | **Sapo-cururu** | Guardião noturno, figura clássica do folclore | `#8D6E63` | `tile/Cururu.svg` ✅ | `host/Cururu.svg` ✅ |
| 4 | 16 | **Tucano** | Embaixador visual das matas brasileiras | `#FFB300` | `tile/Tucano.svg` ✅ | `host/Tucano.svg` ✅ |
| 5 | 32 | **Arara-azul** | Majestade alada e inteligente | `#1E88E5` | `tile/Sagui.svg` ⚠️ placeholder | `host/Sagui.svg` ⚠️ placeholder |
| 6 | 64 | **Preguiça** | Mestre zen da copa das árvores | `#BCAAA4` | `tile/Preguica.svg` ✅ | `host/Preguica.svg` ✅ |
| 7 | 128 | **Mico-leão-dourado** | Ícone absoluto da conservação brasileira | `#FF8F00` | `tile/MicoLeao.svg` ✅ | `host/MicoLeao.svg` ✅ |
| 8 | 256 | **Boto-cor-de-rosa** | Misticismo dos rios, paleta única | `#F48FB1` | `tile/Boto.svg` ✅ | `host/Boto.svg` ✅ |
| 9 | 512 | **Onça-pintada** | Predador alfa supremo | `#FBC02D` | `tile/Onca.svg` ✅ | `host/Onca.svg` ✅ |
| 10 | 1024 | **Sucuri** | Gigante das águas profundas | `#2E7D32` | `tile/Sucuri.svg` ✅ | `host/Sucuri.svg` ✅ |
| 11 | 2048 | **🏆 Capivara Lendária** | "Diplomata da natureza" — fofura suprema | `#FFD54F` | `tile/Capivara.svg` ✅ | `host/Capivara.svg` ✅ |

> Caminhos relativos a `assets/images/animals/`. ⚠️ Nível 5 (Arara-azul) usa `Sagui.svg` como placeholder — substituir quando o SVG definitivo chegar.

### 4.1 Visual do tile
- **Fundo:** branco (`#FFFFFF`)
- **Contorno:** cor da tabela (3px, arredondado)
- **Marca d'água:** ilustração centralizada, opacidade ~25–30%, ocupa ~80% do tile
- **Número:** sobreposto, Fredoka Bold, cor `#3E2723`
- **Sombra:** suave abaixo
- **Animação idle:** respiração lenta + piscar aleatório

### 4.2 Anfitrião do jogo
- **Posição:** canto superior esquerdo, alinhado às 2 primeiras colunas do tabuleiro
- **Conteúdo:** SVG do animal (com fallback pro tile asset) + nome embaixo
- **Atualização:** muda quando o jogador forma um tile de nível superior ao recorde da partida
- **Animação:** transição suave (fade + scale) ao trocar
- **Sem placeholder com mensagem antes do primeiro tile** — o slot do anfitrião fica vazio até o primeiro animal aparecer (ver Fase 2.3.6 item B)

### 4.3 Fundo dinâmico do jogo
- **Cor base:** definida explicitamente por animal via `backgroundBaseColor` (ver 13.1 e 2.3.5 item E)
- **Textura:** padrão geométrico repetido por animal
- **Transição:** suave, sem flicker (ver 2.3.5 item B)

### 4.4 Texto sobre cor — legibilidade
- Textos brancos importantes têm contorno preto sutil (1–1.5px) com **anti-aliasing suave** (ver 2.3.6 item A)
- Aplicado em: nome do anfitrião, cronômetro, pontuação, recorde

---

## 5. Sistema de Vidas

### 5.1 Regras
- **Iniciais:** 5
- **Cap (vidas ganhas):** 15
- **Cap (vidas compradas):** ilimitado
- **Regeneração:** +1 vida a cada 30 min, parando ao atingir 5
- **Consumo:** 1 vida só no game over
- **Mínimo pra jogar:** 1 vida

### 5.2 Vidas zeradas
1. Diálogo: "Você ficou sem vidas! Quer assistir um anúncio de 30s pra ganhar +1 vida?"
2. Aceita: anúncio recompensado → +1 vida
3. **Limite diário:** 40 anúncios por dia
4. Após o limite: bloqueado até a meia-noite local

### 5.3 Modelo de dados
```dart
class LivesState {
  final int current;
  final int earnedCap;            // 15
  final DateTime? nextRegenAt;
  final int adWatchesToday;
  final DateTime adCounterDate;
}
```

---

## 6. Itens e Power-ups

### 6.1 Tipos
| Item | Efeito | Origem |
|---|---|---|
| **Bomba 2** | Explode 2 casas escolhidas | Loja, recompensas |
| **Bomba 3** | Explode 3 casas escolhidas | Apenas loja |
| **Desfazer 1** | Desfaz a última jogada | Loja, recompensas |
| **Desfazer 3** | Desfaz as últimas 3 jogadas | Apenas loja |

### 6.2 Visualização e uso (Fase 2.3.6)

#### Localização
- **`InventoryBar`** no rodapé da tela de jogo, acima do `LivesIndicator`
- Mostra cada item disponível com seu **ícone placeholder** (Material/Lucide), **contador (badge no canto)** e **estado** (habilitado/desabilitado/em uso)
- Itens com contador 0 ficam **acinzentados e desabilitados**, mas continuam visíveis (pra o usuário saber que existem)

#### Ícones placeholder (Fase 2.3.6)
Como os SVGs definitivos ainda não foram produzidos, o inventário usa ícones do Material/Lucide:

| Item | Ícone placeholder | Cor base |
|---|---|---|
| Bomba 2 | `Icons.dangerous` ou Lucide `bomb` | Vermelho-alerta `#C0392B` |
| Bomba 3 | `Icons.dangerous_outlined` (variante outline) | Vermelho-escuro `#8B0000` |
| Desfazer 1 | `Icons.undo` ou Lucide `undo-2` | Azul `#1E88E5` |
| Desfazer 3 | `Icons.replay` ou Lucide `rotate-ccw` | Azul-escuro `#0D47A1` |

> Quando os assets definitivos chegarem (Fase 4), basta plugar nos slots já preparados — sem mudança de código.

#### Fluxo de uso

**Desfazer (1 ou 3):**
1. Tap no ícone → diálogo de confirmação ("Usar 1 desfazer? Restam X")
2. Confirma → reverte estado(s) usando `undoStack` do `GameState`
3. Animação reversa (300ms)
4. Decrementa contador

**Bomba (2 ou 3):**
1. Tap no ícone → entra em **modo seleção** (overlay `BombSelectionOverlay`)
2. Tabuleiro fica destacado, células ficam tocáveis
3. Jogador toca em até N células (2 ou 3 conforme bomba) — células selecionadas pulsam
4. Botão "Explodir" / "Cancelar"
5. Confirma → animação de explosão (500ms) → tiles selecionados removem-se
6. Decrementa contador

#### Regras de bombas
- **Bomba 2:** 2 casas, devem ser **adjacentes** (compartilhar uma borda)
- **Bomba 3:** 3 casas, **não precisam ser adjacentes** (livre escolha)
- Não pode explodir células vazias (desperdício): se selecionar célula vazia, mostrar feedback "selecione um tile"
- Cancelar não consome o item

### 6.3 Game over com itens disponíveis
1. Modal de Game Over checa `Inventory`
2. Se tiver desfazer ≥1: oferece "Desfazer última jogada" (ressuscita a partida)
3. Se tiver bomba ≥1: oferece "Usar bomba" (entra em modo seleção; se acertar, partida continua)
4. Se sem itens: oferece anúncio recompensado pra item grátis (escolha entre vida, bomba ou desfazer)
5. Sempre oferece link pra loja

### 6.4 Modelo de dados
```dart
class Inventory {
  final int bomb2;
  final int bomb3;
  final int undo1;
  final int undo3;
}
```

### 6.5 Ganhar itens iniciais (modo dev / mock)
Pra testar o inventário sem loja real ainda, na Fase 2.3.6:
- Botão "Ganhar 5 de cada item" nas Configurações (modo dev, removido depois)
- Cada game over sem itens mostra "Receber 1 item de mock-anúncio" (sem AdMob real)

---

## 7. Loja de Itens

### 7.1 Pacotes
| # | Nome | Conteúdo | De | Por | Desconto |
|---|---|---|---|---|---|
| 01 | **4× Bomba 3** | 4 bombas que explodem 3 casas | R$ 7,99 | **R$ 3,99** | 50% |
| 02 | **4× Desfazer 3** | 4 desfazer de 3 jogadas | R$ 3,99 | **R$ 1,99** | 50% |
| 03 | **6 vidas** | Direto no inventário | R$ 9,99 | **R$ 2,49** | 75% |
| 04 | **10 vidas** | Direto no inventário | R$ 19,99 | **R$ 4,99** | 75% |
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

### 8.2 Ranking global (cada 7 dias)
| Posição | Recompensa |
|---|---|
| 1º | 10 vidas + 10 desfazer + 10 bombas |
| 2º | 5 vidas + 5 desfazer + 5 bombas |
| 3º | 3 vidas + 3 desfazer + 3 bombas |
| 4º–6º | 3 vidas + 3 bombas |
| 7º–9º | 3 vidas + 3 desfazer |
| 10º | 3 vidas |

### 8.3 Recorde pessoal
- 1 vida + 1 bomba + 1 desfazer

### 8.4 Convite de amigo
- Amigo cria conta + joga 1 partida → 1 combo

---

## 9. Ranking

### 9.1 Tipos
- **Pessoal:** vitalício
- **Global:** reseta a cada 7 dias

### 9.2 Reset
- Sábado às 18:00 (Brasília)
- Resultado da semana anterior na primeira abertura após reset

### 9.3 Modelo (Firestore)
```
rankings/{week_id}/entries/{userId}
  - userId, displayName
  - bestTimeMs, bestNumber
  - completedAt, country
```

---

## 10. Identidade Visual

### 10.1 Direção de arte
**Cartoon fofo (Pokémon Café Mix / Animal Crossing / Suika Game)**:
- Formas arredondadas
- Paleta vibrante mas harmônica
- Iluminação suave
- Outline opcional fino e escuro

### 10.2 Paleta principal
| Uso | Cor | Hex |
|---|---|---|
| Fundo (folhagem) | Verde-floresta médio | `#3FA968` |
| Fundo (céu/claro) | Verde-menta claro | `#D4F1DE` |
| Tabuleiro | Madeira clara | `#E8D5B7` |
| Célula vazia | Madeira sombreada | `#C9B79C` |
| Tile preenchido | Branco | `#FFFFFF` |
| Acento (UI) | Laranja-tucano | `#FF8C42` |
| Texto principal | Marrom escuro | `#3E2723` |
| Texto sobre cor | Branco-creme | `#FFF8E7` |
| Contorno de texto | Preto | `#000000` |
| Sucesso | Verde-folha | `#66BB6A` |
| Alerta | Vermelho-açaí | `#C0392B` |
| Premium/dourado | Dourado | `#FFD54F` |

### 10.3 Tipografia
- **Títulos**: `Fredoka`
- **Texto/UI**: `Nunito`
- **Pontuação e número do tile**: `Fredoka Bold`
- **Texto branco sobre fundo dinâmico**: contorno preto 1–1.5px **com anti-aliasing** (ver 4.4 e 2.3.6 item A)

### 10.4 Iconografia
- Ícones com traço arredondado (Phosphor/Lucide "duotone")
- Botões grandes (≥48x48dp) com sombra inferior

### 10.5 Animações
| Evento | Animação |
|---|---|
| Spawn de tile | Scale 0 → 1.1 → 1, bounce, 200ms |
| Movimento | Translate suave, easing cubicOut, 150ms |
| Merge | Pop, 250ms |
| Merge da Capivara | Flash dourado, partículas, zoom out, 1500ms |
| Troca de anfitrião | Fade + scale, 400ms |
| **Mudança de fundo** | `Tween<Color>`/`AnimatedContainer`, 600–800ms — sem flicker |
| Game Over | Tabuleiro escurece, modal slide+fade |
| Botão pressionado | Scale 1 → 0.95 → 1, 100ms |
| **Pause overlay (entrada)** | Fade do blur 0 → max + scale do conteúdo, 250ms (ver 2.3.6 item C) |
| **Pause overlay (saída)** | Reverso, 200ms |
| Bomba explodindo | Onda + partículas, 500ms |
| Desfazer | Reversão suave, 300ms |
| Bomba — modo seleção (entrada) | Pulse no tabuleiro + dim no resto, 200ms |
| Bomba — célula selecionada | Pulsa loop infinito, opacidade 0.7 ↔ 1.0, 600ms |

---

## 11. Sons e Música
*(inalterado — ver versões anteriores se precisar)*

Sons adicionais para Fase 2.3.6:
- **Tap em ícone do inventário:** click metálico curto
- **Bomba — entrar em modo seleção:** "tic-tac" tenso
- **Bomba — célula selecionada:** click + leve pulso
- **Bomba — explosão:** boom cartoon (já previsto)
- **Desfazer:** rewind/whoosh (já previsto)
- **Pause overlay — abrir:** whoosh suave (efeito vidro)
- **Pause overlay — fechar:** whoosh reverso

---

## 12. Telas e Fluxos

### 12.1 Mapa de telas
*(inalterado)*

### 12.2 Tela: Home
*(inalterado)*

### 12.3 Tela: Jogo
- **Topo esquerdo:** Anfitrião (animal + nome). **Sem placeholder de "Comece a jogar!" antes do primeiro tile** — slot vazio (ver 2.3.6 item B)
- **Topo direito:** StatusPanel (cronômetro + pontuação + recorde + pause integrado)
- **Centro:** tabuleiro 4x4
- **Rodapé:** `InventoryBar` + `LivesIndicator`

#### 12.3.1 Posicionamento do botão pause (Fase 2.3.5)
Integrado ao `StatusPanel` (canto direito) ou flutuante com `LayoutBuilder`.

#### 12.3.2 Pause overlay — vidro fosco cobrindo o tabuleiro (Fase 2.3.6)
**Regra crítica:** quando o jogo está pausado, o jogador **não pode estudar o tabuleiro**.

- **Cobertura:** overlay cobre **100% do tabuleiro** + 80–90% da tela útil (mas mantém visíveis o `LivesIndicator`/`InventoryBar` no rodapé pra informação contextual)
- **Efeito visual:** **vidro fosco** via `BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12))` + tint semi-transparente (ex: branco-creme 30% opacity)
- **Layout do overlay:** logo centralizado + botões "Continuar / Reiniciar / Menu"
- **Sem reposicionamento do tabuleiro:** quando o overlay aparece/desaparece, o tabuleiro **NÃO pode mudar de lugar** (ver 2.3.6 item D)
- **Animação:** entrada com fade+scale (250ms), saída reverso (200ms)

### 12.4–12.8 Outras telas
*(inalterado)*

---

## 13. Modelo de Dados

### 13.1 Animal
```dart
class Animal {
  final int level;
  final int value;
  final String name;
  final String scientificName;
  final String svgPath;
  final String soundPath;
  final Color borderColor;
  final String? funFact;
  final String? hostSvgPath;
  final double? hostAspectRatio;
  final String? backgroundTexturePath;
  final TexturePattern texturePattern;
  final Color backgroundBaseColor;
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
*(inalterado — ver versão anterior)*

### 13.5 Inventory (Hive, typeId: 2 — Fase 2.3.6)
```dart
class Inventory {
  final int bomb2;
  final int bomb3;
  final int undo1;
  final int undo3;
}
```

### 13.6 PlayerProfile, ShopPackage, ShareCode
*(inalterados)*

---

## 14. Persistência (Hive + Firestore)
*(inalterado)*

---

## 15. Roadmap de Implementação

### ✅ Fase 1 — MVP do tabuleiro
### ✅ Fase 2.1 — Visual base
### ✅ Fase 2.2 — Cronômetro + Anfitrião (versão inicial)
### ✅ Fase 2.3 — HomeScreen + Vidas + Anfitrião refatorado + Fundo dinâmico
### ✅ Fase 2.3.5 — Refinamento e Bugfixes (5 correções)

### 🚧 Fase 2.3.6 — Polimento UX + Inventário (PRÓXIMA)
**Objetivo:** corrigir 4 bugs visuais identificados em uso real **+** entregar a funcionalidade completa de inventário (Bomba + Desfazer) usando ícones placeholder Material/Lucide.

**Por que combinar:** os 4 bugs são pequenos mas afetam a experiência. Aproveitar a fase pra entregar o inventário, que estava planejado pra Fase 2.4, mas não depende de assets finais (apenas ícones genéricos).

**Estimativa:** 1 semana e meia.

#### A — Contorno do `OutlinedText` com anti-aliasing
**Bug atual:** o contorno preto ao redor das fontes brancas é pixelado, fica feio.
**Causa provável:** uso de `Paint.style = stroke` cria um stroke duro sem suavização adequada nas fontes; a abordagem com 4 `Shadow` empilhadas em offsets diagonais também sofre se for usada com `blurRadius: 0`.
**Correção:**
- Trocar a abordagem por **8 shadows em distribuição radial** (offsets em 0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°) com **`blurRadius: 0.8–1.0`** — gera um halo preto suavizado que parece um contorno, mas com anti-aliasing natural
- Alternativa: usar `Paint.style = stroke` com `Paint.strokeJoin = StrokeJoin.round` e `Paint.strokeCap = StrokeCap.round` + camada de blur leve via `Paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 0.5)`
- Testar visualmente em todas as 11 cores de fundo de animal antes de fechar

**Casos de teste:**
- Snapshot test: cronômetro branco com novo `OutlinedText` em fundo amarelo (Tucano) — borda visivelmente suave, sem pixels denteados
- Compare visual side-by-side com versão anterior — diferença claramente perceptível
- Performance: render em 60fps (8 shadows não pode tornar o widget custoso — usar `RepaintBoundary` se necessário)

#### B — Remover placeholder "Comece a jogar!" do anfitrião
**Bug atual:** ao começar o jogo, aparece um tile com cor de fundo do tabuleiro no topo com texto "Comece a jogar!" — esquisito e sem sentido.
**Correção:**
- Quando `highestLevelReached == 0` (jogo recém iniciado): o slot do anfitrião renderiza um `SizedBox.shrink()` ou um espaço vazio que **mantém a altura da área** (pra não fazer o tabuleiro pular)
- Alternativa visual mais elegante: ícone discreto da Capivara em silhueta (sem texto), sugerindo "este é seu objetivo final" — usar opacidade ~15% pra não chamar atenção
- Decisão fica pro brainstorm escolher (ver pontos abertos)

**Casos de teste:**
- Início de jogo: nenhum tile placeholder visível
- Após formar primeiro 2 (Tanajura): slot exibe Tanajura corretamente
- Layout do tabuleiro NÃO muda quando o slot deixa de estar vazio (ver item D)

#### C — Pause overlay com vidro fosco cobrindo o tabuleiro
**Bug atual:** a tela de pausa não cobre todo o tabuleiro, permitindo que o jogador **estude o jogo enquanto pausado** (vantagem injusta).
**Correção:** ver seção 12.3.2
- Implementar via `BackdropFilter` + `ImageFilter.blur(sigmaX: 12, sigmaY: 12)` aplicado a um overlay que cobre 100% do tabuleiro
- Tint suave por cima (ex: branco-creme 30% opacity) pra reforçar legibilidade dos botões
- Cobertura: 80–90% da tela útil — mantém `LivesIndicator` e `InventoryBar` visíveis no rodapé (informação contextual ok), mas **tabuleiro inteiro coberto**
- Animação de entrada: fade do blur 0 → 12 (250ms) + scale do conteúdo do overlay (logo + botões)
- Animação de saída: reverso (200ms)

**Casos de teste:**
- Snapshot test: tabuleiro completamente ininteligível através do overlay (sigma alto)
- O `BoardWidget` não recebe nenhum input enquanto overlay está ativo (gestures absorvidos)
- Em telas de baixo desempenho (Android antigo), `BackdropFilter` não trava o app — testar com fallback (overlay sólido com 90% opacity) se sigma blur ficar lento
- `LivesIndicator` e `InventoryBar` permanecem visíveis e clicáveis durante pausa

#### D — Tabuleiro não move ao pausar
**Bug atual:** quando entra em pausa, o tabuleiro muda de lugar (provavelmente uma `Column` com filho extra ou troca de `Stack` que reflow).
**Causa provável:** o overlay de pausa está sendo adicionado dentro do `Column` da tela de jogo (empurrando os outros widgets) ou o `LayoutBuilder` recalcula com altura diferente.
**Correção:**
- O `PauseOverlay` deve ser renderizado **dentro de um `Stack`** que envolve toda a `GameScreen`, com `Positioned.fill` no overlay
- O tabuleiro fica em uma `position fixa` da `Stack`, não dentro de uma `Column` que o overlay possa afetar
- Quando o overlay entra/sai, **nada além do overlay** muda no layout
- Garantir que `pause = true/false` não causa rebuild do `BoardWidget` — usar `Selector` Riverpod pra isolar

**Casos de teste:**
- Animação: gravar 60 frames durante a entrada do pause overlay e comparar posição do tabuleiro no frame 0 vs frame 60 — deve ser idêntica
- Posição em pixels do tabuleiro **não muda** entre estado pausado e não pausado (assert direto)
- O `BoardWidget` não rebuilda quando o flag `isPaused` muda (verificar com `RepaintBoundary` + debug paint)

---

#### E — Inventário (Bomba + Desfazer) — funcionalidade completa
**Objetivo:** entregar o sistema de inventário usando ícones placeholder, deixando os assets finais pra Fase 4.

**Sub-tarefas:**

##### E.1 — Modelo e persistência (1–2 dias)
- Criar `Inventory` model + `InventoryHiveAdapter` (typeId: 2)
- Criar `InventoryNotifier` (Riverpod) com métodos:
  - `consume(ItemType)` → decrementa contador
  - `add(ItemType, int)` → soma
  - `count(ItemType)` → leitura
- Persistir auto-save após cada mudança
- Estado inicial: `Inventory(0, 0, 0, 0)` (zero de tudo — itens vêm de recompensas/loja/mock)
- Botão "Ganhar 5 de cada item" nas Configurações (modo dev) pra facilitar testes

##### E.2 — `InventoryBar` widget (1 dia)
- Posicionado no rodapé da `GameScreen`, acima do `LivesIndicator`
- Renderiza 4 `InventoryItemButton`s lado a lado (Bomba 2, Bomba 3, Desfazer 1, Desfazer 3)
- Cada botão: ícone placeholder (Material/Lucide) + badge com contador no canto superior direito
- Itens com contador 0: acinzentados, desabilitados, mas visíveis
- Tamanho do botão: 56x56dp, espaçamento 8dp

##### E.3 — Desfazer (1–2 dias)
- Tap em "Desfazer 1" ou "Desfazer 3" → diálogo de confirmação
- Confirma → `gameNotifier.undo(steps)` reverte estado(s) usando `undoStack`
- Animação de reversão suave (300ms) — ver `flutter_animate`
- Decrementa contador via `InventoryNotifier.consume`
- Garantir que `undoStack` no `GameState` mantém pelo menos 3 estados anteriores
- Caso de borda: se `undoStack.length < steps`, desabilitar o botão (não dá pra desfazer mais do que tem histórico)

##### E.4 — Bomba — modo de seleção (2–3 dias)
- Tap em "Bomba 2" ou "Bomba 3" → entra em modo seleção
- Mostra `BombSelectionOverlay`:
  - Tabuleiro fica destacado (escurece tudo ao redor)
  - Texto na parte de cima: "Selecione 2 casas adjacentes" / "Selecione 3 casas"
  - Botão "Cancelar" e "Explodir" (este desabilitado até atingir o número de seleções)
- Tap em célula:
  - Se não-vazia: marca como selecionada (pulsa loop)
  - Se vazia: mostra snackbar "Selecione um tile" e ignora
  - **Bomba 2:** valida adjacência (compartilhar borda) — se a 2ª seleção não é adjacente à 1ª, desmarca a 1ª e mantém a nova
  - **Bomba 3:** sem restrição de adjacência
- Tap em célula já selecionada: desmarca
- Botão "Explodir":
  - Animação de explosão (500ms) — onda + partículas — em cada célula selecionada
  - Tiles removidos do tabuleiro
  - Decrementa contador
  - Sai do modo seleção
- Botão "Cancelar": sai do modo sem consumir item

##### E.5 — Game Over com itens (1 dia)
- Modal de Game Over verifica `Inventory`
- Se `undo1 + undo3 ≥ 1`: botão "Desfazer última jogada"
- Se `bomb2 + bomb3 ≥ 1`: botão "Usar bomba"
- Se ambos 0: oferta de mock-anúncio recompensado (escolha entre vida, bomba ou desfazer)
- Sempre: link pra loja (a loja real é Fase 2.7, mas link já pode ser placeholder)

**Casos de teste obrigatórios:**
- `Inventory` persiste corretamente em Hive (matar app + reabrir)
- `InventoryBar` mostra contadores corretos
- Desfazer reverte estado corretamente (1 e 3 passos)
- Desfazer desabilitado se não há histórico suficiente
- Bomba 2 valida adjacência (snapshot test com células diagonais não-adjacentes)
- Bomba 3 aceita células não-adjacentes
- Cancelar bomba não consome item
- Explodir bomba consome item e remove tiles
- Tap em célula vazia durante modo bomba não conta
- Game Over com itens mostra opções corretas
- Mock-anúncio funciona (sem AdMob real)

---

### 🔜 Fase 2.5 — Recompensas diárias (3 dias)
*(inalterado)*

### 🔜 Fase 2.6 — Coleção + Configurações (1 semana)
*(inalterado)*

### 🔜 Fase 2.7 — Loja mock (3 dias)
*(inalterado)*

### 🔜 Fase 3 — Backend, ranking e monetização (3–4 semanas)
*(inalterado)*

### 🔜 Fase 4 — Arte final (paralelo)
- Receber/integrar SVGs definitivos dos 11 animais
- **Substituir ícones placeholder do inventário** por SVGs definitivos (ver Fase 2.3.6 item E)
- Background de floresta na Home
- Logo do jogo
- Ícone do app

### 🔜 Fase 5 — Áudio (1 semana)
*(inalterado)*

### 🔜 Fase 6 — Polimento e Lançamento
*(inalterado)*

---

## 16. Considerações Especiais

### 16.1 Acessibilidade
- WCAG AA
- Forma + cor + número + nome
- `Semantics` pra leitor de tela
- Pause overlay deve ser anunciado ao leitor de tela ("Jogo pausado")
- Modo "alta visibilidade"
- Tamanho de fonte ajustável

### 16.2 Performance
- `const` e Riverpod selectors
- Pré-carregar SVGs (`precachePicture`)
- Pool de AudioPlayers
- 60fps em Snapdragon 660+ / iPhone 8+
- `RepaintBoundary` no `GameBackground`
- **`BackdropFilter` é custoso** — testar em devices fracos; ter fallback se ficar < 50fps (ver 2.3.6 item C)

### 16.3 LGPD / COPPA / Crianças
*(inalterado)*

### 16.4 Aspectos legais
*(inalterado)*

### 16.5 SEO e App Store
*(inalterado)*

---

## 17. Prompt Sugerido para o Claude Code (Fase 2.3.6 — via skill superpowers)

> O prompt abaixo entra no fluxo do **superpowers/brainstorming**. O resultado esperado é uma **spec detalhada da Fase 2.3.6** (refinada via brainstorm), que depois alimenta o **superpowers/writing-plans** pra gerar o plano executável. Nada de código nesta etapa — apenas elicitação, refinamento de design e plano.

---

> Use a skill `superpowers/brainstorming` pra refinar o design da próxima fase do projeto **Capivara 2048** (Flutter).
>
> **Contexto:** Estamos no projeto Capivara 2048. Use `CAPIVARA_2048_DESIGN.md` como spec geral (especialmente seções 4.2–4.4, 6, 12.3.2, 13.5 e 15 — Fase 2.3.6).
>
> **Fases concluídas:**
> - Fase 1, 2.1, 2.2, 2.3, 2.3.5
>
> **Tópico do brainstorm:** desenhar a **Fase 2.3.6 — Polimento UX + Inventário (sem assets finais)**. Combina:
> - **4 bugs visuais** identificados em uso real (precisam ser corrigidos antes de escalar)
> - **Funcionalidade completa de inventário** (Bomba 2/3 + Desfazer 1/3) usando ícones placeholder Material/Lucide (os SVGs definitivos virão na Fase 4)
>
> **Os 4 bugs visuais a refinar:**
>
> 1. **Contorno do OutlinedText pixelado** (item A): o contorno preto ao redor das fontes brancas (criado na 2.3.5) está sem anti-aliasing, fica feio. Solução: trocar 4 shadows em diagonais por 8 shadows radiais com `blurRadius: 0.8–1.0` (halo suave) ou usar `Paint.maskFilter` com blur leve.
>
> 2. **Placeholder "Comece a jogar!" do anfitrião** (item B): no início do jogo aparece um tile vazio com texto "Comece a jogar!" no slot do anfitrião — esquisito. Solução: slot fica vazio (`SizedBox` mantendo altura) ou silhueta discreta da Capivara como objetivo final (decidir no brainstorm).
>
> 3. **Pause overlay não cobre o tabuleiro** (item C, seção 12.3.2): jogador consegue estudar o tabuleiro pausado (vantagem injusta). Solução: `BackdropFilter` com blur sigma 12 cobrindo 100% do tabuleiro, mantendo `LivesIndicator` e `InventoryBar` visíveis. Ter fallback pra devices fracos.
>
> 4. **Tabuleiro move ao pausar** (item D): provavelmente o overlay está dentro de uma `Column` que reflow. Solução: usar `Stack` com `Positioned.fill` pro overlay, isolando-o do layout do tabuleiro.
>
> **Funcionalidade do inventário (item E — 5 sub-tarefas):**
>
> E.1 — Model + Hive + Notifier (`Inventory` typeId 2)
> E.2 — `InventoryBar` no rodapé da GameScreen (4 botões com badge de contador)
> E.3 — Desfazer 1 e 3 (usando `undoStack` do GameState)
> E.4 — Bomba 2 (adjacentes obrigatórias) e Bomba 3 (livre) com modo de seleção overlay
> E.5 — Game Over modal com opções de usar item ou ganhar via mock-anúncio
>
> **Ícones placeholder usados na Fase 2.3.6** (substituídos por SVGs definitivos na Fase 4):
> - Bomba 2: `Icons.dangerous` (vermelho)
> - Bomba 3: `Icons.dangerous_outlined` (vermelho-escuro)
> - Desfazer 1: `Icons.undo` (azul)
> - Desfazer 3: `Icons.replay` (azul-escuro)
>
> **Pontos abertos pra explorar no brainstorm (elicitação esperada):**
>
> Sobre os bugs:
> - Item B: o slot vazio é melhor que silhueta discreta da Capivara? Tem risco de o jogador achar que tem um bug se não houver nada lá?
> - Item C: e se o `BackdropFilter` ficar lento em algum device — qual o critério pra usar fallback (sólido com opacidade alta)? Detectar via flag de configuração ou medir FPS em runtime?
> - Item D: vale aproveitar pra refatorar a estrutura inteira da `GameScreen` pra `Stack` (mais robusto pra overlays futuros — game over, modais, etc.) ou só corrigir o caso da pausa?
>
> Sobre o inventário:
> - E.4 — restrição de adjacência da Bomba 2 deve ser **horizontal/vertical apenas** (4-vizinhos) ou também diagonal (8-vizinhos)? Qual é mais intuitivo?
> - E.4 — feedback visual quando o jogador toca em célula não-adjacente na Bomba 2: substituir a primeira ou rejeitar a segunda? Qual frustra menos?
> - E.5 — quando o Game Over oferece "ganhar item via anúncio", o jogador escolhe qual tipo (vida, bomba, desfazer) ou o sistema decide com base no que faria mais sentido (ex: tem bomba útil disponível? ofereceria desfazer pra tentar outra estratégia)?
> - E.3 — qual o tamanho ideal do `undoStack` no GameState? 3 cobre Desfazer 3, mas vale guardar mais pra ter folga? Custo de memória vs benefício?
> - Posicionamento do `InventoryBar`: acima ou abaixo do `LivesIndicator` no rodapé?
> - Botão de mock "ganhar 5 de cada item" — fica nas Configurações ou direto na tela de Debug? Como esconder em release sem quebrar testes?
>
> Sobre integração:
> - Faz sentido um teste de smoke end-to-end que cubra o fluxo completo (iniciar partida → usar bomba → pausar → continuar → desfazer → game over → usar último desfazer pra ressuscitar)? Vai capturar regressões cruzadas dos 4 bugs e do inventário ao mesmo tempo
> - Como organizar a ordem das 9 sub-tarefas (4 bugs + 5 sub-itens de inventário) — tudo paralelo, ou bugs primeiro depois inventário?
>
> **Output esperado do brainstorm:**
> Uma **spec detalhada da Fase 2.3.6** (markdown, tipo `FASE_2_3_6_SPEC.md`) com:
> - Decisões tomadas em cada ponto aberto
> - Para cada uma das 9 sub-entregas (4 bugs + 5 do inventário): arquivos a criar/modificar, mudança exata, casos de teste obrigatórios, critérios de aceite
> - Ordem de execução recomendada (dependências entre os 9 itens)
> - Cobertura de testes existentes que precisa ser atualizada
> - Estratégia de teste de smoke end-to-end (se decidido fazer)
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
- **Royal Match / Candy Crush** — referência de monetização
- **Folclore brasileiro** — pesquisa para futuras expansões

---

*Documento vivo — atualize conforme o desenvolvimento evolui.*
