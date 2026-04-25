# Fase 2 — Visual Base, Cronômetro, Anfitrião e Pausa — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the visual identity (theme, palette, fonts), rewrite TileWidget with white background + colored border + watermark slot, add a game timer, host banner showing the current top animal, and a pause system that hides the board and stops the clock.

**Architecture:** Incremental — each task leaves the game in a playable state. Data flows down from GameState (adds `maxLevel`, `elapsedMs`, `isPaused`); GameNotifier owns a periodic Timer; widgets read state via Riverpod selectors. No new packages beyond `google_fonts`.

**Tech Stack:** Flutter 3.x, Dart, flutter_riverpod ^2.6.1, google_fonts ^6.x

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `pubspec.yaml` | Modify | Add `google_fonts` dependency + assets section |
| `lib/core/theme/app_theme.dart` | Create | AppTheme.light() — palette + Fredoka/Nunito |
| `lib/app.dart` | Modify | Apply AppTheme |
| `lib/data/models/animal.dart` | Modify | Rename `tileColor`→`borderColor`, add `assetPath` |
| `lib/data/animals_data.dart` | Modify | Update field names + add `assetPath` per animal |
| `lib/data/models/game_state.dart` | Modify | Add `maxLevel`, `elapsedMs`, `isPaused` |
| `lib/presentation/controllers/game_notifier.dart` | Modify | Add Timer, pause/resume/tick, maxLevel tracking |
| `lib/presentation/widgets/tile_widget.dart` | Rewrite | White bg, colored border, watermark slot, Fredoka number |
| `lib/presentation/widgets/host_banner.dart` | Create | AnimatedSwitcher showing current top animal + name |
| `lib/presentation/widgets/score_panel.dart` | Modify | Add MM:SS timer display + pause IconButton |
| `lib/presentation/widgets/pause_overlay.dart` | Create | Opaque overlay: Continuar / Reiniciar / Menu |
| `lib/presentation/screens/game/game_screen.dart` | Modify | Wire HostBanner, PauseOverlay, swipe guard |
| `test/presentation/controllers/game_notifier_test.dart` | Modify | Tests for maxLevel, elapsedMs, isPaused, pause/resume |

---

## Task 1: Add `google_fonts` dependency and assets section

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add dependency and assets**

Open `pubspec.yaml`. Under `dependencies:`, add after `uuid`:
```yaml
  google_fonts: ^6.2.1
```

Under the `flutter:` section, add after `uses-material-design: true`:
```yaml
  assets:
    - assets/images/animals/
```

Also create the directory so Flutter doesn't warn:
```bash
mkdir -p assets/images/animals
```

- [ ] **Step 2: Get packages**

```bash
flutter pub get
```

Expected: resolves without errors, `google_fonts` appears in `.dart_tool/package_config.json`.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock assets/
git commit -m "chore: add google_fonts dep and animals asset directory"
```

---

## Task 2: Create AppTheme

**Files:**
- Create: `lib/core/theme/app_theme.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Create `app_theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: false);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF3FA968),
      cardColor: const Color(0xFFE8D5B7),
      primaryColor: const Color(0xFFFF8C42),
      colorScheme: base.colorScheme.copyWith(
        primary: const Color(0xFFFF8C42),
        secondary: const Color(0xFF66BB6A),
        error: const Color(0xFFC0392B),
        surface: const Color(0xFFD4F1DE),
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.fredoka(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF3E2723),
        ),
        displayMedium: GoogleFonts.fredoka(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF3E2723),
        ),
        titleLarge: GoogleFonts.fredoka(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3E2723),
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 16,
          color: const Color(0xFF3E2723),
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 14,
          color: const Color(0xFF3E2723),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8C42),
          foregroundColor: const Color(0xFFFFF8E7),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Apply theme in `app.dart`**

Current `app.dart` content — replace `MaterialApp(...)` theme line. Open the file, find the `MaterialApp` widget, and add/replace the `theme:` parameter:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/game/game_screen.dart';

class CapivaraApp extends StatelessWidget {
  const CapivaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Capivara 2048',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const GameScreen(),
      ),
    );
  }
}
```

- [ ] **Step 3: Run the app and verify fonts load**

