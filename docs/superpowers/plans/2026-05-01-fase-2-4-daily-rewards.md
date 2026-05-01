# Fase 2.4 — Recompensas Diárias Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar o sistema de Recompensas Diárias (ciclo 7 dias) com modelo Hive, lógica de streak pura testável, tela com grid de 7 dias, integração com vidas/inventário, e entry point na HomeScreen.

**Architecture:** `DailyRewardsState` standalone (Hive typeId 3) + engine puro em `daily_rewards_engine.dart` (funções estáticas, parâmetro `now` explícito) + `DailyRewardsNotifier` que coordena entrega via `ref` nos providers de vidas e inventário. Ordem TDD: A (modelo) → B (engine) → D (notifier) → C (tela) → E (entry point).

**Tech Stack:** Flutter 3.x, Riverpod `StateNotifier`, Hive (adapter manual), `flutter_animate`, `Timer.periodic` para countdown, `flutter_test` + Hive temp dir para testes.

---

## Mapa de arquivos

| Ação | Arquivo |
|------|---------|
| Criar | `lib/data/models/daily_rewards_state.dart` |
| Criar | `lib/data/models/daily_rewards_state_adapter.dart` |
| Criar | `lib/data/repositories/daily_rewards_repository.dart` |
| Criar | `lib/domain/daily_rewards/daily_rewards_engine.dart` |
| Criar | `lib/domain/daily_rewards/daily_rewards_notifier.dart` |
| Criar | `lib/domain/daily_rewards/ad_service.dart` |
| Criar | `lib/presentation/screens/daily_rewards/daily_rewards_screen.dart` |
| Criar | `lib/presentation/widgets/daily_reward_day_tile.dart` |
| Criar | `lib/presentation/widgets/daily_reward_overlay.dart` |
| Criar | `lib/presentation/widgets/daily_reward_entry_tile.dart` |
| Modificar | `lib/main.dart` |
| Modificar | `lib/presentation/screens/home_screen.dart` |
| Criar | `test/domain/daily_rewards_engine_test.dart` |
| Criar | `test/domain/daily_rewards_notifier_test.dart` |
| Criar | `test/presentation/daily_rewards_screen_available_test.dart` |
| Criar | `test/presentation/daily_rewards_screen_claimed_test.dart` |
| Criar | `test/presentation/daily_rewards_screen_streak_broken_test.dart` |
| Criar | `test/presentation/daily_rewards_screen_cycle_completed_test.dart` |

---

## Task 1: `DailyRewardsState` — modelo e adapter Hive

**Files:**
- Create: `lib/data/models/daily_rewards_state.dart`
- Create: `lib/data/models/daily_rewards_state_adapter.dart`

- [ ] **Step 1: Criar `daily_rewards_state.dart`**

```dart
// lib/data/models/daily_rewards_state.dart

class DailyRewardsState {
  final int currentDay;
  final DateTime lastClaimedDate;
  final bool claimedThisCycle;

  const DailyRewardsState({
    required this.currentDay,
    required this.lastClaimedDate,
    required this.claimedThisCycle,
  });

  factory DailyRewardsState.initial() => DailyRewardsState(
        currentDay: 1,
        lastClaimedDate: DateTime(1970),
        claimedThisCycle: false,
      );

  DailyRewardsState copyWith({
    int? currentDay,
    DateTime? lastClaimedDate,
    bool? claimedThisCycle,
  }) {
    return DailyRewardsState(
      currentDay: currentDay ?? this.currentDay,
      lastClaimedDate: lastClaimedDate ?? this.lastClaimedDate,
      claimedThisCycle: claimedThisCycle ?? this.claimedThisCycle,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DailyRewardsState &&
      other.currentDay == currentDay &&
      other.lastClaimedDate == lastClaimedDate &&
      other.claimedThisCycle == claimedThisCycle;

  @override
  int get hashCode => Object.hash(currentDay, lastClaimedDate, claimedThisCycle);
}
```

- [ ] **Step 2: Criar `daily_rewards_state_adapter.dart`**

```dart
// lib/data/models/daily_rewards_state_adapter.dart
import 'package:hive/hive.dart';
import 'daily_rewards_state.dart';

class DailyRewardsStateAdapter extends TypeAdapter<DailyRewardsState> {
  @override
  final int typeId = 3;

  @override
  DailyRewardsState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyRewardsState(
      currentDay: (fields[0] as int?) ?? 1,
      lastClaimedDate: (fields[1] as DateTime?) ?? DateTime(1970),
      claimedThisCycle: (fields[2] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, DailyRewardsState obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.currentDay)
      ..writeByte(1)
      ..write(obj.lastClaimedDate)
      ..writeByte(2)
      ..write(obj.claimedThisCycle);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyRewardsStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/data/models/daily_rewards_state.dart lib/data/models/daily_rewards_state_adapter.dart
git commit -m "feat: DailyRewardsState model + Hive adapter (typeId 3)"
```

---

## Task 2: `DailyRewardsRepository`

**Files:**
- Create: `lib/data/repositories/daily_rewards_repository.dart`

- [ ] **Step 1: Escrever o teste de repositório (Hive com tempDir)**

```dart
// test/domain/daily_rewards_repository_test.dart
import 'package:capivara_2048/data/models/daily_rewards_state.dart';
import 'package:capivara_2048/data/models/daily_rewards_state_adapter.dart';
import 'package:capivara_2048/data/repositories/daily_rewards_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_daily_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(DailyRewardsStateAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('load returns initial when box is empty', () async {
    final repo = DailyRewardsRepository();
    final state = await repo.load();
    expect(state, DailyRewardsState.initial());
  });

  test('save and load round-trips correctly', () async {
    final repo = DailyRewardsRepository();
    final saved = DailyRewardsState(
      currentDay: 3,
      lastClaimedDate: DateTime(2026, 5, 1),
      claimedThisCycle: true,
    );
    await repo.save(saved);
    final loaded = await repo.load();
    expect(loaded.currentDay, 3);
    expect(loaded.lastClaimedDate, DateTime(2026, 5, 1));
    expect(loaded.claimedThisCycle, true);
  });

  test('reset returns state to initial', () async {
    final repo = DailyRewardsRepository();
    await repo.save(DailyRewardsState(
      currentDay: 5,
      lastClaimedDate: DateTime(2026, 5, 3),
      claimedThisCycle: true,
    ));
    await repo.reset();
    final loaded = await repo.load();
    expect(loaded, DailyRewardsState.initial());
  });
}
```

- [ ] **Step 2: Rodar o teste para ver falhar**

```bash
flutter test test/domain/daily_rewards_repository_test.dart
```

