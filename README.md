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
- **Ranking Global semanal** — top 50 por tempo até 2048, reinício todo sábado às 18h
- **Recompensas por recorde e convite** — ganhe vidas, bombas e desfazeres ao bater seus recordes
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

O projeto usa dois flavors Android:

| Flavor | Package                        | Firebase            | Uso                        |
| ------ | ------------------------------ | ------------------- | -------------------------- |
| `prod` | `com.catraia.capivara2048`     | `bichim-prd`        | Release / produção         |
| `tst`  | `com.catraia.capivara2048.dev` | `olha-o-bichim-dev` | QA / testes em dispositivo |

O Firebase (dev ou prd) é selecionado via `--dart-define=FLAVOR=dev|prd`.
O emulador local é ativado **separadamente** via `--dart-define=USE_EMULATOR=true`.

> **Pré-requisito:** antes do primeiro build ou `flutter run`, execute o `flutterfire configure`
> conforme descrito em [`FIREBASE.md`](FIREBASE.md) para gerar os arquivos
> `lib/firebase_options_dev.dart` e `lib/firebase_options_prd.dart`.

### Executar

**Cenário 1 — Emulador Firebase + Genymotion ou WiFi**

```bash
# Inicie o emulador Firebase em outro terminal primeiro:
firebase emulators:start

# Rode o app apontando para o IP fixo da sua máquina na rede
flutter run --flavor tst \
  --dart-define=FLAVOR=dev \
  --dart-define=USE_EMULATOR=true \
  --dart-define=EMULATOR_HOST=10.0.0.2 \
  --dart-define=AD_UNIT_ANDROID=ca-app-pub-3940256099942544/5224354917 \
  --dart-define=AD_UNIT_IOS=ca-app-pub-3940256099942544/1712485313
```

**Cenário 2 — Emulador Firebase + celular físico via USB**

```bash
# Inicie o emulador Firebase em outro terminal primeiro:
firebase emulators:start

# Redirecione as portas do emulador para o celular:
adb reverse tcp:8080 tcp:8080
adb reverse tcp:9099 tcp:9099

# Rode o app
flutter run --flavor tst \
  --dart-define=FLAVOR=dev \
  --dart-define=USE_EMULATOR=true \
  --dart-define=AD_UNIT_ANDROID=ca-app-pub-3940256099942544/5224354917 \
  --dart-define=AD_UNIT_IOS=ca-app-pub-3940256099942544/1712485313
```

**Cenário 3 — Dispositivo físico sem emulador (Firebase dev real)**

```bash
flutter run --flavor tst --dart-define=FLAVOR=dev
```

**Cenário 4 — Produção (Firebase prd)**

```bash
flutter run --flavor prod --dart-define=FLAVOR=prd
```

> Omitir `FLAVOR` equivale a `FLAVOR=dev` (default seguro).
> `USE_EMULATOR=true` é necessário apenas para desenvolvimento local com emuladores Firebase.

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

> **Importante:** sempre especifique `--flavor` no build para evitar erros do Google Services.

```bash
# Android APK — produção
flutter build apk --flavor prd --release --dart-define=FLAVOR=prd \
  --dart-define=AD_UNIT_ANDROID=ca-app-pub-3940256099942544/5224354917 \
  --dart-define=AD_UNIT_IOS=ca-app-pub-3940256099942544/1712485313

# Android AAB — produção (upload para Play Store)
flutter build appbundle --flavor prod --release --dart-define=FLAVOR=prd \
  --dart-define=AD_UNIT_ANDROID=ca-app-pub-3940256099942544/5224354917 \
  --dart-define=AD_UNIT_IOS=ca-app-pub-3940256099942544/1712485313
# Saída: build/app/outputs/bundle/prdRelease/app-prd-release.aab

# iOS — produção
flutter build ios --flavor prd --release --dart-define=FLAVOR=prd

# Android APK — QA / testes em dispositivo (flavor tst, Firebase dev real)
flutter build apk --flavor tst --debug --dart-define=FLAVOR=dev
```

> **CI/CD:** os valores de `AD_UNIT_ANDROID`, `AD_UNIT_IOS` e outros segredos
> são injetados via GitHub Secrets no workflow de release. Ver `.github/workflows/`.

## Builds

| Comando | Flavor | Serviços | Uso |
|---------|--------|----------|-----|
| `flutter run --dart-define=FLAVOR=dev` | dev | Reais (Firebase dev / sandbox) | Desenvolvimento local |
| `flutter build apk --dart-define=FLAVOR=tst` | tst | Fake (sem Firebase) | QA — testes sem lojas |
| `flutter build apk --dart-define=FLAVOR=tst --dart-define=USE_REAL_IAP=true` | tst | IAP Real (sandbox) | QA com Play Store sandbox |
| `flutter build apk --dart-define=FLAVOR=prd` | prd | Reais (produção) | Release |

Para configurar produtos nas lojas e contas de teste, consulte [`IAP.md`](IAP.md).

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
- **Fase 4A** — Firebase + Auth + Sync Engine ✅ _(v1.4.0)_
  - PlayerProfile, AuthService (Google, Apple, Email), SyncEngine, SyncConflictResolver
  - OnboardingAuthScreen, ProfileScreen, AuthBanner
  - Firebase inicializado com flavors prod/tst, emulador local opcional (`USE_EMULATOR=true`)
- **Fase 4B** — Ranking Global Semanal + Ranking Lendas ✅
  - Ranking semanal Firestore (top 50 por tempo até 2048, reinício automático)
  - Ranking Lendas persistido localmente
- **Fase 4C** — Convites, Anúncios Reais e IAP Real ✅
  - Deep links de convite + Firestore
  - Google Mobile Ads integrado
  - in_app_purchase (produtos reais)
- **Fase 4 gaps** — registerInvite pós-login, Convidar Amigos no ProfileScreen, Restaurar Compras real ✅
- **Fase 4.1** — EmailAuthScreen, AvatarPickerScreen, AvatarWidget ✅
  - updateAvatar(), destaque de avatar na Home
  - Fix legibilidade InviteFriendsScreen
- **Fase 4.1.1** — Tipografia consistente: Fredoka + OutlinedText em todas as telas sobre fundos não-sólidos ✅
- **Fase 4.2** — Exclusão de conta LGPD, edição de nome, troca/esqueci senha ✅
  - Persistência de avatar no tile, auth gates (startup, shop, daily, ranking)
  - Sync de game records
- **Fase 4.3** — Ranking Global, Recompensas e Auditoria de Flavors
  - Aba Global no Ranking (tempo até 2048, reinício semanal, tiebreaker por tile máximo)
  - Dialogs pós-milestone: posição no ranking (2048), tempo (4096), contagem (8192)
  - Recompensas por recorde pessoal (combo: vida + bomba3 + desfazer) — novo melhor tempo no 2048 ou novo tile máximo
  - Recompensas por convite — convidador recebe combo quando convidado joga 1ª partida
  - Tabela de prêmios semanais revisada (top 10, posições 1–10)
  - Fake* providers exclusivos para flavor `tst`; `dev` usa serviços reais
- **Fase 5** — Arte adicional e polimento visual (logo, ícone, splash final)
- **Fase 6** — Áudio (sound design dos 13 animais, SFX, música)
- **Fase 7** — Polimento, l10n, acessibilidade, lançamento

## Design

Ver [`CAPIVARA_2048_DESIGN.md`](CAPIVARA_2048_DESIGN.md) para a especificação completa do jogo.

## Changelog

Ver [`CHANGELOG.md`](CHANGELOG.md).
