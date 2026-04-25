# 🦫 Capivara 2048 — Design Concept

> Documento de especificação para desenvolvimento. Pensado para ser alimentado em ferramentas como Claude Code para implementação iterativa.

---

## 1. Visão Geral

**Capivara 2048** é um puzzle game multiplataforma inspirado na mecânica clássica do 2048, onde os números tradicionais são substituídos por animais da fauna amazônica. O objetivo final é alcançar a **Capivara Lendária**, o "2048" do jogo, representada como uma capivara fofinha, carismática e icônica.

### 1.1 Pitch em uma frase
"Combine animais da Amazônia em um tabuleiro 4x4 e descubra a Capivara Lendária."

### 1.2 Diferenciais
- **Identidade brasileira/amazônica**: tema único em um gênero saturado
- **Apelo visual**: estética cartoon fofa, estilo Pokémon/Animal Crossing
- **Sons imersivos**: cada animal tem um som característico ao se combinar
- **Modo Desafio Diário**: tabuleiros pré-configurados com objetivos específicos
- **Mascote forte**: a Capivara como ícone do jogo (mascote-meme natural)

### 1.3 Público-alvo
- **Primário**: jogadores casuais de puzzle (10-45 anos)
- **Secundário**: amantes de animais, brasileiros com afinidade cultural, público educacional
- **Terciário**: turistas/estrangeiros interessados na Amazônia

---

## 2. Stack Técnica

### 2.1 Framework principal
**Flutter 3.x** (Dart) — multiplataforma único para iOS, Android, Web e Desktop (Windows/macOS/Linux).

### 2.2 Bibliotecas recomendadas
| Categoria | Biblioteca | Uso |
|---|---|---|
| Estado | `flutter_riverpod` ou `provider` | Gerenciamento de estado do tabuleiro |
| Animações | `flutter_animate` | Transições suaves de movimento e merge |
| Áudio | `audioplayers` ou `just_audio` | Sons dos animais e música ambiente |
| Persistência | `shared_preferences` + `hive` | High score, progresso, desafios diários |
| Gestos | `flutter` nativo (GestureDetector) | Detectar swipes |
| Tipografia | `google_fonts` | Fontes amigáveis (Fredoka, Nunito) |
| Ícones/SVG | `flutter_svg` | Renderizar ilustrações vetoriais |
| Hapticfeedback | `flutter` nativo (HapticFeedback) | Vibração leve no merge |
| Localização | `flutter_localizations` + `intl` | PT-BR e EN como mínimo |

