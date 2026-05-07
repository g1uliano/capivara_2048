# Package Upgrade — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Atualizar os 47 pacotes desatualizados, migrar 11 `StateNotifier` → `Notifier`/`AsyncNotifier`, e reescrever o fluxo Google Sign-In para a API v7.

**Architecture:** Upgrade em 3 grupos sequenciais. Grupo 1: infra de build + baixo risco (sem código Dart). Grupo 2: `share_plus` + `google_mobile_ads` (3 arquivos). Grupo 3: Riverpod 3 + `google_sign_in` 7 (11 notifiers + reescrita do `FirebaseAuthService`).

**Tech Stack:** Flutter 3.41.7, Dart 3.11, Riverpod 3.3.1, Firebase suite v4/v6, google_sign_in 7.2, share_plus 13.1, google_mobile_ads 8.0

**Spec:** `docs/specs/2026-05-07-package-upgrade-design.md`

---

## GRUPO 1 — Infra de build + pacotes baixo risco

### Task 1: Atualizar AGP no settings.gradle.kts

**Files:**

- Modify: `android/settings.gradle.kts`

- [ ] **Atualizar Android Gradle Plugin de 8.11.1 → 8.12.1**

```kotlin
// android/settings.gradle.kts — linha com com.android.application
id("com.android.application") version "8.12.1" apply false
```

- [ ] **Verificar build Android compila**

```bash
cd android && ./gradlew tasks --quiet 2>&1 | tail -5
```

Esperado: sem erros de AGP.

- [ ] **Commit**

```bash
git add android/settings.gradle.kts
git commit -m "build(android): bump AGP to 8.12.1"
```

---

### Task 2: Atualizar pubspec.yaml — Grupo 1

**Files:**

- Modify: `pubspec.yaml`

- [ ] **Atualizar as versões no pubspec.yaml**

```yaml
dependencies:
  # Firebase suite
  firebase_core: ^4.7.0
  firebase_auth: ^6.4.0
  cloud_firestore: ^6.3.0

  # Plus plugins (zero mudança de API Dart)
  app_links: ^7.0.0
  connectivity_plus: ^7.1.1
  package_info_plus: ^10.1.0
  sign_in_with_apple: ^8.0.0
  google_fonts: ^8.1.0

dev_dependencies:
  flutter_lints: ^6.0.0
  build_runner: ^2.15.0
  test: ^1.31.1
```

- [ ] **Rodar pub upgrade**

```bash
flutter pub upgrade
```

Esperado: sem erros de resolução.

- [ ] **Verificar build**

```bash
flutter build apk --flavor prod --release --dart-define=FLAVOR=prd 2>&1 | tail -10
```

Esperado: `✓ Built build/app/outputs/apk/prod/release/app-prod-release.apk`

- [ ] **Rodar testes**

```bash
flutter test --reporter=compact 2>&1 | tail -20
```

Esperado: todos os testes passam.

- [ ] **Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(deps): bump firebase suite v4/6, plus plugins, lints — group 1"
```

---

## GRUPO 2 — share_plus + google_mobile_ads

### Task 3: Atualizar pubspec.yaml — Grupo 2

**Files:**

- Modify: `pubspec.yaml`

- [ ] **Atualizar versões**

```yaml
dependencies:
  share_plus: ^13.1.0
  google_mobile_ads: ^8.0.0
