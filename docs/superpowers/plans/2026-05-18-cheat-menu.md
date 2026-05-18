# Cheat Menu (Debug) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Substituir o menu de debug de galeria de animais por um Cheat Menu com controles de vidas, itens e pulo de nível — acessível apenas em `kDebugMode` pelo `PauseOverlay`.

**Architecture:** Dois métodos novos nos notifiers (`debugSetLives`, `debugJumpToLevel`) encapsulam toda a lógica; `CheatMenuScreen` é um `ConsumerStatefulWidget` puro que chama esses métodos. O `PauseOverlay` troca o botão "Debug" por "Cheats" com navegação para a nova tela.

**Tech Stack:** Flutter / Dart, Riverpod (`ConsumerStatefulWidget`, providers), `uuid` (já disponível), `google_fonts`, `flutter_test`.

---

## Task 1: `debugSetLives` no LivesNotifier

**Files:**
- Modify: `lib/domain/lives/lives_notifier.dart`
- Modify: `test/domain/lives_notifier_test.dart`

- [ ] **Step 1.1: Adicionar testes para `debugSetLives` em `test/domain/lives_notifier_test.dart`**

Adicionar ao final do arquivo (antes do `}`  que fecha `main()`), junto com a classe auxiliar:

```dart
class _FakeLivesRepository implements LivesRepository {
  @override Future<LivesState> load() async => LivesState.initial();
  @override Future<void> save(LivesState state) async {}
  @override Future<bool> getMigrationFlag(String key) async => true;
  @override Future<void> setMigrationFlag(String key) async {}
}
```

E dentro de `main()`:

```dart
  group('debugSetLives', () {
    late ProviderContainer container;

    setUp(() async {
      container = ProviderContainer(
        overrides: [
          livesRepositoryProvider.overrideWithValue(_FakeLivesRepository()),
        ],
      );
      await container.read(livesProvider.notifier).awaitReady();
    });

    tearDown(() => container.dispose());

    test('sets lives to given value', () {
      container.read(livesProvider.notifier).debugSetLives(3);
      expect(container.read(livesProvider).lives, 3);
    });

    test('clamps to 0 when negative', () {
      container.read(livesProvider.notifier).debugSetLives(-1);
      expect(container.read(livesProvider).lives, 0);
    });

    test('clamps to earnedCap (15) when over', () {
      container.read(livesProvider.notifier).debugSetLives(20);
      expect(container.read(livesProvider).lives, 15);
    });
  });
```

Os imports necessários no topo do arquivo (adicionar os que faltam):

```dart
import 'package:capivara_2048/data/repositories/lives_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

- [ ] **Step 1.2: Rodar os testes — esperar FAIL**

```
flutter test test/domain/lives_notifier_test.dart
```

Esperado: falha com `NoSuchMethodError` ou `MissingPluginException` pois `debugSetLives` não existe.

- [ ] **Step 1.3: Implementar `debugSetLives` em `lib/domain/lives/lives_notifier.dart`**

Adicionar logo antes do método `debugSetState` existente (linha ~234):

```dart
  void debugSetLives(int n) {
    if (!kDebugMode) return;
    state = state.copyWith(lives: n.clamp(0, state.earnedCap));
  }
```

`kDebugMode` já está disponível via `import 'package:flutter/widgets.dart'` que existe no arquivo.

- [ ] **Step 1.4: Rodar os testes — esperar PASS**

```
flutter test test/domain/lives_notifier_test.dart
```

Esperado: todos os testes passam (inclusive os existentes de `applyRegen`, `applyConsume`, etc.).

- [ ] **Step 1.5: Commit**

```bash
git add lib/domain/lives/lives_notifier.dart test/domain/lives_notifier_test.dart
git commit -m "feat(debug): adicionar debugSetLives ao LivesNotifier"
```

---

## Task 2: `debugJumpToLevel` no GameNotifier

**Files:**
- Modify: `lib/presentation/controllers/game_notifier.dart`
- Create: `test/presentation/game_notifier_debug_test.dart`

- [ ] **Step 2.1: Criar `test/presentation/game_notifier_debug_test.dart`**

```dart
import 'dart:math';
import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/presentation/controllers/game_notifier.dart';
import 'package:capivara_2048/presentation/controllers/personal_records_notifier.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePersonalRecordsNotifier extends PersonalRecordsNotifier {
  @override
  Future<void> updateHighestLevel(int level) async {}
  @override
  Future<void> recordMilestone(int level, DateTime reachedAt) async {}
}

