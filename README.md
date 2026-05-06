# 🦫 Olha o Bichim!

[![CI](https://github.com/g1uliano/capivara_2048/actions/workflows/ci.yml/badge.svg)](https://github.com/g1uliano/capivara_2048/actions/workflows/ci.yml)

> Anteriormente conhecido como Capivara 2048

> Combine animais da Amazônia em um tabuleiro 4x4 e descubra a Capivara Lendária.

Puzzle game multiplataforma inspirado no 2048 clássico, onde os números são substituídos por animais da fauna amazônica (e brasileira). O objetivo é alcançar a **Capivara Lendária** — o tile 2048.

## Animais

| Nível | Valor | Animal                   |
| ----- | ----- | ------------------------ |
| 1     | 2     | Tanajura                 |
| 2     | 4     | Lobo-guará               |
| 3     | 8     | Sapo-cururu              |
| 4     | 16    | Tucano                   |
| 5     | 32    | Sagui                    |
| 6     | 64    | Preguiça                 |
| 7     | 128   | Mico-leão-dourado        |
| 8     | 256   | Boto-cor-de-rosa         |
| 9     | 512   | Onça-pintada             |
| 10    | 1024  | Sucuri                   |
| 11    | 2048  | **🏆 Capivara Lendária** |
| 12    | 4096  | **🌊 Peixe-boi**         |
| 13    | 8192  | **🐊 Jacaré**            |

## Features

- Mecânica 2048 clássica com swipe nas 4 direções
- Estética cartoon fofa (estilo Pokémon Café Mix / Animal Crossing)
- Sons característicos de cada animal ao fazer merge
- Música ambiente de floresta amazônica
- **Modo Desafio Diário** com seed por data e streak
- **Coleção de animais** — desbloqueie ao alcançar cada nível
- Localização PT-BR e EN
- Feedback háptico no merge

## Como compilar e executar

### Pré-requisitos

- [Flutter SDK 3.x](https://docs.flutter.dev/get-started/install) instalado e no PATH
- `flutter doctor` sem erros críticos

### Instalação

```bash
git clone git@github.com:g1uliano/capivara_2048.git
cd capivara_2048
flutter pub get
```

### Flavors e Firebase

O projeto usa dois flavors: `dev` (emulador Firebase local) e `prd` (Firebase de produção).
O flavor é selecionado via `--dart-define=FLAVOR=dev|prd`.

> **Pré-requisito:** antes do primeiro build ou `flutter run`, execute o `flutterfire configure`
> conforme descrito em [`FIREBASE.md`](FIREBASE.md) para gerar os arquivos
> `lib/firebase_options_dev.dart` e `lib/firebase_options_prd.dart`.

### Executar

```bash
# Desenvolvimento (usa Firebase Emulator local)
flutter run --dart-define=FLAVOR=dev

# Produção (usa Firebase real)
flutter run --dart-define=FLAVOR=prd

# Sem flag: equivalente a FLAVOR=dev (default seguro)
flutter run
```

> Para usar o emulador Firebase em dev, rode `firebase emulators:start` em outro terminal
> antes de `flutter run`. Ver [`FIREBASE.md §11`](FIREBASE.md) para detalhes.

### Testes

```bash
# Tier 1 — unit/widget tests (headless, sem device, sem Firebase)
flutter test

# Tier 1 — suite E2E completa (95+ cenários)
flutter test test/e2e/run_all_test.dart
```

Os testes sempre usam Fakes (FakeAuthService, FakeSyncEngine, etc.) — sem necessidade de
Firebase configurado. Ver **[docs/TESTING.md](docs/TESTING.md)** para o guia completo.

### Build de produção

```bash
# Android APK — produção
flutter build apk --release --dart-define=FLAVOR=prd

# iOS — produção
flutter build ios --release --dart-define=FLAVOR=prd

# Android APK — desenvolvimento/QA
flutter build apk --debug --dart-define=FLAVOR=dev
```

> **CI/CD:** os valores de `AD_UNIT_ANDROID`, `AD_UNIT_IOS` e outros segredos
> são injetados via GitHub Secrets no workflow de release. Ver `.github/workflows/`.

## Stack

- **Flutter 3.x** (Dart) — iOS, Android, Web, Desktop
- **Riverpod** — gerenciamento de estado
- **Hive + SharedPreferences** — persistência local
- **audioplayers** — sons e música ambiente
- **flutter_animate** — animações de merge e spawn

## Estrutura do projeto

```
lib/
├── core/          # constantes, tema, utils
├── data/          # models, repositories, animals_data
├── domain/        # game_engine, daily_challenge
└── presentation/  # screens, widgets, controllers
assets/
├── images/animals/
├── sounds/animals/
├── sounds/ui/
├── music/
└── fonts/
```

## Roadmap

- **Fase 1** — MVP: game engine puro + tela básica ✅ _(v0.1.1)_
- **Fase 2** — Identidade visual, HomeScreen, vidas, fundo dinâmico ✅ _(v0.3.5)_
  - 2.5 — Rebranding "Olha o Bichim!", GameTitleImage, ícone e launcher name ✅ _(v0.9.1)_
  - 2.6 — Home redesenhada, Coleção, Configurações, stubs de navegação ✅ _(v0.9.2)_
  - 2.11 — ShopOverlay sobre o jogo, ícones desabilitados do inventário ✅ _(v1.1.0)_
  - 2.12 — Peixe-boi (4096), Jacaré (8192), multi-vitória, ranking local, PersonalRecords ✅ _(v1.1.0)_
  - 2.13 — Redesign da HomeScreen, botões PNG ilustrados, reorganização de assets ✅ _(v1.2.0)_
- **Fase 3** — E2E Test Framework (95+ cenários, golden tests, APK Tier 2, CI) ✅ _(v1.3.7)_
  - 3.0–3.4 — Harness + 80 cenários E2E (flows, engine, items, nav, persistence, daily, settings, collection, accessibility, regression)
  - 3.5 — Golden tests com alchemist (5 telas × 3 viewports)
  - 3.6 — APK Tier 2 com TestRunnerScreen + Share + Demo mode
  - 3.7 — CI GitHub Actions (Tier 1 em PR/push, golden diffs como artefato)
  - 3.8 — Documentação do framework de testes
- **Fase 4** — Arte adicional e polimento visual (logo, ícone, splash final)
- **Fase 5** — Áudio (sound design dos 13 animais, SFX, música)
- **Fase 6** — Polimento, l10n, acessibilidade, lançamento

## Design

Ver [`CAPIVARA_2048_DESIGN.md`](CAPIVARA_2048_DESIGN.md) para a especificação completa do jogo.

## Changelog

Ver [`CHANGELOG.md`](CHANGELOG.md).
