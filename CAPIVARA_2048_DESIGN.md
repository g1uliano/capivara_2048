# 🦫 Capivara 2048 — Design Concept (Consolidado v2)

> Documento de especificação para desenvolvimento. Pensado para ser alimentado em ferramentas como Claude Code para implementação iterativa.
>
> **Status atual:** Fase 2.3.5 concluída ✅ — 5 bugfixes: vidas no game over, cores explícitas por animal, transição sem flicker, OutlinedText, pause posicionado dinamicamente.
>
> **Próximo:** **Fase 2.4** — Inventário: Bomba + Desfazer.
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
│   │   ├── inventory_bar.dart       (Fase 2.4)
│   │   └── animal_card.dart
│   └── controllers/
└── assets_manifest.dart
assets/
├── images/animals/tile/
├── images/animals/host/
├── images/textures/
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
- A cada movimento válido, surge uma nova peça em célula vazia (90% nível 1, 10% nível 2)
- **Game Over (jogo trancado):** tabuleiro cheio sem movimentos possíveis — **consome 1 vida apenas neste momento** (ver regra crítica em 3.4)
- **Vitória:** Capivara Lendária (nível 11) formada — jogador pode continuar para superar a pontuação

### 3.2 Pontuação e tempo
- Cada merge soma o valor da peça resultante à pontuação
- Tabela de valores: nível 1 = 2 pts, nível 2 = 4, nível 3 = 8... nível 11 = 2048
- **Cronômetro:** começa quando a primeira peça é gerada e para quando o 2048 é formado (registro de tempo para o ranking)
- **High score pessoal**: maior pontuação alcançada
- **Maior nível alcançado**: nível mais alto formado (1–11)

### 3.3 Algoritmo de movimento (Fase 1)
1. Para cada linha/coluna na direção do swipe:
   - Filtrar células não-vazias mantendo ordem
   - Fundir pares iguais consecutivos (cada peça pode fundir só uma vez por movimento)
   - Preencher restante com células vazias
2. Se o tabuleiro mudou: gerar nova peça
3. Verificar game over e vitória

### 3.4 Regra crítica: quando uma vida é consumida
**A vida é consumida APENAS no momento do Game Over (jogo trancado).** Não é consumida ao iniciar uma partida nem ao sair pro menu.

| Ação | Consome vida? |
|---|---|
| Iniciar nova partida | ❌ Não |
| Sair pro menu durante partida | ❌ Não |
| Continuar partida salva | ❌ Não |
| Reiniciar partida em andamento | ❌ Não |
| **Tabuleiro tranca (Game Over)** | ✅ **Sim, 1 vida** |
| Atingir 2048 (vitória) | ❌ Não |

> **Razão:** se a vida fosse consumida ao iniciar, o jogador perderia vida só por sair do jogo (cenário comum: abrir, fechar pra atender alguém). Cobrar só no game over recompensa quem joga até o fim e é mais justo.

> **Limite de vidas pra iniciar:** o jogador precisa ter **pelo menos 1 vida** pra iniciar uma partida. Se tem 0, vê a tela "sem vidas" com timer de regen e mock-anúncio.

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

### 4.1 Visual do tile
- **Fundo do tile:** branco (`#FFFFFF`)
- **Contorno do tile:** cor definida na tabela (3px, arredondado)
- **Marca d'água:** ilustração do animal centralizada, com **opacidade ~25–30%**, ocupando ~80% do tile
- **Número:** sobreposto à marca d'água, **bem visível**, fonte Fredoka Bold, cor escura `#3E2723`, tamanho proporcional ao tile
- **Sombra:** suave abaixo do tile
- **Animação idle:** respiração lenta e piscar de olhos aleatório quando estático

