# 🦫 Capivara 2048 — Design Concept (Consolidado v2)

> Documento de especificação para desenvolvimento. Pensado para ser alimentado em ferramentas como Claude Code para implementação iterativa.
>
> **Status atual:** Fase 2.11 concluída ✅ (v1.0.1) — Loja em overlay acessível pelos ícones desabilitados do inventário. Fase 2.10 concluída ✅ (v1.0.0). Fases 2.4 a 2.9 também concluídas.
>
> **Próximo:** **Fase 2.12 — Expansão além do 2048: Peixe-boi (4096) e Jacaré (8192) + Ranking Lendas**
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
**Flutter 3.x** (Dart) — mobile (Android e iOS). Linux e Web foram removidos do escopo do projeto.

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
| Localização | `flutter_localizations` + `intl` | PT-BR no lançamento; EN e outros em expansão futura |
| Backend | `firebase_core` + `cloud_firestore` + `firebase_auth` | Ranking, contas |
| Anúncios | `google_mobile_ads` | Recompensados de 30s |
| Compras | `in_app_purchase` | Loja |
| Compartilhamento | `share_plus` + `app_links` | Códigos de resgate |
| Blur (UI) | `flutter` nativo (`BackdropFilter` + `ImageFilter.blur`) | Efeito vidro fosco |
| Splash Screen | `flutter_native_splash` | Splash screen nativa — Android e iOS (Fase 2.9) ✅ |
| Orientação | `flutter` nativo (`SystemChrome.setPreferredOrientations`) | Bloqueio portrait-only (Fase 2.9) ✅ |

### 2.3 Estrutura de pastas
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── theme/
│   └── utils/
│       ├── fake_ad_service.dart        ✅
│       └── fake_ranking_service.dart   ← novo (Fase 2.12)
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
│   │   ├── shop/           ✅ (Fase 2.8)
│   │   ├── ranking/
│   │   ├── collection/     ✅ (Fase 2.6)
│   │   ├── daily_rewards/  ✅ (Fase 2.4)
│   │   ├── invite_friends/
│   │   ├── settings/       ✅ (Fase 2.6)
│   │   └── tutorial/
│   ├── widgets/
│   │   ├── board_widget.dart                ✅
│   │   ├── tile_widget.dart                 ✅
│   │   ├── score_panel.dart                 ✅
│   │   ├── status_panel.dart                ✅
│   │   ├── game_header.dart                 ✅
│   │   ├── host_banner.dart                 ✅
│   │   ├── host_artwork.dart                ✅
│   │   ├── game_background.dart             ✅
│   │   ├── game_title_image.dart            ✅ (Fase 2.5)
│   │   ├── lives_indicator.dart             ✅ (centralizado na 2.3.12)
│   │   ├── lives_status_banner.dart         ✅
│   │   ├── pause_button_tile.dart           ✅
│   │   ├── outlined_text.dart               ✅
│   │   ├── pause_overlay.dart               ✅
│   │   ├── inventory_bar.dart               ✅
│   │   ├── inventory_item_button.dart       ✅
│   │   ├── confirm_use_dialog.dart          ✅
│   │   ├── bomb_selection_overlay.dart      ✅
│   │   ├── game_over_item_screen.dart       ✅ (Fase 2.9) + animação piscante (Fase 2.10)
│   │   ├── game_over_no_items_overlay.dart  ✅ (Fase 2.10)
│   │   ├── shop_overlay.dart                ← novo (Fase 2.11)
│   │   └── animal_card.dart
│   └── controllers/
└── assets_manifest.dart
assets/
├── images/
│   ├── fundo.png                     ✅
│   ├── splash/splash_logo.png        ✅ (Fase 2.9)
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
- **Game Over:** tabuleiro cheio sem movimentos — inicia o fluxo de salvamento por itens (ver 3.5) ou oferta de aquisição de item (ver 3.6); vida consumida apenas se o jogador confirmar Game Over sem usar/adquirir itens
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
**A vida é consumida APENAS quando o jogador confirma o Game Over sem usar nenhum item de salvamento.**

> **Nota (bug corrigido na v1.0.x):** a implementação anterior consumia a vida imediatamente quando o tabuleiro travava, antes de qualquer decisão do jogador. A spec abaixo sempre foi a correta — o bug era na implementação. A correção garante que a vida só é descontada ao confirmar "Desistir" na `GameOverItemScreen` ou "Encerrar partida" na `GameOverNoItemsOverlay`.

| Ação | Consome vida? |
|---|---|
| Iniciar nova partida | ❌ Não |
| Sair pro menu durante partida | ❌ Não |
| Continuar partida salva | ❌ Não |
| Reiniciar partida em andamento | ❌ Não |
| **Tabuleiro tranca → jogador recusa todos os itens e confirma Game Over** | ✅ **Sim, 1 vida** |
| **Tabuleiro tranca → jogador sem itens → recusa anúncio, compra e encerra** | ✅ **Sim, 1 vida** |
| Usar item de salvamento e continuar a partida | ❌ Não |
| Adquirir item via anúncio ou compra e continuar | ❌ Não |
| Atingir 2048 (vitória) | ❌ Não |

> **Limite pra iniciar:** ≥1 vida disponível.

### 3.5 Fluxo de Game Over com itens de salvamento — jogador TEM itens (Fase 2.9 + 2.10)

Quando o tabuleiro trava e o jogador **possui ao menos 1 item no inventário**, o jogo não encerra imediatamente. Inicia o fluxo de salvamento com a `GameOverItemScreen`:

**Passo 1 — Detecção:** o engine detecta que não há movimentos possíveis.

**Passo 2 — Análise de inventário:** o sistema verifica quais itens do inventário do jogador são capazes de desbloquear a partida:
- **Desfazer (1 ou 3):** sempre é capaz de salvar — volta o estado antes do travamento
- **Bomba (2 ou 3):** é capaz de salvar — remove tiles e libera espaço

**Passo 3 — Apresentação na `GameOverItemScreen` com animação piscante (Fase 2.10):** a tela `GameOverItemScreen` é exibida em tela cheia. O ícone do item em destaque pisca em loop para chamar atenção do jogador. A tela:
- Exibe **um item por vez**, em destaque, com seu ícone PNG grande (≥120×120dp) centralizado na tela
- O ícone executa animação de **pulso piscante** em loop contínuo: opacidade 1.0 → 0.4 → 1.0, duração 800ms por ciclo, easing `easeInOut` — a animação para imediatamente quando o jogador toca em "Usar item"
- Exibe a mensagem clara no padrão: `"Deseja usar o item [Nome do Item] para [descrição do efeito]?"`
- Exibe o contador atual do item: `"Você tem X deste item"`
- Exibe dois botões: **"Usar item"** (destaque, `#FF8C42`) e **"Próximo item"** (secundário, cinza)
- Se houver mais de 1 tipo de item, ao tocar em "Próximo item" exibe o próximo; o próximo também inicia a animação piscante imediatamente
- **Ordem de prioridade:** Desfazer 3 → Desfazer 1 → Bomba 3 → Bomba 2
- O tabuleiro fica visível ao fundo com opacidade reduzida

**Passo 4a — Jogador usa o item:**
- Animação piscante para; item executado; contador decrementado; tela fechada; partida continua — **nenhuma vida consumida**

**Passo 4b — Jogador recusa todos os itens:**
- Ao tocar "Próximo item" no último item: botão muda para **"Desistir"** (vermelho `#EF5350`)
- Ao tocar "Desistir": `AlertDialog` de confirmação → ao confirmar: 1 vida consumida, modal padrão de Game Over

### 3.6 Fluxo de Game Over sem itens — jogador NÃO TEM itens (Fase 2.10)

Quando o tabuleiro trava e o jogador **não possui nenhum item no inventário**, o jogo exibe a `GameOverNoItemsOverlay` — overlay que se abre por cima do tabuleiro, oferecendo três caminhos antes de confirmar o Game Over.

**Detalhes do overlay:**
- Abre por cima do tabuleiro (que fica visível ao fundo com opacidade reduzida, sem interação)
- **Sem `AppBar`** e **sem botão voltar Android** — o jogador deve tomar uma das três decisões
- Exibe o título: `"Você não possui mais itens!"` em `OutlinedText` branco, Fredoka 22
- **Sorteia aleatoriamente** 1 dos 4 itens (Bomba 2, Bomba 3, Desfazer 1, Desfazer 3) para ser o "item da vez" — sorteio feito ao abrir e não muda enquanto o overlay estiver visível
- Exibe o item sorteado em destaque: ícone PNG ≥100×100dp com bounce de entrada (scale 0.8→1.05→1.0, 400ms), nome (Fredoka SemiBold 18) e descrição do efeito (Nunito 14, cinza)

**Três opções exibidas (de cima pra baixo):**

**Opção 1 — Ver anúncio (destaque principal):**
- Botão: `"📺 Ver anúncio e receber [Nome do Item]"` (cor `#FF8C42`, largura total, altura 52dp)
- Ao tocar: exibe anúncio recompensado de 30s (`FakeAdService` em dev; `google_mobile_ads` em produção)
- Após o anúncio: item sorteado entregue no inventário; overlay fecha; partida continua — **nenhuma vida consumida**
- **Limite diário:** usa o mesmo contador de 40 anúncios/dia do `LivesState.adWatchesToday` (§5.4)
- Se limite atingido: botão exibe `"Limite diário atingido"` e fica desabilitado (cinza)