```bash
flutter run -d linux
```

Expected: app launches, fonts look rounder (Nunito/Fredoka), background still green, no errors in console.

- [ ] **Step 4: Commit**

```bash
git add lib/core/theme/app_theme.dart lib/app.dart
git commit -m "feat: add AppTheme with Fredoka/Nunito and Capivara palette"
```

---

## Task 3: Update `Animal` model and `animals_data.dart`

**Files:**
- Modify: `lib/data/models/animal.dart`
- Modify: `lib/data/animals_data.dart`

- [ ] **Step 1: Update `animal.dart`**

Replace full file:

```dart
import 'package:flutter/material.dart';

class Animal {
  final int level;
  final int value;
  final String name;
  final Color borderColor;
  final String assetPath;

  const Animal({
    required this.level,
    required this.value,
    required this.name,
    required this.borderColor,
    required this.assetPath,
  });
}
```

- [ ] **Step 2: Update `animals_data.dart`**

Replace full file:

```dart
import 'package:flutter/material.dart';
import 'models/animal.dart';

const List<Animal> animals = [
  Animal(level: 1,  value: 2,    name: 'Tanajura',           borderColor: Color(0xFFC0392B), assetPath: 'assets/images/animals/tanajura.png'),
  Animal(level: 2,  value: 4,    name: 'Lobo-guará',         borderColor: Color(0xFFE67E22), assetPath: 'assets/images/animals/lobo_guara.png'),
  Animal(level: 3,  value: 8,    name: 'Sapo-cururu',        borderColor: Color(0xFF8D6E63), assetPath: 'assets/images/animals/sapo_cururu.png'),
  Animal(level: 4,  value: 16,   name: 'Tucano',             borderColor: Color(0xFFFFB300), assetPath: 'assets/images/animals/tucano.png'),
  Animal(level: 5,  value: 32,   name: 'Arara-azul',         borderColor: Color(0xFF1E88E5), assetPath: 'assets/images/animals/arara_azul.png'),
  Animal(level: 6,  value: 64,   name: 'Preguiça',           borderColor: Color(0xFFBCAAA4), assetPath: 'assets/images/animals/preguica.png'),
  Animal(level: 7,  value: 128,  name: 'Mico-leão-dourado',  borderColor: Color(0xFFFF8F00), assetPath: 'assets/images/animals/mico_leao.png'),
  Animal(level: 8,  value: 256,  name: 'Boto-cor-de-rosa',   borderColor: Color(0xFFF48FB1), assetPath: 'assets/images/animals/boto.png'),
  Animal(level: 9,  value: 512,  name: 'Onça-pintada',       borderColor: Color(0xFFFBC02D), assetPath: 'assets/images/animals/onca_pintada.png'),
  Animal(level: 10, value: 1024, name: 'Sucuri',             borderColor: Color(0xFF2E7D32), assetPath: 'assets/images/animals/sucuri.png'),
  Animal(level: 11, value: 2048, name: 'Capivara Lendária',  borderColor: Color(0xFFFFD54F), assetPath: 'assets/images/animals/capivara_lendaria.png'),
];

Animal animalForLevel(int level) =>
    animals.firstWhere((a) => a.level == level);
```

- [ ] **Step 3: Fix compile errors**

`TileWidget` references `animal.tileColor` — update that reference to `animal.borderColor`. Open `lib/presentation/widgets/tile_widget.dart`, find `animal.tileColor` and replace with `animal.borderColor`.

- [ ] **Step 4: Verify app compiles and runs**

```bash
flutter run -d linux
```