### 4.2 Anfitrião do jogo
- **Posição:** canto superior esquerdo, alinhado às 2 primeiras colunas do tabuleiro
- **Conteúdo:** SVG do animal (com fallback pro tile asset) + nome embaixo (Fredoka SemiBold)
- **Importante:** o nome SEMPRE aparece junto, pois crianças podem jogar e essa é a informação primária
- **Atualização:** muda quando o jogador forma um tile de nível superior ao atual recorde da partida
- **Animação:** transição suave (fade + scale) ao trocar de anfitrião

### 4.3 Fundo dinâmico do jogo
- **Cor base:** derivada do `borderColor` do animal anfitrião, clareada para não cansar a vista
- **Textura:** padrão geométrico repetido por animal (placeholder via CustomPainter ou SVG)
- **Transição:** suave entre cores quando o anfitrião muda — **NÃO pode causar flicker/pisca** (ver Fase 2.3.5, item B)

### 4.4 Texto sobre cor — legibilidade
Para garantir que textos sobre o fundo dinâmico (especialmente brancos) sejam legíveis em qualquer cor:
- Textos brancos importantes (anfitrião, status, etc.) devem ter **contorno preto sutil** (1–1.5px) via `Paint.style = stroke` ou `Shadow` empilhada
- Aplicado especialmente em: nome do anfitrião, cronômetro, pontuação, recorde

---

## 5. Sistema de Vidas

### 5.1 Regras
- **Vidas iniciais:** 5
- **Capacidade máxima (vidas ganhas):** 15
- **Capacidade máxima (vidas compradas):** ilimitada
- **Regeneração:** +1 vida a cada **30 minutos**, parando ao atingir 5 vidas
- **Consumo:** 1 vida **somente no game over** (ver seção 3.4)
- **Mínimo pra jogar:** 1 vida disponível (senão exibe tela "sem vidas")

### 5.2 Vidas zeradas
1. Diálogo: "Você ficou sem vidas! Quer assistir um anúncio de 30s para ganhar +1 vida?"
2. Se aceitar: anúncio recompensado → +1 vida
3. **Limite diário:** até 40 anúncios recompensados de vida por dia
4. Após o limite: opção bloqueada até a meia-noite (timezone do dispositivo)

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
| **Bomba 2** | Explode 2 casas adjacentes escolhidas | Padrão (loja, recompensas) |
| **Bomba 3** | Explode 3 casas escolhidas (categoria separada) | Apenas loja |
| **Desfazer 1** | Desfaz a última jogada | Padrão (loja, recompensas) |
| **Desfazer 3** | Desfaz as últimas 3 jogadas (categoria separada) | Apenas loja |

### 6.2 Game over com itens disponíveis
1. Verificar inventário
2. Se tiver itens: oferecer usá-los
3. Se não: oferecer anúncio recompensado pra item grátis
4. Sempre oferecer link pra loja

### 6.3 Modelo de dados
```dart
class Inventory {
  final int bomb2;
  final int bomb3;
  final int undo1;
  final int undo3;
}
```

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
Toda compra gera um código único; o amigo recebe metade. Código vale 1× pra 1 jogador. Resgate oferece dobrar via anúncio.

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

### 8.2 Ranking global (a cada 7 dias)
| Posição | Recompensa |
|---|---|
| 1º | 10 vidas + 10 desfazer + 10 bombas |
| 2º | 5 vidas + 5 desfazer + 5 bombas |
| 3º | 3 vidas + 3 desfazer + 3 bombas |
| 4º–6º | 3 vidas + 3 bombas |
| 7º–9º | 3 vidas + 3 desfazer |
| 10º | 3 vidas |

### 8.3 Recorde pessoal
- A cada recorde quebrado: 1 vida + 1 bomba + 1 desfazer

### 8.4 Convite de amigo
- Amigo cria conta + joga 1 partida → convidante ganha 1 combo

---

## 9. Ranking

### 9.1 Tipos
- **Pessoal:** vitalício (melhores tempos, maior número)
- **Global:** reseta a cada 7 dias

