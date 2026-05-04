# E2E Test Framework — Design Doc

**Data:** 2026-05-04
**Versão alvo:** v1.3.0
**Status:** Design aprovado · pendente de implementação

## Motivação

O projeto tem **340 unit/widget tests** passando, com cobertura forte em:
- Game engine puro (`domain/game_engine/`)
- Telas isoladas (`presentation/screens/*_test.dart`)
- Notifiers (Hive round-trip, lógica de inventário, vidas)

**Lacuna identificada:** não há cobertura de:
1. Fluxos completos atravessando múltiplas telas + providers + persistência
2. Validação visual/posicional (golden snapshots em diferentes viewports)
3. Comportamento real do engine de animações (gestos reais, timing)
4. Persistência real entre sessões ("fechar e reabrir o app")

Bugs recentes (v1.2.8, v1.2.9, v1.2.10) seriam capturados por testes desse nível antes de chegar ao usuário.

## Objetivo

Criar um framework de testes funcionais (e2e) com **duas camadas**:

- **Tier 1 (headless, primário):** roda com `flutter test` em qualquer máquina, sem device, em segundos. Usa `WidgetTester` e bootstrapa a árvore raiz `CapivaraApp`.
- **Tier 2 (device real, secundário):** APK distribuível com **TestRunnerScreen** visual — instala no celular, abre, vê os testes rodarem ao vivo na tela. Inclui Share button e Demo mode.

**Princípio:** uma única fonte de cenários (`allScenarios`), dois runners diferentes que consomem essa lista.

## Arquitetura

### Estrutura de diretórios

```
test/
├── unit/                          # já existe
├── widget/                        # já existe (renomear se necessário)
└── e2e/                           # NOVO
    ├── _harness/
    │   ├── test_harness.dart      # GameTestHarness (boot/restart/teardown)
    │   ├── tester_extensions.dart # swipeBoard, tapByKey, gameState, etc.
    │   ├── scenario.dart          # E2EScenario class + tags enum
    │   └── registry.dart          # allScenarios = [...]
    ├── flows/
    │   ├── play_a_game.dart
    │   ├── continue_after_pause.dart
    │   └── ... (21 cenários)
    ├── engine/                    # 11 cenários
    ├── items/                     # 9 cenários
    ├── nav/                       # 9 cenários
    ├── collection/                # 6 cenários
    ├── persistence/               # 9 cenários
    ├── pause/                     # 6 cenários
    ├── daily/                     # 4 cenários
    ├── settings/                  # 4 cenários
    ├── golden/                    # 15 cenários (5 telas × 3 viewports)
    ├── accessibility/             # 4 cenários
    ├── regression/                # 4+ cenários (cresce a cada bugfix)
    └── run_all_test.dart          # entry point Tier 1

integration_test/                  # NOVO — Tier 2
├── runner_entry.dart              # main que roda TestRunnerApp
└── tier2_only/                    # cenários exclusivos do device real
    └── ...

lib/
└── main_test.dart                 # NOVO — entry alternativo (flavor test)
```

### Componentes principais

#### `E2EScenario`

```dart
enum ScenarioTag { critical, slow, demo, tier1_only, tier2_only, golden }

class E2EScenario {
  final String id;          // ex: 'flow.play_a_game'
  final String title;
  final Set<ScenarioTag> tags;
  final Future<void> Function(WidgetTester, GameTestHarness) run;

  const E2EScenario({
    required this.id,
    required this.title,
    required this.tags,
    required this.run,
  });
}
```

#### `GameTestHarness`

```dart
class GameTestHarness {
  late ProviderContainer container;
  late Directory tempDir;

  /// Bootstrap completo com Hive em diretório temp + SharedPrefs mock.
  Future<Widget> boot({
    GameState? initialGameState,
    Inventory? initialInventory,
    PersonalRecords? initialRecords,
    DailyRewardsState? initialDaily,
    LivesState? initialLives,
  });

  /// Cold restart: dispose container, mantém Hive em disco.
  Future<Widget> restart();

  /// Limpa tudo (Hive + temp dir).
  Future<void> teardown();
}
```

#### `WidgetTester` extensions (semantic helpers)

| Helper | Implementação |
|---|---|
| `tapByKey(String key)` | `tap(find.byKey(Key(key)))` + pumpAndSettle |
| `swipeBoard(Direction)` | drag na área do `BoardWidget` |
| `tapTile(int row, int col)` | tap na célula específica |
| `useItem(ItemType)` | tap no botão do inventário |
| `gotoScreen(ScreenId)` | navega via Home |
| `gameState` | `container.read(gameProvider)` |
| `forceWin([level])` | manipula engine direto (para testes que precisam do estado pós-vitória sem jogar 200 movimentos) |
| `forceGameOver()` | enche o tabuleiro até travar |
| `triggerColdRestart()` | dispose + re-boot mantendo Hive |

