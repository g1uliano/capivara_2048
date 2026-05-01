# Fase 2.5 — Branding "Olha o Bichim!" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidar a identidade "Olha o Bichim!" — rebranding de strings, logo na Home, ícone do app e launcher name em todas as plataformas.

**Architecture:** Fase de branding puro sem nova lógica de jogo. `GameTitleImage` é um `StatelessWidget` passivo que recebe o asset como parâmetro; a `HomeScreen` (já `ConsumerStatefulWidget`) sorteia o asset uma vez em `initState` e o mantém pela sessão. O ícone é gerado via `flutter_launcher_icons` a partir de um PNG com tight crop pré-processado por ImageMagick.

**Tech Stack:** Flutter 3.x, Dart, flutter_launcher_icons ^0.14.0, ImageMagick (CLI), Riverpod, Hive.

---

## Mapa de arquivos

| Arquivo | Ação | Responsabilidade |
|---------|------|-----------------|
| `lib/app.dart` | Modificar | Trocar `title:` de `'Capivara 2048'` → `'Olha o Bichim!'` |
| `ios/Runner/Info.plist` | Modificar | `CFBundleDisplayName` → `'Olha o Bichim!'` |
| `README.md` | Modificar | Título → `# 🦫 Olha o Bichim!` |
| `lib/presentation/widgets/game_title_image.dart` | Criar | Widget `GameTitleImage` + `pickAsset` testável |
| `lib/presentation/screens/home_screen.dart` | Modificar | Integrar `GameTitleImage`, adicionar `_titleAsset` em `initState` |
| `test/presentation/game_title_image_test.dart` | Criar | Testes unitários e de widget para `GameTitleImage` |
| `test/presentation/home_screen_test.dart` | Modificar | Adicionar teste: HomeScreen usa asset válido |
| `pubspec.yaml` | Modificar | Adicionar assets `title/` e `icon/`; `flutter_launcher_icons` em dev_dependencies; bloco de config |
| `assets/images/icon/app_icon_tight.png` | Criar (ImageMagick) | Versão tight-crop do ícone para adaptive icon |
| `android/app/src/main/AndroidManifest.xml` | Modificar | `android:label` → `"Olha o Bichim!"` |
| `ios/Runner/Info.plist` | Modificar | `CFBundleDisplayName` → `"Olha o Bichim!"` |
| `web/index.html` | Modificar | `<title>` → `"Olha o Bichim!"` |
| `web/manifest.json` | Modificar | `name` e `short_name` → `"Olha o Bichim!"` |
| `CHANGELOG.md` | Modificar | Entrada v0.9.1 |
| `CLAUDE.md` | Modificar | Fase atual → 2.5 concluída |
| `CAPIVARA_2048_DESIGN.md` | Modificar | Remover "(anteriormente Capivara 2048)" da Seção 1 |

---

## Task 1: Rebranding de strings de exibição (Entrega A)

**Files:**
- Modify: `lib/app.dart:52`
- Modify: `ios/Runner/Info.plist:10`
- Modify: `README.md:1`

- [ ] **Step 1: Trocar title em `lib/app.dart`**

  Linha 52, mudar:
  ```dart
  title: 'Capivara 2048',
  ```
  para:
  ```dart
  title: 'Olha o Bichim!',
  ```

- [ ] **Step 2: Trocar `CFBundleDisplayName` em `ios/Runner/Info.plist`**

  Linha 10-11, mudar:
  ```xml
  <key>CFBundleDisplayName</key>
  <string>Capivara 2048</string>
  ```
  para:
  ```xml
  <key>CFBundleDisplayName</key>
  <string>Olha o Bichim!</string>
  ```
  **Não alterar** `CFBundleName` (fica `capivara_2048`).

- [ ] **Step 3: Trocar título em `README.md`**

  Linha 1, mudar:
  ```markdown
  # 🦫 Capivara 2048
  ```
  para:
  ```markdown
  # 🦫 Olha o Bichim!
  ```
  Adicionar subtítulo na linha 2 se não existir:
  ```markdown
  > Anteriormente conhecido como Capivara 2048
  ```