Esperado: FAIL com `Target of URI doesn't exist`

- [ ] **Step 3: Implementar o repositório**

```dart
// lib/data/repositories/daily_rewards_repository.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/daily_rewards_state.dart';

class DailyRewardsRepository {
  static const _boxName = 'daily_rewards';
  static const _key = 'state';

  Future<DailyRewardsState> load() async {
    final box = await Hive.openBox<DailyRewardsState>(_boxName);
    return box.get(_key) ?? DailyRewardsState.initial();
  }

  Future<void> save(DailyRewardsState state) async {
    final box = await Hive.openBox<DailyRewardsState>(_boxName);
    await box.put(_key, state);
  }

  Future<void> reset() async {
    final box = await Hive.openBox<DailyRewardsState>(_boxName);
    await box.put(_key, DailyRewardsState.initial());
  }
}
```

- [ ] **Step 4: Rodar o teste para ver passar**

```bash
flutter test test/domain/daily_rewards_repository_test.dart
```

Esperado: todos os 3 testes PASS

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/daily_rewards_repository.dart test/domain/daily_rewards_repository_test.dart
git commit -m "feat: DailyRewardsRepository com testes Hive"
```

---

## Task 3: `DailyRewardsEngine` — lógica pura

**Files:**
- Create: `lib/domain/daily_rewards/daily_rewards_engine.dart`
- Create: `test/domain/daily_rewards_engine_test.dart`

- [ ] **Step 1: Escrever os 12 testes unitários do engine**

```dart
// test/domain/daily_rewards_engine_test.dart
import 'package:capivara_2048/data/models/daily_rewards_state.dart';
import 'package:capivara_2048/domain/daily_rewards/daily_rewards_engine.dart';
import 'package:flutter_test/flutter_test.dart';

DailyRewardsState _state({
  int currentDay = 1,
  DateTime? lastClaimedDate,
  bool claimedThisCycle = false,
}) =>
    DailyRewardsState(
      currentDay: currentDay,
      lastClaimedDate: lastClaimedDate ?? DateTime(1970),
      claimedThisCycle: claimedThisCycle,
    );

DateTime day(int d) => DateTime(2026, 5, d);

void main() {
  group('computeDailyRewardStatus', () {
    test('1: nunca coletou → available', () {
      final s = DailyRewardsState.initial();
      expect(computeDailyRewardStatus(day(1), s), DailyRewardStatus.available);
    });

    test('2: coletou hoje (gap=0) → alreadyClaimed', () {
      final s = _state(
        currentDay: 2,
        lastClaimedDate: day(5),
        claimedThisCycle: true,
      );
      expect(computeDailyRewardStatus(day(5), s), DailyRewardStatus.alreadyClaimed);
    });

    test('3: coletou ontem, dia 1–6 → available', () {
      final s = _state(
        currentDay: 3,
        lastClaimedDate: day(4),
        claimedThisCycle: true,
      );
      expect(computeDailyRewardStatus(day(5), s), DailyRewardStatus.available);
    });

    test('4: coletou Dia 7 ontem (gap=1) → cycleCompleted', () {
      final s = _state(
        currentDay: 7,
        lastClaimedDate: day(7),
        claimedThisCycle: true,
      );
      expect(computeDailyRewardStatus(day(8), s), DailyRewardStatus.cycleCompleted);
    });

    test('5: gap=2 → streakBroken', () {
      final s = _state(
        currentDay: 3,
        lastClaimedDate: day(3),
        claimedThisCycle: true,
      );
      expect(computeDailyRewardStatus(day(5), s), DailyRewardStatus.streakBroken);
    });

    test('6: gap=10 → streakBroken', () {
      final s = _state(
        currentDay: 2,
        lastClaimedDate: day(1),
        claimedThisCycle: true,
      );
      expect(computeDailyRewardStatus(day(11), s), DailyRewardStatus.streakBroken);
    });

    test('7: relógio retrocedeu (now < last) → alreadyClaimed', () {
      final s = _state(
        currentDay: 2,
        lastClaimedDate: day(10),
        claimedThisCycle: true,
      );
      expect(computeDailyRewardStatus(day(9), s), DailyRewardStatus.alreadyClaimed);
    });

    test('8: meia-noite — coletou dia anterior, abre dia seguinte → available', () {
      // Coletou no dia 4 (claimedThisCycle=true, currentDay=3 → applyClaim já avançou para 4)
      // Abre no dia 5: gap=1, claimedThisCycle=true, currentDay=4 < 7 → available
      final s = _state(
        currentDay: 4,
        lastClaimedDate: day(4),
        claimedThisCycle: true,
      );
      expect(computeDailyRewardStatus(day(5), s), DailyRewardStatus.available);
    });

    test('9: 7 dias consecutivos — Dia 8 cycleCompleted, Dia 9 streakBroken', () {
      var s = DailyRewardsState.initial();
      for (int d = 1; d <= 7; d++) {
        expect(computeDailyRewardStatus(day(d), s), DailyRewardStatus.available);
        s = applyClaim(day(d), s);
      }
      expect(computeDailyRewardStatus(day(8), s), DailyRewardStatus.cycleCompleted);
      expect(computeDailyRewardStatus(day(9), s), DailyRewardStatus.streakBroken);
    });
  });

  group('applyStreakReset', () {
    test('10: reset retorna currentDay=1, claimedThisCycle=false', () {
      final s = _state(currentDay: 5, claimedThisCycle: true, lastClaimedDate: day(3));
      final result = applyStreakReset(s);
      expect(result.currentDay, 1);
      expect(result.claimedThisCycle, false);
      expect(result.lastClaimedDate, day(3)); // lastClaimedDate não muda
    });
  });

  group('applyClaim', () {
    test('11: applyClaim Dia 6 avança para Dia 7', () {
      final s = _state(currentDay: 6, lastClaimedDate: day(3), claimedThisCycle: false);
      final result = applyClaim(day(4), s);
      expect(result.currentDay, 7);
      expect(result.claimedThisCycle, true);
      expect(result.lastClaimedDate, day(4));
    });

    test('12: applyClaim Dia 7 permanece em 7', () {
      final s = _state(currentDay: 7, lastClaimedDate: day(6), claimedThisCycle: false);
      final result = applyClaim(day(7), s);
      expect(result.currentDay, 7);
      expect(result.claimedThisCycle, true);
      expect(result.lastClaimedDate, day(7));
    });
  });

  group('rewardForDay', () {
    test('Dia 1: 1x undo1', () {
      final r = rewardForDay(1);
      expect(r.undo1, 1);
      expect(r.bomb2, 0);
      expect(r.lives, 0);
    });

    test('Dia 7: combo completo', () {
      final r = rewardForDay(7);
      expect(r.undo1, 2);
      expect(r.bomb2, 2);
      expect(r.lives, 2);
    });
  });
}
```

- [ ] **Step 2: Rodar para ver falhar**

```bash
flutter test test/domain/daily_rewards_engine_test.dart
```

Esperado: FAIL com `Target of URI doesn't exist`

