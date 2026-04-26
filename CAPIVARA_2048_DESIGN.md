# 🦫 Capivara 2048 — Design Concept (Consolidado v2)

> Documento de especificação para desenvolvimento. Pensado para ser alimentado em ferramentas como Claude Code para implementação iterativa.
>
> **Status atual:** Fase 2.3 concluída ✅ — HomeScreen (novo jogo / continuar / ranking placeholder / sair), sistema de vidas com Hive (regen offline, mock-anúncio, limite 40/dia), LivesIndicator, HostArtwork com fallback, StatusPanel HH:MM:SS, pause flutuante, GameBackground com textura geométrica por animal. Próximo: **Fase 2.4** (inventário: Bomba + Desfazer).
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
- **Anfitrião dinâmico**: o animal correspondente ao maior tile da partida atual aparece no topo da tela como mascote da rodada — função educativa para crianças
- **Free-to-play justo**: sistema de vidas, itens, loja, anúncios opcionais, recompensas diárias e convites
- **Competitivo**: ranking global semanal + ranking pessoal vitalício
- **Mascote forte**: a Capivara como ícone do jogo (mascote-meme natural)

### 1.4 Público-alvo
- **Primário**: jogadores casuais de puzzle (8–45 anos)
- **Secundário**: crianças (jogo é adequado e ensina sobre fauna brasileira)
- **Terciário**: brasileiros com afinidade cultural, público educacional, turistas

---

## 2. Stack Técnica

### 2.1 Framework principal
**Flutter 3.x** (Dart) — multiplataforma único para iOS, Android, Web e Desktop (Windows/macOS/Linux).

### 2.2 Bibliotecas recomendadas
| Categoria | Biblioteca | Uso |
|---|---|---|
| Estado | `flutter_riverpod` | Gerenciamento de estado do tabuleiro e da loja |
| ID | `uuid` | IDs dos tiles para animação |
| Animações | `flutter_animate` | Transições suaves de movimento e merge |
| Áudio | `audioplayers` ou `just_audio` | Sons dos animais e música ambiente |
| Persistência | `hive` + `shared_preferences` | High score, vidas, inventário, desafios |
| Tipografia | `google_fonts` | Fontes amigáveis (Fredoka, Nunito) |
| Ícones/SVG | `flutter_svg` | Renderizar ilustrações vetoriais |
| Haptic | `flutter` nativo (HapticFeedback) | Vibração leve no merge |
| Localização | `flutter_localizations` + `intl` | PT-BR e EN como mínimo |
| Backend | `firebase_core` + `cloud_firestore` + `firebase_auth` | Ranking global, contas, convites, códigos |
| Anúncios | `google_mobile_ads` | Anúncios recompensados de 30s |
| Compras | `in_app_purchase` | Loja de itens (Android e iOS) |
| Compartilhamento | `share_plus` + `app_links` (deep linking) | Códigos de resgate via link |