- [ ] **Step 4: Verificar grep limpo**

  ```bash
  grep -rni "capivara 2048" lib/ test/
  ```
  Esperado: zero hits.

- [ ] **Step 5: Rodar analyze**

  ```bash
  flutter analyze
  ```
  Esperado: zero issues.

- [ ] **Step 6: Commit**

  ```bash
  git add lib/app.dart ios/Runner/Info.plist README.md
  git commit -m "feat(branding): rebranding strings exibidas → Olha o Bichim! (Fase 2.5-A)"
  ```

---

## Task 2: Registrar assets no `pubspec.yaml` (Entrega B — pré-requisito)

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Adicionar paths de assets**

  No bloco `assets:` do `pubspec.yaml`, adicionar após a última entrada existente:
  ```yaml
      - assets/images/title/
      - assets/images/icon/
  ```
  O bloco completo deve ficar:
  ```yaml
    assets:
      - assets/images/animals/tile/
      - assets/images/animals/host/
      - assets/images/textures/
      - assets/images/fundo.png
      - assets/icons/inventory/
      - assets/images/title/
      - assets/images/icon/
  ```

- [ ] **Step 2: Verificar que os PNGs existem**

  ```bash
  ls assets/images/title/
  ls assets/images/icon/
  ```
  Esperado: `title_orange.png`, `title_brown.png` em `title/`; `app_icon.png` em `icon/`.

- [ ] **Step 3: Commit**

  ```bash
  git add pubspec.yaml
  git commit -m "chore: registrar assets images/title/ e images/icon/ no pubspec"
  ```

---

## Task 3: Criar `GameTitleImage` — testes primeiro (TDD) (Entrega B)

**Files:**
- Create: `test/presentation/game_title_image_test.dart`

- [ ] **Step 1: Criar arquivo de teste**

  ```dart
  // test/presentation/game_title_image_test.dart
  import 'dart:math';
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:capivara_2048/presentation/widgets/game_title_image.dart';

  void main() {
    const orange = 'assets/images/title/title_orange.png';
    const brown = 'assets/images/title/title_brown.png';
    const validAssets = {orange, brown};

    group('GameTitleImage.pickAsset', () {
      test('Random(0) retorna title_orange.png', () {
        final result = GameTitleImage.pickAsset(random: Random(0));
        expect(result, orange);
      });

      test('Random(1) retorna title_brown.png', () {
        final result = GameTitleImage.pickAsset(random: Random(1));
        expect(result, brown);
      });

      test('sem random injetado retorna um asset válido', () {
        final result = GameTitleImage.pickAsset();
        expect(validAssets, contains(result));
      });
    });

    group('GameTitleImage widget', () {
      testWidgets('renderiza Image.asset com path correto (orange)', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GameTitleImage(asset: orange, height: 220),
            ),
          ),
        );
        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);
        final image = tester.widget<Image>(imageFinder);
        final provider = image.image as AssetImage;
        expect(provider.assetName, orange);
      });

      testWidgets('renderiza Image.asset com path correto (brown)', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GameTitleImage(asset: brown, height: 220),
            ),
          ),
        );
        final image = tester.widget<Image>(find.byType(Image));
        final provider = image.image as AssetImage;
        expect(provider.assetName, brown);
      });

      testWidgets('semanticLabel é "Olha o Bichim!"', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GameTitleImage(asset: orange),
            ),
          ),
        );
        final image = tester.widget<Image>(find.byType(Image));
        expect(image.semanticLabel, 'Olha o Bichim!');
      });
    });
  }
  ```

- [ ] **Step 2: Rodar testes para confirmar que falham (arquivo não existe ainda)**

  ```bash
  flutter test test/presentation/game_title_image_test.dart
  ```
  Esperado: FAIL — `game_title_image.dart` não existe.