#### Registry único

```dart
// test/e2e/_harness/registry.dart
final List<E2EScenario> allScenarios = [
  ...flowScenarios,
  ...engineScenarios,
  ...itemsScenarios,
  ...navScenarios,
  ...collectionScenarios,
  ...persistenceScenarios,
  ...pauseScenarios,
  ...dailyScenarios,
  ...settingsScenarios,
  ...goldenScenarios,
  ...accessibilityScenarios,
  ...regressionScenarios,
];
```

### Tier 1 — Headless runner

```dart
// test/e2e/run_all_test.dart
void main() {
  for (final s in allScenarios.where((s) =>
      !s.tags.contains(ScenarioTag.tier2_only))) {
    testWidgets(s.title, (tester) async {
      final h = GameTestHarness();
      addTearDown(h.teardown);
      await s.run(tester, h);
    });
  }
}
```

Roda com `flutter test test/e2e/run_all_test.dart` em qualquer máquina.

### Tier 2 — APK com TestRunnerScreen

#### Build

```bash
flutter build apk --target=lib/main_test.dart --flavor test --release
```

Produz `app-test-release.apk` com:
- `applicationIdSuffix .test` → instala em paralelo ao app real
- Ícone amarelo "Bichim TEST"
- Entry point `TestRunnerApp` em vez de `CapivaraApp`

#### TestRunnerScreen — UX

```
┌────────────────────────────────────┐
│ Bichim — Test Suite        ⋮ menu  │
│ ┌────────────────────────────────┐ │
│ │ ▶ Run all  ⟳ Run failed  ⏸ Stop│ │
│ │ Filter: [critical ▾]            │ │
│ └────────────────────────────────┘ │
│ ▶ flow (12)            ✓10 ✗1 ⏸1   │
│   ✓ play_a_game            0.42s   │
│   ✗ shop_purchase_undo     1.10s ▾ │
│      [stack trace expandida]       │
│   ⟳ continue_resumes_game          │
│ ▶ persistence (8)      ✓8 ✗0       │
│ ▶ golden (15)          ✓14 ✗1 ▾    │
│   ✗ home_360x640                   │
│   [diff visual: esperado | atual]  │
│ ─────────────────────────────────  │
│ 38/52 ✓ · 2 ✗ · 12 ⏸ · 14.3s        │
│ [📤 Compartilhar]  [🎬 Modo Demo]   │
└────────────────────────────────────┘
```

- ✓ verde / ✗ vermelho / ⟳ rodando / ○ pendente
- Lista agrupada por categoria (expand/collapse)
- Tap em teste falhado → expande stack trace + screenshot do estado final
- Tap em teste passado → mostra duração e asserções

#### Share button (📤)

Usa `share_plus` para abrir o Android share sheet com:
1. **PNG resumo** (print da tela do runner com totais)
2. **JSON detalhado:**
```json
{
  "build": "1.3.0+1",
  "device": "sdk_gphone64_x86_64 (Android 15)",
  "totals": {"passed": 38, "failed": 2, "skipped": 12, "duration_s": 14.3},
  "results": [
    {"id": "flow.play_a_game", "status": "passed", "ms": 420},
    {"id": "flow.shop_purchase_undo", "status": "failed", "ms": 1100,
     "error": "...", "stack": "..."}
  ]
}
```

User pode compartilhar via WhatsApp, e-mail, Telegram, etc. — sem cabo, sem adb, sem logcat.

#### Demo mode (🎬)

- Filtra cenários com tag `demo` (subset visualmente atrativo)
- Pula `expect()` — só executa as ações
- Loop infinito com `pumpAndSettle` reduzido pra fluidez
- Botão flutuante "⏹ Parar" durante o demo
- Uso: gravar screencast pra divulgação, demonstração presencial

## Cenários (catálogo completo)

**~110 cenários estimados, ~85 no Tier 1, ~5-8 exclusivos Tier 2.**

### `flow.*` — Fluxos completos (21)
1. `flow.smoke_boot` — app abre, splashscreen, Home
2. `flow.new_game_basic` — Home → Novo jogo → 5 movimentos válidos
3. `flow.continue_after_pause` (regressão v1.2.9)
4. `flow.continue_after_back_button` (regressão v1.2.9)
5. `flow.game_over_no_items` — modal correto
6. `flow.game_over_with_items` — overlay de oferta
7. `flow.use_undo_during_game`
8. `flow.use_bomb2_during_game`
9. `flow.use_bomb3_during_game`
10. `flow.shop_overlay_from_empty_inventory`
11. `flow.shop_purchase_item`
12. `flow.win_2048_first_time` — modal vitória + record
13. `flow.win_4096_first_time`
14. `flow.win_8192_first_time` — Capivara Lendária
15. `flow.continue_after_win`
16. `flow.daily_reward_claim`
17. `flow.daily_reward_locked_same_day`
18. `flow.lives_consumed_on_game_over`
19. `flow.no_lives_screen`
20. `flow.lives_regen_over_time`
21. `flow.full_session` (tier2_only)

