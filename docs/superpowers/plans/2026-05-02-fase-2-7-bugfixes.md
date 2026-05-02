# Fase 2.7 — Bugfixes Visuais de Interface

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Corrigir 4 bugs visuais identificados em uso real pós-Fase 2.6: overflow do tabuleiro em telas pequenas, badge inconsistente na Home, textos ilegíveis sobre fundo dinâmico, e controles de Configurações sem container opaco.

**Architecture:** Quatro fixes ortogonais em ordem C→A→B→D, entregues em um único PR. Fix C usa `LayoutBuilder` para calcular o tamanho do tabuleiro dinamicamente. Fixes B e D aplicam `OutlinedText` e cards brancos semi-opacos seguindo o padrão já estabelecido na `GameScreen`.

**Tech Stack:** Flutter 3.x / Dart, Riverpod, `flutter_test`, `google_fonts`, `OutlinedText` (widget existente em `lib/presentation/widgets/outlined_text.dart`)

---

## Mapa de Arquivos

| Arquivo | Ação | Fix |
|---|---|---|
| `lib/presentation/widgets/board_widget.dart` | Modificar | C |
| `lib/presentation/screens/game/game_screen.dart` | Modificar | C |
| `test/presentation/game_screen_layout_test.dart` | Modificar | C |
| `lib/presentation/screens/home_screen.dart` | Modificar | A |
| `test/presentation/home_screen_test.dart` | Modificar | A |
| `lib/presentation/screens/collection_screen.dart` | Modificar | B |
| `test/presentation/collection_screen_test.dart` | Modificar | B |
| `lib/presentation/screens/settings_screen.dart` | Modificar | B + D |
| `test/presentation/settings_screen_test.dart` | Modificar | B + D |
| `CHANGELOG.md` | Modificar | docs |
| `CLAUDE.md` | Modificar | docs |
| `CAPIVARA_2048_DESIGN.md` | Modificar | docs |

---

## Task 1: Fix C — BoardWidget aceita tamanho externo

**Files:**
- Modify: `lib/presentation/widgets/board_widget.dart`

- [ ] **Step 1: Abrir `board_widget.dart` e localizar o cálculo de boardSize**

O arquivo está em `lib/presentation/widgets/board_widget.dart`. Linha relevante (~14):
```dart
final boardSize = screenWidth - GameConstants.boardPadding * 2;
```

- [ ] **Step 2: Adicionar parâmetro `size` ao construtor de `BoardWidget`**

```dart
class BoardWidget extends ConsumerWidget {
  final double? size;
  const BoardWidget({super.key, this.size});
```

- [ ] **Step 3: Usar `size` quando fornecido**

Substituir a linha de cálculo por:
```dart
final boardSize = size ?? (screenWidth - GameConstants.boardPadding * 2);
```

O bloco `build` completo fica:
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final board = ref.watch(gameProvider).board;
  final screenWidth = MediaQuery.of(context).size.width;
  final boardSize = size ?? (screenWidth - GameConstants.boardPadding * 2);
  final tileSize = (boardSize - GameConstants.tileSpacing * (GameConstants.boardSize + 1)) /
      GameConstants.boardSize;

  return Container(
    width: boardSize,
    height: boardSize,
    // ... resto igual
  );
}
```

- [ ] **Step 4: Verificar que `flutter analyze` passa**

```bash
flutter analyze lib/presentation/widgets/board_widget.dart
```
Esperado: `No issues found!`

---

## Task 2: Fix C — GameScreen usa LayoutBuilder para calcular boardSide

**Files:**
- Modify: `lib/presentation/screens/game/game_screen.dart`

- [ ] **Step 1: Adicionar import de `dart:math`**

No topo do arquivo, adicionar:
```dart
import 'dart:math';
```

- [ ] **Step 2: Envolver o GestureDetector em LayoutBuilder**

Localizar o `GestureDetector` que contém `BoardWidget` (linhas ~44–68). Envolvê-lo em `LayoutBuilder`:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final boardSide = min(
      constraints.maxWidth - 24,
      constraints.maxHeight - 140, // header + inventory estimado
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanEnd: (details) {
        if (state.isPaused ||
            isGameOver ||
            hasWon ||
            state.bombMode != null) return;
        final v = details.velocity.pixelsPerSecond;
        const threshold = 100.0;
        if (v.dx.abs() > v.dy.abs()) {
          if (v.dx > threshold) {
            notifier.onSwipe(Direction.right);
          } else if (v.dx < -threshold) {
            notifier.onSwipe(Direction.left);
          }
        } else {
          if (v.dy > threshold) {
            notifier.onSwipe(Direction.down);
          } else if (v.dy < -threshold) {
            notifier.onSwipe(Direction.up);
          }
        }
      },
      child: RepaintBoundary(child: BoardWidget(size: boardSide)),
    );
  },
),
```