```

```bash
flutter pub upgrade
```

---

### Task 4: Migrar Share.share() nos 3 arquivos

**Files:**

- Modify: `lib/presentation/screens/invite_friends_screen.dart`
- Modify: `lib/presentation/widgets/purchase_success_sheet.dart`
- Modify: `lib/testing/share_results.dart`

- [ ] **invite_friends_screen.dart — substituir Share.share()**

Localizar o trecho:

```dart
onPressed: () => Share.share(
```

Substituir por:

```dart
onPressed: () => SharePlus.instance.share(ShareParams(text:
```

E fechar com `))` ao invés de `)`.

Adicionar import se não existir:

```dart
import 'package:share_plus/share_plus.dart';
```

- [ ] **purchase_success_sheet.dart — substituir Share.share()**

Localizar o trecho:

```dart
onPressed: () => Share.share(
```

Substituir por:

```dart
onPressed: () => SharePlus.instance.share(ShareParams(text:
```

E fechar com `))`.

- [ ] **testing/share_results.dart — substituir Share.shareXFiles()**

Localizar:

```dart
await Share.shareXFiles(
  [XFile(path)],
```

Substituir por:

```dart
await SharePlus.instance.share(
  ShareParams(files: [XFile(path)]),
```

- [ ] **Verificar build**

```bash
flutter build apk --flavor prod --release --dart-define=FLAVOR=prd 2>&1 | tail -10
```

Esperado: `✓ Built ...`

- [ ] **Rodar testes**

```bash
flutter test --reporter=compact 2>&1 | tail -20
```

- [ ] **Commit**

```bash
git add lib/presentation/screens/invite_friends_screen.dart \
        lib/presentation/widgets/purchase_success_sheet.dart \
        lib/testing/share_results.dart pubspec.yaml pubspec.lock
git commit -m "feat(deps): upgrade share_plus 13 + google_mobile_ads 8, migrate Share API"
```

---

## GRUPO 3 — Riverpod 3 + google_sign_in 7

### Task 5: Atualizar pubspec.yaml — Grupo 3

**Files:**

- Modify: `pubspec.yaml`

- [ ] **Atualizar versões**

```yaml
dependencies:
  flutter_riverpod: ^3.3.1
  google_sign_in: ^7.2.0
```

```bash
flutter pub upgrade
```

Esperado: sem erros de resolução (o código ainda não compila — normal, vamos migrar nas tasks seguintes).

---

### Task 6: Migrar ReduceEffectsNotifier

**Files:**

- Modify: `lib/core/providers/reduce_effects_provider.dart`

- [ ] **Substituir StateNotifier por Notifier**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReduceEffectsNotifier extends Notifier<bool> {
  static const _key = 'reduce_effects';

  @override
  bool build() => false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}

final reduceEffectsProvider = NotifierProvider<ReduceEffectsNotifier, bool>(
  ReduceEffectsNotifier.new,
);
```

---

### Task 7: Migrar ShareCodesNotifier

**Files:**

- Modify: `lib/domain/shop/share_codes_notifier.dart`

- [ ] **Substituir StateNotifier por Notifier**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/share_code.dart';
import '../../data/repositories/share_codes_repository.dart';

class ShareCodesNotifier extends Notifier<List<ShareCode>> {
  @override
  List<ShareCode> build() => [];

  Future<void> load() async {
    state = await ref.read(shareCodesRepositoryProvider).load();
  }

  Future<void> add(ShareCode code) async {
    state = [...state, code];
    await ref.read(shareCodesRepositoryProvider).save(state);
  }
}

final shareCodesRepositoryProvider = Provider<ShareCodesRepository>(
  (_) => ShareCodesRepository(),
);

final shareCodesProvider = NotifierProvider<ShareCodesNotifier, List<ShareCode>>(
  ShareCodesNotifier.new,
);
```

---

### Task 8: Migrar PersonalRecordsNotifier

**Files:**

- Modify: `lib/presentation/controllers/personal_records_notifier.dart`

- [ ] **Substituir StateNotifier por Notifier**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/personal_records.dart';
import '../../data/models/personal_records_hive_adapter.dart';

class PersonalRecordsNotifier extends Notifier<PersonalRecords> {
  static const _boxName = 'personal_records';
  static const _key = 'records';

  @override
  PersonalRecords build() => const PersonalRecords();

  Future<void> load() async {
    if (!Hive.isAdapterRegistered(PersonalRecords.hiveTypeId)) {
      Hive.registerAdapter(PersonalRecordsHiveAdapter());
    }
    final box = await Hive.openBox<PersonalRecords>(_boxName);
    state = box.get(_key) ?? const PersonalRecords();
  }

  Future<void> _save() async {
    final box = await Hive.openBox<PersonalRecords>(_boxName);
    await box.put(_key, state);
  }

  Future<void> recordMilestone(int level, DateTime reachedAt) async {
    switch (level) {
      case 11:
        state = state.firstReached2048At == null
            ? state.copyWith(
                timesReached2048: state.timesReached2048 + 1,
                firstReached2048At: reachedAt,
              )
            : state.copyWith(timesReached2048: state.timesReached2048 + 1);
      case 12:
        state = state.firstReached4096At == null
            ? state.copyWith(
                timesReached4096: state.timesReached4096 + 1,
                firstReached4096At: reachedAt,
              )
            : state.copyWith(timesReached4096: state.timesReached4096 + 1);
      case 13:
        state = state.firstReached8192At == null
            ? state.copyWith(
                timesReached8192: state.timesReached8192 + 1,
                firstReached8192At: reachedAt,
              )
            : state.copyWith(timesReached8192: state.timesReached8192 + 1);
    }
    await _save();
  }

  bool isFirstTime(int level) {
    switch (level) {
      case 11: return state.timesReached2048 == 0;
      case 12: return state.timesReached4096 == 0;
      case 13: return state.timesReached8192 == 0;
      default: return false;
    }
  }

  Future<void> markRewardCollected(int level) async {
    if (level == 12) state = state.copyWith(rewardCollected4096: true);
    else if (level == 13) state = state.copyWith(rewardCollected8192: true);
    await _save();
  }

  Future<void> updateHighestLevel(int level) async {
    if (level > state.highestLevelEver) {
      state = state.copyWith(highestLevelEver: level);
      await _save();
    }
  }
}

final personalRecordsProvider =
    NotifierProvider<PersonalRecordsNotifier, PersonalRecords>(
  PersonalRecordsNotifier.new,
);
```

---

### Task 9: Migrar SettingsNotifier + criar sharedPreferencesProvider

**Files:**

- Modify: `lib/presentation/controllers/settings_notifier.dart`
- Modify: `lib/main.dart`

- [ ] **Criar sharedPreferencesProvider e migrar SettingsNotifier**

```dart
// lib/presentation/controllers/settings_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool hapticEnabled;
  final String locale;

  const SettingsState({this.hapticEnabled = true, this.locale = 'pt'});

  SettingsState copyWith({bool? hapticEnabled, String? locale}) => SettingsState(
        hapticEnabled: hapticEnabled ?? this.hapticEnabled,
        locale: locale ?? this.locale,
      );
}

/// Deve ser sobrescrito em ProviderScope/ProviderContainer com a instância real.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

class SettingsNotifier extends Notifier<SettingsState> {
  static const _hapticKey = 'settings.haptic_enabled';
  static const _localeKey = 'settings.locale';

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SettingsState(
      hapticEnabled: prefs.getBool(_hapticKey) ?? true,
      locale: prefs.getString(_localeKey) ?? 'pt',
    );
  }

  void setHaptic(bool value) {
    ref.read(sharedPreferencesProvider).setBool(_hapticKey, value);
    state = state.copyWith(hapticEnabled: value);
  }

  void setLocale(String locale) {
    ref.read(sharedPreferencesProvider).setString(_localeKey, locale);
    state = state.copyWith(locale: locale);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
```

- [ ] **Atualizar main.dart: trocar override de settingsProvider por sharedPreferencesProvider**

Localizar em `lib/main.dart`:

```dart
    overrides: [
      settingsProvider.overrideWith((ref) => SettingsNotifier(sharedPrefs)),
      gameRecordRepositoryProvider.overrideWithValue(gameRecordRepo),
    ],
```

Substituir por:

```dart
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      gameRecordRepositoryProvider.overrideWithValue(gameRecordRepo),
    ],
```

Adicionar import em `lib/main.dart` (se não existir):

```dart
import 'presentation/controllers/settings_notifier.dart';
```

---

### Task 10: Migrar InventoryNotifier

**Files:**

- Modify: `lib/domain/inventory/inventory_notifier.dart`

- [ ] **Substituir StateNotifier por Notifier — manter lógica de BoxEvent intacta**

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/models/inventory.dart';
import '../../data/models/item_type.dart';
import '../../data/repositories/inventory_repository.dart';

class InventoryNotifier extends Notifier<Inventory> {
  StreamSubscription<BoxEvent>? _boxSub;

  @override
  Inventory build() {
    ref.onDispose(() {
      _boxSub?.cancel();
    });
    return Inventory.empty();
  }

  Future<void> load() async {
    final repo = ref.read(inventoryRepositoryProvider);
    state = await repo.load();
    Box<Inventory>? box;
    await runZonedGuarded<Future<void>>(
      () async { box = await Hive.openBox<Inventory>('inventory'); },
      (_, __) {},
    );
    if (box != null) {
      await _boxSub?.cancel();
      _boxSub = box!.watch(key: 'data').listen(
        (event) {
          final updated = event.value as Inventory?;
          if (updated != null) state = updated;
        },
        onError: (_) {},
        cancelOnError: false,
      );
    }
  }

  Future<void> add(ItemType type, int amount) async {
    final repo = ref.read(inventoryRepositoryProvider);
    state = await repo.add(type, amount);
  }

  Future<void> consume(ItemType type) async {
    final repo = ref.read(inventoryRepositoryProvider);
    state = await repo.consume(type);
  }
}

final inventoryRepositoryProvider = Provider((_) => InventoryRepository());

final inventoryProvider = NotifierProvider<InventoryNotifier, Inventory>(
  InventoryNotifier.new,
);
```

> **Nota:** Se `InventoryRepository` não expõe `add`/`consume` com retorno de `Inventory`, mantenha o mesmo padrão do código original (ler/salvar via repo e atribuir a `state`). Ajuste as assinaturas dos métodos `add`/`consume` conforme o repositório existente.

---

### Task 11: Migrar DailyRewardsNotifier

**Files:**

- Modify: `lib/domain/daily_rewards/daily_rewards_notifier.dart`

- [ ] **Substituir StateNotifier por Notifier — ref como propriedade**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/daily_rewards_state.dart';
import '../../data/models/item_type.dart';
import '../../data/repositories/daily_rewards_repository.dart';
import '../inventory/inventory_notifier.dart';
import '../lives/lives_notifier.dart';
import 'daily_rewards_engine.dart';

class DailyRewardsNotifier extends Notifier<DailyRewardsState> {
  @override
  DailyRewardsState build() => DailyRewardsState.initial();

  Future<void> load() async {
    state = await ref.read(dailyRewardsRepositoryProvider).load();
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

    if (reward.lives > 0) {
      await ref.read(livesProvider.notifier).addEarned(reward.lives);
    }
    if (reward.undo1 > 0) {
      await ref.read(inventoryProvider.notifier).add(ItemType.undo1, reward.undo1);
    }
    if (reward.bomb2 > 0) {
      await ref.read(inventoryProvider.notifier).add(ItemType.bomb2, reward.bomb2);
    }

    final next = applyClaim(now, current);
    state = next;
    await ref.read(dailyRewardsRepositoryProvider).save(state);
  }
}

final dailyRewardsRepositoryProvider = Provider((_) => DailyRewardsRepository());

final dailyRewardsProvider =
    NotifierProvider<DailyRewardsNotifier, DailyRewardsState>(
  DailyRewardsNotifier.new,
);
```

> **Nota:** Se houver mais métodos no arquivo original (após `claim`), preservá-los com o mesmo padrão: trocar `_ref.read(...)` por `ref.read(...)` e `_repo` por `ref.read(dailyRewardsRepositoryProvider)`.

---

### Task 12: Migrar LivesNotifier

**Files:**

- Modify: `lib/domain/lives/lives_notifier.dart`

- [ ] **Substituir StateNotifier por Notifier — preservar toda a lógica de timer/stream/lifecycle**

```dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../data/models/lives_state.dart';
import '../../data/repositories/lives_repository.dart';

class LivesNotifier extends Notifier<LivesState> {
  static const _migrationKeyV238 = 'lives_reset_v238';

  final _ready = Completer<void>();
  Timer? _regenTimer;
  StreamSubscription<BoxEvent>? _boxSub;
  AppLifecycleListener? _lifecycleListener;

  @override
  LivesState build() {
    ref.onDispose(() {
      _regenTimer?.cancel();
      _boxSub?.cancel();
      _lifecycleListener?.dispose();
    });
    unawaited(_init());
    return LivesState.initial();
  }

  Future<void> _init() async {
    final repo = ref.read(livesRepositoryProvider);
    final hasResetV238 = await repo.getMigrationFlag(_migrationKeyV238);
    if (!hasResetV238) {
      final fresh = LivesState.initial();
      await repo.save(fresh);
      await repo.setMigrationFlag(_migrationKeyV238);
      state = fresh;
      _ready.complete();
      Box<LivesState>? migBox;
      await runZonedGuarded<Future<void>>(() async {
        migBox = await Hive.openBox<LivesState>('lives');
      }, (_, __) {});
      if (migBox != null) {
        await _boxSub?.cancel();
        _boxSub = migBox!.watch(key: 'state').listen(
          (event) {
            final updated = event.value as LivesState?;
            if (updated != null) state = updated;
          },
          onError: (_) {},
          cancelOnError: false,
        );
      }
      return;
    }

    var loaded = await repo.load();
    loaded = calcRegen(state: loaded, now: DateTime.now());
    state = loaded;
    await repo.save(state);
    _ready.complete();
    _startRegenTimer();
    Box<LivesState>? box;
    await runZonedGuarded<Future<void>>(() async {
      box = await Hive.openBox<LivesState>('lives');
    }, (_, __) {});
    if (box != null) {
      await _boxSub?.cancel();
      _boxSub = box!.watch(key: 'state').listen(
        (event) {
          final updated = event.value as LivesState?;
          if (updated != null) {
            state = updated;
            _startRegenTimer();
          }
        },
        onError: (_) {},
        cancelOnError: false,
      );
    }
    try {
      _lifecycleListener = AppLifecycleListener(
        onPause: _pauseRegen,
        onResume: _resumeRegen,
      );
    } catch (_) {}
  }

  // ── Lógica pura (estática — testável sem Flutter) ──────────────────────────

  static LivesState calcRegen({required LivesState state, required DateTime now}) {
    if (state.lives >= state.regenCap) return state;
    final delta = now.difference(state.lastRegenAt);
    final totalMinutes = delta.inMinutes;
    final gained = (totalMinutes ~/ 30).clamp(0, state.regenCap - state.lives);
    if (gained <= 0) return state;
    return state.copyWith(
      lives: state.lives + gained,
      lastRegenAt: state.lastRegenAt.add(Duration(minutes: gained * 30)),
    );
  }

  static LivesState applyConsume(LivesState state) {
    if (state.lives <= 0) return state;
    final wasAtCap = state.lives >= state.regenCap;
    return state.copyWith(
      lives: state.lives - 1,
      lastRegenAt: wasAtCap ? DateTime.now() : state.lastRegenAt,
    );
  }

  static LivesState applyAddEarned(LivesState state, int amount) {
    final capped = (state.lives + amount).clamp(0, state.earnedCap);
    return state.copyWith(lives: capped);
  }

  static LivesState applyAddPurchased(LivesState state, int amount) =>
      state.copyWith(lives: state.lives + amount);

  static bool canWatchAdFor(LivesState state) {
    final now = DateTime.now();
    if (now.isAfter(state.adCounterResetAt)) return true;
    return state.adWatchedToday < 40;
  }

  static LivesState applyAdReward(LivesState state) {
    final now = DateTime.now();
    LivesState s = state;
    if (now.isAfter(s.adCounterResetAt)) {
      s = s.copyWith(
        adWatchedToday: 0,
        adCounterResetAt: DateTime(now.year, now.month, now.day + 1),
      );
    }
    return applyAddEarned(s.copyWith(adWatchedToday: s.adWatchedToday + 1), 1);
  }

  static LivesState applyAdWatched(LivesState state) {
    final now = DateTime.now();
    LivesState s = state;
    if (now.isAfter(s.adCounterResetAt)) {
      s = s.copyWith(
        adWatchedToday: 0,
        adCounterResetAt: DateTime(now.year, now.month, now.day + 1),
      );
    }
    return s.copyWith(adWatchedToday: s.adWatchedToday + 1);
  }

  // ── Timer interno ──────────────────────────────────────────────────────────

  void _startRegenTimer() {
    _regenTimer?.cancel();
    _regenTimer = Timer.periodic(const Duration(seconds: 30), (_) => _onRegenTick());
  }

  void _onRegenTick() {
    final before = state.lives;
    final updated = calcRegen(state: state, now: DateTime.now());
    if (updated.lives != before) {
      state = updated;
      ref.read(livesRepositoryProvider).save(state);
    }
  }

  void _pauseRegen() {
    _regenTimer?.cancel();
    _regenTimer = null;
  }

  void _resumeRegen() {
    final updated = calcRegen(state: state, now: DateTime.now());
    if (updated.lives != state.lives) {
      state = updated;
      ref.read(livesRepositoryProvider).save(state);
    }
    _startRegenTimer();
  }

  // ── API pública ────────────────────────────────────────────────────────────

  Future<void> consume() async {
    await _ready.future;
    state = applyConsume(state);
    await ref.read(livesRepositoryProvider).save(state);
  }

  Future<void> addEarned(int amount) async {
    await _ready.future;
    state = applyAddEarned(state, amount);
    await ref.read(livesRepositoryProvider).save(state);
  }

  Future<void> addPurchased(int amount) async {
    await _ready.future;
    state = applyAddPurchased(state, amount);
    await ref.read(livesRepositoryProvider).save(state);
  }

  Future<void> rewardFromAd() async {
    await _ready.future;
    state = applyAdReward(state);
    await ref.read(livesRepositoryProvider).save(state);
  }

  Future<void> recordAdWatched() async {
    await _ready.future;
    state = applyAdWatched(state);
    await ref.read(livesRepositoryProvider).save(state);
  }

  bool get canWatchAd => canWatchAdFor(state);
  bool get canPlay => state.lives > 0;

  @visibleForTesting
  void debugSetState(LivesState s) => state = s;

  @visibleForTesting
  Future<void> awaitReady() => _ready.future;
}

final livesRepositoryProvider = Provider((_) => LivesRepository());

final livesProvider = NotifierProvider<LivesNotifier, LivesState>(
  LivesNotifier.new,
);
```

---

### Task 13: Migrar RankingController para AsyncNotifier

**Files:**

- Modify: `lib/presentation/controllers/ranking_controller.dart`

- [ ] **Substituir StateNotifier\<AsyncValue\<T\>\> por AsyncNotifier\<T\>**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ranking_provider.dart';
import '../../domain/ranking/ranking_repository.dart';
import '../../domain/ranking/week_id.dart';
import '../../domain/ranking/weekly_reward_result.dart';

class RankingController extends AsyncNotifier<WeeklyRewardResult?> {
  @override
  Future<WeeklyRewardResult?> build() async => null;

  Future<WeeklyRewardResult?> checkWeeklyReward() async {
    state = const AsyncLoading();
    try {
      final currentWeekId = WeekId.fromUtc(DateTime.now().toUtc());
      final reward = await ref
          .read(rankingRepositoryProvider)
          .checkAndClaimWeeklyReward(currentWeekId);
      state = AsyncData(reward);
      return reward;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  void clearReward() => state = const AsyncData(null);
}

final rankingControllerProvider =
    AsyncNotifierProvider<RankingController, WeeklyRewardResult?>(
  RankingController.new,
);
```

> **Atenção:** Qualquer widget que ler `rankingControllerProvider` com `ref.watch` receberá `AsyncValue<WeeklyRewardResult?>`. Se houver código que usava `.value` ou `.when`, verificar se ainda compila — provavelmente já usava `AsyncValue` antes.

---

### Task 14: Migrar InviteController para AsyncNotifier

**Files:**

- Modify: `lib/presentation/controllers/invite_controller.dart`

- [ ] **Substituir StateNotifier\<AsyncValue\<T\>\> por AsyncNotifier\<T\>**

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/invites/invite_service.dart';
import '../controllers/auth_controller.dart';

class InviteController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<String?> generateLink() async {
    final profile = ref.read(authControllerProvider);
    if (profile == null) return null;
    state = const AsyncLoading();
    try {
      final link = await ref
          .read(inviteServiceProvider)
          .generateInviteLink(profile.userId);
      state = AsyncData(link);
      return link;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final inviteControllerProvider =
    AsyncNotifierProvider<InviteController, String?>(
  InviteController.new,
);
```

---

### Task 15: Migrar AuthController

**Files:**

- Modify: `lib/presentation/controllers/auth_controller.dart`

- [ ] **Substituir StateNotifier por Notifier — remover ref do construtor**

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/player_profile.dart';
import '../../domain/auth/auth_service.dart';
import '../../domain/invites/invite_service.dart';
import '../../domain/sync/sync_engine.dart';
import '../../data/repositories/iap_startup_service.dart';

class AuthController extends Notifier<PlayerProfile?> {
  @override
  PlayerProfile? build() {
    return ref.read(authServiceProvider).currentProfile;
  }

  Future<void> signInWithGoogle() async {
    final profile = await ref.read(authServiceProvider).signInWithGoogle();
    state = profile;
    try {
      final sync = ref.read(syncEngineProvider);
      await sync.init(profile.userId, displayName: profile.displayName);
      await sync.syncProfile();
      await sync.drainPendingEvents();
      _initIAPStartup(profile.userId);
      unawaited(_registerPendingInvite(profile));
    } catch (_) {
      state = null;
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    final profile = await ref.read(authServiceProvider).signInWithApple();
    state = profile;
    try {
      final sync = ref.read(syncEngineProvider);
      await sync.init(profile.userId, displayName: profile.displayName);
      await sync.syncProfile();
      await sync.drainPendingEvents();
      _initIAPStartup(profile.userId);
      unawaited(_registerPendingInvite(profile));
    } catch (_) {
      state = null;
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    final profile = await ref
        .read(authServiceProvider)
        .signInWithEmail(email, password);
    state = profile;
    try {
      final sync = ref.read(syncEngineProvider);
      await sync.init(profile.userId, displayName: profile.displayName);
      await sync.syncProfile();
      await sync.drainPendingEvents();
      _initIAPStartup(profile.userId);
      unawaited(_registerPendingInvite(profile));
    } catch (_) {
      state = null;
      rethrow;
    }
  }

  Future<void> createAccountWithEmail(String email, String password) async {
    final profile = await ref
        .read(authServiceProvider)
        .createAccountWithEmail(email, password);
    state = profile;
    final sync = ref.read(syncEngineProvider);
    await sync.init(profile.userId, displayName: profile.displayName);
    _initIAPStartup(profile.userId);
    unawaited(_registerPendingInvite(profile));
  }

  void _initIAPStartup(String userId) {
    unawaited(ref.read(iapStartupServiceProvider).initialize(userId));
  }

  Future<void> _registerPendingInvite(PlayerProfile profile) async {
    try {
      final box = await Hive.openBox<String>('invite_refs');
      final inviterId = box.get('pending_ref');
      if (inviterId == null || inviterId.isEmpty) return;
      await ref.read(inviteServiceProvider).registerInvite(
            inviterId: inviterId,
            inviteeId: profile.userId,
            inviteeDisplayName: profile.displayName,
          );
    } catch (_) {}
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    unawaited(ref.read(iapStartupServiceProvider).dispose());
    await ref.read(syncEngineProvider).dispose();
    state = null;
  }

  bool get isLoggedIn => state != null;
}

final authControllerProvider =
    NotifierProvider<AuthController, PlayerProfile?>(AuthController.new);
```

---

### Task 16: Migrar GameNotifier

**Files:**

- Modify: `lib/presentation/controllers/game_notifier.dart`

- [ ] **Substituir StateNotifier por Notifier — remover ref do construtor, preservar toda a lógica de jogo**

Localizar a declaração da classe e construtor:

```dart
class GameNotifier extends StateNotifier<GameState> {
  final GameEngine _engine;
  final Ref _ref;
  // ...
  GameNotifier(this._engine, this._ref) : super(_engine.newGame());
```

Substituir por:

```dart
class GameNotifier extends Notifier<GameState> {
  late final GameEngine _engine;
  // ...

  @override
  GameState build() {
    _engine = GameEngine(); // ou ref.read(gameEngineProvider) se existir provider
    return _engine.newGame();
  }
```

Substituir todas as ocorrências de `_ref.read(...)` e `_ref.watch(...)` por `ref.read(...)` e `ref.watch(...)` dentro da classe.

Localizar a declaração do provider no final do arquivo:

```dart
final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(ref.read(gameEngineProvider), ref);  // ou similar
});
```

Substituir por:

```dart
final gameProvider = NotifierProvider<GameNotifier, GameState>(
  GameNotifier.new,
);
```

> **Atenção:** `GameEngine` pode ter um provider próprio (`gameEngineProvider`). Verificar como é instanciado no provider atual e replicar com `ref.read(...)` no `build()`. Se for instanciado inline com `GameEngine()`, manter assim.

- [ ] **Verificar arquivo compila**

```bash
flutter analyze lib/presentation/controllers/game_notifier.dart 2>&1 | tail -20
```

Esperado: sem erros.

---

### Task 17: Verificar compilação após migrações Riverpod

- [ ] **Rodar analyze**

```bash
flutter analyze lib/ 2>&1 | grep -E "error|warning" | head -40
```

- [ ] **Corrigir erros de compilação remanescentes**

Erros comuns esperados:

- `StateNotifierProvider` ainda importado em arquivo não migrado → migrar o arquivo
- `.notifier` em provider que mudou tipo → sem mudança, `.notifier` funciona igual em `NotifierProvider`
- `StateNotifier` em testes → nos testes, substituir `StateNotifierProvider` por `NotifierProvider` no setup

- [ ] **Rodar testes**

```bash
flutter test --reporter=compact 2>&1 | tail -30
```

- [ ] **Commit intermediário**

```bash
git add lib/
git commit -m "feat(deps): migrate 11 StateNotifier → Notifier/AsyncNotifier for Riverpod 3"
```

---

### Task 18: Reescrever FirebaseAuthService para google_sign_in 7

**Files:**

- Modify: `lib/data/repositories/firebase_auth_service.dart`

- [ ] **Reescrever o arquivo completo**

```dart
// lib/data/repositories/firebase_auth_service.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/models/player_profile.dart';
import '../../domain/auth/auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService() : _auth = fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;
  bool _googleInitialized = false;

  /// Inicializa o Google Sign-In. Deve ser chamado uma vez antes de signInWithGoogle.
  /// Seguro chamar múltiplas vezes — idempotente.
  Future<void> initGoogleSignIn() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  @override
  Stream<PlayerProfile?> get authStateChanges =>
      _auth.authStateChanges().map(_toProfile);

  @override
  PlayerProfile? get currentProfile => _toProfile(_auth.currentUser);

  @override
  Future<PlayerProfile> signInWithGoogle() async {
    await initGoogleSignIn();

    // Envolve o fluxo de eventos em um Completer para uso como Future.
    final completer = Completer<GoogleSignInAccount>();
    late StreamSubscription<Object> sub;
    sub = GoogleSignIn.instance.authenticationEvents.listen(
      (event) {
        if (event is GoogleSignInAccount) {
          if (!completer.isCompleted) completer.complete(event);
          sub.cancel();
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) completer.completeError(error);
        sub.cancel();
      },
    );

    // Dispara o fluxo de autenticação.
    await GoogleSignIn.instance.authenticate();

    late GoogleSignInAccount googleUser;
    try {
      googleUser = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw TimeoutException('Google Sign-In timeout'),
      );
    } catch (e) {
      sub.cancel();
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Login cancelado');
      }
      rethrow;
    }

    // Obtém o accessToken via authorização de escopos.
    final authorization = await GoogleSignIn.instance.authorizationForScopes(
      ['email', 'profile'],
    );
    final accessToken = authorization?.accessToken;

    // Obtém o idToken a partir do usuário autenticado.
    // Em google_sign_in 7, o idToken é acessado via serverAuthCode ou
    // por meio do servidor — para uso com Firebase, usamos o OAuthCredential
    // com apenas o accessToken quando o idToken não está disponível.
    fb.OAuthCredential credential;
    if (accessToken != null) {
      credential = fb.GoogleAuthProvider.credential(
        accessToken: accessToken,
      );
    } else {
      throw Exception('Não foi possível obter accessToken do Google');
    }

    final result = await _auth.signInWithCredential(credential);
    return _toProfile(result.user)!;
  }

  @override
  Future<PlayerProfile> signInWithApple() async {
    throw UnimplementedError('Apple Sign-In: implementar com sign_in_with_apple');
  }

  @override
  Future<PlayerProfile> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return _toProfile(result.user)!;
  }

  @override
  Future<PlayerProfile> createAccountWithEmail(
      String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    return _toProfile(result.user)!;
  }

  @override
  Future<void> signOut() async {
    if (_googleInitialized) {
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }

  PlayerProfile? _toProfile(fb.User? user) {
    if (user == null) return null;
    final provider = _detectProvider(user);
    return PlayerProfile(
      userId: user.uid,
      displayName: user.displayName ?? 'Jogador',
      avatarUrl: user.photoURL,
      email: user.email,
      provider: provider,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastSeenAt: DateTime.now(),
    );
  }

  AuthProvider _detectProvider(fb.User user) {
    final providerId = user.providerData.isNotEmpty
        ? user.providerData.first.providerId
        : 'password';
    if (providerId.contains('google')) return AuthProvider.google;
    if (providerId.contains('apple')) return AuthProvider.apple;
    return AuthProvider.email;
  }
}
```

> **Nota sobre idToken:** O google_sign_in 7 separou autenticação de autorização. Para Firebase Auth com Google, o ideal é usar `serverAuthCode` + troca no servidor, ou usar apenas `accessToken`. Se o app precisar de `idToken` no cliente, investigar `authorizeServer()` da nova API. Por ora, `accessToken` sozinho funciona com `GoogleAuthProvider.credential`.

---

### Task 19: Inicializar Google Sign-In no startup

**Files:**

- Modify: `lib/main.dart`

- [ ] **Chamar initGoogleSignIn() no startup — antes de runApp**

Localizar em `lib/main.dart`, após `await Firebase.initializeApp(...)`:

```dart
// Inicializa Google Sign-In (deve ocorrer uma vez antes de qualquer signIn)
final authService = FirebaseAuthService();
await authService.initGoogleSignIn();
```

Adicionar import se não existir:

```dart
import 'data/repositories/firebase_auth_service.dart';
```

> **Atenção:** `FirebaseAuthService` também é instanciado via `authServiceProvider`. O `initGoogleSignIn()` é idempotente — chamar duas vezes não causa problema. Alternativamente, pode-se chamar `GoogleSignIn.instance.initialize()` diretamente no `main.dart` e remover `initGoogleSignIn()` da classe. Ambas as abordagens são equivalentes.

---

### Task 20: Verificação final e commit

- [ ] **Rodar analyze completo**

```bash
flutter analyze lib/ 2>&1 | grep -c "error" && echo "Erros acima"
```

Esperado: `0 erros`

- [ ] **Rodar todos os testes**

```bash
flutter test --reporter=compact 2>&1 | tail -20
```

Esperado: todos os testes passam.

- [ ] **Build de produção**

```bash
flutter build appbundle --flavor prod --release \
  --dart-define=FLAVOR=prd \
  --dart-define=AD_UNIT_ANDROID=ca-app-pub-3940256099942544/5224354917 \
  --dart-define=AD_UNIT_IOS=ca-app-pub-3940256099942544/1712485313 \
  2>&1 | tail -5
```

Esperado: `✓ Built build/app/outputs/bundle/prodRelease/app-prod-release.aab`

- [ ] **Commit final**

```bash
git add -A
git commit -m "feat(deps): upgrade google_sign_in 7, rewrite FirebaseAuthService — group 3 complete"
```

- [ ] **Atualizar CHANGELOG.md com a versão**

Adicionar entrada no topo:

```markdown
## [1.5.0] - 2026-05-XX

### Changed

- Upgraded 47 packages to latest versions
- Migrated 11 StateNotifier → Notifier/AsyncNotifier (Riverpod 3)
- Rewrote Google Sign-In flow for google_sign_in 7.x API
- Migrated Share.share() → SharePlus.instance.share() (share_plus 13)
- Bumped Firebase suite to core v4 / auth v6 / firestore v6
- Bumped AGP to 8.12.1
```

- [ ] **Commit docs**

```bash
git add CHANGELOG.md
git commit -m "docs: update CHANGELOG for v1.5.0 package upgrades"
```