### 9.2 Reset
- Sábado às 18:00 (horário de Brasília)
- Resultado da semana anterior mostrado na primeira abertura após reset

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
- Iluminação suave com sombras coloridas
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
| Contorno de texto | Preto | `#000000` |
| Sucesso | Verde-folha | `#66BB6A` |
| Alerta | Vermelho-açaí | `#C0392B` |
| Premium/dourado | Dourado | `#FFD54F` |

### 10.3 Tipografia
- **Títulos**: `Fredoka` (arredondada, divertida)
- **Texto/UI**: `Nunito` (legível, amigável)
- **Pontuação e número do tile**: `Fredoka Bold`
- **Texto branco sobre fundo dinâmico**: contorno preto 1–1.5px (ver 4.4)

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
| **Mudança de fundo** | Cor base via `Tween<Color>`/`AnimatedContainer`, 600–800ms `easeInOut` — **sem flicker** (ver 2.3.5 item B) |
| Game Over | Tabuleiro escurece, modal slide+fade |
| Botão pressionado | Scale 1 → 0.95 → 1, 100ms |
| Bomba explodindo | Onda + partículas, 500ms |
| Desfazer | Reversão suave, 300ms |

---

## 11. Sons e Música

### 11.1 Sons dos animais
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
- Vitória: fanfarra triunfal de ~3s
- Bomba: explosão cartoon
- Desfazer: rewind/whoosh
- Vida ganha: tilim mágico
- Compra concluída: cha-ching

### 11.3 Música ambiente
- Loop suave de floresta (pássaros, água, vento)
- Instrumental: flautas, marimba, percussão suave
- Volume separado de SFX

### 11.4 Considerações técnicas
- Pré-carregar todos os sons no início
- Pool de AudioPlayers
- OGG (Android/Web), M4A/AAC (iOS), MP3 universal
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
- **Indicador de vidas** no topo (com timer de regen)
- Botão grande **"Jogar"** (Novo jogo / Continuar partida salva)
- Cards: Loja, Ranking, Recompensa Diária, Convidar
- Ícones menores: Coleção, Configurações, Como Jogar
- Background: cena da floresta com paralaxe leve

### 12.3 Tela: Jogo
- **Topo esquerdo (largura = 2 colunas do tabuleiro):** Anfitrião (animal + nome)
- **Topo direito (largura = 2 colunas do tabuleiro):** StatusPanel (cronômetro + pontuação + recorde)
- **Botão de pause:** ver regra crítica em 12.3.1
- **Centro:** tabuleiro 4x4
- **Rodapé:** barra de inventário (Fase 2.4) + indicador de vidas
- **Modal Game Over:**
  - Pontuação final, recorde, animal mais alto alcançado
  - Tempo decorrido
  - Botão "Usar item" (se houver)
  - Botão "Assistir anúncio para item grátis"
  - Botão "Loja"
  - "Jogar de novo" (NÃO consome vida — ver 3.4) e "Menu"

#### 12.3.1 Posicionamento do botão pause (corrigido em 2.3.5)
O botão de pause flutuante **não pode sobrepor** outros elementos da UI (recorde, pontuação). Posições válidas:
- **Opção A:** integrado ao `StatusPanel` (canto direito do panel, junto com cronômetro/pontuação)
- **Opção B:** flutuante mas com **margem de segurança garantida** em relação ao `StatusPanel` (mínimo 12dp de gap, com `LayoutBuilder` calculando posição)

> **NÃO usar:** posição `Positioned(top: X, right: Y)` fixa sem checar a altura do StatusPanel — em telas menores ou com cronômetro em formato HH:MM:SS, o panel cresce e colide com o botão.

### 12.4 Tela: Loja
- Lista dos 6 pacotes em cards grandes
- Cada card: imagem, conteúdo, "De/Por", badge de desconto
- Após compra: tela de "Código para presentear amigo"

### 12.5 Tela: Ranking
- Tabs: Global Semanal | Pessoal
- Pódio destacado
- Lista paginada
- Contador regressivo até reset (sábado 18h)