### `engine.*` — Game engine (11)
22. `engine.swipe_up_merges_correctly`
23. `engine.swipe_down_merges_correctly`
24. `engine.swipe_left_merges_correctly`
25. `engine.swipe_right_merges_correctly`
26. `engine.no_op_swipe_doesnt_consume_turn`
27. `engine.score_accumulates`
28. `engine.high_score_updates_on_new_record`
29. `engine.tile_animation_smooth` (tier2_only)
30. `engine.merge_chain_correct`
31. `engine.spawn_only_after_valid_move`
32. `engine.gameover_when_no_moves_possible`

### `items.*` — Inventário (9)
33. `items.bomb2_requires_target_selection`
34. `items.bomb2_cancellable_with_back`
35. `items.bomb3_requires_target_selection`
36. `items.undo1_disabled_at_game_start`
37. `items.undo3_disabled_when_no_history`
38. `items.bomb_dim_overlay_appears`
39. `items.shop_purchase_decrements_currency`
40. `items.item_count_persists_across_sessions`
41. `items.empty_item_pulses_on_attempt`

### `nav.*` — Navegação (9)
42. `nav.home_to_collection`
43. `nav.home_to_settings`
44. `nav.home_to_ranking`
45. `nav.home_to_shop`
46. `nav.home_to_daily_rewards`
47. `nav.home_to_tutorial_bottomsheet`
48. `nav.collection_back_returns_home`
49. `nav.settings_back_returns_home`
50. `nav.android_back_from_each_screen`

### `collection.*` (6)
51. `collection.shows_X_of_13_animals`
52. `collection.locked_animals_show_question_marks`
53. `collection.unlocked_card_opens_detail_sheet`
54. `collection.detail_shows_scientific_name_when_present`
55. `collection.detail_shows_funfact`
56. `collection.progress_bar_matches_count`

### `persistence.*` — Cold restart (9)
57. `persistence.collection_survives_restart` (regressão v1.2.10)
58. `persistence.inventory_survives_restart`
59. `persistence.lives_survive_restart`
60. `persistence.daily_rewards_survive_restart`
61. `persistence.high_score_survives_restart`
62. `persistence.personal_records_survive_restart`
63. `persistence.settings_survive_restart`
64. `persistence.game_records_history_survives_restart`
65. `persistence.in_progress_game_survives_restart`

### `pause.*` (6)
66. `pause.tap_pause_button_shows_overlay`
67. `pause.continuar_resumes_game`
68. `pause.reiniciar_resets_game`
69. `pause.menu_returns_to_home_resumed`
70. `pause.system_back_keeps_paused_state`
71. `pause.game_doesnt_consume_time_while_paused`

### `daily.*` (4)
72. `daily.badge_visible_when_available`
73. `daily.badge_hidden_when_claimed`
74. `daily.cycle_resets_after_X_days`
75. `daily.streak_increments`

### `settings.*` (4)
76. `settings.toggle_reduce_effects_persists`
77. `settings.reduce_effects_disables_blur_in_pause`
78. `settings.toggle_haptics_persists`
79. `settings.language_pt_br_default`

### `golden.*` — Visual snapshots (15)
80–94. Para cada tela em **360×640**, **414×894**, **800×1280**:
- `golden.home_<W>x<H>`
- `golden.game_<W>x<H>`
- `golden.pause_overlay_<W>x<H>`
- `golden.collection_<W>x<H>`
- `golden.daily_<W>x<H>`

### `accessibility.*` (4)
95. `a11y.home_buttons_have_semantics_labels`
96. `a11y.game_board_has_semantics`
97. `a11y.contrast_score_panel_meets_aa`
98. `a11y.no_text_overflow_at_max_font_scale`

### `regression.*` (4+, cresce a cada bugfix)
99. `regression.v1.2.7_header_grows_with_vertical_slack`
100. `regression.v1.2.8_no_progressive_icon_loading`
101. `regression.v1.2.9_continuar_after_back_unpause`
102. `regression.v1.2.10_collection_survives_cold_start`

### Demo subset (tag adicional)
Reusa cenários marcados também com `demo`:
- `flow.new_game_basic`
- `flow.win_2048_first_time`
- `flow.shop_purchase_item`
- `nav.home_to_collection`
- `engine.swipe_*`