---

## Task 4: Implementar `GameTitleImage` (TDD — verde) (Entrega B)

**Files:**
- Create: `lib/presentation/widgets/game_title_image.dart`

- [ ] **Step 1: Criar o widget**

  ```dart
  // lib/presentation/widgets/game_title_image.dart
  import 'dart:math';
  import 'package:flutter/foundation.dart';
  import 'package:flutter/material.dart';

  class GameTitleImage extends StatelessWidget {
    const GameTitleImage({super.key, required this.asset, this.height});

    final String asset;
    final double? height;

    @visibleForTesting
    static String pickAsset({Random? random}) {
      final r = random ?? Random();
      return r.nextInt(2) == 0
          ? 'assets/images/title/title_orange.png'
          : 'assets/images/title/title_brown.png';
    }

    @override
    Widget build(BuildContext context) {
      return Image.asset(
        asset,
        height: height,
        fit: BoxFit.contain,
        semanticLabel: 'Olha o Bichim!',
      );
    }
  }
  ```

- [ ] **Step 2: Rodar testes**

  ```bash
  flutter test test/presentation/game_title_image_test.dart
  ```
  Esperado: todos os testes PASS.

- [ ] **Step 3: Rodar suite completa**

  ```bash
  flutter test
  ```
  Esperado: ≥193 testes passando, zero falhas.

- [ ] **Step 4: Commit**

  ```bash
  git add lib/presentation/widgets/game_title_image.dart test/presentation/game_title_image_test.dart
  git commit -m "feat(branding): GameTitleImage widget com pickAsset testável (Fase 2.5-B)"
  ```

---

## Task 5: Integrar `GameTitleImage` na `HomeScreen` (Entrega B)

**Files:**
- Modify: `lib/presentation/screens/home_screen.dart`
- Modify: `test/presentation/home_screen_test.dart`

- [ ] **Step 1: Escrever teste de integração na HomeScreen**

  Abrir `test/presentation/home_screen_test.dart` e adicionar dentro do `group('HomeScreen', ...)`:

  ```dart
  testWidgets('GameTitleImage usa asset válido da lista', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_wrap(const HomeScreen()));
    await tester.pump();

    const validAssets = {
      'assets/images/title/title_orange.png',
      'assets/images/title/title_brown.png',
    };

    final image = tester.widget<Image>(find.byType(Image).first);
    final provider = image.image as AssetImage;
    expect(validAssets, contains(provider.assetName));
  });
  ```

- [ ] **Step 2: Rodar o novo teste para confirmar que falha**

  ```bash
  flutter test test/presentation/home_screen_test.dart --name "GameTitleImage usa asset válido"
  ```
  Esperado: FAIL — `SizedBox` ainda está lá, não há `Image`.

- [ ] **Step 3: Integrar na HomeScreen**

  Em `lib/presentation/screens/home_screen.dart`:

  1. Adicionar import no topo:
     ```dart
     import '../widgets/game_title_image.dart';
     ```

  2. Na classe `_HomeScreenState`, adicionar campo:
     ```dart
     late final String _titleAsset;
     ```

  3. No `initState`, adicionar após `super.initState()`:
     ```dart
     _titleAsset = GameTitleImage.pickAsset();
     ```

  4. No `build`, substituir linha 71:
     ```dart
     const SizedBox(height: 220),
     ```
     por:
     ```dart
     GameTitleImage(asset: _titleAsset, height: 220),
     ```

- [ ] **Step 4: Rodar testes**

  ```bash
  flutter test test/presentation/home_screen_test.dart
  ```
  Esperado: todos passando incluindo o novo.

- [ ] **Step 5: Rodar suite completa**

  ```bash
  flutter test
  ```
  Esperado: ≥197 testes passando (193 + 4 novos).

- [ ] **Step 6: Rodar analyze**

  ```bash
  flutter analyze
  ```
  Esperado: zero issues.