### 2.3 Estrutura de pastas sugerida
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/        # cores, tamanhos, durações
│   ├── theme/            # tema do app (cartoon fofo)
│   └── utils/            # helpers
├── data/
│   ├── models/           # Animal, Tile, GameState
│   ├── repositories/     # persistência local
│   └── animals_data.dart # dados de cada animal (níveis 1-11)
├── domain/
│   ├── game_engine/      # lógica pura do 2048 (testável)
│   └── daily_challenge/  # gerador de desafios diários
├── presentation/
│   ├── screens/
│   │   ├── home/
│   │   ├── game/
│   │   ├── collection/   # animais "descobertos"
│   │   ├── daily/
│   │   └── settings/
│   ├── widgets/
│   │   ├── board.dart
│   │   ├── tile.dart
│   │   ├── score_panel.dart
│   │   └── animal_card.dart
│   └── controllers/      # Riverpod notifiers
└── assets_manifest.dart
assets/
├── images/animals/       # PNG ou SVG de cada animal
├── sounds/animals/       # MP3/OGG curtos (~1s)
├── sounds/ui/            # cliques, vitória, derrota
├── music/                # loops ambiente da floresta
└── fonts/
```

---

## 3. Mecânica de Jogo

### 3.1 Regras básicas (idênticas ao 2048)
- Tabuleiro **4x4** com 16 células
- O jogador desliza (swipe) em 4 direções: ↑ ↓ ← →
- Todas as peças deslizam para a direção escolhida
- Duas peças **iguais** que colidem se fundem em uma de **nível superior**
- A cada movimento válido, surge uma nova peça aleatória em célula vazia (90% chance de nível 1, 10% chance de nível 2)
- **Game Over**: quando o tabuleiro está cheio e não há movimentos possíveis
- **Vitória**: quando a Capivara Lendária (nível 11) é formada — jogador pode continuar para superar a pontuação

### 3.2 Pontuação
- Cada merge soma o valor da peça resultante à pontuação
- Tabela de valores: nível 1 = 2 pontos, nível 2 = 4, nível 3 = 8... nível 11 = 2048
- High score persistente entre sessões
- Pontuação separada para o Modo Desafio Diário

### 3.3 Movimento (algoritmo)
1. Para cada linha/coluna na direção do swipe:
   - Filtrar células não-vazias mantendo ordem
   - Percorrer e fundir pares iguais consecutivos (cada peça pode fundir só uma vez por movimento)
   - Preencher o restante com células vazias
2. Se o tabuleiro mudou: gerar nova peça aleatória
3. Verificar condição de game over

### 3.4 Modo Desafio Diário
- Um novo desafio é gerado a cada dia (seed baseado na data UTC)
- Tipos de desafio rotativos:
  - **Tabuleiro inicial pré-configurado**: começa com peças específicas, alcance X em N movimentos
  - **Limite de movimentos**: chegar à Capivara em até X movimentos
  - **Sem swipe específico**: vença sem usar swipe pra cima, por exemplo
  - **Meta de pontuação**: alcance X pontos antes de game over
- Streak diário (sequência de dias consecutivos)
- Histórico de desafios completados

---

## 4. Os Animais (Tiles)

A progressão de níveis vai do menor/mais comum ao maior/raríssimo, culminando na **Capivara Lendária**. Cada animal tem cor e personalidade distintas. 

> **Nota Biológica:** Embora o foco principal seja a Amazônia, a inclusão de ícones nacionais de outros biomas (como o Lobo-guará e o Mico-leão-dourado) enriquece o apelo cultural do jogo.

| Nível | Valor | Animal | Justificativa | Cor sugerida |
|---|---|---|---|---|
| 1 | 2 | **Tanajura** | A famosa rainha alada que anuncia as chuvas (e uma iguaria cultural!). O primeiro passo marcante da jornada. | `#C0392B` (Vermelho-terra escuro) |
| 2 | 4 | **Lobo-guará** | Elegante e icônico (a estrela da nota de 200!). Traz um toque amado do cerrado à mistura. | `#E67E22` (Laranja-avermelhado) |
| 3 | 8 | **Sapo-cururu** | Guardião noturno da floresta, resiliente e uma figura clássica do nosso folclore. | `#8D6E63` (Marrom-barro / terroso) |
| 4 | 16 | **Tucano** | O grande embaixador visual das matas brasileiras. Traz um contraste forte e vivacidade à tela. | `#FFB300` (Amarelo-bico vibrante) |
| 5 | 32 | **Arara-azul** | Majestade alada e inteligente. Representa uma beleza rara que desperta a consciência ambiental. | `#1E88E5` (Azul-cobalto brilhante) |
| 6 | 64 | **Preguiça** | O mestre zen da copa das árvores. Seu ritmo lento e sorriso natural a tornam um sucesso inegável de fofura. | `#BCAAA4` (Bege-acinzentado suave) |
| 7 | 128 | **Mico-leão-dourado** | Ágil, expressivo e um ícone absoluto da conservação no Brasil. Uma verdadeira joia animal. | `#FF8F00` (Dourado-alaranjado intenso) |
| 8 | 256 | **Boto-cor-de-rosa** | Carrega o misticismo e as lendas dos rios. Encantador, mágico e com uma paleta de cor única no tabuleiro. | `#F48FB1` (Rosa-chiclete suave) |
| 9 | 512 | **Onça-pintada** | O predador alfa supremo. Imponente, bela e respeitada por toda a fauna. O penúltimo grande desafio. | `#FBC02D` (Amarelo-ouro vivo) |
| 10 | 1024 | **Sucuri** | A gigante colossal das águas profundas. Traz o peso dramático de estar a apenas um passo do objetivo final. | `#2E7D32` (Verde-pântano profundo) |
| 11 | 2048 | **🏆 Capivara Lendária** | A "diplomata da natureza"! O animal mais amigável do mundo alcança seu status divino e fofura suprema. | `#FFD54F` (Dourado-místico radiante) |

> **Nota de design**: a Capivara Lendária deve ter tratamento visual especial — coroa de folhas tropicais, brilho dourado pulsante, animação de aparecimento épica e um som único e extremamente gratificante (fanfarra). Os outros 10 animais são os degraus; ela é a estrela incontestável.

### 4.1 Personalidade visual de cada tile
- Cada animal renderizado como ilustração cartoon redondinha (estilo "blob", arredondada)
- Olhos grandes expressivos (estilo kawaii)
- Cor de fundo do tile combina com a cor principal do animal, mas em um tom pasteurizado para não cansar a vista
- Sombra suave abaixo do tile para dar profundidade (depth)
- Pequena animação idle (respiração lenta, piscar de olhos aleatório) quando estático

---