## Dependencies novas

- `integration_test` (SDK Flutter, sem custo)
- `share_plus` (~50KB) — share sheet do Android
- `golden_toolkit` ou `alchemist` — golden tests determinísticos cross-platform
- `path_provider` (já existe) — gravar JSON em `/sdcard/Download/`

## Pasta `golden_toolkit` vs `alchemist`

- **`golden_toolkit`** (Maintained by eBay): mais maduro, ampla adoção, configura device profiles facilmente.
- **`alchemist`** (Betterment): mais novo, suporta golden tests CI-friendly por padrão (gera goldens "fonteless" pra evitar diff de fonte cross-platform).

**Recomendação:** `alchemist` — porque rodar headless em CI com fontes determinísticas é exatamente o caso d'uso prioritário (Tier 1, requisito D do user).

## Build flavor

```kotlin
// android/app/build.gradle
android {
    flavorDimensions += "environment"
    productFlavors {
        create("prod") { dimension = "environment" }
        create("test") {
            dimension = "environment"
            applicationIdSuffix = ".test"
            resValue("string", "app_name", "Bichim TEST")
        }
    }
}
```

## Estratégia de implementação (fases)

| Fase | Escopo | Duração estimada |
|---|---|---|
| **3.0** | Harness + scenario class + registry vazio + 5 smoke tests | 1 dia |
| **3.1** | `flow.*` (21 cenários) + helpers semânticos completos | 2 dias |
| **3.2** | `engine.*` + `items.*` + `nav.*` (29 cenários) | 2 dias |
| **3.3** | `persistence.*` + `pause.*` + `daily.*` + `settings.*` (23 cenários) | 1.5 dias |
| **3.4** | `collection.*` + `accessibility.*` + `regression.*` (14 cenários) | 1 dia |
| **3.5** | `golden.*` com `alchemist` (15 cenários × 3 viewports) | 1.5 dias |
| **3.6** | Tier 2: `main_test.dart` + flavor + TestRunnerScreen + Share + Demo | 2-3 dias |
| **3.7** | CI workflow GitHub Actions (Tier 1 a cada PR) | 0.5 dia |
| **3.8** | Documentação (README de testes, como rodar, como adicionar cenário) | 0.5 dia |

**Total estimado: ~12-14 dias de trabalho.**

## Critérios de sucesso

1. ✅ `flutter test test/e2e/` roda sem device em <60s
2. ✅ Suite Tier 1 captura todas as regressões da v1.2.7→v1.2.10 (validado adicionando os 4 cenários `regression.*` antes do fix retroativamente passar)
3. ✅ APK Tier 2 instalável em paralelo ao app real, mostra resultado visual em 1 toque
4. ✅ Share button gera JSON + PNG compartilháveis sem cabo
5. ✅ Demo mode roda em loop visualmente atrativo
6. ✅ CI no GitHub Actions verde a cada PR rodando Tier 1
7. ✅ Adicionar um novo cenário leva <5 min (boilerplate mínimo)

## Riscos & mitigações

| Risco | Mitigação |
|---|---|
| Golden tests flaky por diff de fonte cross-platform | Usar `alchemist` (CI mode com fonte fonteless) |
| Tier 1 muito lento (>60s) | Paralelizar com `flutter test --concurrency=N`; medir e otimizar harness |
| TestRunnerScreen UI esquentar device em loops longos | Throttle entre cenários (200ms); limite de tempo total no Demo mode |
| Tier 2 APK conflitando com app real | `applicationIdSuffix .test` resolve |
| Cenários `tier2_only` quebrando em devices com tela diferente | Documentar device alvo; tolerância configurável em assertions de pixel |
| Manutenção: cenários quebram a cada UI tweak | Helpers semânticos (`tapByKey`) em vez de `find.text` + IDs estáveis |

## Fora de escopo (YAGNI)

- ❌ `patrol` (overkill — não testa permissões/notificações no jogo)
- ❌ Testes de performance/profile (Fase 6)
- ❌ Testes de áudio (áudio entra na Fase 5; cenários de áudio entram quando o áudio existir)
- ❌ Multi-language: i18n é Fase 6; teste de PT-BR padrão é suficiente por enquanto
- ❌ Testes em iOS/Web (foco Android Fase 3; iOS/Web entram com a Fase 6)

## Próximos passos

1. **Aprovação final do design** ✅
2. **Setup branch + worktree** para implementação isolada
3. **Plano de implementação detalhado** (`/skill:writing-plans`) quebrando Fases 3.0-3.8 em tarefas verificáveis
4. **Execução** seguindo TDD: cada cenário passa de "skip" → "fail" → "pass" antes de mover pro próximo