- [ ] **Step 3: Verificar que `flutter analyze` passa**

```bash
flutter analyze lib/presentation/screens/game/game_screen.dart
```
Esperado: `No issues found!`

---

## Task 3: Fix C — Teste de overflow em 360×640

**Files:**
- Modify: `test/presentation/game_screen_layout_test.dart`

- [ ] **Step 1: Adicionar imports necessários ao topo do arquivo**

Verificar que `game_screen_layout_test.dart` já importa os adapters Hive e `SharedPreferences`. O arquivo atual já tem `setUpAll`/`tearDownAll` para Hive. Adicionar imports se ausentes:
```dart
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/daily_rewards_state_adapter.dart';
import 'package:capivara_2048/presentation/widgets/board_widget.dart';
```

- [ ] **Step 2: Adicionar teste de overflow em tela 360×640**

Dentro do `group('GameScreen layout', ...)`, adicionar:

```dart
testWidgets('BoardWidget com size pequeno não causa overflow', (tester) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          height: 400,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boardSide = constraints.maxWidth - 24;
              return BoardWidget(size: boardSide);
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();

  // Não deve haver overflow — ausência de RenderFlex overflowed é o critério
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 3: Rodar o teste**

```bash
flutter test test/presentation/game_screen_layout_test.dart -v
```
Esperado: todos os testes PASS.

- [ ] **Step 4: Commit do Fix C**

```bash
git add lib/presentation/widgets/board_widget.dart \
        lib/presentation/screens/game/game_screen.dart \
        test/presentation/game_screen_layout_test.dart
git commit -m "fix(game): LayoutBuilder no GameScreen evita overflow do tabuleiro em telas pequenas"
```

---

## Task 4: Fix A — Badge "!" no card de Recompensa Diária

**Files:**
- Modify: `lib/presentation/screens/home_screen.dart`

- [ ] **Step 1: Localizar `_HomeCard.build()` em `home_screen.dart`**

O método `build` está por volta da linha 209. A lógica de badge fica nas últimas linhas do método (~244–264).

- [ ] **Step 2: Envolver `card` em `SizedBox.expand()` antes do bloco `if (showBadge)`**

Substituir o trecho final do método (após `if (comingSoon) card = Opacity(opacity: 0.5, child: card);`):

```dart
    if (comingSoon) card = Opacity(opacity: 0.5, child: card);

    // Garante tamanho uniforme no grid independente do badge
    card = SizedBox.expand(child: card);

    if (showBadge) {
      card = Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: card),
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return card;
```

- [ ] **Step 3: Verificar que `flutter analyze` passa**

```bash
flutter analyze lib/presentation/screens/home_screen.dart
```
Esperado: `No issues found!`

---

## Task 5: Fix A — Testes do badge

**Files:**
- Modify: `test/presentation/home_screen_test.dart`

- [ ] **Step 1: Criar helper que injeta rewardAvailable=true**

O `home_screen_test.dart` atual usa `_wrap()` sem controle da data. Para forçar `rewardAvailable = true`, precisamos injetar um `DailyRewardsState` com `lastClaimedDate` anterior a hoje.

Adicionar import:
```dart
import 'package:capivara_2048/data/models/daily_rewards_state.dart';
import 'package:capivara_2048/domain/daily_rewards/daily_rewards_notifier.dart';
```

Adicionar helper após `_wrap()`:
```dart
Future<Widget> _wrapWithReward() async {
  final prefs = await SharedPreferences.getInstance();
  final settingsNotifier = SettingsNotifier(prefs);
  // Estado com recompensa disponível: lastClaimedDate ontem
  final yesterday = DateTime.now().subtract(const Duration(days: 2));
  final rewardsState = DailyRewardsState(
    lastClaimedDate: yesterday,
    currentDay: 1,
    streakActive: true,
  );
  final rewardsNotifier = DailyRewardsNotifier(prefs)..state = rewardsState;
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith((ref) => settingsNotifier),
      dailyRewardsProvider.overrideWith((ref) => rewardsNotifier),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}
