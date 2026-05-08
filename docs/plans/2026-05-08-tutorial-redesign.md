# Tutorial Wizard Interativo — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir o atual `_HowToPlaySheet` (BottomSheet com texto puro) por uma `TutorialScreen` wizard de 5 telas, com 2 telas interativas (mini-boards onde o jogador faz o swipe), persistência de `tutorialCompleted` no perfil, e seguindo a identidade visual cartoon-amazônica do app.

**Architecture:** Nova tela full-screen `TutorialScreen` com `PageView` controlado (não-deslizável), 5 páginas isoladas, `TutorialMiniBoard` independente do `GameEngine` (renderiza com `TileWidget` + gestão própria de estado/animação). Persistência via novo campo `PlayerProfile.tutorialCompleted` (Firestore para logados, SharedPreferences para anônimos), exposto por `tutorialControllerProvider` (Riverpod).

**Tech Stack:** Flutter/Dart, Riverpod, Hive, SharedPreferences, Cloud Firestore, flutter_animate, flutter_test

**Spec:** `docs/specs/2026-05-08-tutorial-redesign-design.md`

---

## Mapa de arquivos

| Arquivo                                                                    | Ação                                                                                           |
| -------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `lib/data/models/player_profile.dart`                                      | Modificar — add `tutorialCompleted: bool`                                                      |
| `lib/domain/sync/sync_engine.dart`                                         | Modificar — add `updateTutorialCompleted()` na interface + FakeSyncEngine                      |
| `lib/data/repositories/firebase_sync_engine.dart`                          | Modificar — implementar `updateTutorialCompleted()`                                            |
| `lib/presentation/controllers/tutorial_controller.dart`                    | **Criar** — Notifier + provider                                                                |
| `lib/presentation/controllers/auth_controller.dart`                        | Modificar — método `markTutorialCompleted()`                                                   |
| `lib/presentation/screens/tutorial/tutorial_screen.dart`                   | **Criar**                                                                                      |
| `lib/presentation/screens/tutorial/widgets/tutorial_scaffold.dart`         | **Criar**                                                                                      |
| `lib/presentation/screens/tutorial/widgets/tutorial_dots_indicator.dart`   | **Criar**                                                                                      |
| `lib/presentation/screens/tutorial/widgets/tutorial_mini_board.dart`       | **Criar**                                                                                      |
| `lib/presentation/screens/tutorial/pages/tutorial_welcome_page.dart`       | **Criar**                                                                                      |
| `lib/presentation/screens/tutorial/pages/tutorial_movement_page.dart`      | **Criar**                                                                                      |
| `lib/presentation/screens/tutorial/pages/tutorial_fusion_page.dart`        | **Criar**                                                                                      |
| `lib/presentation/screens/tutorial/pages/tutorial_items_page.dart`         | **Criar**                                                                                      |
| `lib/presentation/screens/tutorial/pages/tutorial_finale_page.dart`        | **Criar**                                                                                      |
| `lib/presentation/screens/home_screen.dart`                                | Modificar — remover `_HowToPlaySheet`, navegar para `TutorialScreen`, semanticLabel "Tutorial" |
| `test/data/models/player_profile_test.dart`                                | **Criar/Modificar** — testes do novo campo                                                     |
| `test/presentation/controllers/tutorial_controller_test.dart`              | **Criar**                                                                                      |
| `test/presentation/screens/tutorial/widgets/tutorial_mini_board_test.dart` | **Criar**                                                                                      |
| `test/presentation/screens/tutorial/tutorial_screen_test.dart`             | **Criar**                                                                                      |

---

## Task 1 — `PlayerProfile`: adicionar `tutorialCompleted`

**Spec:** §4.1

**Files:**

- Modify: `lib/data/models/player_profile.dart`
- Create/Modify: `test/data/models/player_profile_test.dart`

- [ ] **Step 1.1: Escrever testes que falham**