### 2.3 Estrutura de pastas (atualizada)
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/         # boardSize=4, tileSpacing, durações, limites (15 vidas, 30min, etc.)
│   ├── theme/             # tema do app (cartoon fofo)
│   └── utils/             # helpers
├── data/
│   ├── models/            # Animal, Tile, GameState, PlayerInventory, ShopItem, RankingEntry
│   ├── repositories/      # persistência local (Hive) + remota (Firestore)
│   ├── animals_data.dart  # dados dos 11 animais (níveis 1–11)
│   └── shop_data.dart     # pacotes da loja (Pacote 01 a 06)
├── domain/
│   ├── game_engine/       # lógica pura do 2048 (testável) ✅ FEITO
│   ├── lives_system/      # regeneração de vidas (1 a cada 30min, cap 15)
│   ├── ranking/           # cálculo de tempo, marco zero do ranking global
│   ├── rewards/           # ciclo diário de 7 dias, recompensas de ranking
│   └── codes/             # geração e validação de códigos de compartilhamento
├── presentation/
│   ├── screens/
│   │   ├── home/
│   │   ├── game/          # ✅ tela básica feita
│   │   ├── shop/
│   │   ├── ranking/
│   │   ├── collection/
│   │   ├── daily_rewards/
│   │   ├── invite_friends/
│   │   ├── settings/
│   │   └── tutorial/
│   ├── widgets/
│   │   ├── board_widget.dart        # ✅ feito
│   │   ├── tile_widget.dart         # ✅ feito (será refeito na Fase 2)
│   │   ├── score_panel.dart         # ✅ feito
│   │   ├── host_banner.dart         # NOVO: anfitrião no topo
│   │   ├── lives_indicator.dart     # contador de vidas + timer regen
│   │   ├── inventory_bar.dart       # bombas, desfazer disponíveis durante o jogo
│   │   └── animal_card.dart
│   └── controllers/                  # Riverpod notifiers
└── assets_manifest.dart
assets/
├── images/animals/        # SVGs dos 11 animais (em produção pelo usuário)
├── sounds/animals/        # MP3/OGG curtos (~1s)
├── sounds/ui/             # cliques, vitória, derrota, jingles
├── music/                 # loops ambiente
└── fonts/
```

---

## 3. Mecânica de Jogo

### 3.1 Regras básicas (idênticas ao 2048)
- Tabuleiro **4x4** com 16 células
- Swipe nas 4 direções: ↑ ↓ ← →
- Peças iguais que colidem se fundem em uma de nível superior
- A cada movimento válido, surge uma nova peça em célula vazia (90% nível 1, 10% nível 2)
- **Game Over (jogo trancado):** tabuleiro cheio sem movimentos possíveis — consome 1 vida
- **Vitória:** Capivara Lendária (nível 11) formada — jogador pode continuar para superar a pontuação

### 3.2 Pontuação e tempo
- Cada merge soma o valor da peça resultante à pontuação
- Tabela de valores: nível 1 = 2 pts, nível 2 = 4, nível 3 = 8... nível 11 = 2048
- **Cronômetro:** começa quando a primeira peça é gerada e para quando o 2048 é formado (registro de tempo para o ranking)
- **High score pessoal**: maior pontuação alcançada
- **Maior nível alcançado**: nível mais alto formado (1–11)

### 3.3 Algoritmo de movimento (já implementado na Fase 1)
1. Para cada linha/coluna na direção do swipe:
   - Filtrar células não-vazias mantendo ordem
   - Fundir pares iguais consecutivos (cada peça pode fundir só uma vez por movimento)
   - Preencher restante com células vazias
2. Se o tabuleiro mudou: gerar nova peça
3. Verificar game over e vitória

---

## 4. Os Animais (Tiles)

A progressão de níveis vai do menor/mais comum ao maior/raríssimo, culminando na **Capivara Lendária**. Cada animal tem cor de contorno distinta.

> **Nota:** Embora a Amazônia seja o foco, ícones nacionais de outros biomas (Lobo-guará e Mico-leão-dourado) enriquecem o apelo cultural do jogo.

| Nível | Valor | Animal | Justificativa | Cor (contorno do tile) |
|---|---|---|---|---|
| 1 | 2 | **Tanajura** | A famosa rainha alada que anuncia as chuvas. Iguaria cultural e primeiro passo da jornada | `#C0392B` (vermelho-terra) |
| 2 | 4 | **Lobo-guará** | Elegante, icônico — estrela da nota de R$ 200. Toque amado do cerrado | `#E67E22` (laranja-avermelhado) |
| 3 | 8 | **Sapo-cururu** | Guardião noturno, resiliente, figura clássica do folclore brasileiro | `#8D6E63` (marrom-barro) |
| 4 | 16 | **Tucano** | Embaixador visual das matas brasileiras, contraste forte e vivacidade | `#FFB300` (amarelo-bico vibrante) |
| 5 | 32 | **Arara-azul** | Majestade alada e inteligente, beleza que desperta consciência ambiental | `#1E88E5` (azul-cobalto) |
| 6 | 64 | **Preguiça** | Mestre zen da copa das árvores, ritmo lento e fofura inegável | `#BCAAA4` (bege-acinzentado) |
| 7 | 128 | **Mico-leão-dourado** | Ágil, expressivo, ícone absoluto da conservação brasileira | `#FF8F00` (dourado-alaranjado) |
| 8 | 256 | **Boto-cor-de-rosa** | Misticismo dos rios, lendas, paleta única no tabuleiro | `#F48FB1` (rosa-chiclete) |
| 9 | 512 | **Onça-pintada** | Predador alfa supremo, imponente e respeitada | `#FBC02D` (amarelo-ouro) |
| 10 | 1024 | **Sucuri** | Gigante das águas profundas, peso dramático antes do objetivo final | `#2E7D32` (verde-pântano) |
| 11 | 2048 | **🏆 Capivara Lendária** | "Diplomata da natureza" — fofura suprema com status divino | `#FFD54F` (dourado-místico) |