class _FakePrefs implements SharedPreferences {
  @override
  bool? getBool(String key) => null;
  @override
  Future<bool> setBool(String key, bool value) async => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeInventoryRepository implements InventoryRepository {
  @override
  Future<Inventory> load() async => Inventory.empty();
  @override
  Future<void> save(Inventory inventory) async {}
}

ProviderContainer _createContainer() {
  SharedPreferences.setMockInitialValues({});
  return ProviderContainer(
    overrides: [
      personalRecordsProvider.overrideWith(
          () => _FakePersonalRecordsNotifier()),
      sharedPreferencesProvider.overrideWithValue(_FakePrefs()),
      inventoryRepositoryProvider
          .overrideWithValue(_FakeInventoryRepository()),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('debugJumpToLevel', () {
    late ProviderContainer container;

    setUp(() => container = _createContainer());
    tearDown(() => container.dispose());

    test('sets maxLevel to targetLevel', () {
      container.read(gameProvider.notifier).debugJumpToLevel(7);
      expect(container.read(gameProvider).maxLevel, 7);
    });

    test('board contains tile at targetLevel', () {
      container.read(gameProvider.notifier).debugJumpToLevel(7);
      final board = container.read(gameProvider).board;
      final levels = board
          .expand((row) => row)
          .whereType<Tile>()
          .map((t) => t.level)
          .toList();
      expect(levels, contains(7));
    });

    test('score equals sum of (1 << tile.level) for all tiles', () {
      container.read(gameProvider.notifier).debugJumpToLevel(5);
      final state = container.read(gameProvider);
      final expected = state.board
          .expand((row) => row)
          .whereType<Tile>()
          .fold(0, (sum, t) => sum + (1 << t.level));
      expect(state.score, expected);
    });

    test('isPaused is false after jump', () {
      container.read(gameProvider.notifier).debugJumpToLevel(3);
      expect(container.read(gameProvider).isPaused, false);
    });

    test('isGameOver is false after jump', () {
      container.read(gameProvider.notifier).debugJumpToLevel(11);
      expect(container.read(gameProvider).isGameOver, false);
    });

    test('all tile levels >= 1 for targetLevel 1', () {
      container.read(gameProvider.notifier).debugJumpToLevel(1);
      final board = container.read(gameProvider).board;
      final levels = board
          .expand((row) => row)
          .whereType<Tile>()
          .map((t) => t.level)
          .toList();
      expect(levels.every((l) => l >= 1), true);
    });
  });
}
```

- [ ] **Step 2.2: Rodar o teste — esperar FAIL**

```
flutter test test/presentation/game_notifier_debug_test.dart
```

Esperado: falha com `NoSuchMethodError: The method 'debugJumpToLevel' was called on an instance of 'GameNotifier'`.

- [ ] **Step 2.3: Implementar `debugJumpToLevel` em `lib/presentation/controllers/game_notifier.dart`**

Adicionar logo após o método `debugSetState` existente (por volta da linha 265). Verificar que `uuid` já está importado no topo do arquivo (`import 'package:uuid/uuid.dart'`):

```dart
  void debugJumpToLevel(int targetLevel) {
    if (!kDebugMode) return;

    const uuid = Uuid();
    Tile makeTile(int level, int row, int col) =>
        Tile(id: uuid.v4(), level: level, row: row, col: col);
    int lvl(int delta) => max(1, targetLevel - delta);

    final board = List.generate(4, (_) => List<Tile?>.filled(4, null));
    board[0][3] = makeTile(targetLevel, 0, 3);
    board[0][2] = makeTile(lvl(1), 0, 2);
    board[1][3] = makeTile(lvl(2), 1, 3);
    board[3][0] = makeTile(lvl(3), 3, 0);
    board[3][2] = makeTile(1, 3, 2);
    board[3][3] = makeTile(1, 3, 3);

    final score = board
        .expand((row) => row)
        .whereType<Tile>()
        .fold(0, (sum, t) => sum + (1 << t.level));

    _stopTimer();
    _firestoreSaveTimer?.cancel();
    state = GameState(
      board: board,
      score: score,
      highScore: max(state.highScore, score),
      maxLevel: targetLevel,
      hasWon: false,
      isGameOver: false,
      isPaused: false,
    );
  }
```

`max` requer `dart:math` — verificar que já está importado no arquivo. Caso não esteja, adicionar `import 'dart:math';` ao topo.

- [ ] **Step 2.4: Rodar os testes — esperar PASS**

```
flutter test test/presentation/game_notifier_debug_test.dart
```

Esperado: 6 testes passando.

- [ ] **Step 2.5: Commit**

```bash
git add lib/presentation/controllers/game_notifier.dart test/presentation/game_notifier_debug_test.dart
git commit -m "feat(debug): adicionar debugJumpToLevel ao GameNotifier"
```

---

## Task 3: CheatMenuScreen

**Files:**
- Create: `lib/presentation/screens/debug/cheat_menu_screen.dart`

- [ ] **Step 3.1: Criar `lib/presentation/screens/debug/cheat_menu_screen.dart`**

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/animals_data.dart';
import '../../../data/models/item_type.dart';
import '../../../domain/inventory/inventory_notifier.dart';
import '../../../domain/lives/lives_notifier.dart';
import '../../controllers/game_notifier.dart';

class CheatMenuScreen extends ConsumerStatefulWidget {
  const CheatMenuScreen({super.key});

  @override
  ConsumerState<CheatMenuScreen> createState() => _CheatMenuScreenState();
}

class _CheatMenuScreenState extends ConsumerState<CheatMenuScreen> {
  late int _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = ref.read(gameProvider).maxLevel.clamp(1, 13);
  }

  @override
  Widget build(BuildContext context) {
    final lives = ref.watch(livesProvider).lives;
    final inventory = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('🧪 Cheat Menu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Vidas'),
          _CounterRow(
            label: 'Vidas',
            count: lives,
            onIncrement: () =>
                ref.read(livesProvider.notifier).addPurchased(1),
            onDecrement: lives > 0
                ? () => ref
                    .read(livesProvider.notifier)
                    .debugSetLives(lives - 1)
                : null,
          ),
          const Divider(height: 32),
          _SectionHeader('Itens'),
          for (final type in ItemType.values)
            _CounterRow(
              label: _itemLabel(type),
              count: inventory.count(type),
              onIncrement: () =>
                  ref.read(inventoryProvider.notifier).add(type, 1),
              onDecrement: inventory.count(type) > 0
                  ? () =>
                      ref.read(inventoryProvider.notifier).consume(type)
                  : null,
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () =>
                ref.read(inventoryProvider.notifier).addDebugItems(),
            child: const Text('Dar 5 de cada'),
          ),
          const Divider(height: 32),
          _SectionHeader('Pular para Nível'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final animal in animals)
                ChoiceChip(
                  label: Text(
                    '${animal.level} ${animal.name}',
                    style: GoogleFonts.fredoka(fontSize: 13),
                  ),
                  selected: _selectedLevel == animal.level,
                  onSelected: (_) =>
                      setState(() => _selectedLevel = animal.level),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(gameProvider.notifier)
                  .debugJumpToLevel(_selectedLevel);
              Navigator.of(context).pop();
            },
            child: Text(
              '▶ Ir para Nível $_selectedLevel — ${animals[_selectedLevel - 1].name}',
            ),
          ),
        ],
      ),
    );
  }

  String _itemLabel(ItemType type) => switch (type) {
        ItemType.bomb2 => 'Bomba 2×2',
        ItemType.bomb3 => 'Bomba 3×3',
        ItemType.undo1 => 'Desfazer ×1',
        ItemType.undo3 => 'Desfazer ×3',
      };
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.fredoka(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;

  const _CounterRow({
    required this.label,
    required this.count,
    required this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: onDecrement,
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3.2: Verificar compilação**

```
flutter analyze lib/presentation/screens/debug/cheat_menu_screen.dart
```

Esperado: sem erros. Corrigir quaisquer avisos de tipo antes de continuar.

- [ ] **Step 3.3: Commit**

```bash
git add lib/presentation/screens/debug/cheat_menu_screen.dart
git commit -m "feat(debug): criar CheatMenuScreen"
```

---

## Task 4: Wiring — PauseOverlay, deletar AnimalsGalleryScreen, testar

**Files:**
- Modify: `lib/presentation/widgets/pause_overlay.dart`
- Delete: `lib/presentation/screens/debug/animals_gallery_screen.dart`
- Modify: `test/presentation/pause_overlay_test.dart`

- [ ] **Step 4.1: Atualizar `lib/presentation/widgets/pause_overlay.dart`**

Trocar o import:

```dart
// REMOVER:
import '../screens/debug/animals_gallery_screen.dart';

// ADICIONAR:
import '../screens/debug/cheat_menu_screen.dart';
```

Trocar o bloco `if (kDebugMode)` (linhas ~107–118 atuais):

```dart
// REMOVER:
if (kDebugMode)
  TextButton(
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AnimalsGalleryScreen(),
      ),
    ),
    child: OutlinedText(
      text: 'Debug',
      style: const TextStyle(color: Colors.white70),
    ),
  ),

// SUBSTITUIR POR:
if (kDebugMode)
  TextButton(
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CheatMenuScreen(),
      ),
    ),
    child: OutlinedText(
      text: 'Cheats',
      style: const TextStyle(color: Colors.white70),
    ),
  ),