### 12.6 Tela: Recompensas Diárias
- Grid 7 dias
- Dia atual destacado, anteriores marcados
- Botão "Coletar" + oferta de dobrar via anúncio

### 12.7 Tela: Convidar Amigos
- Botão "Gerar link de convite"
- Lista de amigos convidados (status)
- Total de combos ganhos

### 12.8 Tela: Resgatar Código
- Campo de texto
- Botão "Resgatar"
- Oferta de dobrar via anúncio

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
  final String? hostSvgPath;            // null → fallback pro tile assetPath
  final double? hostAspectRatio;        // null → 1.0
  final String? backgroundTexturePath;  // null → CustomPainter placeholder
  final TexturePattern texturePattern;  // dots, diagonal, grid, waves, blobs, scales, radial
  final Color backgroundBaseColor;      // NOVO: cor base derivada e validada manualmente por animal
                                        // (evita dessaturação automática inadequada — ver 2.3.5 item E)
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
  final List<GameState> undoStack;
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
| userId | String? | null = local; preenchido na Fase 3 |
| lastSyncedAt | DateTime? | null = nunca sincronizado |

### 13.5 PlayerProfile, ShopPackage, ShareCode
*(inalterados — ver versões anteriores do doc se precisar)*

---

## 14. Persistência (Hive + Firestore)
*(inalterado)*

---

## 15. Roadmap de Implementação

### ✅ Fase 1 — MVP do tabuleiro
- Game engine puro com testes
- Swipe, spawn, merge, game over
- Pontuação local

### ✅ Fase 2.1 — Visual base
- Paleta, tipografia, theme
- TileWidget redesenhado
- Animações básicas

### ✅ Fase 2.2 — Cronômetro + Anfitrião (versão inicial)
- HostBanner com AnimatedSwitcher
- Cronômetro MM:SS
- Sistema de pausa

### ✅ Fase 2.3 — HomeScreen + Vidas + Anfitrião refatorado + Fundo dinâmico
- HomeScreen (novo jogo / continuar / ranking placeholder / sair)
- Sistema de vidas com Hive (regen offline, mock-anúncio, limite 40/dia)
- LivesIndicator
- HostArtwork com fallback
- StatusPanel HH:MM:SS
- Pause flutuante
- GameBackground com textura geométrica por animal

### ✅ Fase 2.3.5 — Refinamento e Bugfixes
**Objetivo:** corrigir 5 bugs/UX issues identificados em uso real, antes de avançar pra próxima feature. Curta (estimado 2–3 dias). Apenas correções — nenhuma feature nova.

#### A — Vida só consome no Game Over
**Bug atual:** vida é consumida ao iniciar nova partida, então sair do jogo penaliza o jogador.
**Correção:**
- Remover consumo de vida do método `startNewGame()` / Riverpod notifier
- Adicionar consumo apenas no callback de detecção de Game Over (`isGameOver == true`)
- Validar pré-condição antes de iniciar partida: `livesState.current >= 1` (se 0, exibir tela "sem vidas" e bloquear o início)
- Atualizar testes do `lives_system/` pra cobrir os novos cenários (ver tabela em 3.4)

**Casos de teste obrigatórios:**
- Sair pro menu durante partida → vidas inalteradas
- Reiniciar partida em andamento → vidas inalteradas
- Game over → vidas decrementadas em 1
- Vitória (formar 2048) → vidas inalteradas
- Tentativa de iniciar com 0 vidas → bloqueado, exibe tela "sem vidas"

#### B — Transição de fundo sem flicker
**Bug atual:** ao trocar de animal anfitrião, a tela pisca de forma irritante.
**Causa provável:** rebuild da árvore inteira ao invés de apenas interpolar a cor; possivelmente `setState` em widget pai que recria filhos, ou `AnimatedSwitcher` no lugar errado.
**Correção:**
- Trocar a estratégia de animação para `TweenAnimationBuilder<Color>` ou `AnimatedContainer` aplicado **apenas à camada de fundo**, isolada por `RepaintBoundary`
- Garantir que a textura (camada acima da cor) não seja recriada a cada frame (use `ValueKey` na textura baseado no animal, e `AnimatedSwitcher` só pra crossfade da textura — não da cor)
- Duração: 600–800ms, curve `easeInOut`
- Não usar `setState` no widget pai durante a transição — o estado da cor anterior deve ser interno ao `GameBackground`

