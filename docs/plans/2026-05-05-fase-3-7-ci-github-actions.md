# Fase 3.7 — CI GitHub Actions — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar um workflow GitHub Actions que executa a suite Tier 1 (`flutter test test/e2e/run_all_test.dart --concurrency=4`) em todo PR, faz upload dos diffs de golden em caso de falha, e exibe um badge de status no README.

**Architecture:** Workflow único (`.github/workflows/ci.yml`) disparado em `pull_request` e `push` para `main`. Usa `subosito/flutter-action@v2` para setup do Flutter. Em caso de falha dos golden tests, o alchemist escreve imagens de diff em `test/e2e/goldens/failures/` — essas são coletadas e carregadas como artefato de PR.

**Tech Stack:** GitHub Actions, Flutter 3.41.x (stable), alchemist (golden CI mode já configurado via `flutter_test_config.dart`).

---

## Arquivos afetados

| Arquivo                    | Ação                                  |
| -------------------------- | ------------------------------------- |
| `.github/workflows/ci.yml` | Criar — workflow CI                   |
| `README.md`                | Modificar — adicionar badge de status |

---

### Task 1: Criar o workflow GitHub Actions

**Files:**

- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Criar o diretório `.github/workflows/`**

```bash
mkdir -p .github/workflows
```

- [ ] **Step 2: Criar `.github/workflows/ci.yml`**

Conteúdo completo do arquivo:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Flutter Tests (Tier 1)
    runs-on: ubuntu-latest
    timeout-minutes: 20

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.41.7"
          channel: "stable"
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Run Tier 1 test suite
        run: flutter test test/e2e/run_all_test.dart --concurrency=4

      - name: Upload golden diffs on failure
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: golden-failures
          path: test/e2e/goldens/failures/
          if-no-files-found: ignore
          retention-days: 7
```

> **Nota sobre goldens:** O alchemist em CI mode (`flutter_test_config.dart` já configura `isCI: true`) compara contra os PNGs em `test/e2e/goldens/ci/`. Em caso de falha, escreve as imagens de diff em `test/e2e/goldens/failures/` automaticamente. O passo `upload-artifact` coleta esse diretório.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add GitHub Actions workflow for Tier 1 tests (Fase 3.7)"
```

---

### Task 2: Adicionar badge de CI no README

**Files:**

- Modify: `README.md` — adicionar badge logo após o título

- [ ] **Step 1: Adicionar a badge após o título do README**

No `README.md`, localizar a linha:

```markdown
# 🦫 Olha o Bichim!
```

Substituir por:

```markdown
# 🦫 Olha o Bichim!

[![CI](https://github.com/g1uliano/capivara_2048/actions/workflows/ci.yml/badge.svg)](https://github.com/g1uliano/capivara_2048/actions/workflows/ci.yml)
```

> **Nota:** O badge ficará vermelho até o primeiro push/PR após o workflow existir no repositório remoto. Isso é esperado.

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add CI badge to README (Fase 3.7)"
```

---

### Task 3: Push e verificação

- [ ] **Step 1: Push para main**

```bash
git push origin main
```

- [ ] **Step 2: Verificar que o workflow aparece no GitHub**

Acessar `https://github.com/g1uliano/capivara_2048/actions` e confirmar que o workflow "CI" aparece e está rodando (ou passou).

- [ ] **Step 3: Atualizar CHANGELOG.md**

Adicionar entry:

```markdown
## [1.3.6] — 2026-05-05

### Added

- CI GitHub Actions workflow (Fase 3.7): roda suite Tier 1 em todo PR/push para main
- Upload automático de golden diffs como artefato em caso de falha
- Badge de status CI no README
```

- [ ] **Step 4: Atualizar `AGENTS.md` — fase atual**

Em `AGENTS.md`, alterar:

```
Fase atual: **Fase 3.6 concluída (v1.3.5) — próximo: Fase 3.7**
```

Para:

```
Fase atual: **Fase 3.7 concluída (v1.3.6) — próximo: Fase 3.8**
```

E na tabela do roadmap, marcar 3.7 como `✅`.

- [ ] **Step 5: Commit final de release**

```bash
git add CHANGELOG.md AGENTS.md
git commit -m "chore: release v1.3.6 — Fase 3.7 CI GitHub Actions"
git push origin main
```

---

## Self-Review

**Spec coverage:**

- ✅ Tier 1 roda a cada PR → `on: pull_request` + `flutter test test/e2e/run_all_test.dart --concurrency=4`
- ✅ Falha de golden gera diff como artefato → step `upload-artifact` com `test/e2e/goldens/failures/`
- ✅ Badge de status no README → Task 2

**Placeholder scan:** Nenhum TBD/TODO no plano.

**Consistência:** Os caminhos de golden (`test/e2e/goldens/failures/`) são os que o alchemist usa por padrão em CI mode. O `flutter_test_config.dart` já configura `AlchemistConfig` com `isCI: true` baseado em `Platform.environment['CI']`, que o GitHub Actions define automaticamente como `'true'`.