```

- [ ] **Step 4.2: Deletar `lib/presentation/screens/debug/animals_gallery_screen.dart`**

```bash
rm lib/presentation/screens/debug/animals_gallery_screen.dart
```

- [ ] **Step 4.3: Adicionar teste ao `test/presentation/pause_overlay_test.dart`**

Adicionar ao final de `main()`, antes do fechamento `}`:

```dart
  testWidgets('PauseOverlay mostra botão Cheats em kDebugMode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(
          home: Scaffold(body: PauseOverlay()),
        ),
      ),
    );

    // kDebugMode é true em testes — o botão deve existir
    expect(find.text('Cheats'), findsOneWidget);
    expect(find.text('Debug'), findsNothing);
  });
```

- [ ] **Step 4.4: Rodar testes do PauseOverlay**

```
flutter test test/presentation/pause_overlay_test.dart
```

Esperado: todos os testes passam, incluindo o novo.

- [ ] **Step 4.5: Rodar a suite completa**

```
flutter test
```

Esperado: zero falhas. Se houver falhas relacionadas a `AnimalsGalleryScreen` (algum outro arquivo importava), corrigir os imports antes do commit.

- [ ] **Step 4.6: Commit**

```bash
git add lib/presentation/widgets/pause_overlay.dart \
        test/presentation/pause_overlay_test.dart
git commit -m "feat(debug): substituir AnimalsGalleryScreen por CheatMenuScreen no PauseOverlay"
```

---

## Checklist de aceitação (verificar manualmente com `flutter run --flavor tst --dart-define=FLAVOR=dev`)

- [ ] Botão "Cheats" visível no PauseOverlay em debug build
- [ ] `[+]` / `[−]` de vidas refletem no indicador de vidas da HomeScreen ao voltar
- [ ] `[+]` / `[−]` de itens refletem no InventoryBar durante o jogo
- [ ] "Dar 5 de cada" preenche todos os tipos para 5
- [ ] Selecionar nível + "Ir para Nível N" fecha o menu, exibe tabuleiro com tile do nível N visível
- [ ] Anfitrião acima do tabuleiro corresponde ao `maxLevel` injetado
- [ ] Dialog de marco dispara normalmente na primeira jogada após jump para nível >= 11