### 4.1 Visual do tile (NOVO — substitui o conceito anterior)
- **Fundo do tile:** branco (`#FFFFFF`)
- **Contorno do tile:** cor definida na tabela (3px, arredondado)
- **Marca d'água:** ilustração do animal centralizada, com **opacidade ~25–30%**, ocupando ~80% do tile
- **Número:** sobreposto à marca d'água, **bem visível**, fonte Fredoka Bold, cor escura `#3E2723`, tamanho proporcional ao tile
- **Sombra:** suave abaixo do tile (depth)
- **Animação idle:** respiração lenta e piscar de olhos aleatório quando estático

> **Razão da mudança:** o número precisa ser a informação primária (legibilidade), e a marca d'água do animal traz personalidade sem competir pela leitura. Crianças aprendem a associar animal ↔ número facilmente.

### 4.2 Anfitrião do jogo (NOVO)
Quando o jogador atinge o maior nível da partida atual, o animal correspondente vira **anfitrião** e aparece no canto superior esquerdo da tela.

- **Posição:** topo da tela, lado esquerdo
- **Conteúdo:** ilustração do animal (sem marca d'água — versão completa) + **nome do animal escrito embaixo**
- **Importante:** o nome SEMPRE aparece junto, pois crianças podem jogar e essa é a informação primária sobre o animal
- **Atualização:** muda quando o jogador forma um tile de nível superior ao atual recorde da partida
- **Animação:** transição suave (fade + scale) ao trocar de anfitrião

#### Exemplo
- Maior tile na partida = 2 (Tanajura) → anfitrião: Tanajura + texto "Tanajura"
- Jogador forma um 4 → anfitrião muda para Lobo-guará + texto "Lobo-guará"
- Jogador forma um 8 → anfitrião muda para Sapo-cururu + texto "Sapo-cururu"

---

## 5. Sistema de Vidas (NOVO)

### 5.1 Regras
- **Vidas iniciais:** 5
- **Capacidade máxima (vidas ganhas):** 15
- **Capacidade máxima (vidas compradas):** ilimitada — compras se acumulam mesmo acima de 15
- **Regeneração:** +1 vida a cada **30 minutos**, parando ao atingir 5 vidas
  - Se o jogador tem 5+, a regeneração não acontece
  - Se cai abaixo de 5, retoma a regeneração
- **Consumo:** 1 vida por partida iniciada (e perdida — game over)

### 5.2 Vidas zeradas
Quando o jogador fica sem vidas:
1. Diálogo: "Você ficou sem vidas! Quer assistir um anúncio de 30s para ganhar +1 vida?"
2. Se aceitar: anúncio recompensado → +1 vida
3. **Limite diário:** até 40 anúncios recompensados de vida por dia
4. Após o limite: opção bloqueada até a meia-noite (timezone do dispositivo)

### 5.3 Modelo de dados
```dart
class LivesState {
  final int current;              // vidas atuais
  final int earnedCap;            // 15 (cap ganhas)
  final DateTime? nextRegenAt;    // null se já estiver no cap de regen
  final int adWatchesToday;       // contador diário, reseta à meia-noite
  final DateTime adCounterDate;   // data do contador
}
```

---

## 6. Itens e Power-ups (NOVO)

### 6.1 Tipos de itens
Itens são usados **durante uma partida em andamento** ou **quando o jogo trancou**.

| Item | Efeito | Origem |
|---|---|---|
| **Bomba 2** | Explode 2 casas adjacentes escolhidas | Padrão (loja, recompensas) |
| **Bomba 3** | Explode 3 casas escolhidas (categoria separada) | Apenas loja |
| **Desfazer 1** | Desfaz a última jogada | Padrão (loja, recompensas) |
| **Desfazer 3** | Desfaz as últimas 3 jogadas (categoria separada) | Apenas loja |

> **Importante:** Bomba 2 e Bomba 3 são **categorias separadas** no inventário (não são o mesmo item escalado). O mesmo vale para Desfazer 1 e Desfazer 3.

### 6.2 Quando o jogo tranca (game over)
1. Verificar inventário do jogador
2. Se tiver itens utilizáveis (qualquer bomba ou desfazer): oferecer usá-los
3. Se não tiver: oferecer **anúncio recompensado** para receber 1 item necessário (vida extra, bomba ou desfazer) — escolha do jogador
4. Também oferecer **comprar** itens da loja diretamente da tela de game over

### 6.3 Modelo de dados (inventário)
```dart
class Inventory {
  final int bomb2;
  final int bomb3;
  final int undo1;
  final int undo3;
  // vidas têm modelo próprio (LivesState)
}
```

---

## 7. Loja de Itens

### 7.1 Pacotes disponíveis
Todos os preços incluem **promoção fictícia** ("De R$X por R$Y"):

| # | Nome | Conteúdo | De | Por | Desconto |
|---|---|---|---|---|---|
| 01 | **4× Bomba 3** | 4 bombas que explodem 3 casas | R$ 7,99 | **R$ 3,99** | 50% |
| 02 | **4× Desfazer 3** | 4 desfazer de 3 jogadas | R$ 3,99 | **R$ 1,99** | 50% |
| 03 | **6 vidas** | Direto no inventário | R$ 9,99 | **R$ 2,49** | 75% |
| 04 | **10 vidas** | Direto no inventário | R$ 19,99 | **R$ 4,99** | 75% |
| 05 | **Combo Mata Atlântica** | 6 vidas + 2 bombas + 2 desfazer | R$ 10,99 | **R$ 4,99** | 50% |
| 06 | **Combo Floresta Amazônica** | 10 vidas + 4 bombas + 4 desfazer | R$ 31,99 | **R$ 9,99** | 50% |

> **Importante:** todos os pacotes têm quantidades **múltiplas de 2**, pois cada compra dá direito a um **Combo Grátis para um amigo** (metade do que foi comprado — ver seção 7.2).

### 7.2 Compartilhamento com amigos (NOVO)
Toda compra na loja gera um **código único** que o comprador pode enviar para um amigo. O amigo recebe **metade** do que o comprador adquiriu.

#### Fluxo
1. Comprador conclui a compra → ganha o pacote completo + código de compartilhamento
2. Comprador envia o código (link `share_plus` com deep link) para o amigo
3. Amigo abre o link:
   - Se já tem conta: vai direto para "Resgatar código" → ganha o item
   - Se não tem conta: precisa criar conta, depois ir em "Compras → Inserir código"
4. Ao resgatar:
   - **Oferta de dobrar:** "Quer ganhar este item em dobro? Assista 30s de anúncio." (sem limite de repetição para resgates)
   - Aceita → assiste anúncio → recebe item dobrado

#### Regras do código
- **Único por compra**
- **Vale 1× para 1 jogador** apenas
- Se já resgatado: erro "CÓDIGO INVÁLIDO, ITEM JÁ RESGATADO"
- Sem prazo de expiração (apenas o uso único)

#### Modelo de dados (Firestore)
```
shareCodes/{code}
  - buyerId: string
  - packageId: string         # "pkg_01", "pkg_02"...
  - giftContents: object      # metade do conteúdo do pacote
  - status: "pending" | "redeemed" | "expired"
  - redeemedBy: string?       # userId
  - redeemedAt: timestamp?
  - createdAt: timestamp
```

---

## 8. Recompensas

### 8.1 Recompensas diárias (ciclo de 7 dias)
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

### 8.2 Recompensas de ranking global (a cada 7 dias)
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

- Ao receber: oferta de **dobrar** assistindo 30s de anúncio (opcional)

### 8.3 Recompensa por recorde pessoal
A cada **recorde pessoal quebrado** (tempo ou número), o jogador ganha:
- **Combo:** 1 vida + 1 bomba + 1 desfazer

### 8.4 Recompensa por convite de amigo
A cada amigo convidado que **criar conta E jogar pelo menos 1 partida**:
- **1 combo** (1 vida + 1 bomba + 1 desfazer)

#### Mecânica de convite
- Jogador gera link de convite na seção "Convidar amigos"
- Link contém ID do convidante (deep link via `app_links`)
- Quando o convidado se registra usando o link, vínculo é registrado
- Quando o convidado conclui a 1ª partida, recompensa é entregue ao convidante via push/notificação

---

## 9. Ranking

### 9.1 Tipos de ranking
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
  - bestTimeMs: int           # menor tempo para 2048 nesta semana
  - bestNumber: int           # maior número alcançado nesta semana (level)
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
- Idealmente, replay do jogo serializado (lista de movimentos) para validação

---

## 10. Identidade Visual

### 10.1 Direção de arte
**Cartoon fofo (estilo Pokémon Café Mix / Animal Crossing / Suika Game)**:
- Formas arredondadas, sem cantos agressivos
- Paleta vibrante mas harmônica, inspirada na floresta
- Iluminação suave com sombras coloridas (não pretas)
- Outline opcional fino e escuro nos personagens

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
| Sucesso | Verde-folha | `#66BB6A` |
| Alerta | Vermelho-açaí | `#C0392B` |
| Premium/dourado | Dourado | `#FFD54F` |

### 10.3 Tipografia
- **Títulos**: `Fredoka` (arredondada, divertida)
- **Texto/UI**: `Nunito` (legível, amigável)
- **Pontuação e número do tile**: `Fredoka Bold` ou `Bungee` (impacto)

### 10.4 Iconografia
- Ícones com traço arredondado (estilo Phosphor/Lucide "duotone")
- Botões grandes (mínimo 48x48dp), com sombra inferior

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
| Bomba explodindo | Onda + partículas, 500ms |
| Desfazer | Reversão suave do estado anterior, 300ms |

---

## 11. Sons e Música

### 11.1 Sons dos animais (atualizado)
| Animal | Som sugerido |
|---|---|
| **Tanajura** | Zumbido leve + "tlec" |
| **Lobo-guará** | Uivo curto agudo |
| **Sapo-cururu** | "Croac" grave característico |
| **Tucano** | "Tac-tac" do bico + assobio |
| **Arara-azul** | Grasnado curto colorido |
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
- Vitória (Capivara formada): fanfarra triunfal de ~3s
- Bomba: explosão cartoon
- Desfazer: rewind/whoosh
- Vida ganha: tilim mágico
- Compra concluída: cha-ching

### 11.3 Música ambiente
- Loop suave inspirado em floresta (pássaros, água, vento ao fundo)
- Instrumental leve com flautas, marimba, percussão suave
- Volume separado de SFX (slider individual)
- Mute persistente nas configurações

### 11.4 Considerações técnicas
- Pré-carregar todos os sons no início
- Pool de AudioPlayers para evitar latência
- Formatos: OGG (Android/Web), M4A/AAC (iOS), ou MP3 universal
- Tamanho alvo: < 50KB por som de animal

---

## 12. Telas e Fluxos

### 12.1 Mapa de telas (atualizado)
```
main → HomeScreen → GameScreen
           ↑               |
           └── (menu/sair) ┘

[Splash]
   ↓
[Login/Cadastro]  (apenas primeira vez ou se quiser ranking global)
   ↓
[Home/Menu Principal]
   ├── [Jogo Clássico]
   │      ├── (anfitrião no topo)
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
- Botão grande **"Jogar"**
- Cards: Loja, Ranking, Recompensa Diária (com badge), Convidar
- Ícones menores: Coleção, Configurações, Como Jogar
- Background: cena da floresta com paralaxe leve

### 12.3 Tela: Jogo (atualizada)
- **Topo esquerdo:** Anfitrião (animal + nome)
- **Topo direito:** Pontuação atual + recorde + cronômetro + pause
- **Centro:** tabuleiro 4x4
- **Rodapé:** barra de inventário (bombas e desfazer disponíveis, com botão para usar) + indicador de vidas
- **Modal Game Over:**
  - Pontuação final, recorde, animal mais alto alcançado
  - Tempo decorrido
  - Botão "Usar item" (se houver)
  - Botão "Assistir anúncio para item grátis" (se sem itens)
  - Botão "Loja"
  - "Jogar de novo" (consome 1 vida) e "Menu"

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

---

## 13. Modelo de Dados (atualizado)

### 13.1 Animal
```dart
class Animal {
  final int level;             // 1–11
  final int value;             // 2^level
  final String name;           // "Capivara Lendária"
  final String scientificName; // "Hydrochoerus hydrochaeris"
  final String svgPath;        // "assets/images/animals/11_capivara.svg"
  final String soundPath;      // "assets/sounds/animals/capivara.mp3"
  final Color borderColor;     // contorno do tile
  final String? funFact;
  final String? hostSvgPath;             // null → fallback pro tile assetPath
  final double? hostAspectRatio;         // null → 1.0
  final String? backgroundTexturePath;  // null → CustomPainter placeholder
  final TexturePattern texturePattern;  // enum: dots, diagonal, grid, waves, blobs, scales, radial
}
```

### 13.2 Tile
```dart
class Tile {
  final String id;        // UUID
  final int level;
  final int row;
  final int col;
  final bool isNew;
  final bool justMerged;
}
```

### 13.3 GameState (atualizado com cronômetro e anfitrião)
```dart
class GameState {
  final List<List<Tile?>> board;
  final int score;
  final int highScore;
  final int highestLevelReached;     // anfitrião derivado deste valor
  final bool isGameOver;
  final bool hasWon;
  final DateTime? startedAt;         // para cronômetro
  final Duration elapsed;            // tempo decorrido
  final List<GameState> undoStack;   // últimos N estados para desfazer
}
```

### 13.4 LivesState (Hive, typeId: 1)
| Campo | Tipo | Descrição |
|---|---|---|
| lives | int | vidas atuais (0–15) |
| maxLives | int | 5 = cap regen padrão \| 15 = cap inventário \| -1 = ilimitado |
| lastRegenAt | DateTime | timestamp da última vida por regen |
| adWatchedToday | int | contador diário de anúncios mock |
| adCounterResetAt | DateTime | próxima meia-noite local |
| userId | String? | null = local; preenchido na Fase 3 |
| lastSyncedAt | DateTime? | null = nunca sincronizado |

### 13.5 PlayerProfile
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

### 13.6 ShopPackage
```dart
class ShopPackage {
  final String id;            // "pkg_01" ... "pkg_06"
  final String name;
  final String description;
  final double originalPrice;
  final double currentPrice;
  final int discountPercent;
  final RewardBundle contents;     // o que vai pro inventário
  final RewardBundle giftContents; // metade — o que o amigo recebe
}

class RewardBundle {
  final int lives;
  final int bomb2;
  final int bomb3;
  final int undo1;
  final int undo3;
}
```

### 13.7 ShareCode
```dart
class ShareCode {
  final String code;          // 8 chars alfanumérico
  final String buyerId;
  final String packageId;
  final RewardBundle giftContents;
  final ShareCodeStatus status;   // pending | redeemed | expired
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

## 15. Roadmap de Implementação (atualizado)

### ✅ Fase 1 — MVP do tabuleiro (CONCLUÍDA)
- Setup do projeto Flutter
- Game engine puro com testes unitários
- Tela de jogo básica com tiles placeholders (cor + nível)
- Swipe nas 4 direções
- Spawn, merge, game over
- Pontuação local

### 🚧 Fase 2 — Sistemas e identidade visual sem assets finais (4–6 semanas)
**Objetivo:** implementar tudo o que dá pra fazer sem depender dos SVGs definitivos. Tile placeholder usa cor + número grande. Anfitrião usa emoji ou ícone genérico temporariamente. Quando os SVGs ficarem prontos, basta plugar nos slots já preparados.

#### 2.1 — Visual base (1 semana)
- Aplicar paleta de cores definida (seção 10.2)
- Adicionar Fredoka e Nunito via `google_fonts`
- Refazer `tile_widget.dart` com novo conceito: fundo branco + contorno colorido + número grande + slot para marca d'água (placeholder por enquanto)
- Animações de movimento, spawn e merge (`flutter_animate`)
- Splash screen
- Tema do app

#### 2.2 — Cronômetro + Anfitrião (3 dias)
- Adicionar `startedAt` e `elapsed` ao `GameState`
- Iniciar contagem na primeira peça gerada, parar ao formar Capivara
- Componente `HostBanner` no topo da tela (com nome do animal embaixo)
- Atualizar anfitrião quando `highestLevelReached` aumenta
- Animação de transição entre anfitriões

#### 2.3 — HomeScreen, vidas, anfitrião refatorado, fundo dinâmico ✅
- `LivesState` com Hive
- Lógica de regeneração (1 vida / 30 min, cap 5 para regen, cap 15 para inventário)
- Indicador de vidas na Home e na tela de jogo
- Timer regressivo até próxima vida
- Consumo de vida ao iniciar partida
- Tela de "sem vidas" com opção de anúncio (mock por enquanto, integração real do AdMob na Fase 3)
- Limite de 40 anúncios/dia (contador local)

#### 2.4 — Inventário e itens (1 semana)
- Modelos `Inventory`, `Bomb2`, `Bomb3`, `Undo1`, `Undo3`
- `inventory_bar.dart` no rodapé da tela de jogo
- Implementar **Desfazer** (stack de estados)
- Implementar **Bomba** (modo de seleção: tap em até 2 ou 3 células)
- Animações de explosão e reversão
- Confirmação antes de usar (evitar toques acidentais)

#### 2.5 — Recompensas diárias (3 dias)
- Tela de recompensas com grid 7 dias
- Lógica de streak (reseta se pular dia)
- Coleta com confirmação
- Mock do "dobrar via anúncio" (botão funcional sem o ad real)
- Persistência local

#### 2.6 — Tela Home + Coleção + Configurações (1 semana)
- Home com todos os botões e indicadores
- Tela de Coleção (silhuetas para não desbloqueados, card detalhado para desbloqueados)
- Configurações (volume SFX, volume música, haptic, idioma)

#### 2.7 — Loja (mock, sem compras reais ainda) (3 dias)
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

### 🔜 Fase 4 — Arte final (paralelo com Fase 2 e 3)
- Receber/integrar os SVGs dos 11 animais (em produção pelo usuário)
- Plugar SVGs nos slots já preparados (tiles e anfitrião)
- Background de floresta na Home
- Logo do jogo
- Ícone do app
- Splash screen final

### 🔜 Fase 5 — Áudio (1 semana)
- Buscar/gravar sons dos 11 animais
- Música ambiente
- Integração com `audioplayers`
- Mixer de configurações

### 🔜 Fase 6 — Polimento e Lançamento
- Localização PT-BR / EN
- Acessibilidade (contraste, leitor de tela, fonte ajustável)
- Modo escuro (opcional)
- Testes em dispositivos reais
- Build para iOS, Android, Web
- Submissão App Store / Play Store / Web hosting
- Política de privacidade e termos de uso
- LGPD/COPPA compliance (jogo pode ter crianças)

---

## 16. Considerações Especiais

### 16.1 Acessibilidade
- Cores com contraste WCAG AA
- Não depender só de cor (forma + cor + número + nome)
- Suporte a leitor de tela com `Semantics`
- Modo "alta visibilidade" com bordas extras
- Tamanho de fonte ajustável

### 16.2 Performance
- Minimizar rebuilds com `const` e Riverpod selectors
- Pré-carregar SVGs (`precachePicture`)
- Pool de AudioPlayers
- Alvo: 60fps em Snapdragon 660+ / iPhone 8+

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

## 17. Prompt Sugerido para o Claude Code (próxima fase)

> Estamos no projeto **Capivara 2048** (Flutter). Fases 2.1 e 2.2 concluídas — identidade visual base (AppTheme, Fredoka/Nunito), TileWidget redesenhado (fundo branco + borda colorida por animal + marca d'água), HostBanner com AnimatedSwitcher, cronômetro MM:SS, sistema de pausa completo (PauseOverlay + Continuar/Reiniciar/Menu). v0.2.0 lançada.
>
> Use `CAPIVARA_2048_DESIGN.md` como referência. Próximo passo: **Fase 2.3 — Sistema de Vidas**.
>
> O sistema de vidas deve incluir: `LivesState` persistido com Hive (máx 5 vidas, regeneração 1 vida a cada 30 min), consumo de 1 vida por partida iniciada, indicador de vidas na UI (corações), tela de "sem vidas" com timer de recarga visível e mock de anúncio recompensado (botão que simula ganhar 1 vida extra). Nenhum SDK de anúncio real — apenas o mock.
>
> Use o brainstorming skill para refinar o design antes de planejar. Antes de codar, confirme o plano em alto nível.

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