## 5. Identidade Visual

### 5.1 Direção de arte
**Cartoon fofo (estilo Pokémon Café Mix / Animal Crossing / Suika Game)**:
- Formas arredondadas, sem cantos agressivos
- Paleta vibrante mas harmônica, inspirada na floresta
- Iluminação suave com sombras coloridas (não pretas)
- Texturas planas com leve gradiente
- Outline opcional fino e escuro nos personagens

### 5.2 Paleta principal
| Uso | Cor | Hex |
|---|---|---|
| Fundo (folhagem) | Verde-floresta médio | `#3FA968` |
| Fundo (céu/claro) | Verde-menta claro | `#D4F1DE` |
| Tabuleiro | Madeira clara | `#E8D5B7` |
| Célula vazia | Madeira sombreada | `#C9B79C` |
| Acento (UI) | Laranja-tucano | `#FF8C42` |
| Texto principal | Marrom escuro | `#3E2723` |
| Texto sobre cor | Branco-creme | `#FFF8E7` |
| Sucesso | Verde-folha | `#66BB6A` |
| Alerta | Vermelho-açaí | `#C0392B` |

### 5.3 Tipografia
- **Títulos**: `Fredoka` (arredondada, divertida)
- **Texto/UI**: `Nunito` (legível, amigável)
- **Pontuação**: `Fredoka Bold` ou `Bungee` (impacto)

### 5.4 Iconografia
- Ícones com traço arredondado (estilo Phosphor/Lucide "duotone")
- Botões grandes (mínimo 48x48dp), com sombra inferior chamando para clique

### 5.5 Animações principais
| Evento | Animação |
|---|---|
| Spawn de tile | Scale 0 → 1.1 → 1, com pequeno bounce, 200ms |
| Movimento | Translate suave, easing cubicOut, 150ms |
| Merge | Tile destino dá um pop (scale 1 → 1.2 → 1), 250ms |
| Merge da Capivara | Flash dourado, partículas de folhas, zoom out lento, 1500ms |
| Game Over | Tabuleiro escurece, modal entra com slide+fade |
| Botão pressionado | Scale 1 → 0.95 → 1, 100ms |

---

## 6. Sons e Música

### 6.1 Sons dos animais (ao fazer merge)
Cada animal tem um som característico curto (~0.5–1.5s), tocado quando duas peças daquele animal se fundem para formar o próximo nível.

| Animal | Som sugerido |
|---|---|
| Formiga Saúva | Click suave / chocalho leve |
| Borboleta Azul | Wing flutter / sino mágico |
| Sapo-flecha | "Croac" agudo |
| Tucano | "Tac-tac" do bico + assobio |
| Arara-azul | Grasnado curto colorido |
| Preguiça | Bocejo lento e fofo |
| Macaco-aranha | Guincho rápido |
| Boto-cor-de-rosa | Sopro d'água + assobio místico |
| Onça-pintada | Rosnado curto |
| Anaconda Verde | Chiado grave |
| **Capivara Lendária** | "Wheek" característico + fanfarra dourada |

### 6.2 Sons de UI
- Botão clicado: pop suave
- Swipe inválido: thud abafado
- Novo recorde: jingle ascendente
- Game over: nota descendente melancólica
- Vitória (Capivara formada): fanfarra triunfal de ~3s

### 6.3 Música ambiente
- Loop suave inspirado em floresta (sons de pássaros, água, vento ao fundo)
- Instrumental leve com flautas, marimba, percussão suave
- Volume separado de SFX (slider individual)
- Mute persistente nas configurações

### 6.4 Considerações técnicas
- Pré-carregar todos os sons no início do jogo
- Pool de AudioPlayers para evitar latência
- Formatos: OGG (Android/Web) e M4A/AAC (iOS) ou MP3 universal
- Tamanho alvo: < 50KB por som de animal

---

## 7. Telas e Fluxos

### 7.1 Mapa de telas
```
[Splash]
   ↓
[Home/Menu Principal]
   ├── [Jogo Clássico]
   │      └── [Game Over Modal] → Home / Replay
   ├── [Desafio Diário]
   │      └── [Resultado] → Home
   ├── [Coleção de Animais] (visualizar animais já alcançados)
   ├── [Configurações]
   │      ├── Som/Música/Vibração
   │      ├── Idioma
   │      └── Sobre / Créditos
   └── [Como Jogar] (tutorial)
```

### 7.2 Tela: Home
- Logo grande com a Capivara mascote ao centro
- Botão grande **"Jogar"** (modo clássico)
- Botão **"Desafio Diário"** com badge mostrando dias da streak
- Ícones menores: Coleção, Configurações, Como Jogar
- Background: cena da floresta amazônica com paralaxe leve