- [ ] **Step 3: Implementar o engine**

```dart
// lib/domain/daily_rewards/daily_rewards_engine.dart
import '../../data/models/daily_rewards_state.dart';

enum DailyRewardStatus {
  available,
  alreadyClaimed,
  streakBroken,
  cycleCompleted,
}

class DailyReward {
  final int lives;
  final int undo1;
  final int bomb2;

  const DailyReward({
    required this.lives,
    required this.undo1,
    required this.bomb2,
  });
}

const List<DailyReward> kDailyRewards = [
  DailyReward(lives: 0, undo1: 1, bomb2: 0), // Dia 1
  DailyReward(lives: 0, undo1: 0, bomb2: 1), // Dia 2
  DailyReward(lives: 1, undo1: 0, bomb2: 0), // Dia 3
  DailyReward(lives: 0, undo1: 2, bomb2: 0), // Dia 4
  DailyReward(lives: 0, undo1: 0, bomb2: 2), // Dia 5
  DailyReward(lives: 2, undo1: 0, bomb2: 0), // Dia 6
  DailyReward(lives: 2, undo1: 2, bomb2: 2), // Dia 7
];

DailyReward rewardForDay(int day) => kDailyRewards[day - 1];

DailyRewardStatus computeDailyRewardStatus(DateTime now, DailyRewardsState state) {
  final today = DateTime(now.year, now.month, now.day);
  final last = state.lastClaimedDate;

  if (today.isBefore(last)) return DailyRewardStatus.alreadyClaimed;

  final gap = today.difference(last).inDays;

  if (gap == 0) return DailyRewardStatus.alreadyClaimed;
  if (gap >= 2) return DailyRewardStatus.streakBroken;

  // gap == 1
  if (!state.claimedThisCycle) return DailyRewardStatus.available;
  if (state.currentDay == 7) return DailyRewardStatus.cycleCompleted;
  return DailyRewardStatus.available;
}

DailyRewardsState applyStreakReset(DailyRewardsState state) {
  return state.copyWith(currentDay: 1, claimedThisCycle: false);
}

DailyRewardsState applyClaim(DateTime now, DailyRewardsState state) {
  final today = DateTime(now.year, now.month, now.day);
  final nextDay = state.currentDay < 7 ? state.currentDay + 1 : 7;
  return state.copyWith(
    claimedThisCycle: true,
    lastClaimedDate: today,
    currentDay: nextDay,
  );
}
```

- [ ] **Step 4: Rodar para ver passar**

```bash
flutter test test/domain/daily_rewards_engine_test.dart
```

Esperado: todos os 14 testes PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain/daily_rewards/daily_rewards_engine.dart test/domain/daily_rewards_engine_test.dart
git commit -m "feat: DailyRewardsEngine puro com 14 testes unitários"
```

---

## Task 4: `AdService` — interface e fake

**Files:**
- Create: `lib/domain/daily_rewards/ad_service.dart`

- [ ] **Step 1: Criar o arquivo**

```dart
// lib/domain/daily_rewards/ad_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AdService {
  Future<bool> showRewardedAd();
}

class FakeAdService implements AdService {
  @override
  Future<bool> showRewardedAd() async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}

final adServiceProvider = Provider<AdService>((_) => FakeAdService());
```

- [ ] **Step 2: Commit**

```bash
git add lib/domain/daily_rewards/ad_service.dart
git commit -m "feat: AdService interface + FakeAdService (Fase 3 stub)"
```

---

## Task 5: `DailyRewardsNotifier` com testes de integração

**Files:**
- Create: `lib/domain/daily_rewards/daily_rewards_notifier.dart`
- Create: `test/domain/daily_rewards_notifier_test.dart`

- [ ] **Step 1: Escrever os testes de integração**

```dart
// test/domain/daily_rewards_notifier_test.dart
import 'package:capivara_2048/data/models/daily_rewards_state.dart';
import 'package:capivara_2048/data/models/daily_rewards_state_adapter.dart';
import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/item_type.dart';
import 'package:capivara_2048/data/models/lives_state.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/data/repositories/daily_rewards_repository.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/data/repositories/lives_repository.dart';
import 'package:capivara_2048/domain/daily_rewards/daily_rewards_engine.dart';
import 'package:capivara_2048/domain/daily_rewards/daily_rewards_notifier.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