**Casos de teste obrigatórios:**
- Snapshot test: comparar 5 frames durante a transição entre Tucano (amarelo) e Boto (rosa) — não pode haver "salto" abrupto
- Performance: durante a transição, FPS deve permanecer ≥ 50 em emulador
- O `BoardWidget` não deve rebuildar durante a animação (verificar com `RepaintBoundary` e debug paint)

#### C — Botão de pause não sobrepõe StatusPanel
**Bug atual:** em algumas telas o botão de pause flutuante fica quase em cima do recorde.
**Correção:** ver seção 12.3.1
- **Decisão recomendada:** integrar o botão de pause **dentro do `StatusPanel`** (canto direito), eliminando o problema de sobreposição
- Alternativa: manter flutuante mas com `LayoutBuilder` calculando margem de segurança (≥12dp do StatusPanel)

**Casos de teste obrigatórios:**
- Em tela 360x640 (mínima): botão pause não toca StatusPanel
- Em tela 412x915 (média): botão pause não toca StatusPanel
- Cronômetro em HH:MM:SS (longa partida): StatusPanel cresce e botão acompanha
- Pause permanece tocável (área mínima 48x48dp)

#### D — Texto branco com contorno preto pra legibilidade
**Bug atual:** em fundos como amarelo (Tucano, Onça) e dourado (Capivara), texto branco fica difícil de ler.
**Correção:**
- Criar widget utilitário `OutlinedText` ou estilo de tema `outlinedWhiteText` que aplica:
  - `Text` com `style.foreground = Paint()..color = Colors.white`
  - Empilhar com `Text` idêntico que tem `style.foreground = Paint()..style = PaintingStyle.stroke ..strokeWidth = 1.5 ..color = Colors.black`
  - Ou usar `Shadow` simples com offset (1, 1) e (-1, -1) e (1, -1) e (-1, 1) na cor preta
- Aplicar em: nome do anfitrião, cronômetro, pontuação, recorde, qualquer texto branco sobre o `GameBackground`
- **Não aplicar** em textos sobre fundos brancos sólidos (tiles) — só onde há cor variável atrás

**Casos de teste obrigatórios:**
- Snapshot test: cronômetro branco sobre fundo amarelo (Tucano) — contorno preto visível
- Snapshot test: nome do animal sobre fundo dourado (Capivara) — legível
- Contraste WCAG: texto + contorno alcança AA mínimo em todas as 11 cores de animal

#### E — Cor de fundo do Boto deve ser rosa
**Bug atual:** quando atinge o Boto-cor-de-rosa, o fundo não fica rosa (provavelmente está dessaturado pra um bege/cinza).
**Causa provável:** a função genérica `Color.lerp(borderColor, menta, 0.65)` mistura demais o rosa com verde-menta, resultando numa cor sem identidade.
**Correção:**
- **Substituir a derivação genérica por um mapa explícito de cores de fundo por animal**, validado manualmente (campo `backgroundBaseColor` no modelo `Animal` — ver 13.1)
- Cores sugeridas (validar visualmente — ajuste se necessário):