**Opção 2 — Comprar item:**
- Botão: `"🛒 Comprar [Nome do Item]  •  ~R$ X,XX"` (outlined button, largura total, altura 52dp)
- Preço exibido é o preço unitário estimado conforme §7.2
- Ao tocar: `AlertDialog` de confirmação com nome, preço e botões "Cancelar" / "Confirmar compra"
- Cancelar: retorna ao overlay
- Confirmar (mock dev): item entregue; overlay fecha; partida continua — **nenhuma vida consumida**
- Confirmar (produção — Fase 3): abre `in_app_purchase` com o pacote mais barato que contém o item; em sucesso, entrega os itens do pacote completo

**Opção 3 — Encerrar:**
- Botão: `"Encerrar partida"` (TextButton, cinza, menor destaque)
- Ao tocar: `AlertDialog` de confirmação → ao confirmar: 1 vida consumida; overlay fecha; modal padrão de Game Over

**Regra de exibição:**
- `GameOverNoItemsOverlay` só é exibida quando `inventory.isEmpty == true`
- `GameOverItemScreen` só é exibida quando há ao menos 1 item — os dois fluxos são mutuamente exclusivos

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
| 12 | 4096 | **🌊 Peixe-boi Lendário** | Gentil gigante das águas amazônicas, espécie ameaçada | `#006064` | `tile/PeixeBoi.png` | `host/PeixeBoi.png` |
| 13 | 8192 | **🐊 Jacaré Supremo** | Predador ancestral, símbolo de resistência e raridade | `#1B5E20` | `tile/Jacare.png` | `host/Jacare.png` |

> Caminhos relativos a `assets/images/animals/`. Nível 5 = Sagui (substituiu Arara-azul na Fase 2.3.7). Níveis 12 e 13 adicionados na Fase 2.12 — assets já presentes nas pastas.

### 4.1 Visual do tile
- **Fundo:** branco (`#FFFFFF`)
- **Contorno:** cor da tabela (3px, arredondado) — níveis 12 e 13 usam **4px** para reforçar raridade
- **Marca d'água:** PNG do animal centralizado, opacidade ~28%, ocupa ~80% do tile
- **Número:** sobreposto, Fredoka Bold, cor `#3E2723`
- **Sombra:** suave abaixo — níveis 12 e 13 têm sombra levemente mais intensa
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
- **Lado direito do mesmo nível** (acima das colunas 3 e 4): recebe o **`PauseButtonTile`** abaixo do `StatusPanel`/cronômetro

### 4.3 Fundo do jogo (Fase 2.3.9 — PNG; Fase 2.3.11 — unificado com Home)
- Imagem PNG (`assets/images/fundo.png`) renderizada em tela cheia via `BoxFit.cover`
- Sem variação por animal — fundo é o mesmo em qualquer fase do jogo
- O mesmo `fundo.png` é aplicado também na `HomeScreen`
- Cor de fallback: `#D4F1DE` (verde-menta) é exibido apenas se o PNG falhar ao carregar

### 4.4 Texto sobre cor — legibilidade
- Textos brancos importantes têm contorno preto sutil (1–1.5px) com anti-aliasing suave (Fase 2.3.6 item A)
- Aplicado em: nome do anfitrião, cronômetro, pontuação, recorde, todos os textos do `PauseOverlay`
- **Regra geral (a partir da Fase 2.7):** qualquer texto exibido diretamente sobre o `fundo.png` (sem container branco por trás) deve usar `OutlinedText` — texto branco com contorno preto, 8 sombras radiais blur 0.8–1.0. Textos interativos ficam dentro de cards com `Colors.white.withOpacity(0.88)` e `borderRadius: 12`.

### 4.5 Indicador de vidas (Fase 2.3.9; Fase 2.3.12 — centralizado)
- **Posição:** topo da tela, **horizontalmente centralizado**
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
- **Consumo:** 1 vida só quando o jogador confirma Game Over sem usar/adquirir itens de salvamento (ver 3.4, 3.5 e 3.6)
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

> **Atenção (a partir da Fase 2.3.12):** o timer regressivo MM:SS depende da regeneração estar funcionando. Corrigido na Fase 2.3.12 item C.

### 5.4 Vidas zeradas
1. Diálogo: "Você ficou sem vidas! Quer assistir um anúncio de 30s pra ganhar +1 vida?"
2. Aceita: anúncio recompensado → +1 vida
3. **Limite diário:** até 40 anúncios recompensados de vida por dia — este contador é **compartilhado** com o fluxo da `GameOverNoItemsOverlay` (§3.6)
4. Após o limite: opção bloqueada até a meia-noite (timezone do dispositivo)

### 5.5 Modelo de dados
```dart
class LivesState {
  final int current;              // pode ser > 15 se houver compras
  final int regenCap;             // 5 (constante)
  final int earnedCap;            // 15 (cap de vidas ganhas)
  final DateTime? nextRegenAt;    // null se current >= regenCap
  final int adWatchesToday;       // 0..40 (compartilhado entre vidas e GameOverNoItems)
  final DateTime adCounterDate;
}
```

### 5.6 Lógica de adicionar vidas
- **Regen automática:** soma 1 enquanto `current < regenCap`. `Timer.periodic` + `AppLifecycleListener`.
- **Recompensa:** soma N, clamped em `min(current + N, earnedCap)`
- **Compra:** soma N **sem cap**

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
- **Tamanho dos ícones (Fase 2.9):** ícones aumentados para 72×72dp (era 56×56dp); espaçamento vertical entre tabuleiro e `InventoryBar` reduzido de 12dp para 4dp
- **Tap em ícone desabilitado (Fase 2.11):** ao tocar em um ícone com contador 0 (acinzentado), em vez de ignorar o toque, abre a `ShopOverlay` diretamente sobre o jogo — permitindo ao jogador comprar o item sem sair da partida. O cronômetro é pausado enquanto o overlay estiver aberto.

#### Ícones do inventário
PNGs finais (1024×1024, fundo transparente) em `assets/icons/inventory/`:
- `bomb_2.png` — Bomba 2 casas, tema **Sucuri** (verde, com pavio aceso)
- `bomb_3.png` — Bomba 3 casas, tema **Mico-leão-dourado**
- `undo_1.png` — Desfazer 1, tema **Capivara** (segurando relógio com seta de retorno)
- `undo_3.png` — Desfazer 3, tema **Onça-pintada**

**Visual do botão (Fase 2.9):** o PNG ocupa o slot 72×72dp inteiro — o PNG **é** o botão. Sem fundo verde nem `Material`. Fallback automático para `Material(#4CAF50)` + `Icon` branco se o asset falhar ao carregar.

#### Confirmação universal antes do uso (Fase 2.3.8)
**TODOS os itens do inventário exigem confirmação antes de serem usados** — exceto quando acionados pela `GameOverItemScreen` ou `GameOverNoItemsOverlay`, onde a confirmação já está embutida no fluxo.

**Fluxo unificado (uso durante a partida, fora do Game Over):**
1. Tap no ícone do item → abre `ConfirmUseDialog`
2. Cancelar → fecha dialog, nada muda
3. Usar:
   - **Desfazer:** executa `gameNotifier.undo(steps)`, animação reversa (300ms), decrementa contador
   - **Bomba:** entra em modo seleção (`BombSelectionOverlay`) → confirma "Explodir" → animação (500ms), tiles removidos, decrementa contador

#### Regras de bombas
- **Bomba 2:** jogador seleciona 2 tiles à sua escolha para remover do tabuleiro — exibido no `ConfirmUseDialog` como "Selecione 2 tiles para remover do tabuleiro"
- **Bomba 3:** jogador seleciona 3 tiles à sua escolha para remover do tabuleiro — exibido no `ConfirmUseDialog` como "Selecione 3 tiles para remover do tabuleiro"
- Não pode selecionar células vazias: feedback "Selecione um tile com peça"
- Cancelar no `BombSelectionOverlay` não consome o item

### 6.3 Game over — resumo dos dois fluxos
- **Com itens no inventário:** `GameOverItemScreen` com animação piscante (§3.5, Fases 2.9 + 2.10)
- **Sem itens no inventário:** `GameOverNoItemsOverlay` com oferta de anúncio, compra ou encerramento (§3.6, Fase 2.10)