DateTime day(int d) => DateTime(2026, 5, d);

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_notifier_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LivesStateAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DailyRewardsStateAdapter());

    container = ProviderContainer(overrides: [
      livesRepositoryProvider.overrideWithValue(LivesRepository()),
      inventoryRepositoryProvider.overrideWithValue(InventoryRepository()),
      dailyRewardsRepositoryProvider.overrideWithValue(DailyRewardsRepository()),
    ]);
    await container.read(livesProvider.notifier).addEarned(0); // inicializa
    await container.read(inventoryProvider.notifier).load();
    await container.read(dailyRewardsProvider.notifier).load();
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('1: Dia 3 (+1 vida): lives=14 → lives=15 após claim', () async {
    // Setar vidas para 14
    final livesNotifier = container.read(livesProvider.notifier);
    await livesNotifier.addEarned(9); // initial=5, +9=14
    expect(container.read(livesProvider).lives, 14);

    // Setar estado para Dia 3 disponível
    final notifier = container.read(dailyRewardsProvider.notifier);
    notifier.debugSetState(DailyRewardsState(
      currentDay: 3,
      lastClaimedDate: day(1),
      claimedThisCycle: true,
    ));

    await notifier.claim(day(2));
    expect(container.read(livesProvider).lives, 15);
  });

  test('2: Dia 2 (+1 bomba): bomb2 aumenta em 1', () async {
    final notifier = container.read(dailyRewardsProvider.notifier);
    notifier.debugSetState(DailyRewardsState(
      currentDay: 2,
      lastClaimedDate: day(1),
      claimedThisCycle: true,
    ));

    await notifier.claim(day(2));
    expect(container.read(inventoryProvider).bomb2, 1);
  });

  test('3: Dia 7 (combo): lives+2, undo1+2, bomb2+2', () async {
    final notifier = container.read(dailyRewardsProvider.notifier);
    notifier.debugSetState(DailyRewardsState(
      currentDay: 7,
      lastClaimedDate: day(1),
      claimedThisCycle: false,
    ));

    await notifier.claim(day(2));
    expect(container.read(livesProvider).lives, 7); // 5 inicial + 2
    expect(container.read(inventoryProvider).undo1, 2);
    expect(container.read(inventoryProvider).bomb2, 2);
  });

  test('4: claimDouble Dia 2 entrega delta (+1 bomba extra)', () async {
    final notifier = container.read(dailyRewardsProvider.notifier);
    notifier.debugSetState(DailyRewardsState(
      currentDay: 2,
      lastClaimedDate: day(1),
      claimedThisCycle: true,
    ));

    await notifier.claim(day(2)); // entrega base: +1 bomb2
    expect(container.read(inventoryProvider).bomb2, 1);

    await notifier.claimDouble(rewardForDay(2)); // entrega delta: +1 bomb2
    expect(container.read(inventoryProvider).bomb2, 2);

    // DailyRewardsState não mudou (claimedThisCycle permanece true)
    expect(container.read(dailyRewardsProvider).claimedThisCycle, true);
  });

  test('5: streakBroken → claim reseta para Dia 1 e entrega undo1', () async {
    final notifier = container.read(dailyRewardsProvider.notifier);
    notifier.debugSetState(DailyRewardsState(
      currentDay: 5,
      lastClaimedDate: day(1),
      claimedThisCycle: true,
    ));

    // gap=3 → streakBroken
    await notifier.claim(day(4));
    expect(container.read(dailyRewardsProvider).currentDay, 2); // após claim Dia 1, avança para 2
    expect(container.read(inventoryProvider).undo1, 1); // recompensa do Dia 1
  });

  test('6: cycleCompleted → claim entrega Dia 1 do novo ciclo', () async {
    final notifier = container.read(dailyRewardsProvider.notifier);
    // Coletou Dia 7 ontem → cycleCompleted
    notifier.debugSetState(DailyRewardsState(
      currentDay: 7,
      lastClaimedDate: day(7),
      claimedThisCycle: true,
    ));

    await notifier.claim(day(8)); // cycleCompleted → reset para Dia 1 → claim
    expect(container.read(inventoryProvider).undo1, 1); // recompensa do Dia 1
    expect(container.read(dailyRewardsProvider).currentDay, 2); // avança para 2
  });
}
```

- [ ] **Step 2: Rodar para ver falhar**

```bash
flutter test test/domain/daily_rewards_notifier_test.dart
```

Esperado: FAIL com `Target of URI doesn't exist`

- [ ] **Step 3: Implementar o notifier**

```dart
// lib/domain/daily_rewards/daily_rewards_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/daily_rewards_state.dart';
import '../../data/models/item_type.dart';
import '../../data/repositories/daily_rewards_repository.dart';
import '../inventory/inventory_notifier.dart';
import '../lives/lives_notifier.dart';
import 'daily_rewards_engine.dart';

class DailyRewardsNotifier extends StateNotifier<DailyRewardsState> {
  DailyRewardsNotifier(this._repo, this._ref) : super(DailyRewardsState.initial());

  final DailyRewardsRepository _repo;
  final Ref _ref;

  Future<void> load() async {
    state = await _repo.load();
  }

  DailyRewardStatus get status => computeDailyRewardStatus(DateTime.now(), state);

  Future<void> claim(DateTime now) async {
    final s = computeDailyRewardStatus(now, state);
    final claimable = s == DailyRewardStatus.available ||
        s == DailyRewardStatus.streakBroken ||
        s == DailyRewardStatus.cycleCompleted;
    if (!claimable) return;

    var current = state;
    if (s == DailyRewardStatus.streakBroken || s == DailyRewardStatus.cycleCompleted) {
      current = applyStreakReset(current);
    }

    final reward = rewardForDay(current.currentDay);

    if (reward.lives > 0) await _ref.read(livesProvider.notifier).addEarned(reward.lives);
    if (reward.undo1 > 0) await _ref.read(inventoryProvider.notifier).add(ItemType.undo1, reward.undo1);
    if (reward.bomb2 > 0) await _ref.read(inventoryProvider.notifier).add(ItemType.bomb2, reward.bomb2);

    final next = applyClaim(now, current);
    state = next;
    await _repo.save(state);
  }

  Future<void> claimDouble(DailyReward original) async {
    if (original.lives > 0) await _ref.read(livesProvider.notifier).addEarned(original.lives);
    if (original.undo1 > 0) await _ref.read(inventoryProvider.notifier).add(ItemType.undo1, original.undo1);
    if (original.bomb2 > 0) await _ref.read(inventoryProvider.notifier).add(ItemType.bomb2, original.bomb2);
  }

  void debugSetState(DailyRewardsState s) => state = s;
}

final dailyRewardsRepositoryProvider = Provider<DailyRewardsRepository>(
  (_) => DailyRewardsRepository(),
);

final dailyRewardsProvider = StateNotifierProvider<DailyRewardsNotifier, DailyRewardsState>(
  (ref) => DailyRewardsNotifier(ref.read(dailyRewardsRepositoryProvider), ref),
);
```

- [ ] **Step 4: Rodar para ver passar**

```bash
flutter test test/domain/daily_rewards_notifier_test.dart
```

Esperado: todos os 6 testes PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain/daily_rewards/daily_rewards_notifier.dart test/domain/daily_rewards_notifier_test.dart
git commit -m "feat: DailyRewardsNotifier com 6 testes de integração"
```

---

## Task 6: Registrar adapter e inicializar provider em `main.dart`

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Atualizar `main.dart`**

```dart
// lib/main.dart — conteúdo completo atualizado
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/lives_state_adapter.dart';
import 'data/models/inventory_hive_adapter.dart';
import 'data/models/daily_rewards_state_adapter.dart';
import 'core/providers/reduce_effects_provider.dart';
import 'domain/inventory/inventory_notifier.dart';
import 'domain/daily_rewards/daily_rewards_notifier.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(LivesStateAdapter());
  Hive.registerAdapter(InventoryHiveAdapter());
  Hive.registerAdapter(DailyRewardsStateAdapter());
  final container = ProviderContainer();
  await container.read(reduceEffectsProvider.notifier).load();
  await container.read(inventoryProvider.notifier).load();
  await container.read(dailyRewardsProvider.notifier).load();
  runApp(UncontrolledProviderScope(container: container, child: const CapivaraApp()));
}
```

- [ ] **Step 2: Verificar que o app compila**

```bash
flutter analyze
flutter build apk --debug 2>&1 | tail -5
```

Esperado: `No issues found` / `Built build/app/outputs/...`

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: registrar DailyRewardsStateAdapter e inicializar provider em main.dart"
```

---