| Animal | borderColor (tile) | backgroundBaseColor (fundo) |
|---|---|---|
| Tanajura | `#C0392B` | `#F5C2BA` (terracota suave) |
| Lobo-guará | `#E67E22` | `#FAD3B2` (laranja claro) |
| Sapo-cururu | `#8D6E63` | `#D7C4BC` (marrom claro) |
| Tucano | `#FFB300` | `#FFE9A8` (amarelo pastel) |
| Arara-azul | `#1E88E5` | `#B5D7F4` (azul céu pastel) |
| Preguiça | `#BCAAA4` | `#E8E0DC` (bege neutro) |
| Mico-leão-dourado | `#FF8F00` | `#FFD7A1` (dourado pastel) |
| **Boto-cor-de-rosa** | `#F48FB1` | `#FBD0DD` (**rosa claro nítido**) |
| Onça-pintada | `#FBC02D` | `#FFEFB0` (amarelo-ouro pastel) |
| Sucuri | `#2E7D32` | `#BFD9C0` (verde claro) |
| Capivara Lendária | `#FFD54F` | `#FFEFB8` (dourado pastel) |

- Atualizar `animals_data.dart` com o novo campo
- Remover lógica de `Color.lerp` automática do `GameBackground` — ler direto do modelo

**Casos de teste obrigatórios:**
- Cada animal renderiza com a `backgroundBaseColor` exata definida no modelo
- Boto: o fundo é nitidamente rosa (validar com olho humano e snapshot)
- Capivara: fundo é dourado pastel, distinguível do Tucano e da Onça

### 🔜 Fase 2.4 — Inventário e itens (1 semana)
- Modelos `Inventory`, `Bomb2`, `Bomb3`, `Undo1`, `Undo3`
- `inventory_bar.dart` no rodapé da tela de jogo
- **Desfazer** (stack de estados)
- **Bomba** (modo de seleção: tap em até 2 ou 3 células)
- Animações de explosão e reversão
- Confirmação antes de usar

### 🔜 Fase 2.5 — Recompensas diárias (3 dias)
*(inalterado)*

### 🔜 Fase 2.6 — Coleção + Configurações (1 semana)
*(inalterado)*

### 🔜 Fase 2.7 — Loja mock (3 dias)
*(inalterado)*

### 🔜 Fase 3 — Backend, ranking e monetização (3–4 semanas)
*(inalterado)*

### 🔜 Fase 4 — Arte final (paralelo)
*(inalterado)*

### 🔜 Fase 5 — Áudio (1 semana)
*(inalterado)*

### 🔜 Fase 6 — Polimento e Lançamento
*(inalterado)*

---

## 16. Considerações Especiais

### 16.1 Acessibilidade
- Cores com contraste WCAG AA (atenção especial pro texto com contorno — ver 4.4 e 2.3.5 item D)
- Não depender só de cor (forma + cor + número + nome)
- Suporte a leitor de tela com `Semantics`
- Modo "alta visibilidade" com bordas extras
- Tamanho de fonte ajustável

### 16.2 Performance
- Minimizar rebuilds com `const` e Riverpod selectors
- Pré-carregar SVGs (`precachePicture`)
- Pool de AudioPlayers
- Alvo: 60fps em Snapdragon 660+ / iPhone 8+
- `RepaintBoundary` no `GameBackground` pra isolar animações de cor (ver 2.3.5 item B)

### 16.3 LGPD / COPPA / Crianças
*(inalterado)*

### 16.4 Aspectos legais
*(inalterado)*

### 16.5 SEO e App Store
*(inalterado)*

---

## 17. Prompt Sugerido para o Claude Code (Fase 2.3.5 — via skill superpowers)

> O prompt abaixo entra no fluxo do **superpowers/brainstorming**. O resultado esperado é uma **spec detalhada da Fase 2.3.5** (refinada via brainstorm), que depois alimenta o **superpowers/writing-plans** pra gerar o plano executável. Nada de código nesta etapa — apenas elicitação, refinamento de design e plano.

---

