# Guia de Testes — Olha o Bichim!

> Fase 3 completa: E2E Test Framework com 95+ cenários, golden tests, APK Tier 2 e CI.

## Índice

1. [Visão geral](#visão-geral)
2. [Tier 1 — Headless (flutter test)](#tier-1--headless-flutter-test)
3. [Tier 2 — APK TestRunnerScreen](#tier-2--apk-testrunnerscreen)
4. [Golden Tests](#golden-tests)
5. [Adicionar um novo cenário](#adicionar-um-novo-cenário)
6. [Troubleshooting — Goldens flaky](#troubleshooting--goldens-flaky)

---

## Visão geral

O framework tem dois tiers:

| Tier | Ambiente | Ferramenta | Casos de uso |
|------|----------|-----------|-------------|
| **1** | Headless (sem device) | `flutter test` | CI, pré-commit, desenvolvimento rápido |
| **2** | Device/emulador real | APK flavor `tst` | Smoke manual, gravação, compartilhamento de resultados |

**Estrutura de pastas relevante:**

```
test/
├── e2e/
│   ├── _harness/
│   │   ├── scenario.dart      # E2EScenario, ScenarioTag
│   │   ├── test_harness.dart  # GameTestHarness (boot isolado + teardown)
│   │   └── registry.dart      # allScenarios — fonte única de verdade
│   ├── flows/                 # cenários de navegação e fluxo geral
│   ├── engine/                # lógica do game engine
│   ├── items/                 # power-ups (bomb, undo, etc.)
│   ├── nav/                   # smoke de navegação entre telas
│   ├── pause/                 # PauseOverlay
│   ├── persistence/           # persistência e restart
│   ├── daily/                 # desafio diário
│   ├── settings/              # tela de configurações
│   ├── collection/            # tela de coleção
│   ├── accessibility/         # Semantics e contraste
│   ├── regression/            # regressões documentadas v1.2.7+
│   └── golden/                # golden tests (alchemist)
│       └── goldens/ci/        # PNGs baseline
integration_test/
└── tier2_runner.dart          # entry point do APK Tier 2
```

---

## Tier 1 — Headless (flutter test)

Roda em qualquer máquina com Flutter instalado — **sem emulador, sem device**.

### Rodar a suite completa

```bash
# Suite completa: 80 E2EScenarios + 15 golden tests (95+ casos)
flutter test test/e2e/run_all_test.dart

# Com verbose (ver cada caso passando/falhando)
flutter test test/e2e/run_all_test.dart --reporter expanded

# Rodar apenas uma categoria
flutter test test/e2e/flows/

# Rodar apenas um arquivo
flutter test test/e2e/engine/engine_flows.dart
```

### Rodar todos os testes do projeto (unit + widget + E2E)

```bash
flutter test
```

### CI (GitHub Actions)

A suite Tier 1 roda automaticamente em todo PR e push para `main`.
Ver `.github/workflows/ci.yml`.

Em caso de falha nos golden tests, o diff é disponibilizado como artefato no Actions.

---

## Tier 2 — APK TestRunnerScreen

APK instalável **em paralelo** ao app principal (`com.catraia.capivara_2048.test`).
Abre o app → toca **▶ Run** → vê os cenários rodando ao vivo → toca **📤 Compartilhar**.

### Build release

```bash
flutter build apk \
  --target=integration_test/tier2_runner.dart \
  --flavor tst \
  --release

# APK gerado em:
# build/app/outputs/flutter-apk/app-tst-release.apk
```

### Instalar no device conectado

```bash
adb install build/app/outputs/flutter-apk/app-tst-release.apk
```

### Demo Mode

Roda apenas cenários taggeados com `ScenarioTag.demo` e suprime falhas de assertion.
Ideal para gravação de screencasts e apresentações.

```bash
flutter build apk \
  --target=integration_test/tier2_runner.dart \
  --flavor tst \
  --dart-define=DEMO_MODE=true \
  --debug
```

### Compartilhar resultados

O botão **📤 Compartilhar** exporta JSON + PNG via `share_plus`.
O JSON contém: ID do cenário, status (pass/fail), duração e mensagem de erro (se houver).

---

## Golden Tests

Os golden tests capturam screenshots de 5 telas × 3 viewports = **15 PNGs baseline**.

| Tela | Viewports |
|------|-----------|
| `HomeScreen` | 360×640, 414×894, 800×1280 |
| `GameScreen` | 360×640, 414×894, 800×1280 |
| `PauseOverlay` | 360×640, 414×894, 800×1280 |
| `CollectionScreen` | 360×640, 414×894, 800×1280 |
| `DailyRewardsScreen` | 360×640, 414×894, 800×1280 |

**Baselines:** `test/e2e/goldens/ci/`

### Rodar golden tests

```bash
# Apenas golden tests
flutter test test/e2e/run_all_test.dart --name "goldenTest"

# Atualizar baselines (após mudança intencional de UI)
flutter test test/e2e/run_all_test.dart --update-goldens
```

---

## Adicionar um novo cenário

> Tempo estimado: **< 5 minutos** para um cenário simples.

### Passo 1 — Escolher (ou criar) a pasta de categoria

```
test/e2e/
├── flows/      # fluxos gerais de jogo
├── engine/     # lógica do engine
├── nav/        # navegação entre telas
├── items/      # power-ups
├── settings/   # tela de configurações
...
```

Use a pasta existente mais adequada, ou crie uma nova.

### Passo 2 — Criar o cenário

Em `test/e2e/<categoria>/<categoria>_flows.dart` (ou arquivo existente), adicione:

```dart
import 'package:flutter_test/flutter_test.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';

final meuNovoScenario = E2EScenario(
  id: 'categoria.meu_novo_cenario',         // único no projeto
  title: 'descrição curta do que testa',
  tags: {ScenarioTag.critical},             // critical | slow | demo | tier1Only | tier2Only | golden
  run: (tester, harness) async {
    final widget = await tester.runAsync(() => harness.boot());
    await tester.pumpWidget(widget!);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Seu teste aqui:
    expect(find.text('Jogar'), findsOneWidget);
  },
);
```

**Tags disponíveis:**

| Tag | Significado |
|-----|-------------|
| `critical` | Sempre roda no Tier 1 |
| `slow` | Pode ser excluído de runs rápidos |
| `demo` | Roda no Demo Mode do Tier 2 |
| `tier1Only` | Apenas headless |
| `tier2Only` | Apenas APK Tier 2 (excluído do `run_all_test.dart`) |
| `golden` | Reservado para golden tests |

### Passo 3 — Registrar no registry

Em `test/e2e/_harness/registry.dart`, importe e adicione à lista `allScenarios`:

```dart
import '../categoria/categoria_flows.dart';

final List<E2EScenario> allScenarios = <E2EScenario>[
  // ... cenários existentes ...
  meuNovoScenario,  // ← adicionar aqui
];
```

### Passo 4 — Verificar

```bash
flutter test test/e2e/run_all_test.dart --name "categoria.meu_novo_cenario"
```

### Convenção de IDs

```
<categoria>.<nome_snake_case>

Exemplos:
  flow.smoke_boot
  engine.merge_basic
  regression.v1_2_7_header_scale
  collection.locked_card_shows_placeholder
```

---

## Troubleshooting — Goldens flaky

### Problema: golden difere entre máquinas

**Causa:** fontes do sistema, densidade de pixels (DPR), ou sombras divergindo entre ambientes.

**Solução:** o `flutter_test_config.dart` configura `alchemist` em CI mode globalmente:

```dart
// test/flutter_test_config.dart
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
    ),
    run: testMain,
  );
}
```

Isso desabilita platform goldens e usa fontless rendering. **Nunca desabilite esse arquivo.**

---

### Problema: golden falha só no CI

**Causa provável:** `GoogleFonts.config.allowRuntimeFetching = false` não está sendo respeitado,
ou uma fonte foi adicionada que não está em `assets/fonts/`.

**Verificar:**
1. `test_harness.dart` tem `GoogleFonts.config.allowRuntimeFetching = false` no `boot()`?
2. Todas as fontes usadas estão declaradas em `pubspec.yaml` → `flutter.fonts`?

**Diagnóstico rápido:**

```bash
flutter test test/e2e/run_all_test.dart --update-goldens
git diff --stat test/e2e/goldens/
```

Se muitos arquivos mudaram → problema de fonte ou DPR. Se apenas um mudou → mudança de UI intencional.

---

### Problema: golden falha após mudança de UI intencional

Atualize os baselines:

```bash
flutter test test/e2e/run_all_test.dart --update-goldens
git add test/e2e/goldens/
git commit -m "chore: atualizar goldens após mudança de UI intencional"
```

---

### Problema: `pumpAndSettle` trava (timeout)

**Causa:** alguma tela tem `Timer.periodic` ou `AnimationController` que nunca para.

**Telas afetadas:** `DailyRewardsScreen` (usa `Timer.periodic` para countdown).

**Solução:** use sequência de `pump` explícitos em vez de `pumpAndSettle`:

```dart
// ❌ trava:
await tester.pumpAndSettle();

// ✅ funciona:
await tester.pump();
await tester.pump(const Duration(milliseconds: 300));
await tester.pump(const Duration(milliseconds: 300));
```

Ver `test/e2e/flows/daily_flows.dart` para exemplo completo.

---

### Problema: `tap()` não encontra o widget

**Causa comum:** widget tem tamanho 0 (asset não carregado em test) ou está fora da área visível.

**Para `Image.asset`:** especifique `width` **e** `height` explicitamente no widget.
Sem `height`, o widget resolve para 0 em testes e `tap()` não encontra `GestureDetector`.

**Verificar:**

```bash
flutter test --reporter expanded 2>&1 | grep "could not tap"
```

Use `tester.widgetList(find.byType(GestureDetector))` para inspecionar quais GestureDetectors existem.

---

### Problema: `Hive` ou `SharedPreferences` vaza entre testes

**Causa:** `teardown()` não foi chamado.

**Solução:** sempre use `addTearDown`:

```dart
final h = GameTestHarness();
addTearDown(() => tester.runAsync(h.teardown));
```

O `teardown()` fecha o Hive, deleta o diretório temporário e dispõe o `ProviderContainer`.
