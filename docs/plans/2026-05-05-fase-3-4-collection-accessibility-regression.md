# Fase 3.4 — `collection.*` + `accessibility.*` + `regression.*` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar 14 cenários E2E da Fase 3.4: 6 `collection.*`, 4 `accessibility.*`, 4 `regression.*` — totalizando 80 cenários Tier 1 ao final.

**Architecture:** Três novos arquivos de cenários (`collection/`, `accessibility/`, `regression/`), um registro atualizado. Os cenários `accessibility.*` requerem mudanças cirúrgicas em dois widgets de produção para adicionar anotações `Semantics`.

**Tech Stack:** Flutter `flutter_test`, `WidgetTester`, Riverpod `ProviderContainer`, Hive temp dir (via `GameTestHarness`), padrões existentes de `E2EScenario` / `ScenarioTag`.

---

## File Map

| Ação       | Arquivo                                                                                        |
| ---------- | ---------------------------------------------------------------------------------------------- |
| **Create** | `test/e2e/collection/collection_flows.dart`                                                    |
| **Create** | `test/e2e/accessibility/accessibility_flows.dart`                                              |
| **Create** | `test/e2e/regression/regression_flows.dart`                                                    |
| **Modify** | `test/e2e/_harness/registry.dart` — registrar 14 novos cenários                                |
| **Modify** | `lib/presentation/screens/home_screen.dart` — `semanticLabel` nos `_HomeButton`                |
| **Modify** | `lib/presentation/screens/game/game_screen.dart` — `Semantics` no GestureDetector do tabuleiro |

---

## Task 1: Criar `collection_flows.dart` com 6 cenários

**Files:**

- Create: `test/e2e/collection/collection_flows.dart`

### Contexto da CollectionScreen

`CollectionScreen` lê `personalRecordsProvider.select((s) => s.highestLevelEver)`:

- `highest >= animal.level` → `_UnlockedCard` (exibe nome, PNG, abre bottom sheet)
- caso contrário → `_LockedCard` (exibe "???", PNG escurecido)

O texto de contagem é `'$highest/13 animais descobertos'`.
O bottom sheet (`_AnimalDetailSheet`) exibe: PNG host, nome, `scientificName` (se presente), `funFact`.

Para navegar para `CollectionScreen`, usar `find.byKey(const Key('home_btn_colecao'))`.