### 6.4 Modelo de dados
```dart
class Inventory {
  final int bomb2;
  final int bomb3;
  final int undo1;
  final int undo3;
  // sem cap — qualquer valor não-negativo é válido
}

bool get isEmpty => bomb2 == 0 && bomb3 == 0 && undo1 == 0 && undo3 == 0;
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

### 7.2 Preço unitário estimado por item (usado na `GameOverNoItemsOverlay`)
| Item sorteado | Pacote de referência | Preço unitário estimado |
|---|---|---|
| Bomba 2 | Combo Mata Atlântica (2 bombas por R$ 4,99) | ~R$ 1,00 |
| Bomba 3 | 4× Bomba 3 por R$ 3,99 | ~R$ 1,00 |
| Desfazer 1 | Combo Mata Atlântica (2 desfazer por R$ 4,99) | ~R$ 1,00 |
| Desfazer 3 | 4× Desfazer 3 por R$ 1,99 | ~R$ 0,50 |

> **Nota:** os preços unitários exibidos no overlay são estimativas para contexto. A compra real na Fase 3 sempre passa pelo pacote completo via `in_app_purchase`, não por item unitário. Em dev/mock, a compra é simulada e o item é entregue diretamente.

### 7.3 Compartilhamento com amigos
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
| **Lendas 4096** | Vezes que o jogador atingiu 4096 | **Vitalício — nunca reseta** |
| **Lendas 8192** | Vezes que o jogador atingiu 8192 | **Vitalício — nunca reseta** |

> **Regra de desempate no Ranking Lendas:** em caso de empate no contador de vezes, quem atingiu o marco pela primeira vez mais cedo (`firstReachedAt`) fica à frente. Empate exato em ambos os critérios = mesma colocação.

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
  - country: string?   // reservado para expansão futura — não exibido no lançamento

users/{userId}/personalRecords
  - bestTimeMs: int
  - bestNumber: int           // maior número já atingido (2048, 4096 ou 8192)
  - totalGames: int
  - totalWins: int            // vezes que atingiu 2048 ou mais
  - timesReached4096: int     // Fase 2.12
  - timesReached8192: int     // Fase 2.12
  - firstReached4096At: timestamp?   // Fase 2.12 — para desempate
  - firstReached8192At: timestamp?   // Fase 2.12 — para desempate

legendsRankings/4096/entries/{userId}   // Fase 2.12
  - userId: string
  - displayName: string
  - timesReached: int
  - firstReachedAt: timestamp
  - country: string?   // reservado para expansão futura

legendsRankings/8192/entries/{userId}   // Fase 2.12
  - userId: string
  - displayName: string
  - timesReached: int
  - firstReachedAt: timestamp
  - country: string?   // reservado para expansão futura
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
| Botão "Desistir" / "Encerrar" (Game Over) | Vermelho | `#EF5350` |
| Botão "Ver anúncio" (`GameOverNoItemsOverlay`) | Laranja-tucano | `#FF8C42` |
| Contorno tile Peixe-boi (4096) | Azul-petróleo | `#006064` |
| Contorno tile Jacaré (8192) | Verde militar | `#1B5E20` |
| Background card Peixe-boi (Coleção) | Azul bem claro | `#E0F7FA` |
| Background card Jacaré (Coleção) | Verde bem claro | `#E8F5E9` |

### 10.3 Tipografia
- **Títulos**: `Fredoka` (arredondada, divertida)
- **Texto/UI**: `Nunito` (legível, amigável)
- **Pontuação e número do tile**: `Fredoka Bold`
- **Número dentro do coração de vidas**: `Fredoka Bold`, branco com `OutlinedText`
- **Texto da faixa de vidas**: `Fredoka SemiBold`, ~13sp, com `OutlinedText`
- **Nome do anfitrião 2x2**: `Fredoka SemiBold`, 16sp, com `OutlinedText` e `maxLines: 2`
- **Texto branco sobre fundo dinâmico**: contorno preto 1–1.5px com anti-aliasing (ver 4.4)
- **Mensagem da `GameOverItemScreen`**: `Fredoka SemiBold`, 20sp, dentro de card branco semi-opaco
- **Título da `GameOverNoItemsOverlay`**: `Fredoka`, 22sp, `OutlinedText` branco
- **Nome/descrição do item sorteado na `GameOverNoItemsOverlay`**: Fredoka SemiBold 18 / Nunito 14

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
| Merge do Peixe-boi (4096) | Onda azul-petróleo + partículas de água + zoom out, 1500ms ← novo (Fase 2.12) |
| Merge do Jacaré (8192) | Explosão verde-escura + partículas de folha + tremor de tela + haptic longa, 2000ms ← novo (Fase 2.12) |
| Troca de anfitrião | Fade + scale, 400ms |
| Game Over | Tabuleiro escurece levemente, overlay slide-up, 300ms |
| Botão pressionado | Scale 1 → 0.95 → 1, 100ms |
| Pause overlay (entrada) | Fade do blur 0 → max + scale do conteúdo, 250ms |
| Pause overlay (saída) | Reverso, 200ms |
| Bomba explodindo | Onda + partículas, 500ms |
| Desfazer | Reversão suave, 300ms |
| Bomba — modo seleção (entrada) | Pulse no tabuleiro + dim no resto, 200ms |
| Bomba — célula selecionada | Pulsa loop infinito, opacidade 0.7 ↔ 1.0, 600ms |
| `LivesIndicator` — vida ganha | Coração pulsa (scale 1 → 1.15 → 1), 300ms |
| `LivesIndicator` — vida perdida | Coração tremula (rotate ±5°), 200ms |
| Faixa de vidas — transição entre estados | Fade 300ms + scale 1→1.1→1 (200ms) em transições positivas |
| `ConfirmUseDialog` (entrada) | Fade + slide-up, 200ms |
| Botão pause tile-sized — pressionado | Scale 1 → 0.95 → 1, 100ms |
| `GameOverItemScreen` (entrada) | Slide-up + fade, 300ms |
| `GameOverItemScreen` — **ícone do item (loop)** | **Pulso piscante: opacidade 1.0 → 0.4 → 1.0, 800ms/ciclo, easeInOut** ← novo (Fase 2.10) |
| `GameOverItemScreen` — trocar item | Fade-out item atual + fade-in próximo, 200ms; novo item inicia pulso imediatamente |
| `GameOverItemScreen` — usar item | Pulso para imediatamente ao tocar |
| `GameOverNoItemsOverlay` (entrada) | Slide-up + fade, 300ms ← novo (Fase 2.10) |
| `GameOverNoItemsOverlay` — ícone do item sorteado | Bounce de entrada: scale 0.8 → 1.05 → 1.0, 400ms |
| Splash screen (entrada) | Logo fade-in + leve scale, 600ms; saída fade-out, 400ms |

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
- `GameOverItemScreen` — abrir: som de alerta suave / suspense
- `GameOverItemScreen` — ícone piscando: pulso sonoro suave em loop (baixo volume), sincronizado com a animação visual
- `GameOverItemScreen` — usar item: whoosh de salvamento
- `GameOverItemScreen` — desistir: nota descendente
- `GameOverNoItemsOverlay` — abrir: som de alerta mais urgente que o anterior
- `GameOverNoItemsOverlay` — ver anúncio confirmado: tilim de confirmação
- `GameOverNoItemsOverlay` — compra confirmada: cha-ching
- `GameOverNoItemsOverlay` — encerrar: nota descendente melancólica
- Splash screen: jingle curto de entrada (1–2s)

### 11.3 Música ambiente
- Loop suave de floresta (pássaros, água, vento)
- Instrumental: flautas, marimba, percussão suave
- Volume separado de SFX (slider individual)
- Mute persistente nas configurações

### 11.4 Considerações técnicas
- Pré-carregar todos os sons no início
- Pool de AudioPlayers
- Formatos: M4A/AAC (iOS), OGG (Android), MP3 universal como fallback
- Tamanho alvo: < 50KB por som de animal

---

## 12. Telas e Fluxos

### 12.1 Mapa de telas
```
[Splash Screen]       ✅ (Fase 2.9)
   ↓
[Login/Cadastro]  (apenas primeira vez ou se quiser ranking global)
   ↓
[Home/Menu Principal]
   ├── [Jogo Clássico]
   │      ├── (vidas centralizadas no topo — coração + faixa estilizada)
   │      ├── (StatusPanel: cronômetro + pontuação + recorde — sem pause)
   │      ├── (linha intermediária: Anfitrião 2x2 à esquerda, PauseButtonTile à direita)
   │      ├── (tabuleiro 4x4)
   │      ├── (inventário no rodapé — ícones 72×72dp)
   │      │       — tap em ícone desabilitado → [ShopOverlay] ← novo (Fase 2.11)
   │      ├── [ShopOverlay]              ← novo (Fase 2.11)
   │      │       ├── Mesmos 6 pacotes da loja comum, rolável
   │      │       ├── Cronômetro do jogo pausado enquanto aberto
   │      │       └── Botão "X Fechar" retorna ao jogo
   │      ├── [GameOverItemScreen]        ✅ (Fase 2.9) + animação piscante ✅ (Fase 2.10)
   │      │       ├── Ícone do item piscando em loop (opacidade 1.0→0.4→1.0, 800ms)
   │      │       ├── Mensagem explicativa do efeito
   │      │       ├── "Usar item" → animação para → continua partida
   │      │       ├── "Próximo item" → troca item, nova animação inicia
   │      │       └── "Desistir" → confirmação → Game Over real (1 vida)
   │      └── [GameOverNoItemsOverlay]    ✅ (Fase 2.10)
   │              ├── Item sorteado em destaque (1 de 4, aleatório)
   │              ├── "Ver anúncio e receber item" → anúncio 30s → item entregue → continua
   │              ├── "Comprar item" → checkout → item entregue → continua
   │              └── "Encerrar partida" → confirmação → Game Over (1 vida)
   ├── [Loja]
   ├── [Ranking]
   ├── [Recompensas Diárias]
   ├── [Convidar Amigos]
   ├── [Resgatar Código]
   ├── [Coleção de Animais]
   ├── [Configurações]
   └── [Como Jogar]
```