## Task 7: `DailyRewardDayTile` — tile individual do grid

**Files:**
- Create: `lib/presentation/widgets/daily_reward_day_tile.dart`

- [ ] **Step 1: Implementar o widget**

```dart
// lib/presentation/widgets/daily_reward_day_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/daily_rewards/daily_rewards_engine.dart';

enum DayTileState { future, currentAvailable, claimed }

class DailyRewardDayTile extends StatelessWidget {
  final int day;
  final DailyReward reward;
  final DayTileState tileState;
  final bool isDay7;

  const DailyRewardDayTile({
    super.key,
    required this.day,
    required this.reward,
    required this.tileState,
    required this.isDay7,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = tileState == DayTileState.currentAvailable;
    final isClaimed = tileState == DayTileState.claimed;

    return Container(
      width: 64,
      height: 80,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDay7
              ? Colors.amber
              : isCurrent
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
          width: isDay7 || isCurrent ? 2.5 : 0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Opacity(
        opacity: tileState == DayTileState.future ? 0.4 : 1.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Dia $day',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                _RewardIcons(reward: reward),
              ],
            ),
            if (isClaimed)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
              ),
          ],
        ),
      ),
    ).animate(target: isCurrent ? 1 : 0).shimmer(
          duration: 1500.ms,
          color: Colors.white24,
        );
  }
}

class _RewardIcons extends StatelessWidget {
  final DailyReward reward;
  const _RewardIcons({required this.reward});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (reward.undo1 > 0) {
      items.add(_icon('assets/icons/inventory/undo_1.png', reward.undo1));
    }
    if (reward.bomb2 > 0) {
      items.add(_icon('assets/icons/inventory/bomb_2.png', reward.bomb2));
    }
    if (reward.lives > 0) {
      items.add(_liveIcon(reward.lives));
    }
    return Wrap(
      spacing: 2,
      children: items,
    );
  }

  Widget _icon(String asset, int count) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(asset, width: 18, height: 18),
          if (count > 1)
            Text('×$count', style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      );

  Widget _liveIcon(int count) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, color: Colors.redAccent, size: 18),
          if (count > 1)
            Text('×$count', style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/widgets/daily_reward_day_tile.dart
git commit -m "feat: DailyRewardDayTile — tile do grid de recompensas"
```

---

## Task 8: `DailyRewardOverlay` — overlay pós-coleta

**Files:**
- Create: `lib/presentation/widgets/daily_reward_overlay.dart`

- [ ] **Step 1: Implementar o overlay**

```dart
// lib/presentation/widgets/daily_reward_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/daily_rewards/ad_service.dart';
import '../../domain/daily_rewards/daily_rewards_engine.dart';
import '../../domain/daily_rewards/daily_rewards_notifier.dart';

class DailyRewardOverlay extends ConsumerStatefulWidget {
  final DailyReward reward;
  final VoidCallback onDismiss;

  const DailyRewardOverlay({
    super.key,
    required this.reward,
    required this.onDismiss,
  });

  @override
  ConsumerState<DailyRewardOverlay> createState() => _DailyRewardOverlayState();
}

class _DailyRewardOverlayState extends ConsumerState<DailyRewardOverlay> {
  bool _loading = false;
  bool _doubled = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A5F),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _doubled ? 'Recompensa dobrada!' : 'Recompensa coletada!',
                style: GoogleFonts.fredoka(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _RewardSummary(reward: widget.reward, doubled: _doubled),
              const SizedBox(height: 24),
              if (!_doubled) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _onDouble,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Assistir 30s e dobrar',
                            style: GoogleFonts.fredoka(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextButton(
                onPressed: widget.onDismiss,
                child: Text(
                  'Não, obrigado',
                  style: GoogleFonts.nunito(color: Colors.white70, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDouble() async {
    setState(() => _loading = true);
    final adService = ref.read(adServiceProvider);
    final success = await adService.showRewardedAd();
    if (!mounted) return;
    if (success) {
      await ref.read(dailyRewardsProvider.notifier).claimDouble(widget.reward);
      setState(() {
        _loading = false;
        _doubled = true;
      });
    } else {
      setState(() => _loading = false);
    }
  }
}

class _RewardSummary extends StatelessWidget {
  final DailyReward reward;
  final bool doubled;
  const _RewardSummary({required this.reward, required this.doubled});

  @override
  Widget build(BuildContext context) {
    final multiplier = doubled ? 2 : 1;
    final items = <Widget>[];
    if (reward.undo1 > 0) {
      items.add(_row('assets/icons/inventory/undo_1.png', '${reward.undo1 * multiplier}× Desfazer 1'));
    }
    if (reward.bomb2 > 0) {
      items.add(_row('assets/icons/inventory/bomb_2.png', '${reward.bomb2 * multiplier}× Bomba 2'));
    }
    if (reward.lives > 0) {
      items.add(_rowIcon(Icons.favorite, Colors.redAccent, '${reward.lives * multiplier}× Vida'));
    }
    return Column(children: items);
  }

  Widget _row(String asset, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Image.asset(asset, width: 24, height: 24),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
      );

  Widget _rowIcon(IconData icon, Color color, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
      );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/widgets/daily_reward_overlay.dart
git commit -m "feat: DailyRewardOverlay — overlay dobrar recompensa (mock anúncio)"
```

---

## Task 9: `DailyRewardsScreen` — tela principal

**Files:**
- Create: `lib/presentation/screens/daily_rewards/daily_rewards_screen.dart`

- [ ] **Step 1: Implementar a tela**