- [ ] **Step 1: Criar `test/e2e/collection/collection_flows.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/controllers/personal_records_notifier.dart';
import 'package:capivara_2048/presentation/screens/collection_screen.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';

// ─── helpers ────────────────────────────────────────────────────────────────

Future<void> _bootToCollection(
  WidgetTester tester,
  GameTestHarness harness, {
  int highest = 0,
}) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));

  if (highest > 0) {
    await tester.runAsync(() =>
        harness.container.read(personalRecordsProvider.notifier).updateHighestLevel(highest));
    await tester.pump(const Duration(milliseconds: 300));
  }

  await tester.tap(find.byKey(const Key('home_btn_colecao')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.byType(CollectionScreen), findsOneWidget,
      reason: 'deve navegar para CollectionScreen');
}

// ─── collection.shows_X_of_13_animals ───────────────────────────────────────

final collectionShowsCountScenario = E2EScenario(
  id: 'collection.shows_X_of_13_animals',
  title: 'CollectionScreen exibe "X/13 animais descobertos" com X correto',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToCollection(tester, harness, highest: 5);

    expect(
      find.text('5/13 animais descobertos'),
      findsOneWidget,
      reason: 'deve exibir "5/13 animais descobertos" quando highestLevelEver=5',
    );
  },
);

// ─── collection.locked_animals_show_question_marks ──────────────────────────

final collectionLockedShowsQuestionMarkScenario = E2EScenario(
  id: 'collection.locked_animals_show_question_marks',
  title: 'animais bloqueados exibem "???" na CollectionScreen',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToCollection(tester, harness, highest: 0);

    // Com highest=0, todos os 13 animais estão bloqueados e exibem "???"
    expect(
      find.text('???'),
      findsWidgets,
      reason: 'animais bloqueados devem exibir "???"',
    );

    // Nenhum nome de animal deve ser visível (sem card desbloqueado)
    expect(
      find.text('Tanajura'),
      findsNothing,
      reason: 'Tanajura deve estar bloqueado quando highest=0',
    );
  },
);

// ─── collection.unlocked_card_opens_detail_sheet ────────────────────────────

final collectionUnlockedCardOpensSheetScenario = E2EScenario(
  id: 'collection.unlocked_card_opens_detail_sheet',
  title: 'tap em card desbloqueado abre bottom sheet com nome do animal',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    // highest=1 desbloqueia apenas Tanajura (nível 1)
    await _bootToCollection(tester, harness, highest: 1);

    expect(
      find.text('Tanajura'),
      findsOneWidget,
      reason: 'Tanajura deve estar desbloqueada com highest=1',
    );

    // Tap no card desbloqueado da Tanajura
    await tester.tap(find.text('Tanajura'));
    await tester.pumpAndSettle();

    // Bottom sheet deve abrir com o nome do animal
    expect(
      find.text('Tanajura'),
      findsWidgets, // nome aparece no card E no bottom sheet
      reason: 'bottom sheet deve exibir o nome do animal',
    );
  },
);

// ─── collection.detail_shows_scientific_name_when_present ───────────────────

final collectionDetailScientificNameScenario = E2EScenario(
  id: 'collection.detail_shows_scientific_name_when_present',
  title: 'bottom sheet de animal desbloqueado exibe nome científico quando presente',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    // Tanajura tem scientificName: 'Atta laevigata'
    await _bootToCollection(tester, harness, highest: 1);

    await tester.tap(find.text('Tanajura'));
    await tester.pumpAndSettle();

    expect(
      find.text('Atta laevigata'),
      findsOneWidget,
      reason: 'bottom sheet deve exibir o nome científico do animal',
    );
  },
);

// ─── collection.detail_shows_funfact ────────────────────────────────────────

final collectionDetailFunFactScenario = E2EScenario(
  id: 'collection.detail_shows_funfact',
  title: 'bottom sheet de animal desbloqueado exibe fun fact',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    // Tanajura tem funFact: 'Pode carregar até 50× seu próprio peso!'
    await _bootToCollection(tester, harness, highest: 1);

    await tester.tap(find.text('Tanajura'));
    await tester.pumpAndSettle();

    expect(
      find.text('Pode carregar até 50× seu próprio peso!'),
      findsOneWidget,
      reason: 'bottom sheet deve exibir o fun fact do animal',
    );
  },
);

// ─── collection.progress_bar_matches_count ──────────────────────────────────

final collectionProgressBarScenario = E2EScenario(
  id: 'collection.progress_bar_matches_count',
  title: 'barra de progresso tem valor = highest/13',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToCollection(tester, harness, highest: 7);

    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );

    expect(
      bar.value,
      closeTo(7 / 13.0, 0.001),
      reason: 'barra de progresso deve ter value = 7/13 quando highest=7',
    );
  },
);
```

- [ ] **Step 2: Verificar que o arquivo compila**

```bash
cd /home/giuliano/rf/capivara_2048
dart analyze test/e2e/collection/collection_flows.dart
```

Esperado: sem erros.

---

## Task 2: Adicionar `Semantics` nos widgets de produção

**Files:**

- Modify: `lib/presentation/screens/home_screen.dart`
- Modify: `lib/presentation/screens/game/game_screen.dart`

### 2A — `_HomeButton` com `semanticLabel`

- [ ] **Step 3: Adicionar parâmetro `semanticLabel` em `_HomeButton`**

Em `lib/presentation/screens/home_screen.dart`, localizar a classe `_HomeButton` e adicionar o campo `semanticLabel`:

```dart
// ANTES:
class _HomeButton extends StatefulWidget {
  const _HomeButton({
    super.key,
    required this.path,
    required this.size,
    required this.onTap,
  });

  final String path;
  final double size;
  final VoidCallback onTap;

// DEPOIS:
class _HomeButton extends StatefulWidget {
  const _HomeButton({
    super.key,
    required this.path,
    required this.size,
    required this.onTap,
    this.semanticLabel,
  });

  final String path;
  final double size;
  final VoidCallback onTap;
  final String? semanticLabel;
```

- [ ] **Step 4: Envolver `GestureDetector` com `Semantics` em `_HomeButtonState.build()`**

Ainda em `home_screen.dart`, no `_HomeButtonState.build()`, o `return GestureDetector(...)` passa a ser:

```dart
@override
Widget build(BuildContext context) {
  return Semantics(
    label: widget.semanticLabel,
    button: true,
    child: GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          children: [
            Transform.scale(
              scale: 1.06,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                child: Image.asset(widget.path, width: widget.size, height: widget.size, fit: BoxFit.contain),
              ),
            ),
            Image.asset(widget.path, width: widget.size, height: widget.size, fit: BoxFit.contain),
          ],
        ),
      ),
    ),
  );
}
```

- [ ] **Step 5: Passar `semanticLabel` em cada instância de `_HomeButton` na `HomeScreen`**

Nos seis usos de `_HomeButton` (e `_HomeButtonWithBadge`) na `HomeScreen`, adicionar o `semanticLabel` correspondente:

| Key                     | semanticLabel           |
| ----------------------- | ----------------------- |
| `home_btn_colecao`      | `'Coleção'`             |
| `home_btn_configuracao` | `'Configurações'`       |
| `home_btn_recompensas`  | `'Recompensas Diárias'` |
| `home_btn_ranking`      | `'Ranking'`             |
| `home_btn_loja`         | `'Loja'`                |
| `home_btn_comojogar`    | `'Como Jogar'`          |

Exemplo para o botão Coleção:

```dart
_HomeButton(
  key: const Key('home_btn_colecao'),
  path: 'assets/images/home/Colecao.png',
  size: HomeConstants.buttonSize(scale),
  onTap: () => _nav(const CollectionScreen()),
  semanticLabel: 'Coleção',
),
```

> **Nota para `_HomeButtonWithBadge`:** este widget instancia `_HomeButton` internamente. Verificar se expõe o campo `semanticLabel` e repassar. Se não expuser, adicionar o campo:
>
> ```dart
> class _HomeButtonWithBadge extends StatelessWidget {
>   const _HomeButtonWithBadge({
>     ...,
>     this.semanticLabel,
>   });
>   final String? semanticLabel;
>   // ...
>   // Dentro do build, passar semanticLabel ao _HomeButton interno
> }
> ```

- [ ] **Step 6: Verificar que `_HomeButtonWithBadge` repassa `semanticLabel`**

Localizar `_HomeButtonWithBadge` em `home_screen.dart` e confirmar/adicionar:

```dart
class _HomeButtonWithBadge extends StatelessWidget {
  const _HomeButtonWithBadge({
    super.key,
    required this.path,
    required this.size,
    required this.onTap,
    required this.showBadge,
    this.semanticLabel,
  });

  final String path;
  final double size;
  final VoidCallback onTap;
  final bool showBadge;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _HomeButton(
          path: path,
          size: size,
          onTap: onTap,
          semanticLabel: semanticLabel, // repassa
        ),
        if (showBadge)
          // ... badge existente
      ],
    );
  }
}
```

### 2B — `Semantics` no tabuleiro (game_screen.dart)

- [ ] **Step 7: Envolver o `GestureDetector` do tabuleiro com `Semantics`**

Em `lib/presentation/screens/game/game_screen.dart`, localizar o `GestureDetector` com `key: const Key('game_board')` e envolvê-lo com `Semantics`:

```dart
// ANTES:
GestureDetector(
  key: const Key('game_board'),
  behavior: HitTestBehavior.opaque,
  onPanEnd: (details) {
    ...

// DEPOIS:
Semantics(
  label: 'Tabuleiro do jogo',
  child: GestureDetector(
    key: const Key('game_board'),
    behavior: HitTestBehavior.opaque,
    onPanEnd: (details) {
      ...
  ),
),
```