### 12.2 Tela: Splash Screen (Fase 2.9 — concluída ✅)
- Exibida na abertura do app, antes de qualquer navegação
- **Fundo:** cor sólida `#D4F1DE` ou variante do `fundo.png`
- **Conteúdo:** `splash_logo.png` centralizado
- **Duração:** mínimo 1,5s; máximo o tempo de inicialização
- **Implementação:** `flutter_native_splash` para splash nativa + `SplashScreen` widget Flutter
- **`SplashScreen` Flutter:** executa Hive, `precacheImage`, verificação de login; navega para `HomeScreen` com `Navigator.pushReplacement`
- **Sem interação:** nenhum tap aceito durante a splash

### 12.3 Tela: Home
- **Fundo:** `assets/images/fundo.png` — `BoxFit.cover`, fallback `#D4F1DE`
- `GameTitleImage` alternando entre variante laranja e marrom por sessão (Fase 2.5)
- **Indicador de vidas** centralizado no topo
- Botão grande **"Jogar"** (Novo jogo / Continuar partida salva)
- Cards: Loja, Ranking, Recompensa Diária (com badge vermelho quando disponível), Convidar
- Ícones menores: Coleção, Configurações, Como Jogar

### 12.4 Tela: Jogo (layout Fase 2.3.12; InventoryBar Fase 2.9)
**Layout (de cima pra baixo):**

1. **Topo:** `LivesIndicator` — horizontalmente centralizado
2. **Abaixo:** `StatusPanel` (cronômetro + pontuação + recorde)
3. **Linha intermediária:**
   - Esquerda (colunas 1-2), flush-left: `HostBanner` 2x2
   - Direita (colunas 3-4): `PauseButtonTile` (1 tile, alinhado à direita)
4. **Centro:** tabuleiro 4x4
5. **Rodapé:** `InventoryBar` — 4dp acima (era 12dp), ícones 72×72dp (era 56×56dp)

#### 12.4.1 Pause overlay — vidro fosco
- Cobre 100% do tabuleiro + 80–90% da tela útil
- `BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12))` + tint semi-transparente
- Layout: logo + botões "Continuar / Reiniciar / Menu"
- TODOS os textos brancos do overlay usam `OutlinedText`

### 12.5 Tela: GameOverItemScreen (Fase 2.9 + animação piscante Fase 2.10)
Tela dedicada ao salvamento quando o tabuleiro trava e o jogador possui itens.

**Layout:**
```
Stack
├── GameBackground() — fundo.png em tela cheia
├── Tabuleiro ao fundo (opacidade 0.35, sem interação)
└── SafeArea
    └── Column (centralizado verticalmente)
        ├── OutlinedText("Oh não! O tabuleiro travou!", Fredoka 22, branco)
        ├── SizedBox(16)
        ├── Container (card branco semi-opaco, borderRadius 20, padding 24)
        │   ├── [AnimatedOpacity loop 800ms easeInOut — NOVO Fase 2.10]
        │   │   └── Image.asset(itemPngPath, width: 120, height: 120)
        │   ├── SizedBox(12)
        │   ├── Text(mensagemItem, Fredoka SemiBold 20, #3E2723)
        │   └── Text("Você tem $count deste item", Nunito 14, cinza)
        ├── SizedBox(24)
        ├── ElevatedButton("Usar item", #FF8C42, largura total)
        ├── SizedBox(8)
        └── TextButton("Próximo item →" ou "Desistir" em #EF5350)
```

**Sem `AppBar`** — a única saída é usar um item ou confirmar desistência.

### 12.6 Overlay: GameOverNoItemsOverlay (Fase 2.10)
Overlay exibido sobre o tabuleiro quando o inventário está vazio no game over.

**Layout:**
```
Stack (sobre GameScreen, WillPopScope retorna false)
├── Tabuleiro ao fundo (opacidade 0.35, AbsorbPointer)
└── SafeArea
    └── Column (centralizado, padding horizontal 24dp)
        ├── OutlinedText("Você não possui mais itens!", Fredoka 22, branco)
        ├── OutlinedText("Mas você pode conseguir um agora:", Nunito 16, branco)
        ├── SizedBox(20)
        ├── Container (card branco semi-opaco, borderRadius 20, padding 24)
        │   ├── [AnimatedScale bounce entrada 0.8→1.05→1.0, 400ms]
        │   │   └── Image.asset(itemSorteadoPngPath, width: 100, height: 100)
        │   ├── Text(nomeItem, Fredoka SemiBold 18, #3E2723)
        │   └── Text(descricaoEfeito, Nunito 14, cinza)
        ├── SizedBox(24)
        ├── ElevatedButton("📺 Ver anúncio e receber [NomeItem]",
        │     cor: #FF8C42, largura total, altura 52dp)
        │     — desabilitado com "Limite diário atingido" se adWatchesToday >= 40
        ├── SizedBox(8)
        ├── OutlinedButton("🛒 Comprar [NomeItem]  •  ~R$ X,XX",
        │     largura total, altura 52dp)
        ├── SizedBox(16)
        └── TextButton("Encerrar partida", cinza)
```

**Regras de comportamento:**
- Item sorteado determinado ao abrir, não muda enquanto o overlay estiver visível
- Cancelar em qualquer `AlertDialog` retorna ao overlay sem alterar estado
- Botão voltar Android bloqueado (`WillPopScope` retorna false)
- Tabuleiro ao fundo não é interativo (`AbsorbPointer`)

### 12.7 Tela: Loja
- Lista dos 6 pacotes em cards grandes
- Cada card: imagem, conteúdo, "De R$X" (riscado) "Por R$Y" (destaque), badge de desconto
- Após compra: tela de "Código para presentear amigo" com botão de compartilhar

### 12.8 Tela: Ranking
- Tabs: **Global Semanal** | **Pessoal**
- Pódio (1º, 2º, 3º) destacado no topo
- Lista paginada
- Tempo até reset (se Global): contador regressivo até sábado 18h

### 12.9 Tela: Recompensas Diárias (Fase 2.4 — concluída)
- Grid 7 dias (1–7) com recompensa de cada dia
- 4 estados: available / alreadyClaimed / streakBroken / cycleCompleted
- Countdown até meia-noite
- Botão "Coletar" no dia atual
- Após coletar: overlay "dobrar via anúncio" (`FakeAdService` em dev)
- `DailyRewardEntryTile` na `HomeScreen` com badge vermelho + toast na primeira sessão do dia

### 12.10 Tela: Convidar Amigos
- Botão "Gerar link de convite" → compartilha via `share_plus`
- Lista de amigos convidados (status: pendente / completo / recompensa entregue)
- Total de combos ganhos por convites

### 12.11 Tela: Resgatar Código
- Campo de texto para código
- Botão "Resgatar"
- Após resgate: oferta de dobrar via anúncio

### 12.12 Tela: Configurações (atualizada na Fase 2.12)
Card de **Gameplay** (branco semi-opaco, borderRadius 12):
- `SwitchListTile` — **Vibração (Haptic)**: ativa/desativa feedback tátil
- `SwitchListTile` — **Reduzir Efeitos Visuais**: desativa animações complexas para melhor desempenho — *movido do `PauseOverlay` na Fase 2.12*

Card de **Idioma** (Fase 2.12 — removido):
- O dropdown de idioma foi removido. O app é exclusivamente PT-BR no lançamento. O card de idioma não é exibido. Quando a expansão de idiomas for implementada (Fase 6), o card é readicionado.

Card de **Áudio** (desabilitado até Fase 5):
- Sliders de volume SFX e música — visíveis mas `enabled: false` com label "Disponível em breve"

### 12.13 Tela: Debug — Galeria de Animais
Tela acessível apenas em build de debug (via `kDebugMode`). Mostra os 13 animais em 3 modos: tile, host 1x1 e host 2x2 — incluindo Peixe-boi e Jacaré após a Fase 2.12.

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
  final int highestLevelReached;     // inicializa em 1 (Tanajura); máximo 13 (Jacaré)
  final bool isGameOver;
  final bool hasWon;                 // true ao atingir qualquer marco (2048, 4096 ou 8192)
  final int? wonAtLevel;             // 11, 12 ou 13 — nível atingido que gerou a vitória
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
| nextRegenAt | DateTime? | null se current ≥ regenCap |
| adWatchesToday | int | 0..40 — compartilhado entre vidas e `GameOverNoItemsOverlay` |
| adCounterDate | DateTime | data do contador (reset à meia-noite local) |
| userId | String? | null = local |
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

bool get isEmpty => bomb2 == 0 && bomb3 == 0 && undo1 == 0 && undo3 == 0;
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
  final int bestNumber;           // maior número já atingido (2048, 4096 ou 8192)
  final int totalGames;
  final int totalWins;            // vezes que atingiu 2048 ou mais
  final int timesReached4096;     // Fase 2.12
  final int timesReached8192;     // Fase 2.12
  final DateTime? firstReached4096At;   // Fase 2.12 — para desempate no Ranking Lendas
  final DateTime? firstReached8192At;   // Fase 2.12 — para desempate no Ranking Lendas
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
| `personal_ranking` | PersonalRankingState — top 20 entradas por tempo e por número (Fase 2.12) |
| `daily_streak` | int + lastClaimDate |
| `unlocked_animals` | List<int> (níveis vistos) |
| `settings.sound_volume` | double 0–1 |
| `settings.music_volume` | double 0–1 |
| `settings.haptic_enabled` | bool |
| `settings.reduce_motion` | bool — "Reduzir Efeitos Visuais" (movido do PauseOverlay para Settings na Fase 2.12) |
| `settings.locale` | String "pt_BR" — fixo no lançamento; UI de seleção removida na Fase 2.12; EN em expansão futura |
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
- Setup do projeto Flutter, game engine puro, tela de jogo básica, swipe 4 direções, spawn, merge, game over, pontuação local

