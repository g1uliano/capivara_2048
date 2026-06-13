# AGENTS.md — Capivara 2048 (codinome)

## Projeto

"Olha o Bixim!" é um Flutter puzzle game estilo 2048 com animais amazônicos. Spec completa em `CAPIVARA_2048_DESIGN.md` (design doc) - ele pode conter pequenos erros em relação a questões técnicas e de implementação, pois, ele é uma spec geral e um esboço do que tem que ser ou foi implementado, por isso, sempre confira o repositório a procura de arquivos, pastas e pra ter certeza cheque o código e outras specs).

## Stack

- Flutter 3.x / Dart
- Riverpod (estado)
- Hive + SharedPreferences (persistência)
- flutter_animate (animações)

## Estrutura de pastas

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/     # cores, tamanhos, durações
│   ├── theme/         # tema cartoon fofo
│   └── utils/
├── data/
│   ├── models/        # Animal, Tile, GameState, DailyChallenge
│   ├── repositories/  # persistência local
│   └── animals_data.dart
├── domain/
│   ├── game_engine/   # lógica pura 2048 — testável sem Flutter
│   └── daily_challenge/
└── presentation/
    ├── screens/       # home, game, collection, daily, settings
    ├── widgets/       # board, tile, score_panel, animal_card
    └── controllers/   # Riverpod notifiers
```

## Comandos de build

### flutter build

| Descrição                    | Comando |
| ---------------------------- | ------- |
| APK tst dev debug            | `flutter build apk --flavor tst --dart-define=FLAVOR=dev --debug` |
| APK prd release              | `flutter build apk --flavor prd --release --dart-define=FLAVOR=prd --dart-define=AD_UNIT_ANDROID=ca-app-pub-3940256099942544/5224354917 --dart-define=AD_UNIT_IOS=ca-app-pub-3940256099942544/1712485313` |
| AAB prd release (Play Store) | `flutter build appbundle --flavor prod --release --dart-define=FLAVOR=prd --dart-define=AD_UNIT_ANDROID=ca-app-pub-3940256099942544/5224354917 --dart-define=AD_UNIT_IOS=ca-app-pub-3940256099942544/1712485313` |
| iOS prd release              | `flutter build ios --flavor prd --release --dart-define=FLAVOR=prd` |

### flutter run

| Cenário                                    | Comando |
| ------------------------------------------ | ------- |
| Dispositivo físico, Firebase dev real      | `flutter run --flavor tst --dart-define=FLAVOR=dev` |
| Produção (Firebase prd)                    | `flutter run --flavor prod --dart-define=FLAVOR=prd` |
| Emulador Firebase + USB (adb reverse)      | `flutter run --flavor tst --dart-define=FLAVOR=dev --dart-define=USE_EMULATOR=true` |
| Emulador Firebase + WiFi (Genymotion etc.) | `flutter run --flavor tst --dart-define=FLAVOR=dev --dart-define=USE_EMULATOR=true --dart-define=EMULATOR_HOST=10.0.0.2` |

## Regras de desenvolvimento

- **Game engine** (`domain/game_engine/`) deve ser puro Dart, zero dependência de Flutter — facilita testes unitários
- Testes unitários obrigatórios para toda lógica do game engine
- Usar `const` onde possível; minimizar rebuilds com Riverpod selectors
- Imagens pré-carregadas com `precacheImage` no startup
- Pool de AudioPlayers para sons (evitar latência)
- Acessibilidade: usar `Semantics`, contraste WCAG AA mínimo

## Convenções

- Nomes em inglês no código; strings exibidas ao usuário via `intl` (PT-BR e EN)
- Models imutáveis com `copyWith`
- IDs de tiles como UUID para controle de animações

## Legibilidade e tipografia — regras obrigatórias

Todas as telas usam `GameBackground` com a imagem `fundo.png` (floresta amazônica colorida). **Texto branco puro sem sombra é ilegível sobre esse fundo.**

### Texto sobre o fundo do jogo

**Todo texto que aparece diretamente sobre o fundo do jogo DEVE usar `GoogleFonts.fredoka()` com o tratamento de outline.**

| Contexto                 | Font                                         | Tratamento                             | Exemplo                                              |
| ------------------------ | -------------------------------------------- | -------------------------------------- | ---------------------------------------------------- |
| Título no AppBar         | `fredoka(fontSize: 22, color: Colors.white)` | `Text(...)` simples                    | "Configurações", "Ranking"                           |
| Headers/seções no fundo  | `fredoka(fontSize: 14, fontWeight: w600)`    | `OutlinedText(...)`                    | "Gameplay", "Áudio"                                  |
| Mensagens/corpo no fundo | `fredoka(fontSize: 14–18)`                   | `outlinedWhiteTextStyle(fredoka(...))` | "Você não está conectado.", "Salve seu progresso..." |
| Botões de ação no fundo  | `fredoka(fontSize: 16–18)`                   | `outlinedWhiteTextStyle(fredoka(...))` | "Jogar sem conta →", "← Voltar"                      |

Regras:

- **Usar `GoogleFonts.fredoka()`** para todo texto sobre o fundo — nunca `GoogleFonts.nunito()` em texto sobre o background
- **Usar `outlinedWhiteTextStyle()`** de `lib/core/theme/text_styles.dart` ou o widget `OutlinedText` de `lib/presentation/widgets/outlined_text.dart`
- Nunca usar `color: Colors.white` diretamente sem sombra/outline

### Texto dentro de cards, dialogs e sheets (fundo branco/sólido)

Dentro de `Card`, `AlertDialog`, `BottomSheet`, `ElevatedButton` (que têm fundo sólido):

- Corpo/labels: `GoogleFonts.nunito(fontSize: 14–16, color: Colors.black87)`
- Títulos de card: `GoogleFonts.fredoka(fontSize: 16–24, color: Color(0xFF3E2723))`
- Texto secundário: `GoogleFonts.nunito(fontSize: 12–14, color: Colors.grey)`

### AppBar

Todas as AppBars usam o mesmo padrão — **nunca usar `OutlinedText` no AppBar**:

```dart
AppBar(
  title: Text('Título', style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white)),
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  elevation: 0,
)
```

### GlassPanel — texto sobre o fundo do jogo em blocos

Quando um trecho de texto mais longo (título + parágrafo) aparece sobre o fundo do jogo, use o widget `GlassPanel` de `lib/presentation/widgets/glass_panel.dart` em vez de `OutlinedText` isolado. Ele aplica `BackdropFilter` + container esmeralda escuro translúcido com borda sutil, garantindo legibilidade sem esconder o fundo.

```dart
import '../../../widgets/glass_panel.dart';