```

- [ ] **Step 2: Adicionar testes do badge**

```dart
testWidgets('badge "!" aparece no card Recompensa Diária quando recompensa disponível',
    (tester) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(await _wrapWithReward());
  await tester.pump(const Duration(milliseconds: 500));

  expect(find.text('!'), findsOneWidget);
  expect(find.text('Recompensa Diária'), findsOneWidget);
});

testWidgets('card Recompensa Diária sem badge não exibe "!"', (tester) async {
  await tester.pumpWidget(await _wrap());
  await tester.pump(const Duration(milliseconds: 500));

  expect(find.text('!'), findsNothing);
});
```

- [ ] **Step 3: Rodar os testes**

```bash
flutter test test/presentation/home_screen_test.dart -v
```
Esperado: todos PASS.

- [ ] **Step 4: Commit do Fix A**

```bash
git add lib/presentation/screens/home_screen.dart \
        test/presentation/home_screen_test.dart
git commit -m "fix(home): badge '!' com tamanho fixo no card de Recompensa Diária"
```

---

## Task 6: Fix B — OutlinedText na CollectionScreen

**Files:**
- Modify: `lib/presentation/screens/collection_screen.dart`

- [ ] **Step 1: Adicionar import de `outlined_text.dart`**

No topo de `collection_screen.dart`, adicionar:
```dart
import '../widgets/outlined_text.dart';
```

- [ ] **Step 2: Substituir o Text do contador por OutlinedText**

Localizar (~linha 35–39):
```dart
Text(
  '$highest/11 animais descobertos',
  style: GoogleFonts.fredoka(
      fontSize: 16, color: AppColors.primary),
),
```

Substituir por:
```dart
OutlinedText(
  '$highest/11 animais descobertos',
  style: GoogleFonts.fredoka(fontSize: 16),
),
```

- [ ] **Step 3: Verificar que `flutter analyze` passa**

```bash
flutter analyze lib/presentation/screens/collection_screen.dart
```
Esperado: `No issues found!`

---

## Task 7: Fix B — Teste OutlinedText na CollectionScreen

**Files:**
- Modify: `test/presentation/collection_screen_test.dart`

- [ ] **Step 1: Adicionar import de `outlined_text.dart` no teste**

```dart
import 'package:capivara_2048/presentation/widgets/outlined_text.dart';
```

- [ ] **Step 2: Adicionar teste**

```dart
testWidgets('contador usa OutlinedText (legível sobre fundo dinâmico)', (tester) async {
  await tester.pumpWidget(_wrapWithMaxLevel(3));
  await tester.pump();
  expect(find.byType(OutlinedText), findsWidgets);
  // Confirma que o OutlinedText contém o texto do contador
  expect(
    find.descendant(
      of: find.byType(OutlinedText),
      matching: find.textContaining('animais descobertos'),
    ),
    findsOneWidget,
  );
});
```

- [ ] **Step 3: Rodar o teste**

```bash
flutter test test/presentation/collection_screen_test.dart -v
```
Esperado: todos PASS.

---

## Task 8: Fix B — OutlinedText nos títulos de seção da SettingsScreen

**Files:**
- Modify: `lib/presentation/screens/settings_screen.dart`

- [ ] **Step 1: Adicionar import de `outlined_text.dart`**

No topo de `settings_screen.dart`, adicionar:
```dart
import '../widgets/outlined_text.dart';
```

- [ ] **Step 2: Substituir Text por OutlinedText em `_SettingsSection`**

Localizar a classe `_SettingsSection` (~linha 106–120). Substituir o `Text`:
```dart
// ANTES
Text(
  title,
  style: GoogleFonts.fredoka(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
),
```
Por:
```dart
// DEPOIS
OutlinedText(
  title,
  style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w600),
),
```

- [ ] **Step 3: Verificar que `flutter analyze` passa**

```bash
flutter analyze lib/presentation/screens/settings_screen.dart
```
Esperado: `No issues found!`

---

## Task 9: Fix D — Cards brancos semi-opacos na SettingsScreen

**Files:**
- Modify: `lib/presentation/screens/settings_screen.dart`

- [ ] **Step 1: Substituir o body `ListView` pelo novo layout com Cards**

O método `build` atual retorna um `ListView` com items soltos. Substituir o `body:` inteiro:

```dart
body: ListView(
  padding: const EdgeInsets.symmetric(vertical: 8),
  children: [
    _SettingsSection('Geral'),
    Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Colors.white.withOpacity(0.88),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          SwitchListTile(
            tileColor: Colors.transparent,
            title: Text('Vibração', style: GoogleFonts.nunito(fontSize: 16)),
            value: settings.hapticEnabled,
            onChanged: notifier.setHaptic,
            activeColor: AppColors.primary,
          ),
          ListTile(
            tileColor: Colors.transparent,
            title: Text('Idioma', style: GoogleFonts.nunito(fontSize: 16)),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pt', label: Text('PT-BR')),
                ButtonSegment(value: 'en', label: Text('EN')),
              ],
              selected: {settings.locale},
              onSelectionChanged: (s) => notifier.setLocale(s.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected) ? AppColors.primary : null),
              ),
            ),
          ),
        ],
      ),
    ),
    _SettingsSection('Áudio'),
    Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Colors.white.withOpacity(0.88),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            tileColor: Colors.transparent,
            title: Text(
              'Disponível na Fase 5',
              style: GoogleFonts.nunito(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
          Opacity(
            opacity: 0.4,
            child: ListTile(
              tileColor: Colors.transparent,
              title: Text('Volume SFX', style: GoogleFonts.nunito(fontSize: 16)),
              subtitle: Slider(value: 1.0, onChanged: null),
            ),
          ),
          Opacity(
            opacity: 0.4,
            child: ListTile(
              tileColor: Colors.transparent,
              title: Text('Volume Música', style: GoogleFonts.nunito(fontSize: 16)),
              subtitle: Slider(value: 1.0, onChanged: null),
            ),
          ),
        ],
      ),
    ),
    _SettingsSection('Sobre'),
    Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Colors.white.withOpacity(0.88),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          if (_version.isNotEmpty)
            ListTile(
              tileColor: Colors.transparent,
              title: Text('Versão', style: GoogleFonts.nunito(fontSize: 16)),
              trailing: Text(_version, style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey)),
            ),
          ListTile(
            tileColor: Colors.transparent,
            title: Text('Olha o Bichim! © Catraia Aplicativos',
                style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey)),
          ),
        ],
      ),
    ),
  ],
),
```

- [ ] **Step 2: Verificar que `flutter analyze` passa**

```bash
flutter analyze lib/presentation/screens/settings_screen.dart
```
Esperado: `No issues found!`

---

## Task 10: Testes das Tasks 8 e 9

**Files:**
- Modify: `test/presentation/settings_screen_test.dart`

- [ ] **Step 1: Adicionar import de `outlined_text.dart`**

```dart
import 'package:capivara_2048/presentation/widgets/outlined_text.dart';
```

- [ ] **Step 2: Adicionar testes para OutlinedText e Card**

```dart
testWidgets('títulos de seção usam OutlinedText', (tester) async {
  final prefs = await SharedPreferences.getInstance();
  final notifier = SettingsNotifier(prefs);
  await tester.pumpWidget(_wrap(notifier));
  await tester.pump();

  expect(find.byType(OutlinedText), findsWidgets);
  expect(
    find.descendant(
      of: find.byType(OutlinedText),
      matching: find.text('Geral'),
    ),
    findsOneWidget,
  );
});

