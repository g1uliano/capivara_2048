# 🦫 Capivara 2048 — Design Concept (Consolidado v2)

> Documento de especificação para desenvolvimento. Pensado para ser alimentado em ferramentas como Claude Code para implementação iterativa.
>
> **Status atual:** Fase 2.3.7 concluída ✅ (v0.4.0) — SVGs dos 11 animais integrados em tiles e anfitrião, Sagui no nível 5, PauseOverlay com OutlinedText completo, ícones SVG do inventário (bomb ×2/×3, undo ×1/×3), galeria de debug `AnimalsGalleryScreen`. Auditoria visual pendente (`docs/svg_audit_2_3_7.md` — preencher após inspeção na galeria).
>
> **Próximo:** **Fase 2.3.8 — Texturas + Áudio**
>
> **Mudanças principais na v0.4.0:**
> - **SVGs integrados** nos tiles (marca d'água `Opacity(0.27)` + `SvgPicture.asset`) e no anfitrião (`hostSvgPath` populado para todos os 11 animais)
> - **Nível 5 trocado de Arara-azul para Sagui** — `borderColor: #A0826D`, `scientificName: Callithrix penicillata`
> - **PauseOverlay legível** — tint `Colors.black.withOpacity(0.25)` + `OutlinedText` em todos os textos + ícone `Text('⏸')` com 4 sombras
> - **InventoryItemButton** aceita `String? svgPath` opcional com fallback para `IconData`; 4 SVGs de ícones entregues em `assets/icons/inventory/`
> - **Galeria de debug** `AnimalsGalleryScreen` acessível via PauseOverlay → "Debug" (`kDebugMode` apenas)
> - **Model `Animal`** ganhou campos `String? scientificName` e `String? funFact` (nullable, para Coleção na Fase 5)

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
│   ├── inventory_system/   ✅ (Fase 2.3.6)
│   ├── ranking/
│   ├── rewards/
│   └── codes/
├── presentation/
│   ├── screens/
│   │   ├── home/           ✅
│   │   ├── game/           ✅
│   │   ├── debug/          ← Fase 2.3.7 (galeria de animais)
│   │   ├── shop/
│   │   ├── ranking/
│   │   ├── collection/
│   │   ├── daily_rewards/
│   │   ├── invite_friends/
│   │   ├── settings/
│   │   └── tutorial/
│   ├── widgets/
│   │   ├── board_widget.dart            ✅
│   │   ├── tile_widget.dart             ✅ (placeholder; integra SVG na 2.3.7)
│   │   ├── score_panel.dart             ✅
│   │   ├── status_panel.dart            ✅
│   │   ├── host_banner.dart             ✅
│   │   ├── host_artwork.dart            ✅ (placeholder; integra SVG na 2.3.7)
│   │   ├── game_background.dart         ✅
│   │   ├── lives_indicator.dart         ✅
│   │   ├── outlined_text.dart           ✅
│   │   ├── pause_overlay.dart           ✅ (refinamento de legibilidade na 2.3.7)
│   │   ├── inventory_bar.dart           ✅
│   │   ├── inventory_item_button.dart   ✅ (SVG na 2.3.7)
│   │   ├── bomb_selection_overlay.dart  ✅
│   │   └── animal_card.dart
│   └── controllers/
└── assets_manifest.dart
assets/
├── images/animals/tile/        ← SVGs dos tiles (11 arquivos no diretório, AINDA NÃO INTEGRADOS)
│   ├── Tanajura.svg
│   ├── LoboGuara.svg
│   ├── Cururu.svg
│   ├── Tucano.svg
│   ├── Sagui.svg               ← nível 5 (substitui Arara-azul)
│   ├── Preguica.svg
│   ├── MicoLeao.svg
│   ├── Boto.svg
│   ├── Onca.svg
│   ├── Sucuri.svg
│   └── Capivara.svg
├── images/animals/host/        ← SVGs do anfitrião (11 arquivos no diretório, AINDA NÃO INTEGRADOS)
│   ├── Tanajura.svg
│   ├── LoboGuara.svg
│   ├── Cururu.svg
│   ├── Tucano.svg
│   ├── Sagui.svg
│   ├── Preguica.svg
│   ├── MicoLeao.svg
│   ├── Boto.svg
│   ├── Onca.svg
│   ├── Sucuri.svg
│   └── Capivara.svg
├── images/textures/            ← Fase 2.3.8
├── icons/inventory/            ← Fase 2.3.7 (SVGs definitivos do inventário, quando produzidos)
│   ├── bomb_2.svg
│   ├── bomb_3.svg
│   ├── undo_1.svg
│   └── undo_3.svg
├── sounds/animals/             ← Fase 2.3.8
├── sounds/ui/                  ← Fase 2.3.8
├── music/                      ← Fase 2.3.8
└── fonts/
```

> **Estado dos assets dos animais:** os 11 SVGs estão no diretório, mas o código (`tile_widget.dart` e `host_artwork.dart`) ainda renderiza placeholders coloridos. A integração efetiva está planejada pra Fase 2.3.7 item A.

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

| Nível | Valor | Animal | Justificativa | Cor (contorno) | SVG tile (no diretório) | SVG host (no diretório) | Integrado |
|---|---|---|---|---|---|---|---|
| 1 | 2 | **Tanajura** | A famosa rainha alada que anuncia as chuvas | `#C0392B` | `tile/Tanajura.svg` | `host/Tanajura.svg` | ❌ (Fase 2.3.7) |
| 2 | 4 | **Lobo-guará** | Ícone do cerrado, estrela da nota de R$ 200 | `#E67E22` | `tile/LoboGuara.svg` | `host/LoboGuara.svg` | ❌ (Fase 2.3.7) |
| 3 | 8 | **Sapo-cururu** | Guardião noturno, figura clássica do folclore | `#8D6E63` | `tile/Cururu.svg` | `host/Cururu.svg` | ❌ (Fase 2.3.7) |
| 4 | 16 | **Tucano** | Embaixador visual das matas brasileiras | `#FFB300` | `tile/Tucano.svg` | `host/Tucano.svg` | ❌ (Fase 2.3.7) |
| 5 | 32 | **Sagui** | Pequeno primata curioso, ágil e expressivo, comum nas matas brasileiras | `#A0826D` | `tile/Sagui.svg` | `host/Sagui.svg` | ❌ (Fase 2.3.7) |
| 6 | 64 | **Preguiça** | Mestre zen da copa das árvores | `#BCAAA4` | `tile/Preguica.svg` | `host/Preguica.svg` | ❌ (Fase 2.3.7) |
| 7 | 128 | **Mico-leão-dourado** | Ícone absoluto da conservação brasileira | `#FF8F00` | `tile/MicoLeao.svg` | `host/MicoLeao.svg` | ❌ (Fase 2.3.7) |
| 8 | 256 | **Boto-cor-de-rosa** | Misticismo dos rios, paleta única | `#F48FB1` | `tile/Boto.svg` | `host/Boto.svg` | ❌ (Fase 2.3.7) |
| 9 | 512 | **Onça-pintada** | Predador alfa supremo | `#FBC02D` | `tile/Onca.svg` | `host/Onca.svg` | ❌ (Fase 2.3.7) |
| 10 | 1024 | **Sucuri** | Gigante das águas profundas | `#2E7D32` | `tile/Sucuri.svg` | `host/Sucuri.svg` | ❌ (Fase 2.3.7) |
| 11 | 2048 | **🏆 Capivara Lendária** | "Diplomata da natureza" — fofura suprema | `#FFD54F` | `tile/Capivara.svg` | `host/Capivara.svg` | ❌ (Fase 2.3.7) |

> Caminhos relativos a `assets/images/animals/`. **Nível 5 = Sagui** (substitui Arara-azul, asset disponível). Coluna "Integrado" indica se o SVG já está sendo renderizado no widget — atualmente todos são placeholders coloridos, integração efetiva na Fase 2.3.7.

#### `backgroundBaseColor` por animal (cores explícitas — Fase 2.3.5 item E)
| Animal | borderColor | backgroundBaseColor |
|---|---|---|
| Tanajura | `#C0392B` | `#F5C2BA` |
| Lobo-guará | `#E67E22` | `#FAD3B2` |
| Sapo-cururu | `#8D6E63` | `#D7C4BC` |
| Tucano | `#FFB300` | `#FFE9A8` |
| **Sagui** | `#A0826D` | `#E0D2C5` (bege claro) |
| Preguiça | `#BCAAA4` | `#E8E0DC` |
| Mico-leão-dourado | `#FF8F00` | `#FFD7A1` |
| Boto-cor-de-rosa | `#F48FB1` | `#FBD0DD` |
| Onça-pintada | `#FBC02D` | `#FFEFB0` |
| Sucuri | `#2E7D32` | `#BFD9C0` |
| Capivara Lendária | `#FFD54F` | `#FFEFB8` |

### 4.1 Visual do tile
- **Fundo:** branco (`#FFFFFF`)
- **Contorno:** cor da tabela (3px, arredondado)
- **Marca d'água:** ilustração centralizada, opacidade ~25–30%, ocupa ~80% do tile
- **Número:** sobreposto, Fredoka Bold, cor `#3E2723`
- **Sombra:** suave abaixo
- **Animação idle:** respiração lenta + piscar aleatório
- **Estado atual (até 2.3.7):** marca d'água é placeholder colorido (cor do animal com forma genérica). Após 2.3.7, será o SVG real do animal.

### 4.2 Anfitrião do jogo
- **Posição:** canto superior esquerdo, alinhado às 2 primeiras colunas do tabuleiro
- **Conteúdo:** SVG do animal (com fallback pro tile asset) + nome embaixo
- **Atualização:** muda quando o jogador forma um tile de nível superior ao recorde da partida
- **Animação:** transição suave (fade + scale) ao trocar
- **Sem placeholder com mensagem antes do primeiro tile** — o slot do anfitrião fica vazio até o primeiro animal aparecer (decidido na Fase 2.3.6 item B)
- **Estado atual (até 2.3.7):** `host_artwork.dart` renderiza placeholder colorido. Após 2.3.7, renderiza o SVG real do `host/`.

### 4.3 Fundo dinâmico do jogo
- **Cor base:** definida explicitamente por animal via `backgroundBaseColor`
- **Textura:** padrão geométrico repetido por animal (Fase 2.3.8 substitui placeholders)
- **Transição:** suave entre cores quando o anfitrião muda — sem flicker (Fase 2.3.5 item B)

### 4.4 Texto sobre cor — legibilidade
- Textos brancos importantes têm **contorno preto sutil** (1–1.5px) com **anti-aliasing suave** (Fase 2.3.6 item A)
- Aplicado em: nome do anfitrião, cronômetro, pontuação, recorde
- **Pendente (Fase 2.3.7):** aplicar também em **TODOS os textos brancos do `PauseOverlay`** — atualmente alguns ficam ilegíveis em fundos claros (Tucano, Mico, Capivara)

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
| **Bomba 2** | Explode 2 casas adjacentes escolhidas | Loja, recompensas |
| **Bomba 3** | Explode 3 casas escolhidas (categoria separada) | Apenas loja |
| **Desfazer 1** | Desfaz a última jogada | Loja, recompensas |
| **Desfazer 3** | Desfaz as últimas 3 jogadas (categoria separada) | Apenas loja |

### 6.2 Visualização e uso
- **`InventoryBar`** no rodapé da tela de jogo, acima do `LivesIndicator`
- Mostra cada item com **ícone**, **contador (badge)** e **estado**
- Itens com contador 0 ficam **acinzentados e desabilitados**, mas continuam visíveis

#### Ícones do inventário (Fase 2.3.6 → 2.3.7)
- **Fase 2.3.6 (atual):** ícones placeholder Material/Lucide
  - Bomba 2 → `Icons.dangerous` (vermelho `#C0392B`)
  - Bomba 3 → `Icons.dangerous_outlined` (vermelho-escuro `#8B0000`)
  - Desfazer 1 → `Icons.undo` (azul `#1E88E5`)
  - Desfazer 3 → `Icons.replay` (azul-escuro `#0D47A1`)
- **Fase 2.3.7 (próxima):** SVGs definitivos em `assets/icons/inventory/`
  - `bomb_2.svg`, `bomb_3.svg`, `undo_1.svg`, `undo_3.svg`
  - Substituição parcial permitida: SVGs ainda não produzidos mantêm placeholder

#### Fluxo de uso

**Desfazer (1 ou 3):**
1. Tap → diálogo de confirmação ("Usar 1 desfazer? Restam X")
2. Confirma → reverte estado(s) usando `undoStack` do `GameState`
3. Animação reversa (300ms)
4. Decrementa contador

**Bomba (2 ou 3):**
1. Tap → entra em **modo seleção** (overlay `BombSelectionOverlay`)
2. Tabuleiro destacado, células tocáveis
3. Jogador toca em até N células — selecionadas pulsam
4. Botão "Explodir" / "Cancelar"
5. Confirma → animação de explosão (500ms) → tiles selecionados removem-se
6. Decrementa contador

#### Regras de bombas
- **Bomba 2:** 2 casas adjacentes (compartilhar uma borda)
- **Bomba 3:** 3 casas, livre escolha
- Não pode explodir células vazias
- Cancelar não consome o item

### 6.3 Game over com itens disponíveis
1. Modal verifica `Inventory`
2. Se desfazer ≥1: oferece "Desfazer última jogada" (ressuscita)
3. Se bomba ≥1: oferece "Usar bomba" (entra em modo seleção)
4. Se sem itens: oferece anúncio recompensado pra item grátis
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
- Botão "Ganhar 5 de cada item" nas Configurações (modo dev, removido em release)
- Cada game over sem itens mostra "Receber 1 item de mock-anúncio"

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

- Ao receber: oferta de **dobrar** assistindo 30s de anúncio (opcional)
- **Streak quebrada:** se o jogador perde um dia, volta ao Dia 1
- Recompensa entregue na primeira abertura do jogo após meia-noite

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

### 8.3 Recorde pessoal
A cada **recorde pessoal quebrado** (tempo ou número):
- **Combo:** 1 vida + 1 bomba + 1 desfazer

### 8.4 Convite de amigo
A cada amigo convidado que **criar conta E jogar pelo menos 1 partida**:
- **1 combo** (1 vida + 1 bomba + 1 desfazer)

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
- **Títulos**: `Fredoka` (arredondada, divertida)
- **Texto/UI**: `Nunito` (legível, amigável)
- **Pontuação e número do tile**: `Fredoka Bold`
- **Texto branco sobre fundo dinâmico**: contorno preto 1–1.5px **com anti-aliasing** (ver 4.4 e Fase 2.3.6 item A)

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
| Mudança de fundo | `Tween<Color>`/`AnimatedContainer`, 600–800ms — sem flicker |
| Game Over | Tabuleiro escurece, modal slide+fade |
| Botão pressionado | Scale 1 → 0.95 → 1, 100ms |
| Pause overlay (entrada) | Fade do blur 0 → max + scale do conteúdo, 250ms |
| Pause overlay (saída) | Reverso, 200ms |
| Bomba explodindo | Onda + partículas, 500ms |
| Desfazer | Reversão suave, 300ms |
| Bomba — modo seleção (entrada) | Pulse no tabuleiro + dim no resto, 200ms |
| Bomba — célula selecionada | Pulsa loop infinito, opacidade 0.7 ↔ 1.0, 600ms |

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
   │      ├── (anfitrião no topo esquerdo, status no topo direito)
   │      ├── (vidas + inventário visível)
   │      └── [Game Over Modal]
   │              ├── Usar item
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
- **Indicador de vidas** no topo (com timer de regen)
- Botão grande **"Jogar"** (Novo jogo / Continuar partida salva)
- Cards: Loja, Ranking, Recompensa Diária (com badge), Convidar
- Ícones menores: Coleção, Configurações, Como Jogar
- Background: cena da floresta com paralaxe leve

### 12.3 Tela: Jogo
- **Topo esquerdo:** Anfitrião (animal + nome). Sem placeholder antes do primeiro tile
- **Topo direito:** StatusPanel (cronômetro + pontuação + recorde + pause integrado)
- **Centro:** tabuleiro 4x4
- **Rodapé:** `InventoryBar` + `LivesIndicator`

#### 12.3.1 Posicionamento do botão pause (Fase 2.3.5)
Integrado ao `StatusPanel` (canto direito) ou flutuante com `LayoutBuilder` garantindo margem de segurança ≥12dp.

#### 12.3.2 Pause overlay — vidro fosco cobrindo o tabuleiro (Fase 2.3.6)
**Regra crítica:** quando o jogo está pausado, o jogador **não pode estudar o tabuleiro**.

- **Cobertura:** overlay cobre **100% do tabuleiro** + 80–90% da tela útil (mantém visíveis o `LivesIndicator`/`InventoryBar` no rodapé)
- **Efeito visual:** vidro fosco via `BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12))` + tint semi-transparente (branco-creme 30% opacity)
- **Layout do overlay:** logo centralizado + botões "Continuar / Reiniciar / Menu"
- **Sem reposicionamento do tabuleiro** quando o overlay aparece/desaparece
- **Animação:** entrada com fade+scale (250ms), saída reverso (200ms)
- **Texto (Fase 2.3.7):** TODOS os textos brancos do overlay devem usar `OutlinedText` — incluindo "Pausado", botões "Continuar/Reiniciar/Menu", "Redefinir efeitos visuais" e qualquer outro

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
Tela acessível apenas em build de debug (via `kDebugMode`). Mostra os 11 animais lado a lado em 3 modos (tile, host, host com `backgroundBaseColor` aplicada). Serve pra inspeção visual rápida e pra base de snapshot tests.

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
| Campo | Tipo | Descrição |
|---|---|---|
| lives | int | vidas atuais (0–15) |
| maxLives | int | 5 = cap regen padrão / 15 = cap inventário / -1 = ilimitado |
| lastRegenAt | DateTime | timestamp da última vida por regen |
| adWatchedToday | int | contador diário de anúncios mock |
| adCounterResetAt | DateTime | próxima meia-noite local |
| userId | String? | null = local; preenchido na fase de backend |
| lastSyncedAt | DateTime? | null = nunca sincronizado |

### 13.5 Inventory (Hive, typeId: 2 — Fase 2.3.6)
```dart
class Inventory {
  final int bomb2;
  final int bomb3;
  final int undo1;
  final int undo3;
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
  final int bestNumber;       // nível mais alto (1–11)
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
- Refazer `tile_widget.dart` com novo conceito (fundo branco + contorno colorido + número grande + slot pra marca d'água — placeholder)
- Animações de movimento, spawn e merge
- Splash screen, tema do app

### ✅ Fase 2.2 — Cronômetro + Anfitrião (versão inicial)
- Cronômetro MM:SS começa na primeira peça, para ao formar Capivara
- `HostBanner` no topo da tela com nome do animal embaixo
- Atualizar anfitrião quando `highestLevelReached` aumenta
- Animação de transição entre anfitriões
- Sistema de pausa completo (PauseOverlay + Continuar/Reiniciar/Menu)

### ✅ Fase 2.3 — HomeScreen + Vidas + Anfitrião refatorado + Fundo dinâmico
- HomeScreen (novo jogo / continuar / ranking placeholder / sair)
- Sistema de vidas com Hive (regen offline, mock-anúncio, limite 40/dia)
- LivesIndicator
- HostArtwork com fallback (placeholder colorido com proporção livre, slot pronto pra SVG)
- StatusPanel HH:MM:SS
- Pause flutuante
- GameBackground com textura geométrica por animal

### ✅ Fase 2.3.5 — Refinamento e Bugfixes (5 correções)
- A — Vida só consome no Game Over
- B — Transição de fundo sem flicker
- C — Botão pause não sobrepõe StatusPanel
- D — `OutlinedText` widget com contorno preto pra textos brancos sobre fundo dinâmico
- E — Cores explícitas por animal via `backgroundBaseColor`

### ✅ Fase 2.3.6 — Polimento UX + Inventário (v0.3.6)
- 5 bugs visuais corrigidos:
  - A — `OutlinedText` com anti-aliasing (8 shadows radiais)
  - B — Removido placeholder "Comece a jogar!" do anfitrião
  - C — `PauseOverlay` com `BackdropFilter` cobrindo 100% do tabuleiro
  - D — Tabuleiro não move ao pausar (`Stack` + `Positioned.fill`)
  - E — Aplicação inicial de `OutlinedText` em alguns textos do `PauseOverlay` (cobertura ficou incompleta — completar na 2.3.7)
- Inventário completo:
  - Model + Hive + Notifier (`Inventory` typeId 2)
  - `InventoryBar` no rodapé da `GameScreen`
  - Desfazer 1 e 3 (usando `undoStack` do GameState)
  - Bomba 2 (adjacentes obrigatórias) e Bomba 3 (livre) com `BombSelectionOverlay`
  - Game Over modal com opções de usar item ou ganhar via mock-anúncio
  - Ícones placeholder Material/Lucide (substituídos na Fase 2.3.7)
- **Não entregue na 2.3.6:** integração dos SVGs dos animais (apenas posicionados no diretório de assets — vai pra 2.3.7)

### 🚧 Fase 2.3.7 — Integração de Assets dos Animais + Refinamentos (PRÓXIMA)
**Objetivo:** entrega central é integrar os SVGs já produzidos dos 11 animais (tile + host) substituindo os placeholders coloridos. Junto vão 4 entregas relacionadas que se beneficiam dos assets reais visíveis: troca de Arara-azul por Sagui, conclusão do `OutlinedText` no `PauseOverlay`, troca dos ícones placeholder do inventário por SVGs (quando produzidos), e validação visual via tela de debug.

**Estimativa:** 5–7 dias.

#### A — Integração dos SVGs dos animais (tile + host)
**Estado atual:** os 11 SVGs estão em `assets/images/animals/tile/` e `assets/images/animals/host/`, mas o código continua renderizando placeholders coloridos (cor sólida com forma genérica). O motivo é que `tile_widget.dart` e `host_artwork.dart` ainda não usam `flutter_svg` — usam `Container` com cor.

**Mudanças:**
- Confirmar que `flutter_svg` está em `pubspec.yaml` (já listado em 2.2; verificar se está instalado de fato)
- Atualizar `pubspec.yaml` declarando `assets/images/animals/tile/` e `assets/images/animals/host/`
- Refatorar `tile_widget.dart`:
  - Receber o `Animal` (ou pelo menos `tileSvgPath`)
  - Renderizar a marca d'água via `SvgPicture.asset(animal.svgPath)` num `Stack` por baixo do número
  - Aplicar `Opacity(opacity: 0.28)` ou usar `colorFilter` pra dessaturar/clarear
  - Tamanho da marca d'água: ~80% do tile (mantém o número Fredoka Bold por cima legível)
  - Garantir `BoxFit.contain` pra qualquer aspect ratio dos SVGs
  - Pré-cache: chamar `precachePicture` no início do app pra evitar pop-in no primeiro spawn
- Refatorar `host_artwork.dart`:
  - Receber `Animal` (ou pelo menos `hostSvgPath` + `hostAspectRatio`)
  - Renderizar via `SvgPicture.asset(animal.hostSvgPath ?? animal.svgPath)` (fallback automático pro tile asset se um host estiver ausente — embora todos os 11 estejam presentes)
  - `AspectRatio(aspectRatio: animal.hostAspectRatio ?? 1.0)` em volta — mas se vier `null`, usar `BoxFit.contain` no SVG e deixar o widget se ajustar
  - Sem moldura, sem fundo branco, sem borda — só o SVG "solto"
  - Centralizar verticalmente dentro do slot do `HostBanner`
- Atualizar `animals_data.dart`: garantir que cada `Animal` tem `svgPath` e `hostSvgPath` corretos apontando pros arquivos do diretório
- Manter o `borderColor` do tile (`animal.borderColor`) inalterado — a borda do tile continua sendo cor sólida, só a marca d'água passa a ser SVG

**Casos de teste obrigatórios:**
- Cada um dos 11 níveis renderiza com SVG correto na tile (snapshot test pra cada)
- Anfitrião renderiza SVG correto pra cada animal (snapshot test)
- Marca d'água NÃO compete com legibilidade do número (verificar com fundo branco e número escuro Fredoka Bold)
- `hostAspectRatio` aplicado quando definido (ex: testar com aspect 1.5 e 0.7)
- Pré-cache de SVGs não causa lag visível no primeiro frame da partida
- Se um SVG estiver faltando: app não crasha (fallback gracioso ou erro tratado)

#### B — Trocar Arara-azul por Sagui no nível 5
**Contexto:** o asset SVG produzido para o nível 5 foi do **Sagui**, não da Arara-azul originalmente planejada. Em vez de produzir mais um asset, ajustamos o jogo pra refletir o asset existente.

**Mudanças:**
- `animals_data.dart` (nível 5):
  - `name`: "Sagui"
  - `scientificName`: a definir (ex: *Callithrix penicillata* ou *Callithrix jacchus* — decidir no brainstorm)
  - `borderColor`: `#A0826D` (marrom-acinzentado)
  - `backgroundBaseColor`: `#E0D2C5` (bege claro)
  - `svgPath`: `assets/images/animals/tile/Sagui.svg` (já existe)
  - `hostSvgPath`: `assets/images/animals/host/Sagui.svg` (já existe)
  - `funFact` (sugerido): "O sagui é um dos primatas mais comuns das matas brasileiras, conhecido pela cauda anelada e pelos chamados agudos"
- Atualizar nome em strings localizadas (`app_pt.arb`, `app_en.arb` — "Marmoset" em inglês)
- Atualizar som correspondente em 11.1 (já refletido: "Trinado curto agudo")
- Buscar e remover qualquer referência hardcoded a `arara` ou `arara_azul` no código (constantes, testes, comentários)

**Casos de teste obrigatórios:**
- Renderizar tile nível 32 mostra Sagui (snapshot)
- Renderizar anfitrião nível 32 mostra Sagui + texto "Sagui"
- Cor do fundo do jogo quando o Sagui é anfitrião é `#E0D2C5` (bege claro)
- `borderColor` do tile é `#A0826D`
- Nenhuma referência residual a "Arara-azul" no código ou strings (lint/grep)
- Testes de regra de negócio que mencionam o nome do nível 5 atualizados

#### C — Aplicação completa do `OutlinedText` no `PauseOverlay`
**Bug atual:** no menu de pausa, alguns textos brancos ficam ilegíveis em fundos claros do anfitrião (Tucano, Mico, Capivara). A aplicação parcial da Fase 2.3.6 item E não cobriu todos os elementos.

**Elementos a tratar:**
- Título "Pausado"
- Ícone ⏸️ (se for `Icon` Material, aplicar sombra/contorno equivalente via `Stack` ou `IconThemeData` com sombras)
- Botões "Continuar / Reiniciar / Menu" — texto interno
- Legenda "Redefinir efeitos visuais"
- Qualquer outra label/descrição

**Correção:**
- Auditoria completa do `pause_overlay.dart`: localizar todos os `Text` widgets e substituir por `OutlinedText` quando a cor for branca/clara
- Garantir que a implementação do `OutlinedText` é a versão refinada da Fase 2.3.6 item A (8 shadows radiais com `blurRadius: 0.8–1.0`)
- **Reforço de contraste no overlay** (decidir no brainstorm):
  - Opção 1: aumentar tint sobre o blur (tint preto 20–30% por cima, em vez de branco-creme 30%)
  - Opção 2: aplicar fundo semi-opaco preto/escuro nos botões "Continuar/Reiniciar/Menu" (ex: `Colors.black.withOpacity(0.4)` com bordas arredondadas)
  - Opção 3: combinar ambos
- Garantir que os ícones (se houver — ex: ⏸️, 🔄, ↩️) têm a mesma sombra/contorno que os textos

**Casos de teste obrigatórios:**
- Snapshot test: pausar com Tucano como anfitrião (fundo amarelo) — todos os textos do overlay legíveis
- Snapshot test: pausar com Capivara (fundo dourado) — idem
- Snapshot test: pausar com Sucuri (fundo verde claro) — idem
- Snapshot test: pausar com Mico-leão-dourado (fundo dourado-pastel) — idem
- Contraste WCAG AA pra cada combinação texto branco + outline preto + fundo do animal (com blur aplicado)
- Botões: área tocável ≥48dp, texto centralizado e legível
- Lint/grep: nenhum `Text` cor branca/clara no `pause_overlay.dart` que não tenha sido substituído por `OutlinedText`

#### D — Substituir ícones placeholder do inventário por SVGs definitivos
**Contexto:** na Fase 2.3.6 o inventário usa `Icons.dangerous`, `Icons.undo` etc. como placeholders. Quando os SVGs definitivos estiverem prontos, substituir.

**Pré-requisito:** SVGs em `assets/icons/inventory/`:
- `bomb_2.svg`
- `bomb_3.svg`
- `undo_1.svg`
- `undo_3.svg`

> **Estratégia gradual:** se algum SVG ainda não estiver pronto no momento da execução, **manter o placeholder Material/Lucide pra esse item específico** e marcar com `// TODO: trocar quando SVG chegar`. Não bloquear a fase pelos que faltam.

**Mudanças:**
- Atualizar `pubspec.yaml` declarando `assets/icons/inventory/`
- Refatorar `inventory_item_button.dart`:
  - Receber um `String? svgPath` opcional
  - Se `svgPath != null`: renderizar `SvgPicture.asset(svgPath, width: 32, height: 32, colorFilter: ColorFilter.mode(color, BlendMode.srcIn))`
  - Se `svgPath == null`: fallback pro `IconData` legado
- Atualizar a lista de itens em `inventory_bar.dart` apontando pros SVGs disponíveis
- Validar visualmente que os SVGs respeitam contraste no fundo claro do `InventoryBar` e ficam reconhecíveis no tamanho 32x32
- Garantir que o badge de contador continua bem posicionado (canto superior direito) sobre o novo ícone

**Casos de teste obrigatórios:**
- `InventoryItemButton` renderiza SVG quando `svgPath` é passado
- `InventoryItemButton` faz fallback pro `IconData` quando `svgPath` é null
- Snapshot test: cada um dos 4 itens com SVG definitivo (se disponível)
- Item desabilitado (contador 0): SVG fica acinzentado (via `colorFilter` ou opacity)
- Badge de contador continua visível e legível por cima do novo ícone

#### E — Tela de debug + validação visual dos SVGs dos animais
**Contexto:** após integrar os SVGs (item A), validar que cada um renderiza corretamente em ambos os contextos.

**Mudanças:**
- Criar tela `lib/presentation/screens/debug/animals_gallery_screen.dart`
- Acessível apenas em `kDebugMode` (ou via Configurações em modo dev) — esconder em release
- Layout: lista vertical com os 11 animais; cada item mostra:
  - Tile completo (com marca d'água + número fictício do nível)
  - HostArtwork em proporção livre
  - Mesmo HostArtwork dentro de um container com `backgroundBaseColor` aplicada (simula o fundo do jogo)
  - Nome, level, value, hex das cores
- Botões no topo: "Exportar como snapshot" (gera imagem da tela inteira) e "Voltar"

**Verificações pra cada animal:**
- Renderiza como tile com marca d'água em opacidade ~28% e número legível
- Renderiza como host (proporção do `hostAspectRatio` respeitada)
- `borderColor` harmoniza visualmente com o SVG (sem conflito gritante)
- `backgroundBaseColor` harmoniza com o SVG do anfitrião (animal não fica "perdido" no fundo)
- Bounding box ok (animal não está pequeno demais no canto, sem excesso de espaço em branco)

**Saída:**
- **Relatório markdown** (`docs/svg_audit_2_3_7.md`) com:
  - Lista dos 11 animais e status visual ("ok" / "ajustar")
  - Pra os "ajustar": descrição do problema (ex: "Sagui — bounding box muito pequeno, ocupa 60% do tile") e sugestão (ex: "ajustar viewBox no SVG ou aumentar `BoxFit` no widget")
  - Decisão de quais correções entram na própria 2.3.7 (rápidas) vs ficam pra Fase 4 (arte adicional)

**Casos de teste obrigatórios:**
- Tela `/debug/animals_gallery` carrega sem erros e mostra os 11 animais
- Cada animal renderiza com SVG correto (não fallback)
- Snapshot da galeria salvo em `test/snapshots/animals_gallery.png` pra regressão visual

---

### 🔜 Fase 2.3.8 — Texturas + Áudio (2–3 semanas)

#### 2.3.8.A — Texturas (1 semana)
- Receber/produzir 5–6 texturas em `assets/images/textures/`:
  - `forest_floor.svg` — Tanajura, Sapo-cururu
  - `tree_canopy.svg` — Tucano, Sagui, Preguiça, Mico-leão
  - `water_ripple.svg` — Boto, Sucuri
  - `cerrado_grass.svg` — Lobo-guará
  - `dense_jungle.svg` — Onça
  - `magical_leaves.svg` — Capivara
- Atualizar `animals_data.dart` com `backgroundTexturePath`
- Substituir o `CustomPainter` placeholder do `GameBackground` por `DecorationImage` com `repeat: ImageRepeat.repeat`
- Crossfade entre texturas via `AnimatedSwitcher`
- Validar performance: textura repetida deve usar cache de raster

#### 2.3.8.B — Áudio (1–2 semanas)
- Buscar/gravar/sintetizar sons dos 11 animais (~50KB cada, OGG/M4A/MP3)
- Sons de UI: cliques, swipe inválido, jingle de recorde, game over, vitória, bomba, desfazer, vida ganha, compra, pause abrir/fechar
- Música ambiente: loop de floresta com flautas + marimba
- Integrar com `audioplayers` ou `just_audio`
- Pool de AudioPlayers
- Mixer simples nas Configurações
- Pré-carregar tudo no início do app

### 🔜 Fase 2.5 — Recompensas diárias (3 dias)
- Tela de recompensas com grid 7 dias
- Lógica de streak (reseta se pular dia)
- Coleta com confirmação
- Mock do "dobrar via anúncio"
- Persistência local

### 🔜 Fase 2.6 — Tela Home + Coleção + Configurações (1 semana)
- Home com todos os botões e indicadores
- Tela de Coleção (silhuetas para não desbloqueados, card detalhado para desbloqueados)
- Configurações (volume SFX, volume música, haptic, idioma)

### 🔜 Fase 2.7 — Loja mock (3 dias)
- Tela com os 6 pacotes
- Cards com "De/Por" e badges de desconto
- Botão "Comprar" simulado (concede o pacote diretamente em modo dev)
- Tela de "Código para presentear" gerada após compra simulada

### 🔜 Fase 3 — Backend, ranking e monetização (3–4 semanas)
- Setup Firebase (Auth, Firestore)
- Login (Google, Apple, anônimo)
- Sincronização de PlayerProfile
- Ranking global semanal (com reset sábado 18h)
- Ranking pessoal
- Sistema de convites com deep links
- Sistema de códigos de compartilhamento (Firestore)
- Resgate de códigos
- Recompensas de ranking (entregues automaticamente no reset)
- Integração Google Mobile Ads (anúncios recompensados de 30s)
- Integração `in_app_purchase` (compras reais Android e iOS)

### 🔜 Fase 4 — Arte adicional e polimento visual (paralelo com Fase 3)
- Background de floresta na Home
- Logo do jogo
- Ícone do app
- Splash screen final
- Validação visual completa final
- Eventuais correções de SVGs identificadas na auditoria da Fase 2.3.7 item E

### 🔜 Fase 5 — Polimento e Lançamento
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
- WCAG AA (atenção especial pro texto com contorno — ver 4.4 e Fase 2.3.6 item A, 2.3.7 item C)
- Forma + cor + número + nome
- `Semantics` pra leitor de tela
- Pause overlay deve ser anunciado ao leitor de tela ("Jogo pausado")
- Modo "alta visibilidade" com bordas extras
- Tamanho de fonte ajustável

### 16.2 Performance
- `const` e Riverpod selectors
- Pré-carregar SVGs (`precachePicture`) — especialmente os 11 dos animais (Fase 2.3.7 item A)
- Pool de AudioPlayers
- 60fps em Snapdragon 660+ / iPhone 8+
- `RepaintBoundary` no `GameBackground`
- `BackdropFilter` é custoso — fallback se ficar < 50fps

### 16.3 LGPD / COPPA / Crianças
- Jogo pode ter usuários crianças → conformidade COPPA (US) e LGPD (BR)
- Login não obrigatório (pode jogar offline sem ranking global)
- Para login: solicitar consentimento parental se < 13 anos
- Anúncios: usar apenas redes que suportem flag de "criança" (`tagForChildDirectedTreatment`)
- Dados coletados: mínimos necessários

### 16.4 Aspectos legais
- Verificar nomes científicos com IUCN/ICMBio
- Considerar parceria com WWF Brasil ou ICMBio (marketing + propósito)
- Atenção à apropriação cultural — evitar elementos indígenas sem consulta apropriada

### 16.5 SEO e App Store
- Nome: **"Capivara 2048"** (BR) ou **"Brazil Animals 2048"** (EN)
- Keywords: 2048, puzzle, capivara, animais, brasil, fofo, casual, fauna
- Screenshots destacando a Capivara
- Vídeo de gameplay de 30s

---

## 17. Prompt Sugerido para o Claude Code (Fase 2.3.7 — via skill superpowers)

> O prompt abaixo entra no fluxo do **superpowers/brainstorming**. O resultado esperado é uma **spec detalhada da Fase 2.3.7** (refinada via brainstorm), que depois alimenta o **superpowers/writing-plans** pra gerar o plano executável. Nada de código nesta etapa — apenas elicitação, refinamento de design e plano.

---

> Use a skill `superpowers/brainstorming` pra refinar o design da próxima fase do projeto **Capivara 2048** (Flutter).
>
> **Contexto:** Estamos no projeto Capivara 2048. Use `CAPIVARA_2048_DESIGN.md` como spec geral (especialmente seções 4, 6.2, 12.3.2, 12.9 e 15 — Fase 2.3.7).
>
> **Fases concluídas:**
> - Fase 1, 2.1, 2.2, 2.3, 2.3.5
> - **Fase 2.3.6 (v0.3.6)** — 5 bugs visuais corrigidos + inventário completo (Bomba 2/3, Desfazer 1/3) com ícones placeholder Material/Lucide
> - **Importante:** os SVGs dos 11 animais foram **produzidos e estão em `assets/images/animals/tile/` e `assets/images/animals/host/`**, mas **NÃO foram integrados ao código** ainda — `tile_widget.dart` e `host_artwork.dart` continuam renderizando placeholders coloridos. A integração é o item central da Fase 2.3.7.
>
> **Tópico do brainstorm:** desenhar a **Fase 2.3.7 — Integração de Assets dos Animais + Refinamentos**. Cinco entregas que andam juntas:
>
> **A — Integração dos SVGs dos animais (entrega central):** atualizar `pubspec.yaml` declarando `assets/images/animals/tile/` e `host/`. Refatorar `tile_widget.dart` pra renderizar marca d'água via `SvgPicture.asset(animal.svgPath)` em opacidade ~28%, mantendo número Fredoka Bold legível por cima. Refatorar `host_artwork.dart` pra renderizar SVG do `host/` com `hostAspectRatio` opcional, sem moldura. Pré-cache via `precachePicture` no boot.
>
> **B — Trocar Arara-azul por Sagui no nível 5:** o asset SVG produzido foi do Sagui. Atualizar `animals_data.dart` (nome "Sagui", `borderColor: #A0826D`, `backgroundBaseColor: #E0D2C5`, paths `tile/Sagui.svg` e `host/Sagui.svg`), strings localizadas, e varrer hardcoded de "Arara-azul".
>
> **C — Aplicação completa do `OutlinedText` no `PauseOverlay`:** o overlay tem textos brancos ilegíveis em fundos claros (Tucano, Mico, Capivara) — a aplicação iniciada na 2.3.6 ficou incompleta. Auditoria completa: substituir todos os `Text` brancos por `OutlinedText` ("Pausado", ícone ⏸️, botões "Continuar/Reiniciar/Menu", "Redefinir efeitos visuais"). Decidir se reforça contraste com tint extra escuro (20–30% preto) e/ou fundo semi-opaco nos botões.
>
> **D — Substituir ícones placeholder do inventário por SVGs definitivos:** quando `bomb_2.svg`, `bomb_3.svg`, `undo_1.svg`, `undo_3.svg` estiverem em `assets/icons/inventory/`, refatorar `inventory_item_button.dart` pra renderizar via `SvgPicture.asset` com fallback pro `IconData` legado. Substituição parcial permitida (item por item, conforme SVGs ficam prontos).
>
> **E — Tela de debug + validação visual:** criar `/debug/animals_gallery` mostrando os 11 animais (tile + host + host com `backgroundBaseColor` aplicada). Acessível só em `kDebugMode`. Produzir relatório `docs/svg_audit_2_3_7.md` com status visual de cada um (ok / ajustar) e separar quais correções entram na 2.3.7 (rápidas) vs ficam pra Fase 4.
>
> **Pontos abertos pra explorar no brainstorm (elicitação esperada):**
>
> Sobre o item A (integração dos SVGs dos animais — central):
> - Opacidade ideal da marca d'água no tile: 25%, 28%, 30% — o que dá melhor leitura do número Fredoka Bold sem perder identidade do animal? Testar com fundos brancos sólidos.
> - `colorFilter` na marca d'água: deixar SVG colorido como produzido (mantém identidade do animal) ou aplicar dessaturação leve pra reforçar legibilidade? Existe ponto intermediário (saturação reduzida sem dessaturar de vez)?
> - `BoxFit` no `tile_widget`: `contain` (margem em volta) ou `cover` (corta as bordas pra preencher)? Se os SVGs não têm aspect ratio uniforme, `cover` pode cortar partes importantes.
> - Pré-cache: chamar `precachePicture` pra TODOS os 11 SVGs no boot, ou só pros próximos níveis prováveis? Custo de memória vs latência no primeiro spawn.
> - O `hostAspectRatio` em `animals_data.dart` está definido pra cada animal? Se não, precisa medir cada SVG e popular esse campo, ou deixar `null` e usar `BoxFit.contain` no fallback?
>
> Sobre o item B (Sagui):
> - Nome científico — `Callithrix penicillata`, `Callithrix jacchus` ou genérico `Callithrix sp.`?
> - Fun fact pra Coleção — uma frase educativa, qual encaixa melhor com a vibe do jogo?
> - Tem algum lugar no código onde "Arara-azul" foi hardcoded fora do `animals_data.dart` (ex: testes de integração que testam o nome literal)?
>
> Sobre o item C (PauseOverlay):
> - **Reforço de contraste:** tint extra escuro (preto 20–30%) sobre o blur, ou fundo semi-opaco preto/escuro nos botões individualmente, ou ambos? Como cada opção afeta a sensação de "vidro fosco"?
> - O ícone ⏸️ é renderizado como `Icon` Material ou texto/font icon? Se Material, como aplicar sombra/contorno equivalente (talvez um `Stack` com 8 cópias deslocadas em preto, ou `IconThemeData` com sombras)?
> - Botões "Continuar/Reiniciar/Menu" — virar pills com fundo escuro, ou só texto interno passa a ter contorno?
>
> Sobre o item D (SVGs do inventário):
> - Se nenhum dos SVGs do inventário estiver pronto no momento do brainstorm, vale entregar a refatoração da `inventory_item_button.dart` mesmo assim (preparar pra receber `svgPath`)? Os ícones placeholder continuam funcionando até os SVGs chegarem.
> - Tamanho ideal do SVG no botão (32x32 ou 36x36)? Como afeta o badge de contador?
> - Tintar via `colorFilter` ou deixar SVG colorido por dentro? Qual dá mais flexibilidade pra estados (habilitado/desabilitado)?
>
> Sobre o item E (validação):
> - Tela `/debug/animals_gallery` deve ser acessível só em `kDebugMode` ou via Configurações em modo dev? Como esconder em release sem quebrar testes?
> - Snapshot da galeria — usar `golden_toolkit`, `alchemist`, ou snapshot nativo do Flutter? Já tem alguma dessas no projeto?
> - Critério pra "ok" vs "ajustar": julgamento subjetivo do brainstormer, ou checklist objetiva (ex: "ocupa ≥75% do bounding box", "centroide visual está dentro de margem X")?
>
> Sobre integração:
> - Ordem das 5 entregas — A primeiro (integração central, desbloqueia visual), depois E (validação revela problemas), B em paralelo (independente), C e D conforme dispondibilidade?
> - Vale rodar todos os testes existentes contra a nova lista de animais (Sagui no lugar de Arara-azul) — algum teste de regra de negócio que use string literal "Arara"?
> - Após a integração dos SVGs, vale tirar screenshots/vídeo do app rodando pra validar visualmente o resultado antes de fechar a fase?
>
> **Output esperado do brainstorm:**
> Uma **spec detalhada da Fase 2.3.7** (markdown, tipo `FASE_2_3_7_SPEC.md`) com:
> - Decisões tomadas em cada ponto aberto
> - Para cada uma das 5 sub-entregas: arquivos a criar/modificar, mudança exata, casos de teste obrigatórios, critérios de aceite
> - Ordem de execução recomendada e dependências entre as 5 entregas
> - Cobertura de testes existentes que precisa ser atualizada (especialmente os que possam testar "Arara-azul" ou os placeholders coloridos)
> - Estratégia da galeria `/debug/animals_gallery` (formato, tooling, snapshot)
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