```dart
// test/data/models/player_profile_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/player_profile.dart';

void main() {
  group('PlayerProfile.tutorialCompleted', () {
    final base = PlayerProfile(
      userId: 'u1',
      displayName: 'Test',
      provider: AuthProvider.email,
      createdAt: DateTime(2026, 1, 1),
      lastSeenAt: DateTime(2026, 1, 1),
    );

    test('default é false', () {
      expect(base.tutorialCompleted, false);
    });

    test('copyWith preserva outros campos', () {
      final updated = base.copyWith(tutorialCompleted: true);
      expect(updated.tutorialCompleted, true);
      expect(updated.userId, 'u1');
      expect(updated.displayName, 'Test');
    });

    test('toJson inclui o flag quando true', () {
      final json = base.copyWith(tutorialCompleted: true).toJson();
      expect(json['tutorialCompleted'], true);
    });

    test('fromJson sem o campo retorna false', () {
      final p = PlayerProfile.fromJson({
        'userId': 'u1',
        'displayName': 'Test',
        'provider': 'email',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'lastSeenAt': DateTime(2026, 1, 1).toIso8601String(),
      });
      expect(p.tutorialCompleted, false);
    });

    test('round-trip preserva o flag', () {
      final original = base.copyWith(tutorialCompleted: true);
      final restored = PlayerProfile.fromJson(original.toJson());
      expect(restored.tutorialCompleted, true);
    });
  });
}
```

```bash
flutter test test/data/models/player_profile_test.dart --no-pub
```

Esperado: FAIL (campo não existe).

- [ ] **Step 1.2: Adicionar campo, copyWith, toJson, fromJson**

Em `lib/data/models/player_profile.dart`:

- Adicionar `final bool tutorialCompleted;` no construtor (default `false`)
- Adicionar `bool? tutorialCompleted` ao `copyWith`
- Em `toJson`: `'tutorialCompleted': tutorialCompleted` (sempre, não condicional — facilita queries)
- Em `fromJson`: `tutorialCompleted: json['tutorialCompleted'] as bool? ?? false`

```bash
flutter test test/data/models/player_profile_test.dart --no-pub
```

Esperado: All tests passed.

- [ ] **Step 1.3: Análise estática**

```bash
flutter analyze lib/data/models/player_profile.dart
```

Esperado: No issues found.

- [ ] **Step 1.4: Commit**

```bash
git commit -m "feat: add tutorialCompleted to PlayerProfile"
```

---

## Task 2 — `SyncEngine`: contrato `updateTutorialCompleted`

**Spec:** §4.2

**Files:**

- Modify: `lib/domain/sync/sync_engine.dart`
- Modify: `lib/data/repositories/firebase_sync_engine.dart`

- [ ] **Step 2.1: Adicionar método à interface + FakeSyncEngine**

Em `lib/domain/sync/sync_engine.dart`:

```dart
abstract class SyncEngine {
  // ... métodos existentes
  Future<void> updateTutorialCompleted(bool completed);
}

class FakeSyncEngine implements SyncEngine {
  // ... campos existentes
  bool tutorialCompleted = false;

  @override
  Future<void> updateTutorialCompleted(bool completed) async {
    tutorialCompleted = completed;
  }
}
```

- [ ] **Step 2.2: Implementar em `FirebaseSyncEngine`**

Em `lib/data/repositories/firebase_sync_engine.dart`:

```dart
@override
Future<void> updateTutorialCompleted(bool completed) async {
  final user = _auth.currentUser;
  if (user == null) return;
  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'tutorialCompleted': completed,
  }, SetOptions(merge: true));
}
```

- [ ] **Step 2.3: Análise estática**

```bash
flutter analyze lib/domain/sync/sync_engine.dart lib/data/repositories/firebase_sync_engine.dart
```

Esperado: No issues found.

- [ ] **Step 2.4: Commit**

```bash
git commit -m "feat(sync): add updateTutorialCompleted to SyncEngine"
```

---

## Task 3 — `TutorialController` (Riverpod)

**Spec:** §4.3, §4.4

**Files:**

- Create: `lib/presentation/controllers/tutorial_controller.dart`
- Create: `test/presentation/controllers/tutorial_controller_test.dart`

- [ ] **Step 3.1: Escrever testes**