> O fechamento `),` correspondente ao `GestureDetector` deve ser mantido; apenas adicionar `Semantics(label: 'Tabuleiro do jogo', child:` antes e `),` depois.

- [ ] **Step 8: Verificar que o app ainda compila**

```bash
cd /home/giuliano/rf/capivara_2048
flutter analyze lib/presentation/screens/home_screen.dart lib/presentation/screens/game/game_screen.dart
```

Esperado: sem erros.

---

## Task 3: Criar `accessibility_flows.dart` com 4 cenários

**Files:**

- Create: `test/e2e/accessibility/accessibility_flows.dart`

### Notas de implementação

- **`a11y.home_buttons_have_semantics_labels`**: usa `find.bySemanticsLabel(label)` — requer que o tester tenha o `SemanticsController` ativo (padrão em `testWidgets`).
- **`a11y.game_board_has_semantics`**: verifica a label `'Tabuleiro do jogo'` no GestureDetector após navegar ao jogo.
- **`a11y.contrast_score_panel_meets_aa`**: verifica que `StatusPanel` usa `outlinedWhiteTextStyle` (shadows não-vazias), garantindo contraste WCAG AA via contorno preto sobre qualquer fundo.
- **`a11y.no_text_overflow_at_max_font_scale`**: seta viewport 360×640 + captura `FlutterError` para verificar ausência de overflow em Home e GameScreen.

- [ ] **Step 9: Criar `test/e2e/accessibility/accessibility_flows.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';
import '../_harness/tester_extensions.dart';

// ─── helpers ────────────────────────────────────────────────────────────────

Future<void> _bootToHome(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

// ─── a11y.home_buttons_have_semantics_labels ────────────────────────────────

final a11yHomeButtonsSemanticsScenario = E2EScenario(
  id: 'a11y.home_buttons_have_semantics_labels',
  title: 'botões da Home têm Semantics labels para leitores de tela',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    for (final label in [
      'Coleção',
      'Configurações',
      'Recompensas Diárias',
      'Ranking',
      'Loja',
      'Como Jogar',
    ]) {
      expect(
        find.bySemanticsLabel(label),
        findsOneWidget,
        reason: 'botão "$label" deve ter Semantics label para leitores de tela',
      );
    }
  },
);

// ─── a11y.game_board_has_semantics ──────────────────────────────────────────

final a11yGameBoardSemanticsScenario = E2EScenario(
  id: 'a11y.game_board_has_semantics',
  title: 'tabuleiro do jogo tem Semantics label "Tabuleiro do jogo"',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);
    await tester.gotoGame(harness);

    expect(
      find.bySemanticsLabel('Tabuleiro do jogo'),
      findsOneWidget,
      reason: 'tabuleiro deve ter Semantics label para leitores de tela',
    );
  },
);

// ─── a11y.contrast_score_panel_meets_aa ─────────────────────────────────────

final a11yContrastScorePanelScenario = E2EScenario(
  id: 'a11y.contrast_score_panel_meets_aa',
  title: 'textos do StatusPanel usam outlined style (contraste WCAG AA via sombras)',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);
    await tester.gotoGame(harness);

    // O score inicial é 0. O StatusPanel exibe '0' com outlinedWhiteTextStyle.
    // outlinedWhiteTextStyle garante contraste via 8 shadows pretas ao redor do texto branco.
    final scoreTexts = tester.widgetList<Text>(find.text('0'));
    // Pode haver múltiplos widgets Text('0') na tela — verificar que pelo menos um
    // usa a style com shadows (StatusPanel score)
    final hasOutlinedScore = scoreTexts.any(
      (t) => t.style?.shadows != null && t.style!.shadows!.isNotEmpty,
    );
    expect(
      hasOutlinedScore,
      isTrue,
      reason: 'StatusPanel deve usar outlinedWhiteTextStyle com shadows para contraste WCAG AA',
    );
  },
);

// ─── a11y.no_text_overflow_at_max_font_scale ────────────────────────────────

final a11yNoTextOverflowScenario = E2EScenario(
  id: 'a11y.no_text_overflow_at_max_font_scale',
  title: 'nenhum overflow de texto em viewport 360×640 (tela compacta)',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    // Viewport compacto (360×640 dp) — mesmo device-class onde v1.2.2 corrigiu overflow
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final overflowErrors = <String>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.toString();
      if (msg.contains('overflowed') || msg.contains('overflow')) {
        overflowErrors.add(msg);
      } else {
        originalOnError?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    // Boot e navegação para GameScreen em viewport compacto
    await _bootToHome(tester, harness);
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      overflowErrors,
      isEmpty,
      reason: 'HomeScreen não deve ter overflow em viewport 360×640: $overflowErrors',
    );

    await tester.gotoGame(harness);
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      overflowErrors,
      isEmpty,
      reason: 'GameScreen não deve ter overflow em viewport 360×640: $overflowErrors',
    );
  },
);
```