testWidgets('controles estão dentro de Cards brancos semi-opacos', (tester) async {
  final prefs = await SharedPreferences.getInstance();
  final notifier = SettingsNotifier(prefs);
  await tester.pumpWidget(_wrap(notifier));
  await tester.pump();

  expect(find.byType(Card), findsWidgets);
});
```

- [ ] **Step 3: Rodar todos os testes de settings**

```bash
flutter test test/presentation/settings_screen_test.dart -v
```
Esperado: todos PASS.

- [ ] **Step 4: Rodar suite completa**

```bash
flutter test
```
Esperado: zero falhas.

- [ ] **Step 5: Commit dos Fixes B e D**

```bash
git add lib/presentation/screens/collection_screen.dart \
        lib/presentation/screens/settings_screen.dart \
        test/presentation/collection_screen_test.dart \
        test/presentation/settings_screen_test.dart
git commit -m "fix(ui): OutlinedText em textos sobre fundo dinâmico; cards brancos em SettingsScreen"
```

---

## Task 11: flutter analyze final e validação manual

**Files:** nenhum

- [ ] **Step 1: Rodar `flutter analyze` na raiz**

```bash
flutter analyze
```
Esperado: `No issues found!`

- [ ] **Step 2: Rodar suite completa de testes**

```bash
flutter test
```
Esperado: zero falhas.

- [ ] **Step 3: Validação manual — checklist**

| # | Cenário | Como testar |
|---|---|---|
| 1 | Tabuleiro 4×4 completo em tela pequena | Emulador 360×640, iniciar partida |
| 2 | Sem regressão em tela padrão | Emulador 412×892, iniciar partida |
| 3 | Badge "!" na Home com recompensa | Forçar `lastClaimedDate` > 1 dia atrás via debug |
| 4 | Grid Home uniforme sem badge | Estado padrão sem recompensa disponível |
| 5 | Contador legível na CollectionScreen | Abrir Coleção, verificar texto branco com contorno |
| 6 | Cards brancos em SettingsScreen | Abrir Configurações, verificar legibilidade |

---

## Task 12: Documentação e atualização do design doc

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `CLAUDE.md`
- Modify: `CAPIVARA_2048_DESIGN.md`

- [ ] **Step 1: Atualizar `CHANGELOG.md`**

Adicionar entrada no topo (após `# Changelog`):