```dart
// test/presentation/controllers/tutorial_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capivara_2048/presentation/controllers/tutorial_controller.dart';
import 'package:capivara_2048/domain/sync/sync_engine.dart';
import 'package:capivara_2048/data/models/player_profile.dart';

void main() {
  group('TutorialController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isCompleted false por padrão (anônimo)', () async {
      final container = ProviderContainer(overrides: [
        syncEngineProvider.overrideWithValue(FakeSyncEngine()),
      ]);
      final controller = container.read(tutorialControllerProvider.notifier);
      final completed = await controller.isCompleted();
      expect(completed, false);
    });

    test('markCompleted (anônimo) salva em SharedPreferences', () async {
      final container = ProviderContainer(overrides: [
        syncEngineProvider.overrideWithValue(FakeSyncEngine()),
      ]);
      final controller = container.read(tutorialControllerProvider.notifier);
      await controller.markCompleted();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('tutorial_completed'), true);
    });

    test('markCompleted (logado) chama syncEngine', () async {
      final fake = FakeSyncEngine();
      final container = ProviderContainer(overrides: [
        syncEngineProvider.overrideWithValue(fake),
        currentProfileProvider.overrideWithValue(
          PlayerProfile(
            userId: 'u1',
            displayName: 'Test',
            provider: AuthProvider.email,
            createdAt: DateTime.now(),
            lastSeenAt: DateTime.now(),
          ),
        ),
      ]);
      await container
          .read(tutorialControllerProvider.notifier)
          .markCompleted();
      expect(fake.tutorialCompleted, true);
    });
  });
}
```

```bash
flutter test test/presentation/controllers/tutorial_controller_test.dart --no-pub
```

Esperado: FAIL (controller não existe).

- [ ] **Step 3.2: Implementar `TutorialController`**

```dart
// lib/presentation/controllers/tutorial_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/sync/sync_engine.dart';
import 'auth_controller.dart';

class TutorialController extends Notifier<void> {
  static const _prefsKey = 'tutorial_completed';

  @override
  void build() {}

  Future<bool> isCompleted() async {
    final profile = ref.read(currentProfileProvider);
    if (profile != null) {
      return profile.tutorialCompleted;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> markCompleted() async {
    final profile = ref.read(currentProfileProvider);
    if (profile != null) {
      // Sync remoto + atualização otimista do perfil local
      await ref.read(syncEngineProvider).updateTutorialCompleted(true);
      ref.read(authControllerProvider.notifier).updateProfileTutorialFlag(true);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, true);
    }
  }
}

final tutorialControllerProvider =
    NotifierProvider<TutorialController, void>(TutorialController.new);
```

> **Nota:** se `currentProfileProvider` ou `syncEngineProvider` tiverem nomes diferentes no codebase, ajustar imports. Verificar via `grep -rn "currentProfileProvider\|syncEngineProvider" lib/` antes de codar.

- [ ] **Step 3.3: Adicionar `updateProfileTutorialFlag` em `AuthController`**

Em `lib/presentation/controllers/auth_controller.dart`, dentro da classe `AuthController`:

```dart
void updateProfileTutorialFlag(bool completed) {
  final current = state.value;
  if (current == null) return;
  state = AsyncData(current.copyWith(tutorialCompleted: completed));
}
```

(Ajustar conforme padrão real do `AuthController` — usa `state` ou outro mecanismo de update.)

- [ ] **Step 3.4: Rodar testes**

```bash
flutter test test/presentation/controllers/tutorial_controller_test.dart --no-pub
```

Esperado: All tests passed.

- [ ] **Step 3.5: Commit**

```bash
git commit -m "feat: add TutorialController + persistence (Firestore + SharedPreferences)"
```

---

## Task 4 — `TutorialMiniBoard` widget

**Spec:** §3.2, §3.3, §3.4

**Files:**

- Create: `lib/presentation/screens/tutorial/widgets/tutorial_mini_board.dart`
- Create: `test/presentation/screens/tutorial/widgets/tutorial_mini_board_test.dart`

- [ ] **Step 4.1: Escrever testes**