- [ ] **Step 7: Commit**

  ```bash
  git add lib/presentation/screens/home_screen.dart test/presentation/home_screen_test.dart
  git commit -m "feat(branding): integrar GameTitleImage na HomeScreen — sorteio por sessão (Fase 2.5-B)"
  ```

---

## Task 6: Launcher names — Android, iOS, Web (Entrega D)

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Modify: `web/index.html`
- Modify: `web/manifest.json`

- [ ] **Step 1: Android — `android:label`**

  Em `android/app/src/main/AndroidManifest.xml`, localizar a linha:
  ```xml
  android:label="capivara_2048"
  ```
  Substituir por:
  ```xml
  android:label="Olha o Bichim!"
  ```
  O `!` é literal válido em XML — sem escape.

- [ ] **Step 2: iOS — `CFBundleDisplayName`**

  Em `ios/Runner/Info.plist`, a entrada `CFBundleDisplayName` já foi alterada para `"Olha o Bichim!"` na Task 1. Verificar:
  ```bash
  grep -A1 "CFBundleDisplayName" ios/Runner/Info.plist
  ```
  Esperado:
  ```
  <key>CFBundleDisplayName</key>
  <string>Olha o Bichim!</string>
  ```
  `CFBundleName` deve permanecer `capivara_2048`:
  ```bash
  grep -A1 "CFBundleName\"" ios/Runner/Info.plist
  ```
  Esperado: `<string>capivara_2048</string>`.

- [ ] **Step 3: Web — `<title>` em `web/index.html`**

  Localizar a linha `<title>capivara_2048</title>` e substituir por:
  ```html
  <title>Olha o Bichim!</title>
  ```

- [ ] **Step 4: Web — `web/manifest.json`**

  Localizar as entradas `name` e `short_name` e substituir por:
  ```json
  "name": "Olha o Bichim!",
  "short_name": "Olha o Bichim!",
  ```

- [ ] **Step 5: Commit**

  ```bash
  git add android/app/src/main/AndroidManifest.xml web/index.html web/manifest.json
  git commit -m "feat(branding): launcher name → Olha o Bichim! em Android, Web (Fase 2.5-D)"
  ```
  *(iOS já foi commitado na Task 1 junto com Info.plist)*

---

## Task 7: Tight crop do ícone com ImageMagick (Entrega C — pré-requisito)

**Files:**
- Create: `assets/images/icon/app_icon_tight.png`

- [ ] **Step 1: Verificar ImageMagick disponível**

  ```bash
  convert --version
  ```
  Esperado: `Version: ImageMagick 7.x...`. Se não instalado: `sudo pacman -S imagemagick` (Manjaro).

- [ ] **Step 2: Gerar tight crop**

  ```bash
  convert assets/images/icon/app_icon.png \
    -trim +repage \
    -gravity center \
    -background transparent \
    -extent 860x860 \
    assets/images/icon/app_icon_tight.png
  ```
  O `-trim` remove bordas transparentes; `-extent 860x860` repadeia para ~84% de 1024, deixando ~8% de margem em cada lado (dentro da safe zone Android adaptive de 66% do centro).

- [ ] **Step 3: Verificar dimensões**

  ```bash
  identify assets/images/icon/app_icon_tight.png
  ```
  Esperado: `860x860 PNG`.

- [ ] **Step 4: Commit**

  ```bash
  git add assets/images/icon/app_icon_tight.png
  git commit -m "chore(branding): gerar app_icon_tight.png (tight crop 860x860 para adaptive icon)"
  ```

---

## Task 8: Configurar e gerar ícones com `flutter_launcher_icons` (Entrega C)