```dart
// lib/presentation/screens/daily_rewards/daily_rewards_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/lives_state.dart';
import '../../../domain/daily_rewards/daily_rewards_engine.dart';
import '../../../domain/daily_rewards/daily_rewards_notifier.dart';
import '../../../domain/lives/lives_notifier.dart';
import '../../widgets/daily_reward_day_tile.dart';
import '../../widgets/daily_reward_overlay.dart';

class DailyRewardsScreen extends ConsumerStatefulWidget {
  const DailyRewardsScreen({super.key});

  @override
  ConsumerState<DailyRewardsScreen> createState() => _DailyRewardsScreenState();
}

class _DailyRewardsScreenState extends ConsumerState<DailyRewardsScreen> {
  Timer? _timer;
  Duration _untilMidnight = Duration.zero;
  bool _showOverlay = false;
  DailyReward? _lastReward;
  int? _animatingDay;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    if (mounted) setState(() => _untilMidnight = midnight.difference(now));
  }

  String _formatCountdown(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _onClaim(DailyRewardStatus status, int effectiveDay) async {
    final livesState = ref.read(livesProvider);
    final reward = rewardForDay(effectiveDay);

    // Verificar cap de vidas antes de coletar
    if (reward.lives > 0 && livesState.lives >= livesState.earnedCap) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Cap de vidas atingido',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Você já tem o máximo de vidas (${livesState.earnedCap}). '
            'As vidas desta recompensa serão descartadas. Coletar mesmo assim?',
            style: GoogleFonts.nunito(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar', style: GoogleFonts.nunito()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Coletar', style: GoogleFonts.nunito()),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _animatingDay = effectiveDay);
    await ref.read(dailyRewardsProvider.notifier).claim(DateTime.now());

    if (mounted) {
      setState(() {
        _animatingDay = null;
        _lastReward = reward;
        _showOverlay = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyState = ref.watch(dailyRewardsProvider);
    final status = computeDailyRewardStatus(DateTime.now(), dailyState);

    final int effectiveDay = (status == DailyRewardStatus.streakBroken ||
            status == DailyRewardStatus.cycleCompleted)
        ? 1
        : dailyState.currentDay;

    final claimable = status == DailyRewardStatus.available ||
        status == DailyRewardStatus.streakBroken ||
        status == DailyRewardStatus.cycleCompleted;

    return Scaffold(
      backgroundColor: const Color(0xFF1E3A5F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Recompensa Diária',
          style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                if (status == DailyRewardStatus.streakBroken)
                  _StreakBrokenBanner(),
                const SizedBox(height: 12),
                _DayGrid(
                  dailyState: dailyState,
                  status: status,
                  effectiveDay: effectiveDay,
                  animatingDay: _animatingDay,
                ),
                const Spacer(),
                if (claimable)
                  _ClaimButton(
                    status: status,
                    onPressed: () => _onClaim(status, effectiveDay),
                  )
                else
                  _CountdownWidget(countdown: _untilMidnight, formatter: _formatCountdown),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_showOverlay && _lastReward != null)
            DailyRewardOverlay(
              reward: _lastReward!,
              onDismiss: () => setState(() => _showOverlay = false),
            ),
        ],
      ),
    );
  }
}

class _StreakBrokenBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Você perdeu a streak! Recomeçando do Dia 1.',
              style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayGrid extends StatelessWidget {
  final DailyRewardsState dailyState;
  final DailyRewardStatus status;
  final int effectiveDay;
  final int? animatingDay;

  const _DayGrid({
    required this.dailyState,
    required this.status,
    required this.effectiveDay,
    required this.animatingDay,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildTile(int day) {
      final reward = rewardForDay(day);
      final isCurrent = day == effectiveDay &&
          (status == DailyRewardStatus.available ||
              status == DailyRewardStatus.streakBroken ||
              status == DailyRewardStatus.cycleCompleted);
      final isClaimed = day < effectiveDay ||
          (status == DailyRewardStatus.alreadyClaimed && day == dailyState.currentDay) ||
          (status == DailyRewardStatus.cycleCompleted);

      DayTileState tileState;
      if (isClaimed) {
        tileState = DayTileState.claimed;
      } else if (isCurrent) {
        tileState = DayTileState.currentAvailable;
      } else {
        tileState = DayTileState.future;
      }

      Widget tile = DailyRewardDayTile(
        day: day,
        reward: reward,
        tileState: tileState,
        isDay7: day == 7,
      );

      if (animatingDay == day) {
        tile = tile
            .animate()
            .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3), duration: 200.ms)
            .then()
            .scale(begin: const Offset(1.3, 1.3), end: const Offset(1, 1), duration: 200.ms)
            .fadeOut(delay: 300.ms, duration: 200.ms);
      }

      return tile;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [1, 2, 3, 4].map(buildTile).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [5, 6, 7].map(buildTile).toList(),
        ),
      ],
    );
  }
}

class _ClaimButton extends StatelessWidget {
  final DailyRewardStatus status;
  final VoidCallback onPressed;

  const _ClaimButton({required this.status, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final label = status == DailyRewardStatus.cycleCompleted
        ? 'Iniciar novo ciclo'
        : 'Coletar';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label, style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _CountdownWidget extends StatelessWidget {
  final Duration countdown;
  final String Function(Duration) formatter;

  const _CountdownWidget({required this.countdown, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Volte amanhã',
          style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 18),
        ),
        Text(
          formatter(countdown),
          style: GoogleFonts.fredoka(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verificar que compila**

```bash
flutter analyze lib/presentation/screens/daily_rewards/
```

Esperado: `No issues found`

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/daily_rewards/daily_rewards_screen.dart
git commit -m "feat: DailyRewardsScreen — tela com grid 7 dias, 4 estados"
```

---

## Task 10: Testes de widget — 4 estados da tela

**Files:**
- Create: `test/presentation/daily_rewards_screen_available_test.dart`
- Create: `test/presentation/daily_rewards_screen_claimed_test.dart`
- Create: `test/presentation/daily_rewards_screen_streak_broken_test.dart`
- Create: `test/presentation/daily_rewards_screen_cycle_completed_test.dart`

- [ ] **Step 1: Escrever helper de test setup (inline no primeiro arquivo)**

```dart
// test/presentation/daily_rewards_screen_available_test.dart
import 'package:capivara_2048/data/models/daily_rewards_state.dart';
import 'package:capivara_2048/data/models/daily_rewards_state_adapter.dart';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/data/repositories/daily_rewards_repository.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/data/repositories/lives_repository.dart';
import 'package:capivara_2048/domain/daily_rewards/ad_service.dart';
import 'package:capivara_2048/domain/daily_rewards/daily_rewards_notifier.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/presentation/screens/daily_rewards/daily_rewards_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

Future<Directory> setupHive() async {
  final dir = await Directory.systemTemp.createTemp('hive_widget_test');
  Hive.init(dir.path);
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LivesStateAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DailyRewardsStateAdapter());
  return dir;
}

Widget buildScreen(DailyRewardsState initialState) {
  return ProviderScope(
    overrides: [
      livesRepositoryProvider.overrideWithValue(LivesRepository()),
      inventoryRepositoryProvider.overrideWithValue(InventoryRepository()),
      dailyRewardsRepositoryProvider.overrideWithValue(DailyRewardsRepository()),
      adServiceProvider.overrideWithValue(FakeAdService()),
      dailyRewardsProvider.overrideWith(
        (ref) => DailyRewardsNotifier(ref.read(dailyRewardsRepositoryProvider), ref)
          ..debugSetState(initialState),
      ),
    ],
    child: const MaterialApp(home: DailyRewardsScreen()),
  );
}

void main() {
  late Directory tempDir;
  setUp(() async { tempDir = await setupHive(); });
  tearDown(() async { await Hive.close(); await tempDir.delete(recursive: true); });

  testWidgets('estado available: botão Coletar habilitado e título presente', (tester) async {
    // Dia 3 disponível: lastClaimedDate ontem, claimedThisCycle=true, currentDay=3
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final normalizedYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day);

    await tester.pumpWidget(buildScreen(DailyRewardsState(
      currentDay: 3,
      lastClaimedDate: normalizedYesterday,
      claimedThisCycle: true,
    )));
    await tester.pump();

    expect(find.text('Recompensa Diária'), findsOneWidget);
    expect(find.text('Coletar'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.ancestor(of: find.text('Coletar'), matching: find.byType(ElevatedButton)),
    );
    expect(button.onPressed, isNotNull);
  });
}
```