```dart
// test/presentation/screens/tutorial/widgets/tutorial_mini_board_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/animals_data.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/domain/game_engine/direction.dart';
import 'package:capivara_2048/presentation/screens/tutorial/widgets/tutorial_mini_board.dart';

void main() {
  group('TutorialMiniBoard', () {
    testWidgets('renderiza N células conforme initialTiles.length',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TutorialMiniBoard(
            initialTiles: [
              Tile(id: '1', level: 1),
              null,
            ],
            acceptedDirections: const {Direction.right},
            mergedResult: null,
            onCorrectSwipe: () {},
          ),
        ),
      ));
      // 2 células renderizadas
      expect(find.byKey(const Key('tutorial_cell_0')), findsOneWidget);
      expect(find.byKey(const Key('tutorial_cell_1')), findsOneWidget);
    });

    testWidgets('swipe na direção aceita chama onCorrectSwipe',
        (tester) async {
      var called = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TutorialMiniBoard(
            initialTiles: [Tile(id: '1', level: 1), null],
            acceptedDirections: const {Direction.right},
            mergedResult: null,
            onCorrectSwipe: () => called = true,
          ),
        ),
      ));
      await tester.fling(
        find.byKey(const Key('tutorial_mini_board')),
        const Offset(200, 0),
        1000,
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 800));
      expect(called, true);
    });

    testWidgets('swipe em direção rejeitada não chama callback',
        (tester) async {
      var called = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TutorialMiniBoard(
            initialTiles: [Tile(id: '1', level: 1), null],
            acceptedDirections: const {Direction.right},
            mergedResult: null,
            onCorrectSwipe: () => called = true,
          ),
        ),
      ));
      await tester.fling(
        find.byKey(const Key('tutorial_mini_board')),
        const Offset(-200, 0),
        1000,
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 800));
      expect(called, false);
    });
  });
}
```

```bash
flutter test test/presentation/screens/tutorial/widgets/tutorial_mini_board_test.dart --no-pub
```

Esperado: FAIL (widget não existe).

- [ ] **Step 4.2: Implementar `TutorialMiniBoard`**

Esqueleto:

```dart
// lib/presentation/screens/tutorial/widgets/tutorial_mini_board.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../data/models/tile.dart';
import '../../../../domain/game_engine/direction.dart';
import '../../../widgets/tile_widget.dart';

class TutorialMiniBoard extends StatefulWidget {
  final List<Tile?> initialTiles;
  final Set<Direction> acceptedDirections;
  final Tile? mergedResult;
  final VoidCallback onCorrectSwipe;
  final double tileSize;

  const TutorialMiniBoard({
    super.key,
    required this.initialTiles,
    required this.acceptedDirections,
    required this.mergedResult,
    required this.onCorrectSwipe,
    this.tileSize = 90,
  });

  @override
  State<TutorialMiniBoard> createState() => _TutorialMiniBoardState();
}

class _TutorialMiniBoardState extends State<TutorialMiniBoard> {
  late List<Tile?> _tiles;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _tiles = List.of(widget.initialTiles);
  }

  Direction? _resolveDirection(Offset velocity) {
    if (velocity.distance < 100) return null;
    if (velocity.dx.abs() > velocity.dy.abs()) {
      return velocity.dx > 0 ? Direction.right : Direction.left;
    }
    return velocity.dy > 0 ? Direction.down : Direction.up;
  }

  void _handleSwipe(Direction dir) {
    if (_resolved) return;
    if (!widget.acceptedDirections.contains(dir)) return;
    setState(() => _resolved = true);

    // Estado pós-swipe: se há mergedResult, fundir; senão só mover
    setState(() {
      if (widget.mergedResult != null) {
        _tiles = [null, widget.mergedResult]; // simples para 1×2
      } else {
        // movimento: mover tile não-nulo pra última posição
        final t = _tiles.firstWhere((e) => e != null, orElse: () => null);
        _tiles = List.filled(_tiles.length, null);
        _tiles[_tiles.length - 1] = t;
      }
    });

    Future.delayed(const Duration(milliseconds: 600), widget.onCorrectSwipe);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('tutorial_mini_board'),
      onPanEnd: (details) {
        final dir = _resolveDirection(details.velocity.pixelsPerSecond);
        if (dir != null) _handleSwipe(dir);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8D5B7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_tiles.length, (i) {
            final tile = _tiles[i];
            return Padding(
              key: Key('tutorial_cell_$i'),
              padding: const EdgeInsets.all(4),
              child: SizedBox(
                width: widget.tileSize,
                height: widget.tileSize,
                child: TileWidget(tile: tile, size: widget.tileSize),
              ),
            );
          }),
        ),
      ),
    );
  }
}
```