### ✅ Fase 2.1 — Visual base
- Paleta de cores, Fredoka + Nunito, `tile_widget.dart` redesenhado, animações de movimento/spawn/merge, splash screen, tema do app

### ✅ Fase 2.2 — Cronômetro + Anfitrião (versão inicial)
- Cronômetro MM:SS, `HostBanner` com nome do animal, atualização de anfitrião, sistema de pausa completo

### ✅ Fase 2.3 — HomeScreen + Vidas + Anfitrião refatorado + Fundo dinâmico
- HomeScreen, sistema de vidas com Hive, LivesIndicator, HostArtwork, StatusPanel, Pause flutuante

### ✅ Fase 2.3.5 — Refinamento e Bugfixes (5 correções)
- A — Vida só consome no Game Over; B — Transição de fundo sem flicker; C — Pause não sobrepõe StatusPanel; D — `OutlinedText`; E — `backgroundBaseColor` por animal

### ✅ Fase 2.3.6 — Polimento UX + Inventário (v0.3.6)
- Inventário completo: Model + Hive + Notifier, InventoryBar, todos os itens, Game Over modal

### ✅ Fase 2.3.7 — Integração de Assets dos Animais + Refinamentos (v0.4.0)
- SVGs dos 11 animais, Sagui no nível 5, `OutlinedText` no PauseOverlay, ícones SVG do inventário, `AnimalsGalleryScreen`

### ✅ Fase 2.3.8 — Otimização de Assets + Refinamentos de UI (v0.5.0)
- Migração SVG→PNG, `ConfirmUseDialog`, anfitrião redesenhado, fundo fixo, LivesIndicator coração único, `LivesState` com caps, inventário sem cap, 125 testes

### ✅ Fase 2.3.9 — Refinamentos visuais (v0.6.0)
- `LivesStatusBanner` 4 estados, `PauseButtonTile` tile-sized, fundo via PNG, 143 testes

### ✅ Fase 2.3.10 — Reorganização do cabeçalho + Anfitrião 2×2 (v0.7.0)
- `GameHeader` extraído, `HostBanner` 152dp, `HostArtwork` BoxFit.cover, `StatusPanel` fontes, `PauseButtonTile` separado, galeria debug, 152 testes

### ✅ Fase 2.3.11 — Anfitrião inicial Tanajura + Fundo unificado
- `highestLevelReached` inicia em 1, `_Placeholder` removido, fundo unificado na HomeScreen

### ✅ Fase 2.3.12 — Bugfixes de layout, regen e ícones do inventário (v0.8.4)
- `LivesIndicator` centralizado, `HostBanner` flush-left, timer regen implementado, PNGs finais do inventário 56×56dp

---

> **Nota histórica:** a antiga Fase 2.4 — Áudio foi reposicionada para a Fase 5. As fases seguintes foram renumeradas.

### ✅ Fase 2.4 — Recompensas diárias (v0.9.0)
- `DailyRewardsState`, engine puro, `DailyRewardsNotifier`, `DailyRewardsScreen`, badge + toast na Home. 193 testes.

### ✅ Fase 2.5 — Identidade do Jogo: rebranding "Olha o Bichim!" + título + ícone
- Strings de exibição, `GameTitleImage`, `flutter_launcher_icons`, nome do launcher

### ✅ Fase 2.6 — Tela Home + Coleção + Configurações (v0.9.2)
- Home redesenhada, Coleção com 11 animais, Configurações com toggles e sliders desabilitados, stubs de navegação

### ✅ Fase 2.7 — Bugfixes visuais de interface (v0.9.3)
- A — Badge tamanho inconsistente; B — Textos ilegíveis sobre fundo; C — Bottom Overflow; D — Configurações ilegíveis

### ✅ Fase 2.8 — Loja mock (v0.9.4)
- `ShopScreen` com 6 pacotes, compra simulada, `_GiftCodeSheet`, `shop_data.dart`, `generatedShareCodesProvider`

### ✅ Fase 2.9 — Splash Screen, Game Over redesenhado, Inventário maior e Orientação bloqueada (v0.9.9)
- **A** — Splash: `flutter_native_splash` + widget `SplashScreen` com `precacheImage`
- **B** — `GameOverItemScreen`: tela dedicada com ordem de prioridade de itens
- **C** — Inventário: ícones 56→72dp, espaçamento 12→4dp
- **D** — Portrait-only: `SystemChrome` + `AndroidManifest` + `Info.plist`

---

### ✅ Fase 2.10 — Animação piscante no Game Over + Oferta de item via anúncio/compra sem itens (v1.0.0)
- **A** — Animação piscante (opacidade 1.0→0.4→1.0, 800ms/ciclo) no ícone do item em destaque na `GameOverItemScreen`; para ao usar item, reinicia ao trocar de item; `dispose()` sem vazamento
- **B** — `GameOverNoItemsOverlay`: overlay sobre o tabuleiro com item sorteado (1 de 4, aleatório), 3 opções (anúncio / compra mock / encerrar), bloqueio do botão voltar Android, integração com `adWatchesToday`

---

### ✅ Fase 2.11 — Loja em overlay acessível pelos ícones desabilitados do inventário (v1.0.1)
- **A** — Tap em ícone desabilitado (count == 0) abre `ShopOverlay` em vez de ser ignorado
- **B** — `ShopOverlay`: overlay rolável com os 6 pacotes da loja, botão X para fechar, botão voltar Android permitido, tabuleiro ao fundo não interativo
- **C** — Cronômetro pausado enquanto `ShopOverlay` aberta; retoma ao fechar sem conflito com `PauseOverlay`

---

### 🔜 Fase 2.12 — Expansão além do 2048: Peixe-boi (4096) e Jacaré (8192) + Ranking Lendas

**Objetivo:** expandir o jogo para além do tile 2048, adicionando dois novos animais lendários (Peixe-boi 4096 e Jacaré 8192), o diálogo de escolha ao atingir cada marco, e um novo sistema de ranking vitalício baseado em vezes que o jogador atingiu esses marcos raros.

**Estimativa:** 2–3 dias.

---

#### A — Novos tiles e animais

**Dois novos níveis adicionados à tabela de animais:**

| Nível | Valor | Animal | Justificativa | Cor (contorno) | PNG tile | PNG host |
|---|---|---|---|---|---|---|
| 12 | 4096 | **🌊 Peixe-boi Lendário** | Gentil gigante das águas amazônicas, espécie ameaçada | `#006064` (azul-petróleo) | `tile/PeixeBoi.png` | `host/PeixeBoi.png` |
| 13 | 8192 | **🐊 Jacaré Supremo** | Predador ancestral, símbolo de resistência e raridade | `#1B5E20` (verde militar) | `tile/Jacare.png` | `host/Jacare.png` |

> Os arquivos `PeixeBoi.png` e `Jacare.png` já existem nas pastas `assets/images/animals/tile/` e `assets/images/animals/host/` respectivamente.