Expected: app runs, tiles still show colored backgrounds (old behavior preserved), no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/animal.dart lib/data/animals_data.dart lib/presentation/widgets/tile_widget.dart
git commit -m "feat: update Animal model — borderColor + assetPath slot"
```

---

## Task 4: Rewrite `TileWidget`

**Files:**
- Modify: `lib/presentation/widgets/tile_widget.dart`

- [ ] **Step 1: Rewrite `tile_widget.dart`**

Replace full file:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/animals_data.dart';
import '../../data/models/tile.dart';

class TileWidget extends StatelessWidget {
  final Tile? tile;
  final double size;

  const TileWidget({super.key, required this.tile, required this.size});

  @override
  Widget build(BuildContext context) {
    if (tile == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFC9B79C),
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    final animal = animalForLevel(tile!.level);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: animal.borderColor, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          _buildWatermark(animal.assetPath),
          Center(
            child: Text(
              '${1 << tile!.level}',
              style: GoogleFonts.fredoka(
                fontSize: size * 0.35,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3E2723),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatermark(String assetPath) {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Opacity(
          opacity: 0.27,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run the app and verify visual**

```bash
flutter run -d linux
```

Expected: tiles now show white background with colored border, number in Fredoka font, no crash if image assets don't exist yet.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/tile_widget.dart
git commit -m "feat: rewrite TileWidget — white bg, colored border, watermark slot, Fredoka number"
```

---

## Task 5: Add `maxLevel`, `elapsedMs`, `isPaused` to GameState and update GameEngine

**Files:**
- Modify: `lib/data/models/game_state.dart`
- Modify: `lib/domain/game_engine/game_engine.dart`
- Modify: `test/presentation/controllers/game_notifier_test.dart` (or create if absent)

- [ ] **Step 1: Update `game_state.dart`**

Replace full file:

```dart
import 'tile.dart';

class GameState {
  final List<List<Tile?>> board;
  final int score;
  final int highScore;
  final bool isGameOver;
  final bool hasWon;
  final int maxLevel;
  final int elapsedMs;
  final bool isPaused;

  const GameState({
    required this.board,
    required this.score,
    required this.highScore,
    required this.isGameOver,
    required this.hasWon,
    this.maxLevel = 0,
    this.elapsedMs = 0,
    this.isPaused = false,
  });

  GameState copyWith({
    List<List<Tile?>>? board,
    int? score,
    int? highScore,
    bool? isGameOver,
    bool? hasWon,
    int? maxLevel,
    int? elapsedMs,
    bool? isPaused,
  }) {
    return GameState(
      board: board ?? this.board,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      isGameOver: isGameOver ?? this.isGameOver,
      hasWon: hasWon ?? this.hasWon,
      maxLevel: maxLevel ?? this.maxLevel,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}
```

- [ ] **Step 2: Update `game_engine.dart` to compute `maxLevel` after a move**

In `move()`, after computing `unrotated` board, add `maxLevel` calculation. Find the block that builds `next = state.copyWith(...)` and replace it:

```dart
    // Compute the highest level on the new board
    int newMaxLevel = state.maxLevel;
    for (final row in unrotated) {
      for (final t in row) {
        if (t != null && t.level > newMaxLevel) newMaxLevel = t.level;
      }
    }

    var next = state.copyWith(
      board: unrotated,
      score: newScore,
      highScore: newHighScore,
      hasWon: hasWon,
      maxLevel: newMaxLevel,
    );
```

Also update `newGame()` to include the new fields (they default to 0/false so no explicit change needed — but verify the `GameState(...)` call compiles with the new constructor).

- [ ] **Step 3: Write failing tests**

Check if `test/presentation/controllers/game_notifier_test.dart` exists. If not, check `test/` for existing test files and add to the closest related file, or create:

```dart
// test/presentation/controllers/game_notifier_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/game_state.dart';
import 'package:capivara_2048/domain/game_engine/game_engine.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';

void main() {
  group('GameState fields', () {
    test('newGame starts with maxLevel 0, elapsedMs 0, isPaused false', () {
      final engine = GameEngine();
      final state = engine.newGame();
      expect(state.maxLevel, 0);
      expect(state.elapsedMs, 0);
      expect(state.isPaused, false);
    });

    test('copyWith preserves unchanged fields', () {
      const s = GameState(
        board: [],
        score: 10,
        highScore: 20,
        isGameOver: false,
        hasWon: false,
        maxLevel: 3,
        elapsedMs: 5000,
        isPaused: false,
      );
      final s2 = s.copyWith(score: 15);
      expect(s2.maxLevel, 3);
      expect(s2.elapsedMs, 5000);
      expect(s2.isPaused, false);
    });
  });
}
```

- [ ] **Step 4: Run failing tests**