> **Atenção:** verificar a assinatura real do construtor de `Tile` (campos `id`, `level`) consultando `lib/data/models/tile.dart` antes de implementar. Ajustar conforme necessário.

- [ ] **Step 4.3: Rodar testes**

```bash
flutter test test/presentation/screens/tutorial/widgets/tutorial_mini_board_test.dart --no-pub
```

Esperado: All tests passed.

- [ ] **Step 4.4: Commit**

```bash
git commit -m "feat(tutorial): add TutorialMiniBoard widget (independent of GameEngine)"
```

---

## Task 5 — `TutorialScaffold` + `TutorialDotsIndicator`

**Spec:** §3.5, §6

**Files:**

- Create: `lib/presentation/screens/tutorial/widgets/tutorial_scaffold.dart`
- Create: `lib/presentation/screens/tutorial/widgets/tutorial_dots_indicator.dart`

- [ ] **Step 5.1: Implementar `TutorialDotsIndicator`**

```dart
// lib/presentation/screens/tutorial/widgets/tutorial_dots_indicator.dart
import 'package:flutter/material.dart';

class TutorialDotsIndicator extends StatelessWidget {
  final int total;
  final int current;
  const TutorialDotsIndicator({
    super.key,
    required this.total,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white38,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
```

- [ ] **Step 5.2: Implementar `TutorialScaffold`**