### 7.3 Tela: Jogo
- **Topo**: pontuação atual + recorde + botão pause + botão restart
- **Centro**: tabuleiro 4x4 com tiles
- **Rodapé**: dica visual de swipe (apenas nas primeiras partidas)
- **Modal Game Over**: pontuação final, recorde, animal mais alto alcançado, botões "Jogar de novo" e "Menu"

### 7.4 Tela: Coleção
- Grid 3 colunas com os 11 animais
- Animais não alcançados aparecem como silhueta ("?")
- Ao tocar em um descoberto: card com ilustração grande, nome científico real, fato curioso (sem precisar de internet — texto local)

### 7.5 Tela: Desafio Diário
- Calendário do mês com dias completos marcados
- Card do desafio de hoje: tipo, objetivo, recompensa
- Botão "Iniciar"
- Após completar: estado "✓ Concluído hoje, volte amanhã"

---

## 8. Modelo de Dados

### 8.1 Animal
```dart
class Animal {
  final int level;           // 1 a 11
  final int value;           // 2, 4, 8, ... 2048
  final String name;         // "Capivara Lendária"
  final String scientificName; // "Hydrochoerus hydrochaeris"
  final String imagePath;    // "assets/images/animals/capivara.png"
  final String soundPath;    // "assets/sounds/animals/capivara.mp3"
  final Color tileColor;
  final String? funFact;     // curiosidade (opcional)
}
```

### 8.2 Tile
```dart
class Tile {
  final String id;       // UUID, para animação
  final int level;       // referência ao Animal
  final int row;
  final int col;
  final bool isNew;      // recém-spawnado (animação)
  final bool justMerged; // resultado de merge (animação)
}
```

### 8.3 GameState
```dart
class GameState {
  final List<List<Tile?>> board;   // 4x4
  final int score;
  final int highScore;
  final int highestLevelReached;
  final bool isGameOver;
  final bool hasWon;
  final List<int> unlockedAnimals; // níveis já vistos
  final GameMode mode;             // classic | dailyChallenge
}
```

### 8.4 DailyChallenge
```dart
class DailyChallenge {
  final DateTime date;             // chave (UTC)
  final ChallengeType type;
  final Map<String, dynamic> params; // moveLimit, targetScore, initialBoard, etc
  final String description;        // "Forme uma Onça em até 50 movimentos"
  final bool completed;
}
```

---

## 9. Game Engine — Pseudocódigo

```dart
class GameEngine {
  GameState state;

  void move(Direction dir) {
    final rotated = rotateBoard(state.board, dir);
    bool changed = false;

    for (final row in rotated) {
      final result = compactAndMerge(row);
      if (result.changed) changed = true;
      // atualizar score com result.gainedScore
    }

    if (changed) {
      state.board = rotateBack(rotated, dir);
      spawnNewTile();
      checkGameOver();
      checkWin();
    }
  }

  CompactResult compactAndMerge(List<Tile?> row) {
    final filtered = row.where((t) => t != null).toList();
    final merged = <Tile>[];
    int gained = 0;
    int i = 0;

    while (i < filtered.length) {
      if (i + 1 < filtered.length && filtered[i].level == filtered[i+1].level) {
        final newLevel = filtered[i].level + 1;
        merged.add(Tile(level: newLevel, justMerged: true, ...));
        gained += valueForLevel(newLevel);
        i += 2;
      } else {
        merged.add(filtered[i]);
        i++;
      }
    }

    while (merged.length < 4) merged.add(null);
    return CompactResult(merged, gained, /* changed */ true);
  }

  void spawnNewTile() {
    final empty = findEmptyCells(state.board);
    if (empty.isEmpty) return;
    final pos = empty[random.nextInt(empty.length)];
    final level = random.nextDouble() < 0.9 ? 1 : 2;
    placeTile(pos, level);
  }

  bool isGameOver() {
    if (hasEmptyCell(state.board)) return false;
    return !hasPossibleMerge(state.board);
  }
}
```

---

## 10. Persistência (Hive ou SharedPreferences)

| Chave | Conteúdo |
|---|---|
| `high_score_classic` | int |
| `highest_level_reached` | int (1–11) |
| `unlocked_animals` | List<int> |
| `daily_streak` | int |
| `last_daily_date` | String ISO |
| `daily_history` | Map<dateString, completed:bool, score:int> |
| `settings.sound_volume` | double 0–1 |
| `settings.music_volume` | double 0–1 |
| `settings.haptic_enabled` | bool |
| `settings.locale` | String "pt_BR" \| "en_US" |
| `current_game` (auto-save) | serialized GameState |