**Visual dos tiles lendários:**
- Seguem o mesmo padrão visual dos demais tiles (fundo branco, marca d'água, número em Fredoka Bold `#3E2723`)
- Contorno mais espesso: **4px** (em vez de 3px dos outros) para distinguir visualmente a raridade
- Sombra levemente mais intensa para dar peso visual

**Atualização em `animals_data.dart`:** adicionar os dois novos `Animal` à lista, com `level: 12`, `level: 13`, cores e caminhos de PNG corretos.

---

#### B — Fluxo ao atingir 2048, 4096 e 8192

**Regra geral:** ao formar um tile de valor 2048, 4096 ou 8192, o jogo não encerra automaticamente. Em vez disso, exibe um diálogo de escolha. A partida só encerra se o jogador escolher "Encerrar".

**Ao atingir 2048 (Capivara Lendária — nível 11):**

1. Animação especial do merge da Capivara (flash dourado, partículas de folhas, zoom out, 1500ms) — igual ao comportamento atual
2. Cronômetro para
3. Exibe `VictoryChoiceDialog`:
   ```
   🎉 Você chegou à Capivara Lendária!
   "A fofura chegou ao seu limite... ou chegou?"

   [Continuar até o Peixe-boi (4096)]   [Encerrar e salvar resultado]
   ```
4. **Encerrar:** registra o resultado (tempo, pontuação), exibe modal de resultado final, consome lógica normal de fim de partida
5. **Continuar:** o cronômetro **não retoma** — passa a contar a partir de zero para o trecho 2048→4096; ou mantém o cronômetro parado e registra apenas a pontuação como critério. *(Decisão de implementação: o cronômetro do ranking é medido apenas até o 2048 — após isso, a partida continua mas o tempo do ranking já foi registrado)*

**Ao atingir 4096 (Peixe-boi Lendário — nível 12):**

1. Animação especial do merge do Peixe-boi: **onda azul** + partículas de água + zoom out, 1500ms
2. Exibe `VictoryChoiceDialog`:
   ```
   🌊 Você chegou ao Peixe-boi Lendário!
   "As águas da Amazônia nunca foram tão fundas..."

   [Continuar até o Jacaré (8192)]   [Encerrar e salvar resultado]
   ```
3. Registra no **Ranking Lendas — 4096**: incrementa `timesReached4096` do jogador em +1
4. **Encerrar:** modal de resultado final
5. **Continuar:** partida segue

**Ao atingir 8192 (Jacaré Supremo — nível 13):**

1. Animação especial do merge do Jacaré: **explosão verde escura** + partículas de folha + tremor de tela (vibração haptic longa), 2000ms
2. Registra no **Ranking Lendas — 8192**: incrementa `timesReached8192` do jogador em +1
3. Exibe `VictoryChoiceDialog` **sem opção de continuar** — 8192 é o teto definitivo:
   ```
   🐊 Você chegou ao Jacaré Supremo!
   "O predador ancestral foi despertado. Não há mais além."

   [Encerrar — você é uma lenda]
   ```
4. Modal de resultado final exibido automaticamente após o jogador tocar o botão

**`VictoryChoiceDialog` — especificação visual:**
- Overlay sobre o jogo (não nova rota)
- Fundo: card branco semi-opaco (`Colors.white.withOpacity(0.95)`), borderRadius 24, padding 28
- Ícone do animal atingido: PNG 100×100dp com animação de bounce de entrada
- Título: Fredoka Bold 24, `#3E2723`
- Subtítulo: Nunito italic 15, `Colors.grey[600]`
- Botão primário "Continuar": `ElevatedButton`, cor do contorno do animal (azul-petróleo para Peixe-boi, verde-militar para Jacaré), largura total
- Botão secundário "Encerrar": `OutlinedButton`, cinza, largura total
- Botão voltar Android: **bloqueado** enquanto o diálogo estiver aberto (`WillPopScope` retorna false)

---

#### C — Anfitrião ao continuar além do 2048

- Ao continuar após o 2048: o anfitrião passa a ser a **Capivara** (nível 11) e permanece assim até o jogador formar o tile de Peixe-boi
- Ao formar o Peixe-boi: o anfitrião muda para o **Peixe-boi** (nível 12)
- Ao continuar após o 4096: o anfitrião permanece o Peixe-boi até o Jacaré ser formado
- Ao formar o Jacaré: o anfitrião muda para o **Jacaré** (nível 13)
- O `highestLevelReached` em `GameState` agora vai até 13

---

#### D — Ranking Lendas (novo — vitalício)

**Dois novos sub-rankings permanentes, separados do ranking global semanal:**

**Ranking Lendas 4096:**
- Métrica: número de vezes que o jogador atingiu 4096 em qualquer partida
- Persistência: **vitalício** — nunca reseta
- Desempate: quem atingiu primeiro (menor `firstReachedAt`) fica à frente em caso de empate no contador
- Exibição: lista paginada, sem pódio destacado (diferente do ranking global)

**Ranking Lendas 8192:**
- Métrica: número de vezes que o jogador atingiu 8192 em qualquer partida
- Persistência: **vitalício** — nunca reseta
- Desempate: mesma regra — quem atingiu primeiro fica à frente no empate
- Exibição: lista paginada

**Recompensas ao atingir marcos (única vez por jogador — não por vezes atingidas):**

| Marco | Recompensa (entregue na primeira vez) |
|---|---|
| Primeira vez que atinge 4096 | 5 vidas + 5 bombas + 5 desfazer |
| Primeira vez que atinge 8192 | 10 vidas + 10 bombas + 10 desfazer |

> Nas vezes subsequentes, não há recompensa adicional — o incentivo é a posição no ranking.

**Atualização em `PersonalRecords`:**
```dart
class PersonalRecords {
  final int? bestTimeMs;
  final int bestNumber;           // maior número já atingido (2048, 4096 ou 8192)
  final int totalGames;
  final int totalWins;            // vezes que atingiu 2048 ou mais
  final int timesReached4096;     // novo
  final int timesReached8192;     // novo
  final DateTime? firstReached4096At;   // novo — para desempate
  final DateTime? firstReached8192At;   // novo — para desempate
}
```

**Atualização no modelo Firestore:**
```
legendsRankings/4096/entries/{userId}
  - userId: string
  - displayName: string
  - timesReached: int
  - firstReachedAt: timestamp
  - country: string?

legendsRankings/8192/entries/{userId}
  - userId: string
  - displayName: string
  - timesReached: int
  - firstReachedAt: timestamp
  - country: string?
```

---

#### E — Atualização da tela de Ranking

A tela de Ranking recebe uma nova aba:

```
Tabs: [Global Semanal] | [Pessoal] | [Lendas]
```

**Aba Lendas:**
- Dois sub-rankings exibidos em sequência (com separador visual): **4096 — Peixe-boi** e **8192 — Jacaré**
- Cada sub-ranking: lista paginada com posição, nome do jogador, número de vezes atingidas e data da primeira vez
- Sem reset — exibe dados históricos
- Se o jogador ainda não atingiu o marco, exibe mensagem motivacional: `"Você ainda não chegou aqui. Continue jogando!"`

---

#### F — Atualização da tela de Coleção

Os dois novos animais entram na `CollectionScreen`:
- Aparecem como silhueta até o jogador atingir o respectivo tile pela primeira vez
- Ao desbloquear: card com `backgroundBaseColor` derivado da cor de contorno do animal
- Peixe-boi: `backgroundBaseColor = Color(0xFFE0F7FA)` (azul bem claro)
- Jacaré: `backgroundBaseColor = Color(0xFFE8F5E9)` (verde bem claro)

---

#### G — Ranking local (Hive) + mock do ranking global para validação de layout

**Objetivo:** implementar o ranking pessoal completo com persistência local via Hive e criar dados mock suficientes para o ranking global, permitindo validar todo o layout da `RankingScreen` — incluindo pódio, lista paginada, aba Lendas e cronômetro de reset — sem depender do backend real (Fase 3).

---

**G1 — Ranking pessoal local (Hive)**

O ranking pessoal já tem o modelo em `PersonalRecords`. O que falta é a **lista de melhores tempos** e **lista de maiores números** registrados localmente, exibíveis na aba "Pessoal" da `RankingScreen`.

Novo Hive box: `personal_ranking` (typeId: 4)

```dart
class PersonalRankingEntry {
  final int scoreMs;          // tempo em ms até o 2048 (null se não completou)
  final int bestNumber;       // maior número atingido nessa partida
  final DateTime playedAt;
}

class PersonalRankingState {
  final List<PersonalRankingEntry> entries;  // máximo 20 entradas — as melhores
}
```

**Lógica de inserção:**
- Ao encerrar uma partida (por vitória ou desistência), criar um `PersonalRankingEntry` e inserir
- Manter apenas as 20 melhores entradas ordenadas por `scoreMs` (menor é melhor para tempo; null vai ao final)
- Para maior número: ordenar por `bestNumber` decrescente, também top 20

**Exibição na aba "Pessoal" da `RankingScreen`:**
```
Sub-tab: [Melhor tempo] | [Maior número]

Melhor tempo:
  Posição | Tempo     | Maior nº  | Data
  1º      | 04:32     | 2048      | 02/05/2026
  2º      | 05:11     | 2048      | 30/04/2026
  ...

Maior número:
  Posição | Maior nº  | Tempo     | Data
  1º      | 8192      | —         | 01/05/2026
  2º      | 4096      | —         | 28/04/2026
  ...
```

- Se o jogador ainda não tem nenhuma entrada: exibe `"Jogue sua primeira partida para aparecer aqui!"`
- A entrada do jogador atual é sempre destacada (fundo levemente colorido) mesmo que esteja fora do top 20

---

**G2 — Mock do ranking global para validação de layout**

Criar um `FakeRankingService` que fornece dados estáticos simulando um ranking global real, usado exclusivamente em dev (`kDebugMode`). Em produção (Fase 3), esse serviço é substituído pela integração Firestore.

Arquivo novo: `lib/core/utils/fake_ranking_service.dart`

```dart
class FakeRankingService {
  // Retorna lista de entradas mock para o ranking global semanal (melhor tempo)
  static List<GlobalRankingEntry> globalBestTime() => [
    GlobalRankingEntry(userId: 'u1', displayName: 'CapyMaster', bestTimeMs: 182000, bestNumber: 2048),
    GlobalRankingEntry(userId: 'u2', displayName: 'JacaréPro', bestTimeMs: 195000, bestNumber: 4096),
    GlobalRankingEntry(userId: 'u3', displayName: 'PeixeBoi42', bestTimeMs: 201000, bestNumber: 2048),
    // ... 10 entradas no total para pódio + lista
  ];

  // Retorna lista mock para o ranking global (maior número)
  static List<GlobalRankingEntry> globalBestNumber() => [...];

  // Retorna lista mock para Ranking Lendas 4096
  static List<LegendsRankingEntry> legends4096() => [
    LegendsRankingEntry(userId: 'u2', displayName: 'JacaréPro', timesReached: 3, firstReachedAt: DateTime(2026, 4, 1)),
    LegendsRankingEntry(userId: 'u5', displayName: 'Tucano77', timesReached: 3, firstReachedAt: DateTime(2026, 4, 5)),
    // empate proposital para testar o comportamento de mesma posição
  ];

  // Retorna lista mock para Ranking Lendas 8192
  static List<LegendsRankingEntry> legends8192() => [...];

  // Simula o timer de reset: retorna DateTime de quando o próximo reset ocorre
  static DateTime nextResetAt() => DateTime.now().add(const Duration(hours: 72));
}
```

**Dados mock devem cobrir os seguintes casos de layout:**
- Pódio com 1º, 2º e 3º lugares distintos
- Pelo menos 1 empate no Ranking Lendas (mesma posição)
- O jogador local (`userId == localUserId`) aparece em pelo menos uma das listas, em posição que não seja top 3, para testar o destaque de "sua posição"
- Uma entrada com `bestNumber: 4096` e outra com `bestNumber: 8192` no ranking global

**Integração na `RankingScreen`:**
- Em `kDebugMode`: usar `FakeRankingService` para popular as abas Global e Lendas
- Em produção: `RankingScreen` receberá dados do Firestore (Fase 3) — o ponto de injeção deve ser via provider para facilitar a troca
- Criar `rankingProvider` (ou `rankingNotifier`) que em dev retorna dados do `FakeRankingService` e em produção será conectado ao Firestore

```dart
// Estrutura sugerida para facilitar a substituição na Fase 3:
final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  if (kDebugMode) return FakeRankingRepository();
  return FirestoreRankingRepository(); // implementado na Fase 3
});
```

**Cronômetro de reset na aba Global:**
- Exibe contador regressivo até o próximo sábado às 18:00 (Brasília)
- Em dev: usar `FakeRankingService.nextResetAt()` como data alvo
- Formato: `"Reinicia em 2d 14h 32m"` — atualizado a cada minuto

---

**Casos de teste adicionais (G):**

```dart
// personal_ranking_test.dart
testWidgets('entrada adicionada ao encerrar partida', ...)
testWidgets('máximo de 20 entradas mantido — pior resultado é descartado', ...)
testWidgets('aba Pessoal exibe sub-tabs Melhor tempo e Maior número', ...)
testWidgets('entry do jogador atual destacada na lista', ...)
testWidgets('sem partidas → exibe mensagem motivacional', ...)

// fake_ranking_service_test.dart
testWidgets('FakeRankingService.globalBestTime retorna 10 entradas ordenadas', ...)
testWidgets('FakeRankingService.legends4096 contém pelo menos 1 empate', ...)
testWidgets('nextResetAt retorna data futura', ...)

// ranking_screen_test.dart (adicionais)
testWidgets('aba Global exibe pódio com 1º, 2º, 3º', ...)
testWidgets('aba Global exibe cronômetro de reset', ...)
testWidgets('aba Global exibe posição do jogador local destacada', ...)
testWidgets('aba Lendas exibe empate com mesma posição para dois jogadores', ...)
testWidgets('em kDebugMode, dados vêm do FakeRankingService', ...)
```

---

---

#### H — Configurações: remover idioma EN + mover "Reduzir Efeitos Visuais" do PauseOverlay

**Objetivo:** duas limpezas de UI nas Configurações e no menu de pausa, alinhadas ao escopo Brasil-only e à organização lógica das opções do jogo.

---

**H1 — Remover opção de idioma inglês da `SettingsScreen`**

O dropdown de idioma atualmente oferece "Português (BR)" e "English". Como o jogo será lançado exclusivamente no Brasil, a opção EN deve ser removida.

**Mudanças:**
- Em `settings_screen.dart`: remover o `DropdownButton` de idioma inteiramente — ou, se preferível para facilitar expansão futura, manter o widget mas com apenas uma opção visível ("Português (BR)") e desabilitado, com label "Apenas PT-BR disponível no momento"
- **Decisão de implementação recomendada:** remover o dropdown completamente por enquanto. Quando a expansão de idiomas for implementada (Fase 6), o widget é readicionado
- Em `lib/core/constants/` ou onde estiver a lista de locales suportados: remover `en_US` da lista de opções
- A chave `settings.locale` no Hive permanece — apenas não há mais UI para alterá-la
- Garantir que o app sempre inicializa com `pt_BR` independentemente de qualquer valor salvo em `settings.locale` que possa ser `en_US` de builds anteriores

**Arquivos modificados:**
- `lib/presentation/screens/settings/settings_screen.dart`
- `lib/core/constants/supported_locales.dart` (ou equivalente)

---

**H2 — Mover "Reduzir Efeitos Visuais" do `PauseOverlay` para a `SettingsScreen`**

Atualmente o `PauseOverlay` (menu exibido ao pausar o jogo) tem uma opção "Reduzir Efeitos Visuais" (toggle). Ela deve ser removida do overlay de pausa e adicionada à tela de Configurações, junto com os demais toggles de sistema.

**Justificativa:** o menu de pausa deve conter apenas ações rápidas de partida (Continuar, Reiniciar, Menu). Opções de preferências visuais pertencem às Configurações, onde o jogador as acessa fora da partida.

**Mudanças no `PauseOverlay`:**
- Remover o `SwitchListTile` ou `CheckboxListTile` de "Reduzir Efeitos Visuais"
- O overlay fica mais limpo: apenas os três botões de ação (Continuar, Reiniciar, Menu)
- Nenhuma outra alteração no layout do overlay

**Mudanças na `SettingsScreen`:**
- Adicionar toggle "Reduzir Efeitos Visuais" dentro do card de configurações de gameplay (junto com o toggle de haptic)
- Label: `"Reduzir Efeitos Visuais"`
- Sub-label: `"Desativa animações complexas para melhor desempenho"`
- Implementado como `SwitchListTile` dentro do card branco semi-opaco existente (`Colors.white.withOpacity(0.88)`, borderRadius 12)
- O valor é lido/gravado via o mesmo provider/Hive key que já existia (`settings.reduce_motion` ou equivalente)

**Atualização em `14.1` (Hive):** a chave `settings.reduce_motion` (ou o nome atual) já deve existir — apenas muda de onde é controlada na UI.

**Arquivos modificados:**
- `lib/presentation/widgets/pause_overlay.dart` — remover o toggle
- `lib/presentation/screens/settings/settings_screen.dart` — adicionar o toggle no card de gameplay

---

**Casos de teste (H):**

```dart
// settings_screen_test.dart
testWidgets('dropdown de idioma não está presente na SettingsScreen', ...)
testWidgets('toggle "Reduzir Efeitos Visuais" presente na SettingsScreen', ...)
testWidgets('toggle "Reduzir Efeitos Visuais" lê e grava valor correto no provider', ...)

// pause_overlay_test.dart
testWidgets('PauseOverlay não contém toggle "Reduzir Efeitos Visuais"', ...)
testWidgets('PauseOverlay contém apenas Continuar, Reiniciar e Menu', ...)
```

---

**Atualização da ordem de execução recomendada:**

1. **H** (limpeza de Configurações e PauseOverlay) — rápido, sem dependências, bom para começar
2. **A** (novos tiles) — adicionar os dois `Animal` em `animals_data.dart`; verificar galeria de debug
3. **C** (anfitrião) — `highestLevelReached` max 13, lógica do `HostBanner`
4. **B** (fluxo de vitória) — criar `VictoryChoiceDialog`, integrar na `GameScreen`
5. **D** (Ranking Lendas) — modelo de dados + lógica de incremento + recompensas
6. **G1** (ranking pessoal local) — Hive box, lógica de inserção, aba Pessoal completa
7. **G2** (mock global) — `FakeRankingService`, `rankingRepositoryProvider`, layout completo da `RankingScreen`
8. **E** (aba Lendas na RankingScreen) — integrada ao layout já construído em G2
9. **F** (tela de Coleção) — dois novos cards

---

**Atualização dos critérios de aceite:**

| Item | Critério |
|---|---|
| Tiles | Peixe-boi (4096) e Jacaré (8192) renderizam com PNG, cor de contorno e contorno 4px |
| Tiles | Animais aparecem corretamente na galeria de debug |
| Fluxo 2048 | Ao atingir 2048: animação + diálogo com opções Continuar / Encerrar |
| Fluxo 4096 | Ao atingir 4096: animação de onda azul + diálogo com opções Continuar / Encerrar |
| Fluxo 8192 | Ao atingir 8192: animação verde + tremor haptic + diálogo com apenas Encerrar |
| Fluxo 8192 | 8192 é o teto — não há opção de continuar |
| Anfitrião | Capivara vira anfitrião ao continuar após 2048 |
| Anfitrião | Peixe-boi vira anfitrião ao atingir 4096 |
| Anfitrião | Jacaré vira anfitrião ao atingir 8192 |
| Ranking Lendas | `timesReached4096` e `timesReached8192` incrementam corretamente |
| Ranking Lendas | `firstReachedAt` registrado apenas na primeira vez |
| Ranking Lendas | Recompensa de primeira vez entregue apenas 1× por marco |
| Ranking Lendas | Aba Lendas visível na `RankingScreen` com dados mock |
| Ranking Lendas | Empate exibido com mesma posição; desempate por `firstReachedAt` |
| Ranking Pessoal | Entradas salvas localmente no Hive ao encerrar partida |
| Ranking Pessoal | Sub-tabs Melhor tempo e Maior número funcionando |
| Ranking Pessoal | Jogador local destacado na lista |
| Ranking Pessoal | Máximo de 20 entradas mantido |
| Ranking Global (mock) | Pódio com 3 colocações distintas renderizado |
| Ranking Global (mock) | Cronômetro de reset exibindo contagem regressiva |
| Ranking Global (mock) | Posição do jogador local destacada fora do pódio |
| Ranking Global (mock) | Dados injetados via `rankingRepositoryProvider` — substituível na Fase 3 |
| Coleção | Peixe-boi e Jacaré aparecem como silhueta antes de desbloquear |
| Coleção | Desbloqueiam ao atingir o respectivo tile pela primeira vez |
| Configurações | Dropdown de idioma removido da `SettingsScreen` |
| Configurações | Toggle "Reduzir Efeitos Visuais" presente na `SettingsScreen` |
| Configurações | Toggle lê e grava valor corretamente (sem regressão de comportamento) |
| PauseOverlay | Toggle "Reduzir Efeitos Visuais" removido do `PauseOverlay` |
| PauseOverlay | Overlay contém apenas Continuar, Reiniciar e Menu |
| Regressão | Fluxo de Game Over não alterado |
| Regressão | Ranking global semanal não alterado |
| Regressão | Tiles 1–11 sem alteração visual |

---

### 🔜 Fase 3 — Backend, ranking e monetização (3–4 semanas)
- Setup Firebase (Auth, Firestore)
- Login (Google, Apple, anônimo)
- Sincronização de PlayerProfile
- Ranking global semanal
- Ranking Lendas (4096 e 8192) — persistência Firestore
- Sistema de convites com deep links
- Sistema de códigos de compartilhamento
- Recompensas de ranking
- Integração Google Mobile Ads (substitui `FakeAdService`)
- Integração `in_app_purchase` real (substitui mocks da Fase 2.8 e 2.10)

### 🔜 Fase 4 — Arte adicional e polimento visual
- Background de floresta na Home
- Logo do jogo
- Ícone do app
- Splash screen final
- Validação visual completa

### 🔜 Fase 5 — Áudio (1–2 semanas)
**Sons dos 11 animais e UI + música ambiente.** Esta fase entra **depois** de toda a arte e polimento visual e **antes** do lançamento.

- Sound design dos 11 animais (definir tom/duração/estilo) e produção dos clipes
- Sons dos 11 animais (~50KB cada, OGG/M4A/MP3) — ver tabela 11.1
- Sons de UI completos — ver lista 11.2
- Música ambiente: loop de floresta com flautas + marimba
- Integrar com `audioplayers` ou `just_audio` (decidir qual)
- Pool de AudioPlayers (evita latência no merge)
- Mixer simples nas Configurações — habilitar controles desabilitados na Fase 2.6
- Pré-carregar tudo no início do app

### 🔜 Fase 6 — Polimento + Lançamento
- Idioma: **PT-BR exclusivamente** no lançamento — EN e outros idiomas em expansão futura
- Acessibilidade (contraste, leitor de tela, fonte ajustável)
- Modo escuro (opcional)
- Testes em dispositivos reais (Android e iOS)
- Build para Android e iOS
- Submissão App Store / Play Store — região Brasil
- Política de privacidade e termos de uso
- LGPD compliance

---

## 16. Considerações Especiais

### 16.1 Acessibilidade
- WCAG AA
- Forma + cor + número + nome
- `Semantics` pra leitor de tela
- Pause overlay anunciado: "Jogo pausado"
- `LivesIndicator` anunciado com estado atual
- `PauseButtonTile` anunciado: "Botão Pausar"
- `HostBanner` anunciado: "Anfitrião: [nome do animal]"
- `GameOverItemScreen` anunciada: "Salvamento disponível — [nome do item]"
- `GameOverNoItemsOverlay` anunciado: "Sem itens — opções para continuar a partida"
- Modo "alta visibilidade"
- Tamanho de fonte ajustável
- Ícones do inventário 72×72dp — tap area atende guideline de 48dp mínimo

### 16.2 Performance
- `const` e Riverpod selectors
- PNGs em vez de SVGs
- `precacheImage` para todos os assets no boot (via `SplashScreen`)
- Pool de AudioPlayers (Fase 5)
- 60fps em Snapdragon 660+ / iPhone 8+
- `RepaintBoundary` no `GameBackground`
- `BackdropFilter` no `PauseOverlay` — fallback se < 50fps
- **Animação piscante (Fase 2.10):** `AnimationController.repeat` nativo — sem rebuild desnecessário; `dispose()` obrigatório
- **`GameOverNoItemsOverlay` (Fase 2.10):** sem `BackdropFilter` — apenas `ColoredBox` semi-transparente para não adicionar custo de GPU

### 16.3 LGPD / Crianças
- Conformidade **LGPD (BR)** — lançamento exclusivo no Brasil; COPPA (US) será avaliada em expansão futura
- Login não obrigatório
- Consentimento parental se < 13 anos
- Anúncios com flag `tagForChildDirectedTreatment`
- Dados coletados: mínimos necessários

### 16.4 Aspectos legais
- Verificar nomes científicos com IUCN/ICMBio
- Considerar parceria com WWF Brasil ou ICMBio
- Atenção à apropriação cultural

### 16.5 SEO e App Store
- **Lançamento inicial:** Brasil exclusivamente — outros países cobertos em expansão futura
- Nome: "Olha o Bichim!"
- Keywords: 2048, puzzle, capivara, animais, brasil, fofo, casual, fauna, bichim
- Screenshots destacando a Capivara
- Vídeo de gameplay de 30s
- Distribuição via App Store (iOS) e Play Store (Android) — somente região Brasil no lançamento

---

## 17. Prompt Sugerido para o Claude Code (Fase 2.12 — via skill superpowers)

> Use a skill `superpowers/brainstorming` pra refinar o design da próxima fase do projeto **Olha o Bichim!** (Flutter, codename `capivara_2048`).
>
> **Contexto:** Fase 2.11 concluída (v1.0.1). Use `CAPIVARA_2048_DESIGN.md` como spec geral (especialmente §4, §9, §10.2, §10.5, §12, §13.3, §13.6 e §15 — Fase 2.12).
>
> **Fases concluídas:** 1 a 2.11. Áudio na Fase 5. Backend na Fase 3.
>
> **Tópico do brainstorm:** **Fase 2.12 — Expansão além do 2048: Peixe-boi (4096) e Jacaré (8192) + Ranking Lendas**. Novos tiles, diálogo de escolha ao atingir marcos, anfitrião atualizado e sistema de ranking vitalício.
>
> **Seis sub-entregas (A a F):**
>
> **A — Novos tiles:** adicionar `Animal` nível 12 (Peixe-boi, `#006064`, 4px) e nível 13 (Jacaré, `#1B5E20`, 4px) em `animals_data.dart`. Assets já existem nas pastas.
>
> **B — Fluxo de vitória:** `VictoryChoiceDialog` exibido ao atingir 2048, 4096 e 8192. 2048 e 4096 oferecem Continuar / Encerrar. 8192 só oferece Encerrar. WillPopScope bloqueia voltar.
>
> **C — Anfitrião:** `highestLevelReached` vai até 13. Capivara como anfitrião ao continuar após 2048, Peixe-boi ao atingir 4096, Jacaré ao atingir 8192.
>
> **D — Ranking Lendas:** `timesReached4096` e `timesReached8192` em `PersonalRecords`, `firstReachedAt` para desempate, recompensa única na primeira vez por marco, coleções Firestore `legendsRankings/4096` e `legendsRankings/8192`.
>
> **E — Tela de Ranking:** nova aba "Lendas" com dois sub-rankings; mensagem motivacional para quem ainda não atingiu o marco.
>
> **F — Tela de Coleção:** Peixe-boi e Jacaré como silhueta até desbloquear; `backgroundBaseColor` `#E0F7FA` e `#E8F5E9` respectivamente.
>
> **G — Ranking local + mock global:** ranking pessoal persistido em Hive (top 20 por tempo e por número, sub-tabs na aba Pessoal); `FakeRankingService` com dados mock cobrindo pódio, empates, jogador local fora do top 3 e cronômetro de reset; `rankingRepositoryProvider` com injeção via `kDebugMode` para substituição fácil na Fase 3.
>
> **H — Limpeza de Configurações e PauseOverlay:** remover dropdown de idioma EN da `SettingsScreen` (Brasil-only); remover toggle "Reduzir Efeitos Visuais" do `PauseOverlay` e movê-lo para a `SettingsScreen` no card de gameplay, junto ao toggle de haptic.
>
> **Pontos abertos pra explorar no brainstorm:**
>
> - Sub-entrega B: o cronômetro do ranking é medido apenas até o 2048 — ao continuar, o tempo parou de contar para fins de ranking. Como isso deve ser exibido na UI? O cronômetro na tela congela visualmente ou mostra o tempo registrado?
> - Sub-entrega B: ao escolher "Continuar" após o 4096 e eventualmente o tabuleiro travar, o fluxo de Game Over funciona normalmente (com itens, sem itens)? Confirmar que não há conflito com o estado `hasWon`.
> - Sub-entrega D: a recompensa de primeira vez (5 vidas + bombas + desfazer para 4096; 10 de cada para 8192) deve ser entregue imediatamente ao atingir o marco, ou ao encerrar a partida?
> - Sub-entrega E: o Ranking Lendas deve ter recompensas semanais como o Global, ou é puramente prestígio (sem recompensa periódica)?
>
> **Output esperado:** spec detalhada da Fase 2.12 com decisões em cada ponto aberto, arquivos a modificar por sub-entrega, casos de teste obrigatórios, critérios de aceite e plano de validação. Ao final: **prompt de brainstorm da Fase 3** (Backend).
>
> **Não escreva código nesta etapa.**

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