```dart
// lib/presentation/screens/tutorial/widgets/tutorial_scaffold.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../widgets/game_background.dart';
import 'tutorial_dots_indicator.dart';

class TutorialScaffold extends StatelessWidget {
  final Widget body;
  final int currentPage;
  final int totalPages;
  final bool canGoNext;
  final String nextLabel;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const TutorialScaffold({
    super.key,
    required this.body,
    required this.currentPage,
    required this.totalPages,
    required this.canGoNext,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Tutorial',
            style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: onSkip,
              child: Text(
                'Pular',
                style: outlinedWhiteTextStyle(
                  GoogleFonts.fredoka(fontSize: 15, color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: body),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 100,
                      child: onBack == null
                          ? const SizedBox.shrink()
                          : TextButton(
                              onPressed: onBack,
                              child: Text(
                                '← Voltar',
                                style: outlinedWhiteTextStyle(
                                  GoogleFonts.fredoka(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    TutorialDotsIndicator(
                      total: totalPages,
                      current: currentPage,
                    ),
                    SizedBox(
                      width: 100,
                      child: TextButton(
                        onPressed: canGoNext ? onNext : null,
                        child: Text(
                          nextLabel,
                          textAlign: TextAlign.right,
                          style: outlinedWhiteTextStyle(
                            GoogleFonts.fredoka(
                              fontSize: 16,
                              color: canGoNext ? Colors.white : Colors.white24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5.3: Análise estática**

```bash
flutter analyze lib/presentation/screens/tutorial/widgets/
```

Esperado: No issues found.

- [ ] **Step 5.4: Commit**

```bash
git commit -m "feat(tutorial): add TutorialScaffold + dots indicator"
```

---

## Task 6 — Páginas 1, 4 e 5 (estáticas/ilustradas)

**Spec:** §2, §6, §7

**Files:**

- Create: `lib/presentation/screens/tutorial/pages/tutorial_welcome_page.dart`
- Create: `lib/presentation/screens/tutorial/pages/tutorial_items_page.dart`
- Create: `lib/presentation/screens/tutorial/pages/tutorial_finale_page.dart`

- [ ] **Step 6.1: `TutorialWelcomePage`**

Conteúdo:

- `GameTitleImage` (largura adaptativa)
- `OutlinedText('Bem-vindo à floresta', fredoka(28, w600))`
- `outlinedWhiteTextStyle(fredoka(16, height: 1.5))` com copy da spec §2.1
- Animação: fade + slideY de entrada (`flutter_animate`)

- [ ] **Step 6.2: `TutorialItemsPage`**

Conteúdo:

- Título: "Suas ferramentas"
- 3 cards brancos (Card + Color.white.withValues(alpha: 0.88)):
  - Bomba — `Image.asset('assets/images/inventory/bomb_3.png', width: 48)` + título Fredoka + corpo Nunito
  - Desfazer — `Image.asset('assets/images/inventory/undo_1.png', width: 48)`
  - Vidas — `Icon(Icons.favorite, color: Colors.red, size: 48)`
- Cada card entra com slideX staggered (delay 100ms entre eles)

- [ ] **Step 6.3: `TutorialFinalePage`**

Conteúdo:

- Capivara grande: `Image.asset('assets/images/animals/tile/Capivara.png', width: 200)` com `.animate(onPlay: (c) => c.repeat()).scale(begin: Offset(1, 1), end: Offset(1.03, 1.03), duration: 2.seconds)`
- Título: "A Capivara Lendária te espera"
- Corpo: copy spec §2.1
- (Botão "Começar a aventura" fica no `TutorialScaffold` — não nesta página)

- [ ] **Step 6.4: Análise estática**

```bash
flutter analyze lib/presentation/screens/tutorial/pages/tutorial_welcome_page.dart lib/presentation/screens/tutorial/pages/tutorial_items_page.dart lib/presentation/screens/tutorial/pages/tutorial_finale_page.dart
```

Esperado: No issues found.

- [ ] **Step 6.5: Commit**

```bash
git commit -m "feat(tutorial): add Welcome, Items and Finale pages"
```

---

## Task 7 — Páginas 2 e 3 (interativas)

**Spec:** §2, §3.4, §7

**Files:**

- Create: `lib/presentation/screens/tutorial/pages/tutorial_movement_page.dart`
- Create: `lib/presentation/screens/tutorial/pages/tutorial_fusion_page.dart`

- [ ] **Step 7.1: `TutorialMovementPage`**

`StatefulWidget` que recebe `VoidCallback onUserCompleted` (chamado pelo `TutorialMiniBoard.onCorrectSwipe`).

Conteúdo:

- Título: "Deslize pra mover"
- Corpo: copy spec §2.1
- `TutorialMiniBoard` com:
  - `initialTiles: [Tile(level: 1), null]` (1 Tanajura)
  - `acceptedDirections: {Direction.right}`
  - `mergedResult: null` (não funde, só move)
- Hint pulsante abaixo: "👉 Tente deslizar pra direita" (some quando `_completed == true`)
- Quando jogador acerta, exibir overlay "✓ Boa!" antes de o wizard avançar

- [ ] **Step 7.2: `TutorialFusionPage`**

Análogo ao 7.1, mas:

- `initialTiles: [Tile(level: 1), Tile(level: 1)]`
- `acceptedDirections: {Direction.left, Direction.right}`
- `mergedResult: Tile(level: 2)` (Lobo-guará)
- Texto pós-acerto: "✓ Você fez evoluir um bicho!"

- [ ] **Step 7.3: Análise estática**

```bash
flutter analyze lib/presentation/screens/tutorial/pages/
```

Esperado: No issues found.

- [ ] **Step 7.4: Commit**

```bash
git commit -m "feat(tutorial): add Movement and Fusion interactive pages"
```

---

## Task 8 — `TutorialScreen` (orquestrador)

**Spec:** §3.5

**Files:**

- Create: `lib/presentation/screens/tutorial/tutorial_screen.dart`
- Create: `test/presentation/screens/tutorial/tutorial_screen_test.dart`

- [ ] **Step 8.1: Escrever testes**

```dart
// test/presentation/screens/tutorial/tutorial_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/presentation/screens/tutorial/tutorial_screen.dart';

