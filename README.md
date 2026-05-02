# 🦫 Olha o Bichim!
> Anteriormente conhecido como Capivara 2048

> Combine animais da Amazônia em um tabuleiro 4x4 e descubra a Capivara Lendária.

Puzzle game multiplataforma inspirado no 2048 clássico, onde os números são substituídos por animais da fauna amazônica (e brasileira). O objetivo é alcançar a **Capivara Lendária** — o tile 2048.

## Animais

| Nível | Valor | Animal |
|-------|-------|--------|
| 1 | 2 | Tanajura |
| 2 | 4 | Lobo-guará |
| 3 | 8 | Sapo-cururu |
| 4 | 16 | Tucano |
| 5 | 32 | Sagui |
| 6 | 64 | Preguiça |
| 7 | 128 | Mico-leão-dourado |
| 8 | 256 | Boto-cor-de-rosa |
| 9 | 512 | Onça-pintada |
| 10 | 1024 | Sucuri |
| 11 | 2048 | **🏆 Capivara Lendária** |

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

### Executar

```bash
# Web (Chrome)
flutter run -d chrome

# Android (emulador ou dispositivo conectado)
flutter run -d android

# iOS (macOS com Xcode)
flutter run -d ios
```

### Testes

```bash
flutter test
```

### Build de produção

```bash
# Web
flutter build web

# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

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

- **Fase 1** — MVP: game engine puro + tela básica ✅ *(v0.1.1)*
- **Fase 2** — Identidade visual, HomeScreen, vidas, fundo dinâmico ✅ *(v0.3.5)*
  - 2.3.5 — Refinamento: vidas no game over, cores explícitas, transição sem flicker, OutlinedText, pause dinâmico ✅
  - 2.3.6 — Polimento UX + Inventário: Stack layout, frosted-glass PauseOverlay, Bomb 2/3, Undo 1/3, GameOverModal ✅ *(v0.3.6)*
  - 2.5 — Rebranding "Olha o Bichim!", GameTitleImage, ícone e launcher name ✅ *(v0.9.1)*
  - 2.6 — Home redesenhada, Coleção, Configurações, stubs de navegação ✅ *(v0.9.2)*
  - 2.7 — Bugfixes visuais: overflow GameScreen, badge Home, OutlinedText, cards SettingsScreen ✅ *(v0.9.3)*
- **Fase 2.8** — Loja mock ✅ *(v0.9.4)*
- **Fase 3** — Arte final: ilustrações dos 11 animais
- **Fase 4** — Áudio: sons e música
- **Fase 5** — Coleção e Desafio Diário
- **Fase 6** — Polimento e lançamento (iOS / Android / Web)

## Design

Ver [`CAPIVARA_2048_DESIGN.md`](CAPIVARA_2048_DESIGN.md) para a especificação completa do jogo.

## Changelog

Ver [`CHANGELOG.md`](CHANGELOG.md).