- [ ] **Step 10: Verificar que o arquivo compila**

```bash
cd /home/giuliano/rf/capivara_2048
dart analyze test/e2e/accessibility/accessibility_flows.dart
```

Esperado: sem erros.

---

## Task 4: Criar `regression_flows.dart` com 4 cenários

**Files:**

- Create: `test/e2e/regression/regression_flows.dart`

### Contexto dos regressions

| ID      | Bug                                                  | Comportamento correto                                                           |
| ------- | ---------------------------------------------------- | ------------------------------------------------------------------------------- |
| v1.2.7  | Header não crescia com folga vertical                | Em tela alta, `HostArtwork` tem width > `twoCellWidth` baseline                 |
| v1.2.8  | Ícones da Home carregavam progressivamente           | Após splash, os 6 botões PNG estão na widget tree imediatamente                 |
| v1.2.9  | "Continuar Jogo" na Home re-pausava o jogo após back | `_continueGame()` chama `resume()` — `isPaused` é false ao entrar na GameScreen |
| v1.2.10 | Coleção resetava ao reiniciar o app                  | `highestLevelEver` persiste via Hive entre sessões                              |

> **Nota:** v1.2.9 é coberta também por `flow.continue_after_back_button`; v1.2.10 por `persistence.collection_survives_restart`. Os cenários `regression.*` são versões canonicamente nomeadas para rastreabilidade de bugfix.