void main() {
  Widget app() => ProviderScope(
        child: MaterialApp(home: TutorialScreen()),
      );

  group('TutorialScreen', () {
    testWidgets('renderiza tela 1 (Boas-vindas) ao abrir', (tester) async {
      await tester.pumpWidget(app());
      expect(find.textContaining('Bem-vindo'), findsOneWidget);
    });

    testWidgets('botão Pular fecha o tutorial', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ProviderScope(
          child: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(builder: (_) => const TutorialScreen()),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Tutorial'), findsOneWidget);
      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();
      expect(find.text('Tutorial'), findsNothing);
    });

    testWidgets('Próximo desabilitado em página interativa', (tester) async {
      await tester.pumpWidget(app());
      // Avança da página 1 (welcome) → 2 (movement)
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();
      // Próximo está cinza/desabilitado
      final btn = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Próximo'),
          matching: find.byType(TextButton),
        ),
      );
      expect(btn.onPressed, isNull);
    });
  });
}
```

```bash
flutter test test/presentation/screens/tutorial/tutorial_screen_test.dart --no-pub
```

Esperado: FAIL.

- [ ] **Step 8.2: Implementar `TutorialScreen`**

```dart
// lib/presentation/screens/tutorial/tutorial_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/tutorial_controller.dart';
import 'pages/tutorial_welcome_page.dart';
import 'pages/tutorial_movement_page.dart';
import 'pages/tutorial_fusion_page.dart';
import 'pages/tutorial_items_page.dart';
import 'pages/tutorial_finale_page.dart';
import 'widgets/tutorial_scaffold.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final _controller = PageController();
  int _currentPage = 0;
  // Em páginas interativas, fica false até onUserCompleted
  final Map<int, bool> _interactiveCompleted = {1: false, 2: false};

  static const _totalPages = 5;

  bool get _isInteractive =>
      _currentPage == 1 || _currentPage == 2;

  bool get _canGoNext =>
      !_isInteractive || (_interactiveCompleted[_currentPage] ?? false);

  String get _nextLabel =>
      _currentPage == _totalPages - 1 ? 'Começar' : 'Próximo →';

  void _next() {
    if (_currentPage == _totalPages - 1) {
      _complete();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onInteractiveCompleted(int page) {
    setState(() => _interactiveCompleted[page] = true);
    // Auto-avanço opcional após pequeno delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _currentPage == page) _next();
    });
  }

  Future<void> _complete() async {
    await ref.read(tutorialControllerProvider.notifier).markCompleted();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return TutorialScaffold(
      currentPage: _currentPage,
      totalPages: _totalPages,
      canGoNext: _canGoNext,
      nextLabel: _nextLabel,
      onBack: _currentPage == 0 ? null : _back,
      onNext: _next,
      onSkip: _complete,
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentPage = i),
        children: [
          const TutorialWelcomePage(),
          TutorialMovementPage(
            onUserCompleted: () => _onInteractiveCompleted(1),
          ),
          TutorialFusionPage(
            onUserCompleted: () => _onInteractiveCompleted(2),
          ),
          const TutorialItemsPage(),
          const TutorialFinalePage(),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8.3: Rodar testes**

```bash
flutter test test/presentation/screens/tutorial/tutorial_screen_test.dart --no-pub
```

Esperado: All tests passed.

- [ ] **Step 8.4: Commit**

```bash
git commit -m "feat(tutorial): add TutorialScreen orchestrator with PageView"
```

---

## Task 9 — Integrar na Home

**Spec:** §5.1

**Files:**

- Modify: `lib/presentation/screens/home_screen.dart`

- [ ] **Step 9.1: Substituir `_HowToPlaySheet` por navegação**

Em `lib/presentation/screens/home_screen.dart`:

1. Remover a classe `_HowToPlaySheet` inteira (linhas ~450-502 conforme estado atual)
2. Adicionar import: `import 'tutorial/tutorial_screen.dart';`
3. No botão `home_btn_comojogar`:

```dart
_HomeButton(
  key: const Key('home_btn_comojogar'),
  path: 'assets/images/home/ComoJogar.png',
  size: HomeConstants.buttonSize(scale),
  semanticLabel: 'Tutorial',
  onTap: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const TutorialScreen()),
  ),
),
```

- [ ] **Step 9.2: Verificar que nada mais referencia `_HowToPlaySheet`**

```bash
grep -rn "_HowToPlaySheet\|HowToPlay" lib/ test/
```

Esperado: zero matches (ou apenas em arquivos de spec/plan).

- [ ] **Step 9.3: Análise estática + smoke build**

```bash
flutter analyze lib/presentation/screens/home_screen.dart
flutter build apk --debug --flavor dev --dart-define=FLAVOR=dev 2>&1 | tail -10
```

Esperado: No issues found + build OK.

- [ ] **Step 9.4: Commit**

```bash
git commit -m "feat(home): replace HowToPlaySheet with TutorialScreen navigation"
```

---

## Task 10 — Verificação final

**Spec:** geral

- [ ] **Step 10.1: Rodar suite completa**

```bash
flutter test
```

Esperado: todos os testes passam (incluindo os 4 novos arquivos).

- [ ] **Step 10.2: Análise estática completa**

```bash
flutter analyze lib/
```

Esperado: No issues found.

- [ ] **Step 10.3: Smoke manual em emulador**

```bash
flutter run --dart-define=FLAVOR=tst
```

Manual checks:

- [ ] Botão "Como Jogar" na home abre `TutorialScreen` (não BottomSheet)
- [ ] Tela 1 mostra logo + boas-vindas; "Próximo" habilitado
- [ ] Tela 2: tile pulsa; swipe direita avança; swipe esquerda não faz nada
- [ ] Tela 3: 2 tiles; swipe funde com animação; vira Lobo-guará
- [ ] Tela 4: 3 cards (bomba, desfazer, vidas) com ícones
- [ ] Tela 5: Capivara grande com bounce; botão "Começar"
- [ ] Botão "Pular" no AppBar funciona em qualquer tela
- [ ] "Voltar" funciona da tela 2 em diante
- [ ] Após completar, dar pop volta pra Home

- [ ] **Step 10.4: Atualizar CHANGELOG.md**

```markdown
## [Unreleased] (próxima versão)

### Added

- **Tutorial wizard interativo:** novo `TutorialScreen` substitui `_HowToPlaySheet`, com 5 telas (Boas-vindas, Movimento, Fusão, Itens, Capivara Lendária), 2 telas interativas (mini-boards onde o jogador faz swipe), animações com flutter_animate
- **`PlayerProfile.tutorialCompleted`:** persistência do estado do tutorial (Firestore para logados, SharedPreferences para anônimos)

### Changed

- Botão "Como Jogar" na home agora abre tela cheia em vez de BottomSheet; semanticLabel renomeado para "Tutorial"

### Removed

- `_HowToPlaySheet` (substituído pelo `TutorialScreen`)
```

- [ ] **Step 10.5: Atualizar AGENTS.md**

Em `AGENTS.md`, marcar fase 4.4 como completa (ou criar entrada nova caso ainda não exista) na tabela de Roadmap.

- [ ] **Step 10.6: Commit de fechamento + tag**

```bash
git add CHANGELOG.md AGENTS.md
git commit -m "docs: changelog + roadmap for Tutorial wizard (Fase 4.4)"
```

---

## Resumo de risco / áreas de atenção

| Área                                            | Atenção                                                                                       |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `currentProfileProvider` / `syncEngineProvider` | Verificar nomes reais antes de usar (Task 3.2)                                                |
| `Tile` constructor                              | Confirmar campos (`id`, `level`, etc.) em `lib/data/models/tile.dart` antes de Task 4.2 e 7.1 |
| `Direction` enum                                | Confirmar valores em `lib/domain/game_engine/direction.dart`                                  |
| `GameBackground` widget                         | Confirmar API (toma `child` ou `body`)                                                        |
| `outlinedWhiteTextStyle`                        | Confirmar localização em `lib/core/theme/text_styles.dart`                                    |
| `AuthController` state shape                    | Pode ser `AsyncValue<PlayerProfile?>` ou outro — ajustar `updateProfileTutorialFlag`          |

Cada uma dessas verificações leva < 1 min com `grep` ou leitura rápida e evita retrabalho.