```markdown
## [0.9.3] — 2026-05-02

### Fixed
- Tabuleiro 4×4 cortado em telas pequenas (360×640) — `LayoutBuilder` no `GameScreen`
- Badge de Recompensa Diária desalinhava o grid da Home — `SizedBox.expand` + badge "!"
- Textos ilegíveis sobre fundo dinâmico (`CollectionScreen`, `SettingsScreen`) — `OutlinedText`
- Controles de `SettingsScreen` ilegíveis — cards brancos semi-opacos por seção
```

- [ ] **Step 2: Atualizar `CLAUDE.md`**

Localizar a linha:
```
Fase atual: **Fase 2.6 concluída (v0.9.2) — próximo: Fase 2.7**
```
Substituir por:
```
Fase atual: **Fase 2.7 concluída (v0.9.3) — próximo: Fase 2.8**
```

- [ ] **Step 3: Marcar Fase 2.7 como concluída no `CAPIVARA_2048_DESIGN.md` §15**

Localizar (~linha 977):
```
### 🚧 Fase 2.7 — Bugfixes visuais de interface (PRÓXIMA — 1–2 dias)
```
Substituir por:
```
### ✅ Fase 2.7 — Bugfixes visuais de interface (v0.9.3)
```

- [ ] **Step 4: Atualizar §17 do `CAPIVARA_2048_DESIGN.md` com prompt da Fase 2.8**

Localizar (~linha 1330):
```markdown
## 17. Prompt Sugerido para o Claude Code (Fase 2.7 — via skill superpowers)
```

Substituir o conteúdo da seção §17 inteira (do cabeçalho até o fim do arquivo) pelo prompt da Fase 2.8 que está em `docs/superpowers/specs/2026-05-02-fase-2-7-design.md` na seção "Prompt de Brainstorm — Fase 2.8 (para uso no início da próxima sessão)".

O novo §17 deve ficar:

```markdown
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
```

- [ ] **Step 5: Adicionar spec completa da Fase 2.8 no §15 do `CAPIVARA_2048_DESIGN.md`**

Localizar (~linha 1122) a seção `### 🔜 Fase 2.8 — Loja mock (3 dias)`. O conteúdo já existe no design doc. Verificar que o conteúdo está alinhado com a spec em `docs/superpowers/specs/2026-05-02-fase-2-7-design.md` seção "Spec — Fase 2.8". Se houver divergências, o conteúdo da spec prevalece.

- [ ] **Step 6: Commit final de documentação**

```bash
git add CHANGELOG.md CLAUDE.md CAPIVARA_2048_DESIGN.md
git commit -m "chore: bump v0.9.3; docs Fase 2.7 concluída, prompt Fase 2.8 em §17"
```