```bash
flutter test test/presentation/controllers/game_notifier_test.dart
```

Expected: tests PASS (model fields are pure data — they should pass immediately after Step 1).

- [ ] **Step 5: Verify app still runs**

```bash
flutter run -d linux
```

Expected: no regressions, game plays normally.

- [ ] **Step 6: Commit**

```bash
git add lib/data/models/game_state.dart lib/domain/game_engine/game_engine.dart test/presentation/controllers/game_notifier_test.dart
git commit -m "feat: add maxLevel, elapsedMs, isPaused to GameState; track maxLevel in GameEngine"
```

---

## Task 6: Add Timer, pause/resume to `GameNotifier`

**Files:**
- Modify: `lib/presentation/controllers/game_notifier.dart`
- Modify: `test/presentation/controllers/game_notifier_test.dart`

- [ ] **Step 1: Write failing tests first**

Add to `test/presentation/controllers/game_notifier_test.dart`:

```dart
  group('GameNotifier pause/resume', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('isPaused starts false', () {
      final state = container.read(gameProvider);
      expect(state.isPaused, false);
    });

    test('pause() sets isPaused true', () {
      container.read(gameProvider.notifier).pause();
      expect(container.read(gameProvider).isPaused, true);
    });

    test('resume() sets isPaused false', () {
      container.read(gameProvider.notifier).pause();
      container.read(gameProvider.notifier).resume();
      expect(container.read(gameProvider).isPaused, false);
    });

    test('restart() resets isPaused, elapsedMs, maxLevel', () {
      container.read(gameProvider.notifier).pause();
      container.read(gameProvider.notifier).restart();
      final state = container.read(gameProvider);
      expect(state.isPaused, false);
      expect(state.elapsedMs, 0);
      expect(state.maxLevel, 0);
    });
  });
```

- [ ] **Step 2: Run to confirm tests fail**

```bash
flutter test test/presentation/controllers/game_notifier_test.dart
```

Expected: FAIL — `pause` and `resume` methods not found.

- [ ] **Step 3: Rewrite `game_notifier.dart`**

Replace full file:

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/game_state.dart';
import '../../domain/game_engine/direction.dart';
import '../../domain/game_engine/game_engine.dart';

class GameNotifier extends StateNotifier<GameState> {
  final GameEngine _engine;
  Timer? _timer;
  bool _timerStarted = false;

  GameNotifier(this._engine) : super(_engine.newGame());

  void onSwipe(Direction dir) {
    if (state.isGameOver || state.isPaused) return;

    final before = state;
    final next = _engine.move(state, dir);

    // Start timer on first valid move
    if (!_timerStarted && next.board != before.board) {
      _timerStarted = true;
      _startTimer();
    }

    state = next;

    // Stop timer on terminal states
    if (state.isGameOver || state.hasWon) _stopTimer();
  }

  void pause() {
    if (state.isGameOver || state.isPaused) return;
    _stopTimer();
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    if (!state.isPaused) return;
    state = state.copyWith(isPaused: false);
    if (_timerStarted) _startTimer();
  }