- [ ] **Step 2: Escrever teste `alreadyClaimed`**

```dart
// test/presentation/daily_rewards_screen_claimed_test.dart
import 'package:capivara_2048/data/models/daily_rewards_state.dart';
import 'package:capivara_2048/data/models/daily_rewards_state_adapter.dart';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/data/repositories/daily_rewards_repository.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/data/repositories/lives_repository.dart';
import 'package:capivara_2048/domain/daily_rewards/ad_service.dart';
import 'package:capivara_2048/domain/daily_rewards/daily_rewards_notifier.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/presentation/screens/daily_rewards/daily_rewards_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_claimed_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LivesStateAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DailyRewardsStateAdapter());
  });

  tearDown(() async { await Hive.close(); await tempDir.delete(recursive: true); });

  testWidgets('estado alreadyClaimed: mostra "Volte amanhã" e sem botão Coletar', (tester) async {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        livesRepositoryProvider.overrideWithValue(LivesRepository()),
        inventoryRepositoryProvider.overrideWithValue(InventoryRepository()),
        dailyRewardsRepositoryProvider.overrideWithValue(DailyRewardsRepository()),
        adServiceProvider.overrideWithValue(FakeAdService()),
        dailyRewardsProvider.overrideWith(
          (ref) => DailyRewardsNotifier(ref.read(dailyRewardsRepositoryProvider), ref)
            ..debugSetState(DailyRewardsState(
              currentDay: 2,
              lastClaimedDate: normalizedToday,
              claimedThisCycle: true,
            )),
        ),
      ],
      child: const MaterialApp(home: DailyRewardsScreen()),
    ));
    await tester.pump();

    expect(find.text('Volte amanhã'), findsOneWidget);
    expect(find.text('Coletar'), findsNothing);
  });
}
```

- [ ] **Step 3: Escrever teste `streakBroken`**

```dart
// test/presentation/daily_rewards_screen_streak_broken_test.dart
import 'package:capivara_2048/data/models/daily_rewards_state.dart';
import 'package:capivara_2048/data/models/daily_rewards_state_adapter.dart';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/data/repositories/daily_rewards_repository.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/data/repositories/lives_repository.dart';
import 'package:capivara_2048/domain/daily_rewards/ad_service.dart';
import 'package:capivara_2048/domain/daily_rewards/daily_rewards_notifier.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/presentation/screens/daily_rewards/daily_rewards_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_streak_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LivesStateAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DailyRewardsStateAdapter());
  });

  tearDown(() async { await Hive.close(); await tempDir.delete(recursive: true); });

  testWidgets('estado streakBroken: mostra banner de aviso e botão Coletar habilitado', (tester) async {
    // gap >= 2: lastClaimedDate há 3 dias
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    final normalized = DateTime(threeDaysAgo.year, threeDaysAgo.month, threeDaysAgo.day);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        livesRepositoryProvider.overrideWithValue(LivesRepository()),
        inventoryRepositoryProvider.overrideWithValue(InventoryRepository()),
        dailyRewardsRepositoryProvider.overrideWithValue(DailyRewardsRepository()),
        adServiceProvider.overrideWithValue(FakeAdService()),
        dailyRewardsProvider.overrideWith(
          (ref) => DailyRewardsNotifier(ref.read(dailyRewardsRepositoryProvider), ref)
            ..debugSetState(DailyRewardsState(
              currentDay: 4,
              lastClaimedDate: normalized,
              claimedThisCycle: true,
            )),
        ),
      ],
      child: const MaterialApp(home: DailyRewardsScreen()),
    ));
    await tester.pump();

    expect(find.text('Você perdeu a streak! Recomeçando do Dia 1.'), findsOneWidget);
    expect(find.text('Coletar'), findsOneWidget);
  });
}
```

- [ ] **Step 4: Escrever teste `cycleCompleted`**

```dart
// test/presentation/daily_rewards_screen_cycle_completed_test.dart
import 'package:capivara_2048/data/models/daily_rewards_state.dart';
import 'package:capivara_2048/data/models/daily_rewards_state_adapter.dart';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/data/repositories/daily_rewards_repository.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/data/repositories/lives_repository.dart';
import 'package:capivara_2048/domain/daily_rewards/ad_service.dart';
import 'package:capivara_2048/domain/daily_rewards/daily_rewards_notifier.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/presentation/screens/daily_rewards/daily_rewards_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_cycle_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LivesStateAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DailyRewardsStateAdapter());
  });

  tearDown(() async { await Hive.close(); await tempDir.delete(recursive: true); });

  testWidgets('estado cycleCompleted: mostra "Iniciar novo ciclo" habilitado', (tester) async {
    // Coletou Dia 7 ontem → cycleCompleted
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final normalized = DateTime(yesterday.year, yesterday.month, yesterday.day);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        livesRepositoryProvider.overrideWithValue(LivesRepository()),
        inventoryRepositoryProvider.overrideWithValue(InventoryRepository()),
        dailyRewardsRepositoryProvider.overrideWithValue(DailyRewardsRepository()),
        adServiceProvider.overrideWithValue(FakeAdService()),
        dailyRewardsProvider.overrideWith(
          (ref) => DailyRewardsNotifier(ref.read(dailyRewardsRepositoryProvider), ref)
            ..debugSetState(DailyRewardsState(
              currentDay: 7,
              lastClaimedDate: normalized,
              claimedThisCycle: true,
            )),
        ),
      ],
      child: const MaterialApp(home: DailyRewardsScreen()),
    ));
    await tester.pump();

    expect(find.text('Iniciar novo ciclo'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.ancestor(of: find.text('Iniciar novo ciclo'), matching: find.byType(ElevatedButton)),
    );
    expect(button.onPressed, isNotNull);
  });
}
```

- [ ] **Step 5: Rodar todos os testes de widget**