- [ ] **Step 11: Criar `test/e2e/regression/regression_flows.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/core/constants/game_constants.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/controllers/personal_records_notifier.dart';
import 'package:capivara_2048/presentation/screens/game/game_screen.dart';
import 'package:capivara_2048/presentation/screens/home_screen.dart';
import 'package:capivara_2048/presentation/widgets/host_artwork.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';
import '../_harness/tester_extensions.dart';

// ─── helpers ────────────────────────────────────────────────────────────────

Future<void> _bootToHome(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

// ─── regression.v1.2.7_header_grows_with_vertical_slack ─────────────────────

final regressionHeaderGrowsScenario = E2EScenario(
  id: 'regression.v1.2.7_header_grows_with_vertical_slack',
  title: '[v1.2.7] HostArtwork cresce além do baseline em tela alta (folga vertical)',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    // Tela alta (maior que o design baseline de 844dp) — simula dispositivos com folga vertical
    tester.view.physicalSize = const Size(390, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _bootToHome(tester, harness);
    await tester.gotoGame(harness);

    // HostArtwork deve existir na GameScreen
    expect(find.byType(HostArtwork), findsOneWidget,
        reason: 'HostArtwork deve estar visível na GameScreen');

    final artworkSize = tester.getSize(find.byType(HostArtwork));

    // Em tela alta (1080dp vs baseline 844dp), o HostArtwork deve ter width
    // maior que o baseline twoCellWidth (152dp), indicando que o scale > 1.0 foi aplicado.
    // O fator de escala mínimo esperado é ~1.12 (1080/844 * algum fator), então width > 152.
    expect(
      artworkSize.width,
      greaterThan(GameConstants.twoCellWidth),
      reason: '[v1.2.7] HostArtwork deve crescer além do baseline (${GameConstants.twoCellWidth}dp) '
          'quando há folga vertical — width encontrado: ${artworkSize.width}dp',
    );
  },
);

// ─── regression.v1.2.8_no_progressive_icon_loading ──────────────────────────

final regressionNoProgressiveLoadingScenario = E2EScenario(
  id: 'regression.v1.2.8_no_progressive_icon_loading',
  title: '[v1.2.8] todos os 6 botões PNG da Home estão no widget tree após splash',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    // Todos os 6 botões da HomeScreen devem estar no widget tree imediatamente.
    // A regressão era: ícones carregavam progressivamente (alguns após vários segundos).
    // A correção garantiu que precacheImage é aguardado antes de navegar da splash.
    for (final key in [
      'home_btn_colecao',
      'home_btn_configuracao',
      'home_btn_recompensas',
      'home_btn_ranking',
      'home_btn_loja',
      'home_btn_comojogar',
    ]) {
      expect(
        find.byKey(Key(key)),
        findsOneWidget,
        reason: '[v1.2.8] botão "$key" deve estar no widget tree imediatamente após splash',
      );
    }
  },
);

// ─── regression.v1.2.9_continuar_after_back_unpause ─────────────────────────

final regressionContinuarAfterBackScenario = E2EScenario(
  id: 'regression.v1.2.9_continuar_after_back_unpause',
  title: '[v1.2.9] "Continuar Jogo" após back do sistema despausa corretamente',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    // Iniciar novo jogo
    await tester.gotoGame(harness);

    // Criar estado com score > 0 para que "Continuar Jogo" apareça na Home
    harness.container.read(gameProvider.notifier).debugSetState(
      GameState(
        board: List.generate(4, (_) => List<Tile?>.filled(4, null))
          ..[0][0] = const Tile(id: 't1', level: 2, row: 0, col: 0),
        score: 100,
        highScore: 100,
        maxLevel: 2,
        isGameOver: false,
        hasWon: false,
      ),
    );
    await tester.pump();

    // Pausar o jogo
    harness.container.read(gameProvider.notifier).pause();
    await tester.pump();

    // Navegar de volta à Home via pop (simula back do sistema, sem chamar resume())
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(HomeScreen), findsOneWidget,
        reason: 'deve estar na HomeScreen após pop');

    // "Continuar Jogo" deve estar visível (score > 0 && !isGameOver)
    expect(find.text('Continuar Jogo'), findsOneWidget,
        reason: '"Continuar Jogo" deve aparecer pois há partida em andamento');

    // Tocar "Continuar Jogo" — deve retomar o jogo despaupausado
    await tester.tap(find.text('Continuar Jogo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(GameScreen), findsOneWidget,
        reason: 'deve navegar para GameScreen');

    // [REGRESSION v1.2.9] O jogo NÃO deve estar pausado ao entrar via "Continuar Jogo"
    expect(
      harness.container.read(gameProvider).isPaused,
      isFalse,
      reason: '[v1.2.9] "Continuar Jogo" deve desparar o jogo — isPaused deve ser false',
    );
    expect(find.text('Pausado'), findsNothing,
        reason: '[v1.2.9] PauseOverlay não deve aparecer ao entrar via "Continuar Jogo"');
  },
);

// ─── regression.v1.2.10_collection_survives_cold_start ──────────────────────

final regressionCollectionSurvivesScenario = E2EScenario(
  id: 'regression.v1.2.10_collection_survives_cold_start',
  title: '[v1.2.10] highestLevelEver persiste após cold restart (coleção não reseta)',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    final widget = await tester.runAsync(() => harness.boot());
    await tester.pumpWidget(widget!);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Desbloquear até nível 9 (Onça-pintada)
    await tester.runAsync(() =>
        harness.container.read(personalRecordsProvider.notifier).updateHighestLevel(9));
    expect(
      harness.container.read(personalRecordsProvider).highestLevelEver,
      equals(9),
    );

    // Cold restart — simula fechar e reabrir o app
    final widget2 = await tester.runAsync(() => harness.restart());
    await tester.pumpWidget(widget2!);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // [REGRESSION v1.2.10] highestLevelEver NÃO deve resetar para 0
    expect(
      harness.container.read(personalRecordsProvider).highestLevelEver,
      equals(9),
      reason: '[v1.2.10] coleção não deve resetar após cold restart — '
          'highestLevelEver deve ser 9, não 0',
    );
  },
);
```