  void restart() {
    _stopTimer();
    _timerStarted = false;
    state = _engine.newGame();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!state.isPaused && !state.isGameOver && !state.hasWon) {
        state = state.copyWith(elapsedMs: state.elapsedMs + 100);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

final gameEngineProvider = Provider<GameEngine>((ref) => GameEngine());

final gameProvider = StateNotifierProvider<GameNotifier, GameState>(
  (ref) => GameNotifier(ref.read(gameEngineProvider)),
);
```

- [ ] **Step 4: Run tests — all should pass**

```bash
flutter test test/presentation/controllers/game_notifier_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Run full test suite**

```bash
flutter test
```

Expected: all existing tests still PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/controllers/game_notifier.dart test/presentation/controllers/game_notifier_test.dart
git commit -m "feat: add Timer, pause/resume to GameNotifier — cronômetro e pausa"
```

---

## Task 7: Create `HostBanner`

**Files:**
- Create: `lib/presentation/widgets/host_banner.dart`

- [ ] **Step 1: Create `host_banner.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/animals_data.dart';
import '../controllers/game_notifier.dart';

class HostBanner extends ConsumerWidget {
  const HostBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxLevel = ref.watch(gameProvider.select((s) => s.maxLevel));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: maxLevel == 0
                ? _Placeholder(key: const ValueKey('placeholder'))
                : _AnimalHost(
                    key: ValueKey(maxLevel),
                    level: maxLevel,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Comece a jogar!',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: const Color(0xFFFFF8E7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AnimalHost extends StatelessWidget {
  final int level;
  const _AnimalHost({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final animal = animalForLevel(level);
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: animal.borderColor, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              animal.assetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          animal.name,
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: const Color(0xFFFFF8E7),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/presentation/widgets/host_banner.dart
```

Expected: no errors.

- [ ] **Step 3: Commit (widget not yet wired into screen)**

```bash
git add lib/presentation/widgets/host_banner.dart
git commit -m "feat: add HostBanner with AnimatedSwitcher — anfitrião dinâmico"
```

---

## Task 8: Update `ScorePanel` — timer display + pause button

**Files:**
- Modify: `lib/presentation/widgets/score_panel.dart`

- [ ] **Step 1: Rewrite `score_panel.dart`**

Replace full file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/game_notifier.dart';

class ScorePanel extends ConsumerWidget {
  const ScorePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final timerText = state.elapsedMs == 0
        ? '--:--'
        : _formatMs(state.elapsedMs);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Score + high score
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pontuação: ${state.score}',
                  style: GoogleFonts.fredoka(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFF8E7),
                  ),
                ),
                Text(
                  'Recorde: ${state.highScore}',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: const Color(0xFFD4F1DE),
                  ),
                ),
              ],
            ),
          ),
          // Timer
          Text(
            timerText,
            style: GoogleFonts.fredoka(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFF8E7),
            ),
          ),
          const SizedBox(width: 12),
          // Pause button
          IconButton(
            onPressed: state.isGameOver
                ? null
                : () => ref.read(gameProvider.notifier).pause(),
            icon: const Icon(Icons.pause_rounded),
            color: const Color(0xFFFFF8E7),
            iconSize: 28,
            tooltip: 'Pausar',
          ),
        ],
      ),
    );
  }

  String _formatMs(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
```

- [ ] **Step 2: Run app and verify ScorePanel layout**

```bash
flutter run -d linux
```

Expected: score on left, `--:--` timer in center, pause icon on right. After first swipe, timer starts counting. No layout overflow.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/score_panel.dart
git commit -m "feat: update ScorePanel — MM:SS timer display and pause button"
```

---

## Task 9: Create `PauseOverlay`

**Files:**
- Create: `lib/presentation/widgets/pause_overlay.dart`

- [ ] **Step 1: Create `pause_overlay.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/game_notifier.dart';

class PauseOverlay extends ConsumerWidget {
  const PauseOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: const Color(0xF02D7A4F),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pause_circle_filled_rounded,
              size: 72,
              color: Color(0xFFFFF8E7),
            ),
            const SizedBox(height: 16),
            Text(
              'Pausado',
              style: GoogleFonts.fredoka(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFF8E7),
              ),
            ),
            const SizedBox(height: 32),
            _PauseButton(
              label: 'Continuar',
              icon: Icons.play_arrow_rounded,
              onPressed: () => ref.read(gameProvider.notifier).resume(),
            ),
            const SizedBox(height: 12),
            _PauseButton(
              label: 'Reiniciar',
              icon: Icons.refresh_rounded,
              onPressed: () => ref.read(gameProvider.notifier).restart(),
            ),
            const SizedBox(height: 12),
            _PauseButton(
              label: 'Menu',
              icon: Icons.home_rounded,
              onPressed: () {
                ref.read(gameProvider.notifier).resume();
                Navigator.of(context).maybePop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PauseButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/presentation/widgets/pause_overlay.dart
```

Expected: no errors.

- [ ] **Step 3: Commit (not yet visible — wired in Task 10)**

```bash
git add lib/presentation/widgets/pause_overlay.dart
git commit -m "feat: add PauseOverlay — opaque board cover with Continuar/Reiniciar/Menu"
```

---

## Task 10: Wire everything in `GameScreen`

**Files:**
- Modify: `lib/presentation/screens/game/game_screen.dart`

- [ ] **Step 1: Rewrite `game_screen.dart`**

Replace full file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/game_engine/direction.dart';
import '../../controllers/game_notifier.dart';
import '../../widgets/board_widget.dart';
import '../../widgets/host_banner.dart';
import '../../widgets/pause_overlay.dart';
import '../../widgets/score_panel.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameProvider);
    final blocked = state.isPaused || state.isGameOver;

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanEnd: blocked
              ? null
              : (details) {
                  final v = details.velocity.pixelsPerSecond;
                  const threshold = 100.0;
                  if (v.dx.abs() > v.dy.abs()) {
                    if (v.dx > threshold) {
                      ref.read(gameProvider.notifier).onSwipe(Direction.right);
                    } else if (v.dx < -threshold) {
                      ref.read(gameProvider.notifier).onSwipe(Direction.left);
                    }
                  } else {
                    if (v.dy > threshold) {
                      ref.read(gameProvider.notifier).onSwipe(Direction.down);
                    } else if (v.dy < -threshold) {
                      ref.read(gameProvider.notifier).onSwipe(Direction.up);
                    }
                  }
                },
          child: Column(
            children: [
              const ScorePanel(),
              const HostBanner(),
              const Spacer(),
              Stack(
                children: [
                  const BoardWidget(),
                  if (state.isPaused) const PauseOverlay(),
                ],
              ),
              const Spacer(),
              if (state.isGameOver) _buildOverlay('Game Over!', ref, context),
              if (state.hasWon && !state.isGameOver)
                _buildOverlay('Capivara Lendária! 🎉', ref, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(String message, WidgetRef ref, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            message,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFF8E7),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ref.read(gameProvider.notifier).restart(),
            child: const Text('Jogar de novo'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run full test suite**

```bash
flutter test
```

Expected: all tests PASS.

- [ ] **Step 3: Run the app and do a full manual test**

```bash
flutter run -d linux
```

Test the following:
1. App launches — `--:--` no timer, "Comece a jogar!" no banner
2. Primeiro swipe — timer starts counting, host banner shows first animal formed
3. Form higher tiles — host banner animates to new animal with fade+scale
4. Press pause — overlay appears covering board, timer stops
5. Press Continuar — overlay disappears, timer resumes from where it stopped
6. Press pause → Reiniciar — game resets, timer resets to `--:--`, banner resets
7. Swipe until game over — timer stops, game over text appears, pause button disabled

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/screens/game/game_screen.dart
git commit -m "feat: wire GameScreen — HostBanner, PauseOverlay, swipe guard — Fase 2.1+2.2 completa"
```

---

## Self-Review

**Spec coverage:**
- ✅ AppTheme (palette, Fredoka/Nunito) — Task 2
- ✅ Animal.borderColor + assetPath — Task 3
- ✅ TileWidget rewrite (white bg, colored border, watermark slot, Fredoka number) — Task 4
- ✅ GameState maxLevel + elapsedMs + isPaused — Task 5
- ✅ GameNotifier Timer, pause/resume, maxLevel tracking — Task 6
- ✅ HostBanner with AnimatedSwitcher, placeholder, name — Task 7
- ✅ ScorePanel MM:SS timer + pause button — Task 8
- ✅ PauseOverlay (opaque, hides board, 3 buttons) — Task 9
- ✅ GameScreen Stack + swipe guard + HostBanner — Task 10

**Type consistency:**
- `animal.borderColor` — defined Task 3, used Tasks 4, 7 ✅
- `animal.assetPath` — defined Task 3, used Tasks 4, 7 ✅
- `state.maxLevel` — defined Task 5, tracked Task 6, read Task 7 ✅
- `state.elapsedMs` — defined Task 5, incremented Task 6, displayed Task 8 ✅
- `state.isPaused` — defined Task 5, set Task 6, checked Tasks 8, 9, 10 ✅
- `notifier.pause()` / `notifier.resume()` — defined Task 6, called Tasks 8, 9, 10 ✅
- `notifier.restart()` — existed before, tested Task 6, called Tasks 9, 10 ✅

**No placeholders found.**