**Files:**
- Modify: `pubspec.yaml`
- Generated: `android/app/src/main/res/mipmap-*/`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/`, `web/icons/`, `windows/runner/resources/`

- [ ] **Step 1: Adicionar `flutter_launcher_icons` em `dev_dependencies`**

  Em `pubspec.yaml`, no bloco `dev_dependencies:`, adicionar:
  ```yaml
  flutter_launcher_icons: ^0.14.0
  ```

- [ ] **Step 2: Adicionar bloco de configuração**

  No final de `pubspec.yaml` (fora do bloco `flutter:`), adicionar:
  ```yaml
  flutter_launcher_icons:
    android: true
    ios: true
    web:
      generate: true
      image_path: assets/images/icon/app_icon_tight.png
    windows:
      generate: true
      image_path: assets/images/icon/app_icon_tight.png
    image_path: assets/images/icon/app_icon_tight.png
    adaptive_icon_background: '#D4F1DE'
    adaptive_icon_foreground: assets/images/icon/app_icon_tight.png
  ```

- [ ] **Step 3: Instalar dependência**

  ```bash
  flutter pub get
  ```
  Esperado: resolve sem erro.

- [ ] **Step 4: Gerar ícones**

  ```bash
  dart run flutter_launcher_icons
  ```
  Esperado: output listando arquivos gerados para android, ios, web, windows. Sem erros.

- [ ] **Step 5: Verificar arquivos gerados**

  ```bash
  ls android/app/src/main/res/mipmap-hdpi/
  ls ios/Runner/Assets.xcassets/AppIcon.appiconset/ | head -5
  ls web/icons/
  ```
  Esperado: `ic_launcher.png` (e `ic_launcher_foreground.png`) em cada resolução Android; `Icon-App-*.png` no iOS; `Icon-192.png` e `Icon-512.png` no web.

- [ ] **Step 6: Rodar testes para garantir nada quebrou**

  ```bash
  flutter test
  ```
  Esperado: todos passando.

- [ ] **Step 7: Commit dos arquivos gerados**

  ```bash
  git add pubspec.yaml pubspec.lock \
    android/app/src/main/res/mipmap-hdpi/ \
    android/app/src/main/res/mipmap-mdpi/ \
    android/app/src/main/res/mipmap-xhdpi/ \
    android/app/src/main/res/mipmap-xxhdpi/ \
    android/app/src/main/res/mipmap-xxxhdpi/ \
    android/app/src/main/res/mipmap-anydpi-v26/ \
    ios/Runner/Assets.xcassets/AppIcon.appiconset/ \
    web/icons/ \
    windows/runner/resources/
  git commit -m "feat(branding): gerar ícones do app via flutter_launcher_icons (Fase 2.5-C)"
  ```

---

## Task 9: Validação manual (checkpoint)

- [ ] **Step 1: Android — emulador Pixel 7 API 34**

  ```bash
  flutter run -d <android-emulator-id>
  ```
  Conferir:
  - Nome "Olha o Bichim!" no launcher
  - Ícone adaptive visível e não-minúsculo (elemento central ocupa boa parte do círculo)
  - Logo alternando entre orange/brown ao abrir o app várias vezes

- [ ] **Step 2: iOS — simulador iPhone 15**

  ```bash
  flutter run -d <ios-simulator-id>
  ```
  Conferir:
  - Nome "Olha o Bichim!" no launcher sem truncamento
  - Ícone arredondado visível e correto

- [ ] **Step 3: Web**

  ```bash
  flutter run -d chrome
  ```
  Conferir:
  - `<title>` na aba do browser: "Olha o Bichim!"
  - Favicon na aba do browser

  Se ícone minúsculo no Android adaptive: ajustar parâmetro `-extent` da Task 7 (reduzir para 800x800 ou 820x820) e regenerar.

---

## Task 10: Atualizações documentais e bump de versão (Entrega E)

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `CLAUDE.md`
- Modify: `CAPIVARA_2048_DESIGN.md`
- Modify: `pubspec.yaml` (versão)

- [ ] **Step 1: Atualizar `CHANGELOG.md`**

  Adicionar no topo (antes das entradas existentes):
  ```markdown
  ## [0.9.1] — 2026-05-01

  ### Fase 2.5 — Identidade "Olha o Bichim!"
  - Rebranding: strings de exibição "Capivara 2048" → "Olha o Bichim!" (app title, Info.plist, README)
  - Novo widget `GameTitleImage` com sorteio por sessão entre variante orange e brown
  - Logo na HomeScreen substituindo placeholder SizedBox(height: 220)
  - Launcher name "Olha o Bichim!" em Android, iOS, Web
  - Ícone do app gerado via flutter_launcher_icons com adaptive icon background #D4F1DE
  ```

- [ ] **Step 2: Atualizar `CLAUDE.md`**

  Localizar a linha que descreve a fase atual (algo como "Fase atual: **Fase 2.4 concluída**") e atualizar para:
  ```
  Fase atual: **Fase 2.5 concluída (v0.9.1) — próximo: Fase 2.6**
  ```
  Também atualizar a tabela de fases se presente, marcando 2.5 como concluída.

- [ ] **Step 3: Atualizar `CAPIVARA_2048_DESIGN.md`**

  3a. Na Seção 1 (Visão Geral), remover qualquer referência a "(anteriormente Capivara 2048)" ou similar — o rebranding está consolidado.

  3b. Na seção de roadmap (§15), marcar a Fase 2.5 como concluída (trocar `🔜` por `✅`) e atualizar o cabeçalho da Fase 2.6 para indicar que é a próxima.

  3c. Substituir a seção `## 17. Prompt Sugerido para o Claude Code (Fase 2.5 — via skill superpowers)` pelo prompt da Fase 2.6 abaixo, renomeando para `## 17. Prompt Sugerido para o Claude Code (Fase 2.6 — via skill superpowers)`:

  ```markdown
  ## 17. Prompt Sugerido para o Claude Code (Fase 2.6 — via skill superpowers)

  > O prompt abaixo entra no fluxo do **superpowers/brainstorming**. O resultado esperado é uma **spec detalhada da Fase 2.6** (refinada via brainstorm), que depois alimenta o **superpowers/writing-plans** pra gerar o plano executável. Nada de código nesta etapa — apenas elicitação, refinamento de design e plano.

  ---

  > Use a skill `superpowers/brainstorming` pra refinar o design da próxima fase do projeto **Olha o Bichim!** (Flutter, codename `capivara_2048`).
  >
  > **Contexto:** Fase 2.5 concluída (v0.9.1) — rebranding, `GameTitleImage` na Home, ícone e launcher name. Use `CAPIVARA_2048_DESIGN.md` como spec geral (especialmente §10 — Identidade Visual, §12.1 — Mapa de telas, §12.2 — Tela Home, §13.1 — modelo `Animal`, §15 — roadmap Fase 2.6).
  >
  > **Fases concluídas:** Fases 1 a 2.5 (v0.9.1, ≥197 testes passando). Áudio segue na **Fase 5**.
  >
  > **Tópico do brainstorm:** **Fase 2.6 — Tela Home redesenhada + Tela de Coleção + Configurações**. Esta fase torna o app navegável e visualmente completo antes do backend (Fase 3). Não há nova lógica de jogo.
  >
  > **Sub-entregas (ver §15 — Fase 2.6):**
  >
  > **A — Home redesenhada:**
  > - Consumir `GameTitleImage(asset: _titleAsset, height: 220)` já existente no slot definido na 2.5 — não reescrever o widget.
  > - Todos os botões e indicadores do mapa de telas (§12.2): Novo Jogo, Continuar, Ranking (desabilitado "Em breve"), Recompensa Diária (com badge), Coleção, Configurações, Como Jogar.
  > - `LivesIndicator` já existente mantido no topo.
  > - Animação de entrada do logo (`flutter_animate` fade+scale) entra nesta fase — decidir no brainstorm.
  > - Layout final da Home antes do backend; Fase 3 só adiciona dados reais nos slots já existentes.
  >
  > **B — Tela de Coleção:**
  > - Grid dos 11 animais (Tanajura → Capivara Lendária).
  > - Animal desbloqueado (`highestLevelReached >= animal.level`): card colorido com PNG tile + nome + fun fact.
  > - Animal bloqueado: silhueta escura (PNG tile com `ColorFilter` ou opacidade) + "???" no nome.
  > - Card detalhado ao tocar num animal desbloqueado: nome completo, nome científico, fun fact, imagem host 2x2.
  > - Usar `backgroundBaseColor` do modelo `Animal` (§13.1) como cor de fundo do card.
  > - Fonte: Fredoka (título) + Nunito (fun fact) — padrão §10.3.
  >
  > **C — Configurações:**
  > - Haptic feedback toggle (persistente via SharedPreferences).
  > - Seleção de idioma (PT-BR / EN) — placeholder; l10n real na Fase 6.
  > - Sliders de volume SFX e música: presentes mas **desabilitados/ocultos** com label "Disponível na Fase 5" — os controles precisam existir no layout para a Fase 5 habilitá-los.
  > - Informações do app: versão (via `package_info_plus`), "Sobre".
  >
  > **D — Navegação entre telas:**
  > - Definir padrão de roteamento: `Navigator.push` com `MaterialPageRoute` (padrão atual do projeto) vs `go_router` vs `bottom NavigationBar`.
  > - Botão "Voltar" ou AppBar em cada tela secundária.
  > - Telas de Ranking, Loja, Convidar, Resgatar Código: stubs navegáveis com "Em breve" — não implementar conteúdo.
  >
  > **E — README, CHANGELOG, CLAUDE.md, design doc:**
  > - Atualizar documentação ao fechar a fase.
  > - Atualizar §17 do design doc com o prompt de brainstorm da **Fase 2.7**.
  >
  > **Pontos abertos pra explorar no brainstorm (elicitação esperada):**
  >
  > Sobre **A (Home):**
  > - Layout exato dos botões: lista vertical (padrão atual) ou grid de cards (Loja, Ranking, etc.)? §12.2 descreve cards — alinhar com a identidade visual cartoon.
  > - Animação de entrada do logo nesta fase (fade+scale `flutter_animate`) ou ainda estático? Recomendação inicial: animar aqui, já que é o redesign completo da Home.
  > - `DailyRewardEntryTile` já existente: reposicioná-lo ou mantê-lo no canto superior direito?
  > - Como Jogar: tela dedicada ou bottom sheet/modal simples?
  >
  > Sobre **B (Coleção):**
  > - Grid: quantas colunas? (2 = cards grandes com fun fact visível; 3 = mais compacto, fun fact só no detalhe). Recomendação: 2 colunas com fun fact truncado.
  > - Card detalhado: modal/bottom sheet ou nova tela de rota? Recomendação: bottom sheet (menos navegação).
  > - Silhueta de animal bloqueado: `ColorFilter.matrix` pra escurecer o PNG (mantém shape) ou `Image` com `color: Colors.black54` e `colorBlendMode: BlendMode.srcATop`?
  > - Ordem: nível crescente (1→11) ou por desbloqueio? Recomendação: nível crescente fixo.
  > - Cabeçalho: "X/11 animais descobertos" com barra de progresso.
  >
  > Sobre **C (Configurações):**
  > - Tela dedicada via `Navigator.push` ou bottom sheet/modal? Recomendação: tela dedicada (mais espaço para os controles futuros de áudio).
  > - Haptic: `HapticFeedback.lightImpact()` — onde aplicar no app (botões, merges)?
  > - `package_info_plus` já está no projeto? Verificar pubspec antes de adicionar.
  > - Idioma: `Locale` hard-coded ou via `Intl`? Fase 6 faz l10n real — o toggle de Configurações apenas persiste a preferência.
  >
  > Sobre **D (navegação):**
  > - Padrão atual: `Navigator.push` com `MaterialPageRoute` — manter ou migrar para `go_router` agora? Recomendação: manter `Navigator.push` até a Fase 3, quando deep links exigirão roteamento nomeado.
  > - Transições: `MaterialPageRoute` padrão (slide) ou `PageRouteBuilder` com fade/scale cartoon? Recomendação: slide padrão nesta fase, animar na Fase 6.
  >
  > Sobre **testes:**
  > - Widget tests obrigatórios: `CollectionScreen` (desbloqueados vs bloqueados), `SettingsScreen` (toggle haptic persiste), `HomeScreen` redesenhada (todos os botões presentes).
  > - Golden tests (opcional): úteis pra garantir layout da Coleção — decidir se entram nesta fase.
  > - `highestLevelReached` controla desbloqueio — testar com valores 1, 5, 11.
  >
  > Sobre **sincronização com Fase 2.7 (Loja mock) e Fase 3 (Backend):**
  > - Botão "Loja" na Home já deve navegar para stub de Loja (Fase 2.7 implementa o conteúdo).
  > - Slots de Ranking, Convidar, Resgatar Código ficam como stubs navegáveis — Fase 3 preenche.
  > - `PlayerProfile` (Fase 3) vai alimentar a Coleção com dados reais — o widget deve estar pronto para receber o provider quando existir.
  >
  > **Output esperado do brainstorm:**
  > Uma **spec detalhada da Fase 2.6** (`docs/superpowers/specs/YYYY-MM-DD-fase-2-6-design.md`) com:
  > - Decisões tomadas em cada ponto aberto (layout Home, colunas da Coleção, silhueta técnica, navegação, animação do logo).
  > - Para cada sub-entrega (A–E): arquivos a criar/modificar, contratos exatos (assinaturas de widgets, modelos de dados usados, providers Riverpod necessários), casos de teste obrigatórios, critérios de aceite.
  > - Diagrama de navegação textual (quais rotas existem, quais são stubs).
  > - Lista de pontos a sincronizar com Fase 2.7 (Loja) e Fase 3 (Backend/PlayerProfile).
  > - Plano de validação manual (emulador Android, simulador iOS, web — conferir layout, navegação, Coleção com animais desbloqueados e bloqueados).
  > - Ao final do documento: **prompt de brainstorm da Fase 2.7** seguindo este mesmo padrão de cascata.
  >
  > Esse documento será depois consumido pela skill `superpowers/writing-plans` pra gerar o plano executável (TDD-friendly, com checkpoints).
  >
  > **Não escreva código nesta etapa.** Foque em refinar o design, fazer perguntas críticas e produzir a spec.
  ```