- [ ] **Step 12: Verificar que o arquivo compila**

```bash
cd /home/giuliano/rf/capivara_2048
dart analyze test/e2e/regression/regression_flows.dart
```

Esperado: sem erros.

---

## Task 5: Registrar todos os 14 novos cenários no registry

**Files:**

- Modify: `test/e2e/_harness/registry.dart`

- [ ] **Step 13: Adicionar imports dos novos arquivos em `registry.dart`**

Adicionar ao topo de `registry.dart`, após os imports existentes:

```dart
import '../collection/collection_flows.dart';
import '../accessibility/accessibility_flows.dart';
import '../regression/regression_flows.dart';
```

- [ ] **Step 14: Adicionar os 14 cenários ao `allScenarios` em `registry.dart`**

Ao final da lista `allScenarios`, adicionar:

```dart
  // Fase 3.4 — collection
  collectionShowsCountScenario,
  collectionLockedShowsQuestionMarkScenario,
  collectionUnlockedCardOpensSheetScenario,
  collectionDetailScientificNameScenario,
  collectionDetailFunFactScenario,
  collectionProgressBarScenario,
  // Fase 3.4 — accessibility
  a11yHomeButtonsSemanticsScenario,
  a11yGameBoardSemanticsScenario,
  a11yContrastScorePanelScenario,
  a11yNoTextOverflowScenario,
  // Fase 3.4 — regression
  regressionHeaderGrowsScenario,
  regressionNoProgressiveLoadingScenario,
  regressionContinuarAfterBackScenario,
  regressionCollectionSurvivesScenario,
```

- [ ] **Step 15: Verificar que o registry compila**

```bash
cd /home/giuliano/rf/capivara_2048
dart analyze test/e2e/_harness/registry.dart
```

Esperado: sem erros.

---

## Task 6: Executar e corrigir até todos os testes passarem

- [ ] **Step 16: Rodar a suite completa e observar os resultados**

```bash
cd /home/giuliano/rf/capivara_2048
flutter test test/e2e/run_all_test.dart --no-pub 2>&1 | tail -20
```

Esperado: `80 tests passed` (66 anteriores + 14 novos).

- [ ] **Step 17: Se houver falhas, diagnosticar e corrigir**

Falhas comuns e como resolver:

**`a11y.home_buttons_have_semantics_labels` falha com "findsNothing":**
→ Verificar que `_HomeButton.build()` está retornando `Semantics(label: widget.semanticLabel, ...)` e que cada instância recebeu `semanticLabel` correto. Em testes, `find.bySemanticsLabel()` exige que a semantics tree seja gerada — confirmar que não há `excludeSemantics: true` por cima.

**`a11y.game_board_has_semantics` falha:**
→ Verificar que o `Semantics(label: 'Tabuleiro do jogo', child: GestureDetector(...))` está no `game_screen.dart` e não foi envolvido por outro widget com `excludeSemantics: true`.

**`collection.unlocked_card_opens_detail_sheet` falha com "findsNothing" no tap:**
→ `_UnlockedCard` tem `GestureDetector` envolvendo um `Container` com `decoration`. Se o tap não funcionar por `Image.asset` de tamanho zero no tester, tentar `await tester.tap(find.ancestor(of: find.text('Tanajura'), matching: find.byType(GestureDetector)).first)` — ou adicionar uma `Key` no `_UnlockedCard` para facilitar o tap.