> Use a skill `superpowers/brainstorming` pra refinar o design da próxima fase do projeto **Capivara 2048** (Flutter).
>
> **Contexto:** Estamos no projeto Capivara 2048. Use `CAPIVARA_2048_DESIGN.md` como spec geral (especialmente seções 3.4, 4.2–4.4, 12.3, 13.1 e 15 — Fase 2.3.5).
>
> **Fases concluídas:**
> - Fase 1, 2.1, 2.2, 2.3 (HomeScreen, sistema de vidas, anfitrião refatorado com fallback, fundo dinâmico, StatusPanel HH:MM:SS, pause flutuante)
>
> **Tópico do brainstorm:** desenhar a **Fase 2.3.5 — Refinamento e Bugfixes**. Não é nova feature — são 5 correções identificadas em uso real do app, que precisam ser tratadas antes de avançar pra Fase 2.4 (inventário).
>
> **As 5 correções a refinar:**
>
> 1. **Vida só consome no Game Over** (seção 2.3.5 item A): atualmente o app consome 1 vida ao iniciar nova partida. Isso é injusto — se o jogador sai do jogo, perde vida. A vida deve ser consumida APENAS quando o tabuleiro tranca (game over). Pré-condição pra iniciar partida: ter ≥1 vida.
>
> 2. **Transição de fundo sem flicker** (item B): atualmente a troca de cor de fundo ao mudar de anfitrião faz a tela piscar. Causa provável: rebuild da árvore ao invés de interpolação isolada. Solução: `TweenAnimationBuilder<Color>` ou `AnimatedContainer` apenas na camada de cor, dentro de `RepaintBoundary`, sem recriar a textura.
>
> 3. **Botão de pause sem sobreposição** (item C, seção 12.3.1): em algumas telas o botão de pause flutuante fica quase em cima do recorde. Decisão recomendada: integrar o botão **dentro do StatusPanel** (canto direito do panel). Alternativa: manter flutuante com margem de segurança via `LayoutBuilder`.
>
> 4. **Texto branco com contorno preto pra legibilidade** (item D, seção 4.4): em fundos amarelos (Tucano, Onça, Capivara) o texto branco vira invisível. Solução: widget utilitário `OutlinedText` que aplica stroke preto 1–1.5px ou shadows multidirecionais. Aplicar em: nome do anfitrião, cronômetro, pontuação, recorde.
>
> 5. **Cor de fundo do Boto deve ser rosa** (item E): atualmente o `Color.lerp` automático mistura rosa com menta e gera bege/cinza sem identidade. Solução: substituir a derivação automática por um mapa explícito de cores (campo `backgroundBaseColor` no modelo `Animal`) — ver tabela em 2.3.5 item E. Cada uma das 11 cores foi pré-validada visualmente, mas o brainstorm pode propor ajustes.
>
> **Pontos abertos pra explorar no brainstorm (elicitação esperada):**
> - Como sinalizar visualmente pro usuário que "sair pro menu" não custa vida (talvez tooltip, talvez badge no botão)?
> - O `OutlinedText` deve ser um widget novo ou um helper de `TextStyle` (mais leve)? Qual reusa melhor o sistema de tema existente?
> - O botão de pause integrado ao `StatusPanel` afeta a hierarquia visual? Talvez precise de redesign do panel pra acomodar 3 elementos (cronômetro, score, pause) em vez de 2
> - As cores `backgroundBaseColor` da tabela em 2.3.5 item E foram propostas — o brainstorm deve confirmar se cada uma combina com a textura geométrica usada no `GameBackground`, ou se algumas precisam ser ajustadas
> - Estratégia de migração da `LivesState` existente pro novo comportamento (vidas atuais dos jogadores existentes ficam intactas? lives já consumidas em "iniciar" não são reembolsadas, certo?)
> - Faz sentido aproveitar essa fase pra adicionar um teste de "smoke" end-to-end que detecte regressões dos 5 bugs de uma vez?
>
> **Output esperado do brainstorm:**
> Uma **spec detalhada da Fase 2.3.5** (markdown, tipo `FASE_2_3_5_SPEC.md`) com:
> - Decisões tomadas em cada ponto aberto
> - Para cada uma das 5 correções: arquivo(s) a modificar, mudança exata, casos de teste obrigatórios
> - Ordem de execução recomendada (dependências entre correções)
> - Critérios de aceite por correção (definição de "feito")
> - Cobertura de testes existentes que precisa ser atualizada/expandida
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