- [ ] **Step 4: Bump de versão em `pubspec.yaml`**

  Mudar:
  ```yaml
  version: 0.9.0+22
  ```
  para:
  ```yaml
  version: 0.9.1+23
  ```

- [ ] **Step 5: Rodar suite completa e analyze**

  ```bash
  flutter test && flutter analyze
  ```
  Esperado: todos os testes passando, zero issues de análise.

- [ ] **Step 6: Verificação final de grep**

  ```bash
  grep -rni "capivara 2048" lib/ test/
  ```
  Esperado: zero hits.

- [ ] **Step 7: Commit e push final**

  ```bash
  git add CHANGELOG.md CLAUDE.md CAPIVARA_2048_DESIGN.md pubspec.yaml
  git commit -m "chore: bump v0.9.1+23; docs Fase 2.5 concluída"
  git push
  ```

---

## Critérios de aceite (verificar antes de fechar)

- [ ] `flutter analyze` zero issues
- [ ] `flutter test` ≥197 testes passando
- [ ] `grep -rni "capivara 2048" lib/ test/` → zero hits
- [ ] Logo aparece nas duas variantes ao longo de múltiplas sessões
- [ ] Ícone visível e não-minúsculo no launcher Android (emulador Pixel 7 API 34)
- [ ] Nome "Olha o Bichim!" no launcher Android e iOS sem truncamento
- [ ] Favicon e `<title>` corretos no build web
- [ ] Versão em `pubspec.yaml`: `0.9.1+23`