GlassPanel(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
  child: Column(
    children: [
      Text('Título', style: GoogleFonts.fredoka(fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white)),
      const SizedBox(height: 12),
      Text('Corpo', style: GoogleFonts.fredoka(fontSize: 16, height: 1.5, color: Colors.white)),
    ],
  ),
)
```

**Regras:**

- Texto dentro do `GlassPanel` usa `color: Colors.white` diretamente (sem outline — o fundo escuro garante legibilidade)
- `OutlinedText` continua sendo usado para textos isolados/curtos diretamente sobre o fundo (ex: hints de swipe)
- Não usar `OutlinedText` dentro de `GlassPanel`
- Implementação de referência: `OnboardingAuthScreen._ContentPanel`, `InviteFriendsScreen._GlassPanel`, todas as páginas de `TutorialScreen`

### TabBar

Todos os `TabBar` devem ter `labelStyle` e `unselectedLabelStyle` explícitos:

```dart
TabBar(
  labelStyle: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w600),
  unselectedLabelStyle: GoogleFonts.fredoka(fontSize: 14),
  labelColor: Colors.white,
  unselectedLabelColor: Colors.white70,
  indicatorColor: Colors.white,
)
```

## Fases do roadmap

Sempre confirmar em qual fase estamos antes de implementar. Fase atual: **Fase 6 (v1.9.35) — Polimento, l10n, acessibilidade, lançamento**.

| Fase      | Foco                                                                                                                                                                 |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1         | Setup, game engine puro, tela básica com placeholders                                                                                                                |
| 2         | Identidade visual, paleta, tipografia, animações, vidas, inventário, recompensas, coleção, loja mock                                                                 |
| 2.5 ✅    | Rebranding "Olha o Bichim!", GameTitleImage, ícone do app, launcher name                                                                                             |
| 2.6 ✅    | Tela Home + Coleção + Configurações + stubs                                                                                                                          |
| 2.11 ✅   | ShopOverlay sobre o jogo acessível pelos ícones desabilitados do inventário                                                                                          |
| 2.12 ✅   | Peixe-boi (4096), Jacaré (8192), multi-vitória, ranking local, PersonalRecords                                                                                       |
| 3 ✅      | E2E Test Framework: 95+ cenários, golden tests, APK Tier 2, CI GitHub Actions, documentação                                                                          |
| 3.5 ✅    | `golden.*` com `alchemist` — 15 testes (5 telas × 3 viewports)                                                                                                       |
| 3.6 ✅    | Tier 2: APK flavor `tst` + TestRunnerScreen + Share + Demo (integration_test)                                                                                        |
| 3.7 ✅    | CI GitHub Actions: suite Tier 1 em PR/push, golden diffs como artefato, badge no README                                                                              |
| 3.8 ✅    | Documentação do framework de testes (`docs/TESTING.md`)                                                                                                              |
| 4A ✅     | Firebase + Auth + Sync Engine (PlayerProfile, AuthService, SyncEngine, OnboardingAuthScreen, ProfileScreen)                                                          |
| 4B ✅     | Ranking Global Semanal (Firestore) + Ranking Lendas persistido                                                                                                       |
| 4C ✅     | Convites (deep links, Firestore) + Anúncios Reais (Google Mobile Ads) + IAP Real (in_app_purchase)                                                                   |
| 4 gaps ✅ | registerInvite pós-login, ProfileScreen Convidar Amigos + Restaurar Compras real                                                                                     |
| 4.1 ✅    | EmailAuthScreen, AvatarPickerScreen, AvatarWidget, updateAvatar(), destaque avatar na Home, fix legibilidade InviteFriendsScreen                                     |
| 4.1.1 ✅  | Tipografia consistente: Fredoka em todas as telas/widgets sobre fundos não-sólidos                                                                                   |
| 4.2 ✅    | Exclusão de conta LGPD, nome no cadastro, editar nome, trocar/esqueci senha, persistência avatar tile, auth gates (startup, shop, daily, ranking), sync game records |
| 4.3 ✅    | Ranking Global (aba + dialogs pós-milestone), recompensas por recorde pessoal/convite, tabela semanal revisada, flavor audit                                         |
| 4.4 ✅    | Tutorial wizard interativo: TutorialScreen (5 telas, 2 interativas), TutorialMiniBoard, tutorialCompleted no PlayerProfile                                           |
| 4.5 ✅    | Polimento: Bomba 3 ≥5 peças, IAP real em dev/overlay/loja, haptic graduado, texto "Ok" pós-ad                                                                        |
| 4.6 ✅    | Recompensas Diárias: trilha serpentina + CapivaraMascot; sync pós-login completo (inventário IAP, recordes, coleção, daily rewards)                                  |
| 5 ✅      | Arte adicional e polimento visual — sistema de SFX procedural (fases 5.1 e 5.2); demais itens visuais descartados |
| 5.1 ✅    | Sistema de áudio procedural: SfxrSynth (efeitos 8-bit), JungleSequencer (Bossa Nova MPB ~85s), AudioServiceImpl (flutter_soloud), controles nas Configurações, hooks de jogo |
| 5.2 ✅    | Reformulação trilha tema: SynthCore (Karplus-Strong/filteredNoise/ADSR, 32kHz), JungleSequencer bossa jazz+nylon KS+ambiência+bichos, AnimalVoices (vozes bicho + merge pluck), SFX desfazer 1/3, evento AnimalReached |
| 6         | Polimento, l10n, acessibilidade, lançamento                                                                                                                          |

## Release checklist

Sempre que lançar uma nova versão (merge + push):

1. Atualizar `CHANGELOG.md` com a versão e as mudanças
2. Atualizar `README.md` se necessário (roadmap, features, versão)
3. Atualizar `CLAUDE.md` se houver informações relevantes (convenções novas, decisões de arquitetura, bugs conhecidos, etc.)
4. Atualizar `AGENTS.md` se houver informações relevantes (fase atual, convenções, regras novas)
5. Fazer merge em main e push

> **Nota:** sempre que `CLAUDE.md` for atualizado, verificar se `AGENTS.md` também precisa ser atualizado — e vice-versa. Os dois devem estar em sincronia quanto à fase atual, convenções de desenvolvimento e decisões de arquitetura.

## Animais (referência rápida)

Níveis 1–11: Tanajura → Lobo-guará → Sapo-cururu → Tucano → **Sagui** → Preguiça → Mico-leão-dourado → Boto-cor-de-rosa → Onça-pintada → Sucuri → **Capivara Lendária (2048)**.

Diretrizes comportamentais para reduzir erros comuns de LLMs. Mesclar com as instruções específicas do projeto conforme necessário.

**Trade-off:** Estas diretrizes priorizam cautela em vez de velocidade. Para tarefas triviais, use o bom senso.

## 1. Pense Antes de Codar

**Não assuma. Não esconda confusão. Exponha trade-offs.**

Antes de implementar:

- Declare suas suposições explicitamente. Se incerto, pergunte.
- Se houver múltiplas interpretações, apresente-as — não escolha silenciosamente.
- Se existir uma abordagem mais simples, diga. Questione quando justificado.
- Se algo estiver obscuro, pare. Nomeie o que está confuso. Pergunte.

## 2. Simplicidade Primeiro

**Código mínimo que resolve o problema. Nada especulativo.**

- Nenhuma feature além do que foi pedido.
- Nenhuma abstração para código de uso único.
- Nenhuma "flexibilidade" ou "configurabilidade" não solicitada.
- Nenhum tratamento de erros para cenários impossíveis.
- Se você escrever 200 linhas e pudesse ser 50, reescreva.

Pergunte a si mesmo: "Um engenheiro sênior diria que isso está overcomplicated?" Se sim, simplifique.

## 3. Mudanças Cirúrgicas

**Toque apenas o necessário. Limpe apenas sua própria bagunça.**

Ao editar código existente:

- Não "melhore" código adjacente, comentários ou formatação.
- Não refatore coisas que não estão quebradas.
- Siga o estilo existente, mesmo que você faria diferente.
- Se notar código morto não relacionado, mencione — não delete.

Quando suas mudanças criarem órfãos:

- Remova imports/variáveis/funções que SUAS mudanças tornaram desnecessários.
- Não remova código morto pré-existente a menos que solicitado.

O teste: cada linha alterada deve rastrear diretamente ao pedido do usuário.

## 4. Execução Orientada a Objetivos

**Defina critérios de sucesso. Itere até verificar.**

Transforme tarefas em objetivos verificáveis:

- "Adicionar validação" → "Escrever testes para entradas inválidas, depois fazê-los passar"
- "Corrigir o bug" → "Escrever um teste que o reproduza, depois fazê-lo passar"
- "Refatorar X" → "Garantir que os testes passem antes e depois"

Para tarefas de múltiplos passos, declare um plano breve:

```
1. [Passo] → verificar: [checagem]
2. [Passo] → verificar: [checagem]
3. [Passo] → verificar: [checagem]
```

Critérios de sucesso fortes permitem iterar de forma independente. Critérios fracos ("fazer funcionar") exigem clarificações constantes.

---

**Estas diretrizes estão funcionando se:** menos mudanças desnecessárias nos diffs, menos reescritas por complicação excessiva, e perguntas de clarificação vêm antes da implementação, não depois dos erros.