---

## 11. Roadmap de Implementação (sugestão de fases)

### Fase 1 — MVP do tabuleiro (1 semana)
- Setup do projeto Flutter
- Estrutura de pastas
- Game engine puro (testável, sem UI), com testes unitários
- Tela de jogo básica com tiles representados por cor + número
- Swipe funcionando nas 4 direções
- Spawn, merge, game over
- Pontuação local

### Fase 2 — Identidade visual (1-2 semanas)
- Substituir números por placeholder de animais (emojis ou shapes)
- Aplicar paleta de cores definida
- Tipografia (Fredoka, Nunito)
- Animações de movimento, spawn e merge
- Tela Home básica

### Fase 3 — Arte final (paralelo, 2-3 semanas)
- Ilustrar/contratar arte dos 11 animais (estilo cartoon fofo)
- Integrar imagens nos tiles
- Background de floresta na Home
- Logo do jogo
- Ícone do app

### Fase 4 — Áudio (1 semana)
- Buscar/gravar sons dos animais (royalty-free ou customizados)
- Música ambiente
- Integração com `audioplayers`
- Mixer simples nas configurações

### Fase 5 — Coleção e Desafio Diário (1-2 semanas)
- Tela de coleção com cards dos animais
- Persistência de animais desbloqueados
- Gerador de desafios diários (com seed por data)
- Tela e fluxo do desafio
- Streak

### Fase 6 — Polimento e Lançamento
- Localização PT-BR / EN
- Acessibilidade (tamanho de fonte, contraste, screen readers)
- Feedback háptico
- Modo escuro (opcional)
- Splash screen
- Build para iOS, Android, Web
- App Store / Play Store / Web hosting

---

## 12. Considerações Especiais

### 12.1 Acessibilidade
- Cores com contraste WCAG AA mínimo
- Não depender só de cor para diferenciar animais (forma + cor + nome)
- Suporte a leitor de tela com `Semantics`
- Modo "alta visibilidade" com bordas extras
- Tamanho de fonte ajustável

### 12.2 Performance
- Minimizar rebuilds usando `const` e Riverpod selectors
- Pré-carregar imagens (`precacheImage`)
- Pool de AudioPlayers para sons rápidos
- Alvo: 60fps em dispositivos médios (Snapdragon 660+, iPhone 8+)

### 12.3 Monetização (futuro, fora do MVP)
- App gratuito
- Anúncios opcionais (banner discreto, intersticial após X partidas)
- Versão Premium (compra única) sem ads + skins de animais (variantes sazonais: capivara de natal, etc)
- Sem mecânicas pay-to-win — é puzzle, deve ser justo

### 12.4 Aspectos legais e éticos
- Verificar nomes científicos com fontes confiáveis (IUCN, ICMBio)
- Curiosidades educativas com fontes citadas
- Considerar parceria com instituições de conservação (WWF Brasil, ICMBio) — bom marketing e propósito
- Atenção à apropriação cultural — evitar elementos indígenas sem consulta apropriada

### 12.5 SEO e App Store
- Nome do app: **"Capivara 2048"** ou **"Amazon Animals 2048"** (versão internacional)
- Keywords: 2048, puzzle, capivara, animais, amazônia, brasil, fofo, casual
- Screenshots da App Store mostrando a Capivara em destaque
- Vídeo de gameplay de 30s

---

## 13. Prompt Sugerido para o Claude Code

> Quero criar um jogo Flutter chamado "Capivara 2048" — um puzzle 4x4 estilo 2048 onde os números são animais amazônicos, e a peça final (2048) é uma capivara fofa. Use o documento `CAPIVARA_2048_DESIGN.md` neste repositório como referência completa. Comece pela Fase 1 do roadmap: setup do projeto, estrutura de pastas conforme especificado, game engine puro com testes unitários, e uma tela de jogo básica com tiles representados por placeholders simples (cor + nível). Use Riverpod para estado e siga as convenções definidas no documento. Antes de codar, me confirme o plano em alto nível.

---

## 14. Anexo — Lista de Referências de Inspiração

- **2048** original (Gabriele Cirulli) — mecânica base
- **Suika Game** — fofura e física aconchegante
- **Animal Crossing** — paleta e tipografia amigável
- **Pokémon Café Mix** — estilo cartoon arredondado
- **Threes!** — predecessor do 2048, polimento
- **Alto's Odyssey** — ambientação atmosférica
- **Folclore amazônico** — pesquisa para futuras expansões (Boto, Curupira, Iara)

---

*Documento vivo — atualize conforme o desenvolvimento evolui.*