```bash
flutter test test/presentation/daily_rewards_screen_available_test.dart test/presentation/daily_rewards_screen_claimed_test.dart test/presentation/daily_rewards_screen_streak_broken_test.dart test/presentation/daily_rewards_screen_cycle_completed_test.dart
```

Esperado: todos os 4 testes PASS

- [ ] **Step 6: Commit**

```bash
git add test/presentation/daily_rewards_screen_available_test.dart test/presentation/daily_rewards_screen_claimed_test.dart test/presentation/daily_rewards_screen_streak_broken_test.dart test/presentation/daily_rewards_screen_cycle_completed_test.dart
git commit -m "test: testes de widget DailyRewardsScreen — 4 estados"
```

---

## Task 11: `DailyRewardEntryTile` — tile na barra superior da HomeScreen

**Files:**
- Create: `lib/presentation/widgets/daily_reward_entry_tile.dart`
- Modify: `lib/presentation/screens/home_screen.dart`

- [ ] **Step 1: Criar o entry tile com badge**

```dart
// lib/presentation/widgets/daily_reward_entry_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/daily_rewards/daily_rewards_screen.dart';
import '../../domain/daily_rewards/daily_rewards_engine.dart';
import '../../domain/daily_rewards/daily_rewards_notifier.dart';

class DailyRewardEntryTile extends ConsumerWidget {
  const DailyRewardEntryTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyState = ref.watch(dailyRewardsProvider);
    final status = computeDailyRewardStatus(DateTime.now(), dailyState);
    final hasReward = status == DailyRewardStatus.available ||
        status == DailyRewardStatus.cycleCompleted;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DailyRewardsScreen()),
      ),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.card_giftcard, color: Colors.white, size: 32),
            ),
            if (hasReward)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Adicionar `DailyRewardEntryTile` e toast na `HomeScreen`**

Substituir a linha `const Center(child: LivesIndicator()),` pela Row com os dois widgets, e converter `HomeScreen` de `ConsumerWidget` para `ConsumerStatefulWidget` para o toast:

```dart
// lib/presentation/screens/home_screen.dart — conteúdo completo atualizado
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/daily_rewards/daily_rewards_engine.dart';
import '../../domain/daily_rewards/daily_rewards_notifier.dart';
import '../../domain/lives/lives_notifier.dart';
import '../controllers/game_notifier.dart';
import '../widgets/daily_reward_entry_tile.dart';
import '../widgets/game_background.dart';
import '../widgets/lives_indicator.dart';
import 'game/game_screen.dart';
import 'no_lives_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _toastShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowToast());
  }

  void _maybeShowToast() {
    if (_toastShown) return;
    final dailyState = ref.read(dailyRewardsProvider);
    final status = computeDailyRewardStatus(DateTime.now(), dailyState);
    if (status == DailyRewardStatus.available || status == DailyRewardStatus.cycleCompleted) {
      _toastShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sua recompensa diária está disponível!',
            style: GoogleFonts.nunito(),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final hasSave = gameState.score > 0;

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    LivesIndicator(),
                    DailyRewardEntryTile(),
                  ],
                ),
                const Spacer(),
                const SizedBox(height: 220),
                const SizedBox(height: 32),
                _HomeButton(
                  label: 'Novo Jogo',
                  onPressed: () => _startNew(context),
                ),
                const SizedBox(height: 12),
                _HomeButton(
                  label: 'Continuar',
                  onPressed: hasSave ? () => _continue(context) : null,
                ),
                const SizedBox(height: 12),
                const _RankingButton(),
                const SizedBox(height: 12),
                _HomeButton(
                  label: 'Sair',
                  onPressed: () => SystemNavigator.pop(),
                  secondary: true,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startNew(BuildContext context) {
    if (!ref.read(livesProvider.notifier).canPlay) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NoLivesScreen(midGame: false)),
      );
      return;
    }
    ref.read(gameProvider.notifier).restart();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  void _continue(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen()));
  }
}

class _HomeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;

  const _HomeButton({
    required this.label,
    this.onPressed,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary ? Colors.white24 : Colors.white,
          foregroundColor: secondary ? Colors.white : AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _RankingButton extends StatelessWidget {
  const _RankingButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
                foregroundColor: Colors.white38,
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Ranking',
                style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Positioned(
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Em breve',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Verificar que compila**

```bash
flutter analyze lib/presentation/
```

Esperado: `No issues found`

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/widgets/daily_reward_entry_tile.dart lib/presentation/screens/home_screen.dart
git commit -m "feat: DailyRewardEntryTile na HomeScreen com badge e toast"
```

---

## Task 12: Rodar suite completa e bump de versão

- [ ] **Step 1: Rodar todos os testes**

```bash
flutter test
```

Esperado: todos os testes passam (engine, notifier, repository, widget x4, + testes anteriores do projeto)

- [ ] **Step 2: Rodar análise estática**

```bash
flutter analyze
```

Esperado: `No issues found`

- [ ] **Step 3: Bump de versão em `pubspec.yaml`**

Localizar a linha `version:` e atualizar de `0.8.4+21` (ou o valor atual) para `0.9.0+22`:

```yaml
version: 0.9.0+22
```

- [ ] **Step 4: Atualizar `CLAUDE.md` — fase atual**

Na linha que descreve a fase atual em `CLAUDE.md`:

```
Fase atual: **Fase 2.4 concluída (v0.9.0) — próximo: Fase 2.5 (Home definitiva + Coleção + Configurações)**
```

- [ ] **Step 5: Commit final**

```bash
git add pubspec.yaml CLAUDE.md
git commit -m "chore: bump versão 0.8.4 → 0.9.0 (Fase 2.4 concluída)"
```

---

## Checklist de critérios de aceite

- [ ] `DailyRewardsState` persiste e carrega corretamente via Hive
- [ ] Streak quebra ao pular 1 dia (gap ≥ 2)
- [ ] Ciclo de 7 dias completa e reinicia corretamente
- [ ] Relógio retrocedido não libera recompensa nem pune usuário
- [ ] Cap de 15 vidas respeitado com aviso de confirmação
- [ ] Recompensa não acumula (perdeu o dia = perdeu)
- [ ] Atomicidade: entrega antes de gravar estado
- [ ] `DailyRewardEntryTile` com badge na barra superior da Home
- [ ] Toast uma vez por sessão quando disponível
- [ ] Overlay "Dobrar" entrega delta correto (não duplica base)
- [ ] `FakeAdService` com delay de 1s funcionando
- [ ] Testes unitários: 14 casos do engine (incluindo rewardForDay)
- [ ] Testes de integração: 6 casos do notifier
- [ ] Testes de widget: 4 estados da tela
- [ ] `flutter analyze` sem issues
- [ ] Sem SFX/música