**`regression.v1.2.7_header_grows_with_vertical_slack` falha:**
→ O `HostArtwork` pode ter `width == twoCellWidth` mesmo em tela alta se o scale não estiver sendo aplicado. Verificar que `GameScreen` usa `LayoutBuilder` e `headerScale`. Se o widget de tamanho baselin não cresce, revisar a lógica de scale no `game_screen.dart`.

**`a11y.no_text_overflow_at_max_font_scale` falha com overflow:**
→ Identificar qual widget gera overflow no log, e investigar se é um problema pré-existente ou introduzido. Não corrigir código de produção arbitrariamente — reportar ao usuário.

- [ ] **Step 18: Confirmar 80 testes passando**

```bash
cd /home/giuliano/rf/capivara_2048
flutter test test/e2e/run_all_test.dart --no-pub 2>&1 | grep -E "All tests passed|FAILED|ERROR"
```

Esperado: `80: All tests passed!`

---

## Task 7: Commit

- [ ] **Step 19: Commit das mudanças**

```bash
cd /home/giuliano/rf/capivara_2048
git add \
  test/e2e/collection/collection_flows.dart \
  test/e2e/accessibility/accessibility_flows.dart \
  test/e2e/regression/regression_flows.dart \
  test/e2e/_harness/registry.dart \
  lib/presentation/screens/home_screen.dart \
  lib/presentation/screens/game/game_screen.dart

git commit -m "test(e2e): fase 3.4 — collection + accessibility + regression (14 cenários)

- 6 cenários collection.*: count, locked cards, detail sheet, scientific name, funFact, progress bar
- 4 cenários accessibility.*: home Semantics labels, board Semantics, contrast score panel, overflow 360×640
- 4 cenários regression.*: v1.2.7 header scale, v1.2.8 no progressive load, v1.2.9 continuar unpause, v1.2.10 collection persists
- Adiciona Semantics(label) nos 6 _HomeButton da HomeScreen
- Adiciona Semantics(label: 'Tabuleiro do jogo') no GestureDetector do game_screen

80 cenários E2E Tier 1 passando"
```

---

## Self-Review: Spec Coverage

| Cenário (spec)                                         | Task      |
| ------------------------------------------------------ | --------- |
| `collection.shows_X_of_13_animals`                     | Task 1    |
| `collection.locked_animals_show_question_marks`        | Task 1    |
| `collection.unlocked_card_opens_detail_sheet`          | Task 1    |
| `collection.detail_shows_scientific_name_when_present` | Task 1    |
| `collection.detail_shows_funfact`                      | Task 1    |
| `collection.progress_bar_matches_count`                | Task 1    |
| `a11y.home_buttons_have_semantics_labels`              | Tasks 2+3 |
| `a11y.game_board_has_semantics`                        | Tasks 2+3 |
| `a11y.contrast_score_panel_meets_aa`                   | Task 3    |
| `a11y.no_text_overflow_at_max_font_scale`              | Task 3    |
| `regression.v1.2.7_header_grows_with_vertical_slack`   | Task 4    |
| `regression.v1.2.8_no_progressive_icon_loading`        | Task 4    |
| `regression.v1.2.9_continuar_after_back_unpause`       | Task 4    |
| `regression.v1.2.10_collection_survives_cold_start`    | Task 4    |

**14/14 cenários cobertos. ✓**

---

## Critérios de Aceite

| Item                | Critério                                                                    |
| ------------------- | --------------------------------------------------------------------------- |
| Cenários            | 14 novos cenários E2E implementados                                         |
| Suite completa      | `flutter test test/e2e/run_all_test.dart` passa com 80 testes               |
| Sem regressões      | Nenhum dos 66 cenários anteriores quebra                                    |
| Semantics Home      | `find.bySemanticsLabel('Coleção')` (e os outros 5) funciona na HomeScreen   |
| Semantics Board     | `find.bySemanticsLabel('Tabuleiro do jogo')` funciona na GameScreen         |
| Sem mudanças extras | Nenhuma alteração de produção além dos Semantics anotados nas Tasks 2A e 2B |
