# Performance Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar sistema de Performance Mode que detecta dispositivos fracos automaticamente (heurística + FPS em runtime), sugere ativação via dialog, e expõe controles granulares em Configurações — além de corrigir o threshold de swipe de 100→50 px/s.

**Architecture:** `PerformanceSettings` (modelo + Riverpod notifier, SharedPreferences) controla qualidade dos tiles, blur e animações. `DeviceCapabilityDetector` roda heurística de modelo/SDK no launch. `FpsMonitorNotifier` usa `SchedulerBinding.addTimingsCallback` para detectar drops em runtime durante o jogo. `TileWidget` passa de `StatelessWidget` para `ConsumerWidget` com três variantes de render.

**Tech Stack:** Flutter 3.x, Riverpod 3 (`NotifierProvider`), SharedPreferences (existente), `device_info_plus` (nova dependência), `SchedulerBinding.addTimingsCallback`, `GoogleFonts.fredoka`/`nunito` (padrão existente).

---

## File Map

| Arquivo | Status | Responsabilidade |
|---------|--------|-----------------|
| `lib/domain/performance/performance_settings.dart` | NOVO | Enum `TileQuality`, modelo `PerformanceSettings` imutável + JSON |
| `lib/domain/performance/device_capability_detector.dart` | NOVO | Heurística de modelo/SDK para detectar dispositivo fraco |
| `lib/presentation/controllers/performance_settings_notifier.dart` | NOVO | Riverpod `NotifierProvider`, load/save/enable/disable |
| `lib/presentation/controllers/fps_monitor_notifier.dart` | NOVO | `SchedulerBinding` FPS listener, emite `true` quando drops detectados |
| `lib/presentation/widgets/performance_suggestion_dialog.dart` | NOVO | Dialog estilo `_CannotUseItemDialog` com botões "Ativar"/"Agora não" |
| `test/domain/performance_settings_test.dart` | NOVO | Testes do modelo (copyWith, toJson, fromJson) |
| `test/domain/device_capability_detector_test.dart` | NOVO | Testes da heurística (lógica pura) |
| `test/presentation/performance_settings_notifier_test.dart` | NOVO | Testes do notifier (load, enable, setTileQuality, persistência) |
| `pubspec.yaml` | MODIFICAR | Adicionar `device_info_plus` |
| `lib/main.dart` | MODIFICAR | Substituir `reduceEffectsProvider` por `performanceSettingsProvider` |
| `lib/presentation/widgets/tile_widget.dart` | MODIFICAR | `ConsumerWidget` + 3 variantes de tile |
| `lib/presentation/widgets/pause_overlay.dart` | MODIFICAR | Trocar `reduceEffectsProvider` por `performanceSettingsProvider` |
| `lib/presentation/screens/settings_screen.dart` | MODIFICAR | Seção Performance; remover toggle "Reduzir Efeitos Visuais" |
| `lib/presentation/screens/game/game_screen.dart` | MODIFICAR | Threshold 100→50; integrar `FpsMonitorNotifier` |
| `lib/presentation/screens/home_screen.dart` | MODIFICAR | Trigger heurística + dialog no `initState` |
| `lib/presentation/widgets/capivara_mascot.dart` | MODIFICAR | Desabilitar animação quando `animationsEnabled = false` |
| `lib/presentation/widgets/daily_reward_day_tile.dart` | MODIFICAR | Desabilitar pulse/sparkles quando `animationsEnabled = false` |
| `lib/presentation/screens/daily_rewards/daily_rewards_screen.dart` | MODIFICAR | Desabilitar claim animation quando `animationsEnabled = false` |
| `lib/core/providers/reduce_effects_provider.dart` | DELETAR | Substituído por `performanceSettingsProvider` |

---

## Task 1: Adicionar device_info_plus ao pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Adicionar dependência**

Abrir `pubspec.yaml` e adicionar logo após `package_info_plus`:

```yaml
  device_info_plus: ^13.1.0
```

- [ ] **Step 2: Instalar**

```bash
flutter pub get
```

Expected: resolução sem conflitos.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add device_info_plus dependency"
```

---

## Task 2: Modelo PerformanceSettings (TDD)

**Files:**
- Create: `lib/domain/performance/performance_settings.dart`
- Create: `test/domain/performance_settings_test.dart`

- [ ] **Step 1: Escrever o teste**

Criar `test/domain/performance_settings_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/performance/performance_settings.dart';

void main() {
  group('PerformanceSettings', () {
    test('defaults: disabled, full quality, blur on, animations on, autoDetect on', () {
      const s = PerformanceSettings();
      expect(s.enabled, false);
      expect(s.tileQuality, TileQuality.full);
      expect(s.blurEffectsEnabled, true);
      expect(s.animationsEnabled, true);
      expect(s.autoDetectEnabled, true);
      expect(s.hasShownSuggestionDialog, false);
    });

    test('copyWith altera apenas o campo especificado', () {
      const s = PerformanceSettings();
      final s2 = s.copyWith(enabled: true, tileQuality: TileQuality.simple);
      expect(s2.enabled, true);
      expect(s2.tileQuality, TileQuality.simple);
      expect(s2.blurEffectsEnabled, true);
      expect(s2.animationsEnabled, true);
    });

    test('toJson / fromJson round-trip', () {
      const s = PerformanceSettings(
        enabled: true,
        tileQuality: TileQuality.fullOpacity,
        blurEffectsEnabled: false,
        animationsEnabled: false,
        autoDetectEnabled: false,
        hasShownSuggestionDialog: true,
      );
      final s2 = PerformanceSettings.fromJson(s.toJson());
      expect(s2.enabled, true);
      expect(s2.tileQuality, TileQuality.fullOpacity);
      expect(s2.blurEffectsEnabled, false);
      expect(s2.animationsEnabled, false);
      expect(s2.autoDetectEnabled, false);
      expect(s2.hasShownSuggestionDialog, true);
    });

    test('fromJson com chave ausente usa defaults', () {
      final s = PerformanceSettings.fromJson({});
      expect(s.enabled, false);
      expect(s.tileQuality, TileQuality.full);
      expect(s.blurEffectsEnabled, true);
    });

    test('== e hashCode baseados em campos', () {
      const a = PerformanceSettings(enabled: true);
      const b = PerformanceSettings(enabled: true);
      const c = PerformanceSettings(enabled: false);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, b.hashCode);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste para confirmar falha**

```bash
flutter test test/domain/performance_settings_test.dart
```

Expected: FAIL — `performance_settings.dart` não existe ainda.

- [ ] **Step 3: Implementar o modelo**

Criar `lib/domain/performance/performance_settings.dart`:

```dart
import 'dart:convert';

enum TileQuality { full, fullOpacity, simple }

class PerformanceSettings {
  const PerformanceSettings({
    this.enabled = false,
    this.tileQuality = TileQuality.full,
    this.blurEffectsEnabled = true,
    this.animationsEnabled = true,
    this.autoDetectEnabled = true,
    this.hasShownSuggestionDialog = false,
  });

  final bool enabled;
  final TileQuality tileQuality;
  final bool blurEffectsEnabled;
  final bool animationsEnabled;
  final bool autoDetectEnabled;
  final bool hasShownSuggestionDialog;

  PerformanceSettings copyWith({
    bool? enabled,
    TileQuality? tileQuality,
    bool? blurEffectsEnabled,
    bool? animationsEnabled,
    bool? autoDetectEnabled,
    bool? hasShownSuggestionDialog,
  }) {
    return PerformanceSettings(
      enabled: enabled ?? this.enabled,
      tileQuality: tileQuality ?? this.tileQuality,
      blurEffectsEnabled: blurEffectsEnabled ?? this.blurEffectsEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      autoDetectEnabled: autoDetectEnabled ?? this.autoDetectEnabled,
      hasShownSuggestionDialog:
          hasShownSuggestionDialog ?? this.hasShownSuggestionDialog,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'tileQuality': tileQuality.index,
        'blurEffectsEnabled': blurEffectsEnabled,
        'animationsEnabled': animationsEnabled,
        'autoDetectEnabled': autoDetectEnabled,
        'hasShownSuggestionDialog': hasShownSuggestionDialog,
      };

  factory PerformanceSettings.fromJson(Map<String, dynamic> json) =>
      PerformanceSettings(
        enabled: json['enabled'] as bool? ?? false,
        tileQuality:
            TileQuality.values[json['tileQuality'] as int? ?? 0],
        blurEffectsEnabled: json['blurEffectsEnabled'] as bool? ?? true,
        animationsEnabled: json['animationsEnabled'] as bool? ?? true,
        autoDetectEnabled: json['autoDetectEnabled'] as bool? ?? true,
        hasShownSuggestionDialog:
            json['hasShownSuggestionDialog'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformanceSettings &&
          enabled == other.enabled &&
          tileQuality == other.tileQuality &&
          blurEffectsEnabled == other.blurEffectsEnabled &&
          animationsEnabled == other.animationsEnabled &&
          autoDetectEnabled == other.autoDetectEnabled &&
          hasShownSuggestionDialog == other.hasShownSuggestionDialog;

  @override
  int get hashCode => Object.hash(
        enabled,
        tileQuality,
        blurEffectsEnabled,
        animationsEnabled,
        autoDetectEnabled,
        hasShownSuggestionDialog,
      );
}
```

- [ ] **Step 4: Rodar os testes**

```bash
flutter test test/domain/performance_settings_test.dart
```

Expected: 5 testes PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/performance/performance_settings.dart test/domain/performance_settings_test.dart
git commit -m "feat(performance): add PerformanceSettings model with TileQuality enum"
```

---

## Task 3: DeviceCapabilityDetector (TDD)

**Files:**
- Create: `lib/domain/performance/device_capability_detector.dart`
- Create: `test/domain/device_capability_detector_test.dart`

- [ ] **Step 1: Escrever o teste**

Criar `test/domain/device_capability_detector_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/performance/device_capability_detector.dart';

void main() {
  group('DeviceCapabilityDetector.isLowEndFromModel', () {
    test('Redmi Note detectado como fraco', () {
      expect(
        DeviceCapabilityDetector.isLowEndFromModel('Redmi Note 9S', 30),
        true,
      );
    });

    test('Poco M detectado como fraco', () {
      expect(
        DeviceCapabilityDetector.isLowEndFromModel('Poco M3 Pro', 31),
        true,
      );
    });

    test('Galaxy A23 detectado como fraco', () {
      expect(
        DeviceCapabilityDetector.isLowEndFromModel('Samsung Galaxy A23', 32),
        true,
      );
    });

    test('Moto G detectado como fraco', () {
      expect(
        DeviceCapabilityDetector.isLowEndFromModel('Moto G82', 33),
        true,
      );
    });

    test('Pixel 8 não detectado como fraco', () {
      expect(
        DeviceCapabilityDetector.isLowEndFromModel('Pixel 8', 34),
        false,
      );
    });

    test('Samsung Galaxy S24 não detectado como fraco', () {
      expect(
        DeviceCapabilityDetector.isLowEndFromModel('SM-S926B', 34),
        false,
      );
    });

    test('SDK < 31 detectado como fraco independente do modelo', () {
      expect(
        DeviceCapabilityDetector.isLowEndFromModel('Pixel 9', 30),
        true,
      );
    });
  });
}
```

- [ ] **Step 2: Rodar o teste para confirmar falha**

```bash
flutter test test/domain/device_capability_detector_test.dart
```

Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar o detector**

Criar `lib/domain/performance/device_capability_detector.dart`:

```dart
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceCapabilityDetector {
  static const _lowEndPatterns = [
    'redmi note',
    'redmi',
    'poco m',
    'poco c',
    'galaxy a0',
    'galaxy a1',
    'galaxy a2',
    'galaxy a3',
    'galaxy a5',
    'moto g',
    'moto e',
  ];

  /// Retorna `true` se o dispositivo for considerado fraco pela heurística.
  /// Só roda no Android; iOS sempre retorna `false`.
  static Future<bool> isLowEndDevice() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    final info = await DeviceInfoPlugin().androidInfo;
    return isLowEndFromModel(info.model, info.version.sdkInt);
  }

  @visibleForTesting
  static bool isLowEndFromModel(String model, int sdkInt) {
    if (sdkInt < 31) return true;
    final lower = model.toLowerCase();
    return _lowEndPatterns.any((p) => lower.contains(p));
  }
}
```

- [ ] **Step 4: Rodar os testes**

```bash
flutter test test/domain/device_capability_detector_test.dart
```

Expected: 7 testes PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/performance/device_capability_detector.dart test/domain/device_capability_detector_test.dart
git commit -m "feat(performance): add DeviceCapabilityDetector heuristic"
```

---

## Task 4: PerformanceSettingsNotifier (TDD)

**Files:**
- Create: `lib/presentation/controllers/performance_settings_notifier.dart`
- Create: `test/presentation/performance_settings_notifier_test.dart`

- [ ] **Step 1: Escrever o teste**

Criar `test/presentation/performance_settings_notifier_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capivara_2048/domain/performance/performance_settings.dart';
import 'package:capivara_2048/presentation/controllers/performance_settings_notifier.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('PerformanceSettingsNotifier', () {
    test('estado inicial: disabled, full quality, blur on, animations on', () async {
      final c = await _container();
      await c.read(performanceSettingsProvider.notifier).load();
      final s = c.read(performanceSettingsProvider);
      expect(s.enabled, false);
      expect(s.tileQuality, TileQuality.full);
      expect(s.blurEffectsEnabled, true);
      expect(s.animationsEnabled, true);
    });

    test('enable() ativa modo e persiste', () async {
      final c = await _container();
      await c.read(performanceSettingsProvider.notifier).load();
      await c.read(performanceSettingsProvider.notifier).enable();
      expect(c.read(performanceSettingsProvider).enabled, true);
      expect(c.read(performanceSettingsProvider).hasShownSuggestionDialog, true);
    });

    test('disable() desativa modo e persiste', () async {
      final c = await _container();
      await c.read(performanceSettingsProvider.notifier).load();
      await c.read(performanceSettingsProvider.notifier).enable();
      await c.read(performanceSettingsProvider.notifier).disable();
      expect(c.read(performanceSettingsProvider).enabled, false);
    });

    test('setTileQuality() altera e persiste', () async {
      final c = await _container();
      await c.read(performanceSettingsProvider.notifier).load();
      await c.read(performanceSettingsProvider.notifier).setTileQuality(TileQuality.simple);
      expect(c.read(performanceSettingsProvider).tileQuality, TileQuality.simple);
    });

    test('setBlurEffects(false) persiste', () async {
      final c = await _container();
      await c.read(performanceSettingsProvider.notifier).load();
      await c.read(performanceSettingsProvider.notifier).setBlurEffects(false);
      expect(c.read(performanceSettingsProvider).blurEffectsEnabled, false);
    });

    test('setAnimations(false) persiste', () async {
      final c = await _container();
      await c.read(performanceSettingsProvider.notifier).load();
      await c.read(performanceSettingsProvider.notifier).setAnimations(false);
      expect(c.read(performanceSettingsProvider).animationsEnabled, false);
    });

    test('persiste entre reinicializações do container', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Boot 1: ativa performance mode
      final c1 = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      await c1.read(performanceSettingsProvider.notifier).load();
      await c1.read(performanceSettingsProvider.notifier).enable();
      await c1.read(performanceSettingsProvider.notifier).setTileQuality(TileQuality.simple);
      c1.dispose();

      // Boot 2: novo container com mesmas prefs deve carregar estado persistido
      final c2 = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(c2.dispose);
      await c2.read(performanceSettingsProvider.notifier).load();
      expect(c2.read(performanceSettingsProvider).enabled, true);
      expect(c2.read(performanceSettingsProvider).tileQuality, TileQuality.simple);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste para confirmar falha**

```bash
flutter test test/presentation/performance_settings_notifier_test.dart
```

Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar o notifier**

Criar `lib/presentation/controllers/performance_settings_notifier.dart`:

```dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/performance/performance_settings.dart';
import 'settings_notifier.dart'; // sharedPreferencesProvider

class PerformanceSettingsNotifier extends Notifier<PerformanceSettings> {
  static const _key = 'performance_settings';

  @override
  PerformanceSettings build() => const PerformanceSettings();

  Future<void> load() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      state = PerformanceSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> enable() async {
    state = state.copyWith(enabled: true, hasShownSuggestionDialog: true);
    await _save();
  }

  Future<void> disable() async {
    state = state.copyWith(enabled: false);
    await _save();
  }

  Future<void> setTileQuality(TileQuality quality) async {
    state = state.copyWith(tileQuality: quality);
    await _save();
  }

  Future<void> setBlurEffects(bool value) async {
    state = state.copyWith(blurEffectsEnabled: value);
    await _save();
  }

  Future<void> setAnimations(bool value) async {
    state = state.copyWith(animationsEnabled: value);
    await _save();
  }

  Future<void> setAutoDetect(bool value) async {
    state = state.copyWith(autoDetectEnabled: value);
    await _save();
  }
}

final performanceSettingsProvider =
    NotifierProvider<PerformanceSettingsNotifier, PerformanceSettings>(
  PerformanceSettingsNotifier.new,
);
```

- [ ] **Step 4: Rodar os testes**

```bash
flutter test test/presentation/performance_settings_notifier_test.dart
```

Expected: 7 testes PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/controllers/performance_settings_notifier.dart test/presentation/performance_settings_notifier_test.dart
git commit -m "feat(performance): add PerformanceSettingsNotifier with SharedPreferences persistence"
```

---

## Task 5: Substituir reduceEffectsProvider e deletar o arquivo

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/presentation/widgets/pause_overlay.dart`
- Delete: `lib/core/providers/reduce_effects_provider.dart`

- [ ] **Step 1: Atualizar main.dart**

Em `lib/main.dart`:

1. Remover o import:
```dart
// REMOVER:
import 'core/providers/reduce_effects_provider.dart';
```

2. Adicionar o import:
```dart
import 'presentation/controllers/performance_settings_notifier.dart';
```

3. Substituir a linha de load:
```dart
// REMOVER:
await container.read(reduceEffectsProvider.notifier).load();

// ADICIONAR:
await container.read(performanceSettingsProvider.notifier).load();
```

- [ ] **Step 2: Atualizar pause_overlay.dart**

Em `lib/presentation/widgets/pause_overlay.dart`:

1. Substituir import:
```dart
// REMOVER:
import '../../core/providers/reduce_effects_provider.dart';

// ADICIONAR:
import '../controllers/performance_settings_notifier.dart';
```

2. Em `_PauseOverlayState.build`, substituir:
```dart
// REMOVER:
final reduceEffects = ref.watch(reduceEffectsProvider);

// ADICIONAR:
final reduceEffects = ref.watch(
  performanceSettingsProvider.select((s) => !s.blurEffectsEnabled),
);
```

O restante do código (`if (!reduceEffects) { content = BackdropFilter(...) }`) permanece idêntico — a semântica é a mesma: `reduceEffects = true` quando blur está desabilitado.

- [ ] **Step 3: Deletar reduce_effects_provider.dart**

```bash
rm lib/core/providers/reduce_effects_provider.dart
```

- [ ] **Step 4: Verificar que compila**

```bash
flutter analyze
```

Expected: zero erros. Se aparecer algum import residual de `reduce_effects_provider`, corrigi-lo.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/presentation/widgets/pause_overlay.dart
git rm lib/core/providers/reduce_effects_provider.dart
git commit -m "refactor(performance): replace reduceEffectsProvider with performanceSettingsProvider"
```

---

## Task 6: Fix do threshold de swipe

**Files:**
- Modify: `lib/presentation/screens/game/game_screen.dart:210`

- [ ] **Step 1: Alterar o threshold**

Em `lib/presentation/screens/game/game_screen.dart`, linha 210:

```dart
// ANTES:
const threshold = 100.0;

// DEPOIS:
const threshold = 50.0;
```

- [ ] **Step 2: Verificar que compila**

```bash
flutter analyze lib/presentation/screens/game/game_screen.dart
```

Expected: sem erros.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/screens/game/game_screen.dart
git commit -m "fix(game): lower swipe threshold 100→50 px/s to detect slow swipes"
```

---

## Task 7: TileWidget — 3 variantes de qualidade (TDD)

**Files:**
- Modify: `lib/presentation/widgets/tile_widget.dart`
- Create: `test/presentation/tile_widget_quality_test.dart`

- [ ] **Step 1: Escrever o teste**

Criar `test/presentation/tile_widget_quality_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capivara_2048/data/models/tile.dart';
import 'package:capivara_2048/domain/performance/performance_settings.dart';
import 'package:capivara_2048/presentation/controllers/performance_settings_notifier.dart';
import 'package:capivara_2048/presentation/controllers/settings_notifier.dart';
import 'package:capivara_2048/presentation/widgets/tile_widget.dart';

Widget _buildTile(Tile? tile, PerformanceSettings perf) {
  SharedPreferences.setMockInitialValues({});
  return ProviderScope(
    overrides: [
      performanceSettingsProvider.overrideWith(() {
        final n = PerformanceSettingsNotifier();
        return n..state = perf;
      }),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: TileWidget(tile: tile, size: 80),
      ),
    ),
  );
}

void main() {
  group('TileWidget quality variants', () {
    final tile = Tile(id: 'a', level: 4, mergedThisTurn: false);

    testWidgets('TileQuality.full mostra Image com Opacity 0.27', (tester) async {
      await tester.pumpWidget(
        _buildTile(tile, const PerformanceSettings(tileQuality: TileQuality.full)),
      );
      await tester.pump();
      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, closeTo(0.27, 0.01));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('TileQuality.fullOpacity mostra Image sem Opacity wrapper', (tester) async {
      await tester.pumpWidget(
        _buildTile(tile, const PerformanceSettings(tileQuality: TileQuality.fullOpacity)),
      );
      await tester.pump();
      expect(find.byType(Opacity), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('TileQuality.simple não mostra Image', (tester) async {
      await tester.pumpWidget(
        _buildTile(tile, const PerformanceSettings(tileQuality: TileQuality.simple)),
      );
      await tester.pump();
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('TileQuality.simple exibe nome do animal', (tester) async {
      await tester.pumpWidget(
        _buildTile(tile, const PerformanceSettings(tileQuality: TileQuality.simple)),
      );
      await tester.pump();
      // Nível 4 = Tucano
      expect(find.text('Tucano'), findsOneWidget);
    });

    testWidgets('tile null sempre renderiza célula vazia independente do quality', (tester) async {
      await tester.pumpWidget(
        _buildTile(null, const PerformanceSettings(tileQuality: TileQuality.simple)),
      );
      await tester.pump();
      expect(find.byType(Image), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste para confirmar falha**

```bash
flutter test test/presentation/tile_widget_quality_test.dart
```

Expected: FAIL — `TileWidget` ainda é `StatelessWidget` sem suporte a quality.

- [ ] **Step 3: Implementar as variantes**

Substituir o conteúdo de `lib/presentation/widgets/tile_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/animals_data.dart';
import '../../data/models/tile.dart';
import '../../domain/performance/performance_settings.dart';
import '../controllers/performance_settings_notifier.dart';

class TileWidget extends ConsumerWidget {
  final Tile? tile;
  final double size;

  const TileWidget({super.key, required this.tile, required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tile == null) return _EmptyCell(size: size);
    final quality = ref.watch(
      performanceSettingsProvider.select((s) => s.tileQuality),
    );
    return switch (quality) {
      TileQuality.full => _FilledTileFull(tile: tile!, size: size),
      TileQuality.fullOpacity => _FilledTileFullOpacity(tile: tile!, size: size),
      TileQuality.simple => _FilledTileSimple(tile: tile!, size: size),
    };
  }
}

class _EmptyCell extends StatelessWidget {
  final double size;
  const _EmptyCell({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFC9B79C),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _FilledTileFull extends StatelessWidget {
  final Tile tile;
  final double size;
  const _FilledTileFull({required this.tile, required this.size});

  @override
  Widget build(BuildContext context) {
    final animal = animalForLevel(tile.level);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: animal.borderColor, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(size * 0.08),
              child: Opacity(
                opacity: 0.27,
                child: Image.asset(
                  animal.tilePngPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              '${1 << tile.level}',
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
}

class _FilledTileFullOpacity extends StatelessWidget {
  final Tile tile;
  final double size;
  const _FilledTileFullOpacity({required this.tile, required this.size});

  @override
  Widget build(BuildContext context) {
    final animal = animalForLevel(tile.level);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: animal.borderColor, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(size * 0.08),
              child: Image.asset(
                animal.tilePngPath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          Center(
            child: Text(
              '${1 << tile.level}',
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
}

class _FilledTileSimple extends StatelessWidget {
  final Tile tile;
  final double size;
  const _FilledTileSimple({required this.tile, required this.size});

  @override
  Widget build(BuildContext context) {
    final animal = animalForLevel(tile.level);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: animal.backgroundBaseColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: animal.borderColor, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            animal.name,
            style: GoogleFonts.fredoka(
              fontSize: size * 0.18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3E2723),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${1 << tile.level}',
            style: GoogleFonts.fredoka(
              fontSize: size * 0.30,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3E2723),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar os testes**

```bash
flutter test test/presentation/tile_widget_quality_test.dart
```

Expected: 5 testes PASS.

- [ ] **Step 5: Rodar toda a suite para regressão**

```bash
flutter test
```

Expected: todos os testes passando (verificar se golden tests precisam de atualização — se sim, rodar `flutter test --update-goldens`).

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/widgets/tile_widget.dart test/presentation/tile_widget_quality_test.dart
git commit -m "feat(performance): add TileWidget quality variants (full/fullOpacity/simple)"
```

---

## Task 8: PerformanceSuggestionDialog

**Files:**
- Create: `lib/presentation/widgets/performance_suggestion_dialog.dart`

- [ ] **Step 1: Implementar o dialog**

Criar `lib/presentation/widgets/performance_suggestion_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/performance_settings_notifier.dart';

Future<void> showPerformanceSuggestionDialog(
  BuildContext context,
  WidgetRef ref,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PerformanceSuggestionDialog(ref: ref),
  );
}

class _PerformanceSuggestionDialog extends StatelessWidget {
  final WidgetRef ref;
  const _PerformanceSuggestionDialog({required this.ref});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFFF9800), width: 3),
      ),
      title: Text(
        'Modo de Performance 🐢',
        style: GoogleFonts.fredoka(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: const Color(0xFFE65100),
        ),
      ),
      content: Text(
        'Detectamos que seu dispositivo pode estar com dificuldades para rodar o jogo suavemente. Quer ativar o Modo de Performance?',
        style: GoogleFonts.nunito(fontSize: 16),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Agora não',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              color: const Color(0xFFE65100),
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF9800),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          ),
          onPressed: () {
            ref.read(performanceSettingsProvider.notifier).enable();
            Navigator.of(context).pop();
          },
          child: Text(
            'Ativar',
            style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verificar que compila**

```bash
flutter analyze lib/presentation/widgets/performance_suggestion_dialog.dart
```

Expected: sem erros.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/widgets/performance_suggestion_dialog.dart
git commit -m "feat(performance): add PerformanceSuggestionDialog"
```

---

## Task 9: FpsMonitorNotifier + integração no GameScreen

**Files:**
- Create: `lib/presentation/controllers/fps_monitor_notifier.dart`
- Modify: `lib/presentation/screens/game/game_screen.dart`

- [ ] **Step 1: Implementar o notifier**

Criar `lib/presentation/controllers/fps_monitor_notifier.dart`:

```dart
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FpsMonitorNotifier extends Notifier<bool> {
  // state = true: drops detectados, exibir dialog
  static const _windowSize = 30;
  static const _thresholdMicros = 22000; // 22ms = ~45fps

  TimingsCallback? _callback;
  final List<int> _frameMicros = [];

  @override
  bool build() => false;

  void start() {
    if (_callback != null || state) return;
    _callback = _onTimings;
    SchedulerBinding.instance.addTimingsCallback(_callback!);
  }

  void stop() {
    if (_callback == null) return;
    SchedulerBinding.instance.removeTimingsCallback(_callback!);
    _callback = null;
    _frameMicros.clear();
  }

  void _onTimings(List<FrameTiming> timings) {
    if (state) return;
    for (final t in timings) {
      final us = t.buildDuration.inMicroseconds + t.rasterDuration.inMicroseconds;
      _frameMicros.add(us);
      if (_frameMicros.length > _windowSize) _frameMicros.removeAt(0);
    }
    if (_frameMicros.length < _windowSize) return;
    final avg = _frameMicros.reduce((a, b) => a + b) / _windowSize;
    if (avg > _thresholdMicros) {
      stop();
      state = true;
    }
  }
}

final fpsMonitorProvider =
    NotifierProvider<FpsMonitorNotifier, bool>(FpsMonitorNotifier.new);
```

- [ ] **Step 2: Integrar no GameScreen**

Em `lib/presentation/screens/game/game_screen.dart`:

1. Adicionar imports no topo:
```dart
import '../controllers/fps_monitor_notifier.dart';
import '../controllers/performance_settings_notifier.dart';
import '../widgets/performance_suggestion_dialog.dart';
```

2. Em `_GameScreenState`, adicionar `initState` e `dispose`:
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) => _startFpsMonitor());
}

void _startFpsMonitor() {
  final perf = ref.read(performanceSettingsProvider);
  if (perf.autoDetectEnabled && !perf.enabled) {
    ref.read(fpsMonitorProvider.notifier).start();
  }
}

@override
void dispose() {
  ref.read(fpsMonitorProvider.notifier).stop();
  super.dispose();
}
```

3. No método `build` de `_GameScreenState`, logo após os `ref.listen` existentes, adicionar:
```dart
ref.listen<bool>(fpsMonitorProvider, (prev, next) {
  if (next == true && prev == false) {
    final perf = ref.read(performanceSettingsProvider);
    if (!perf.enabled) {
      showPerformanceSuggestionDialog(context, ref);
    }
  }
});
```

- [ ] **Step 3: Verificar que compila**

```bash
flutter analyze lib/presentation/controllers/fps_monitor_notifier.dart lib/presentation/screens/game/game_screen.dart
```

Expected: sem erros.

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/controllers/fps_monitor_notifier.dart lib/presentation/screens/game/game_screen.dart
git commit -m "feat(performance): add FpsMonitorNotifier and integrate into GameScreen"
```

---

## Task 10: DeviceCapabilityDetector — trigger no HomeScreen

**Files:**
- Modify: `lib/presentation/screens/home_screen.dart`

- [ ] **Step 1: Adicionar imports**

Em `lib/presentation/screens/home_screen.dart`, adicionar:
```dart
import '../../domain/performance/device_capability_detector.dart';
import '../controllers/performance_settings_notifier.dart';
import '../widgets/performance_suggestion_dialog.dart';
```

- [ ] **Step 2: Adicionar trigger no initState**

Em `_HomeScreenState.initState`, após a chamada `super.initState()`, adicionar:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) => _checkDevicePerformance());
```

- [ ] **Step 3: Implementar _checkDevicePerformance**

Dentro de `_HomeScreenState`, adicionar o método:
```dart
Future<void> _checkDevicePerformance() async {
  if (!mounted) return;
  final perf = ref.read(performanceSettingsProvider);
  if (perf.hasShownSuggestionDialog || perf.enabled) return;
  final isLowEnd = await DeviceCapabilityDetector.isLowEndDevice();
  if (!mounted || !isLowEnd) return;
  await showPerformanceSuggestionDialog(context, ref);
}
```

- [ ] **Step 4: Verificar que compila**

```bash
flutter analyze lib/presentation/screens/home_screen.dart
```

Expected: sem erros.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/home_screen.dart
git commit -m "feat(performance): trigger device heuristic dialog from HomeScreen"
```

---

## Task 11: Desabilitar animações decorativas

**Files:**
- Modify: `lib/presentation/widgets/capivara_mascot.dart`
- Modify: `lib/presentation/widgets/daily_reward_day_tile.dart`
- Modify: `lib/presentation/screens/daily_rewards/daily_rewards_screen.dart`

- [ ] **Step 1: capivara_mascot.dart — desabilitar bob**

Localizar o widget `CapivaraMascot`. Ele usa `flutter_animate`:
```dart
// Encontrar onde a animação .animate().moveY() é aplicada
// e adicionar leitura do provider
```

Adicionar import:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/performance_settings_notifier.dart';
```

Mudar a classe para `ConsumerWidget` (ou `ConsumerStatelessWidget` se já for stateless). Dentro do `build`, antes da imagem animada:

```dart
final animationsEnabled = ref.watch(
  performanceSettingsProvider.select((s) => s.animationsEnabled),
);
```

Onde a animação é aplicada:
```dart
// ANTES:
Image.asset(...).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(...)

// DEPOIS:
animationsEnabled
  ? Image.asset(...).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(...)
  : Image.asset(...)
```

- [ ] **Step 2: daily_reward_day_tile.dart — desabilitar pulse e sparkles**

Localizar `daily_reward_day_tile.dart`. Adicionar import e leitura do provider (tornar `ConsumerWidget` se necessário):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/performance_settings_notifier.dart';
```

No `build`:
```dart
final animationsEnabled = ref.watch(
  performanceSettingsProvider.select((s) => s.animationsEnabled),
);
```

Para o pulse (`.animate(...).scale(...)`):
```dart
// Substituir o bloco de animação por condicional:
animationsEnabled
  ? Container(...).animate(...).scale(...)
  : Container(...)
```

Para os sparkles (fade/rotate):
```dart
animationsEnabled ? _SparkleWidget(...) : const SizedBox.shrink()
```

- [ ] **Step 3: daily_rewards_screen.dart — desabilitar claim animation**

Localizar a animação do claim (`.animate().scale(...).then().scale(...).fadeOut(...)`). Aplicar o mesmo padrão com `animationsEnabled`.

- [ ] **Step 4: Verificar que compila**

```bash
flutter analyze lib/presentation/widgets/capivara_mascot.dart lib/presentation/widgets/daily_reward_day_tile.dart lib/presentation/screens/daily_rewards/daily_rewards_screen.dart
```

Expected: sem erros.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/capivara_mascot.dart lib/presentation/widgets/daily_reward_day_tile.dart lib/presentation/screens/daily_rewards/daily_rewards_screen.dart
git commit -m "feat(performance): disable decorative animations when animationsEnabled=false"
```

---

## Task 12: Seção Performance na tela de Configurações

**Files:**
- Modify: `lib/presentation/screens/settings_screen.dart`

- [ ] **Step 1: Atualizar imports**

Em `lib/presentation/screens/settings_screen.dart`:

```dart
// REMOVER:
import '../../core/providers/reduce_effects_provider.dart';

// ADICIONAR:
import '../controllers/performance_settings_notifier.dart';
import '../../domain/performance/performance_settings.dart';
```

- [ ] **Step 2: Substituir o toggle de "Reduzir Efeitos Visuais"**

Remover o bloco `Consumer` que contém o toggle `reduceEffectsProvider`.

- [ ] **Step 3: Adicionar seção Performance após a seção Gameplay**

Após o `Card` da seção "Gameplay" e antes do `_SettingsSection('Áudio')`, inserir:

```dart
_SettingsSection('Performance'),
Consumer(
  builder: (context, ref, _) {
    final perf = ref.watch(performanceSettingsProvider);
    final notifier = ref.read(performanceSettingsProvider.notifier);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Colors.white.withValues(alpha: 0.88),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            tileColor: Colors.transparent,
            title: Text('Modo de Performance', style: GoogleFonts.nunito(fontSize: 16)),
            value: perf.enabled,
            onChanged: (v) => v ? notifier.enable() : notifier.disable(),
            activeThumbColor: AppColors.primary,
          ),
          SwitchListTile(
            tileColor: Colors.transparent,
            title: Text('Detecção automática', style: GoogleFonts.nunito(fontSize: 16)),
            subtitle: Text(
              'Sugere ativar quando o jogo tiver lentidão',
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey),
            ),
            value: perf.autoDetectEnabled,
            onChanged: (v) => notifier.setAutoDetect(v),
            activeThumbColor: AppColors.primary,
          ),
          Opacity(
            opacity: perf.enabled ? 1.0 : 0.4,
            child: IgnorePointer(
              ignoring: !perf.enabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Qualidade dos tiles',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SegmentedButton<TileQuality>(
                      segments: const [
                        ButtonSegment(
                          value: TileQuality.full,
                          label: Text('Completo'),
                        ),
                        ButtonSegment(
                          value: TileQuality.fullOpacity,
                          label: Text('Sem opacidade'),
                        ),
                        ButtonSegment(
                          value: TileQuality.simple,
                          label: Text('Simples'),
                        ),
                      ],
                      selected: {perf.tileQuality},
                      onSelectionChanged: (s) => notifier.setTileQuality(s.first),
                      style: ButtonStyle(
                        textStyle: WidgetStateProperty.all(
                          GoogleFonts.nunito(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  SwitchListTile(
                    tileColor: Colors.transparent,
                    title: Text('Efeitos de blur', style: GoogleFonts.nunito(fontSize: 16)),
                    value: perf.blurEffectsEnabled,
                    onChanged: (v) => notifier.setBlurEffects(v),
                    activeThumbColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    tileColor: Colors.transparent,
                    title: Text('Animações', style: GoogleFonts.nunito(fontSize: 16)),
                    value: perf.animationsEnabled,
                    onChanged: (v) => notifier.setAnimations(v),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  },
),
```

- [ ] **Step 4: Verificar que compila**

```bash
flutter analyze lib/presentation/screens/settings_screen.dart
```

Expected: sem erros.

- [ ] **Step 5: Rodar todos os testes**

```bash
flutter test
```

Expected: todos passando.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/screens/settings_screen.dart
git commit -m "feat(performance): add Performance section to SettingsScreen"
```

---

## Self-Review

**Spec coverage:**
- [x] Auto-detecção heurística (Task 3, 10)
- [x] Auto-detecção FPS em runtime (Task 9)
- [x] Dialog estilo CannotUseItem com "Ativar"/"Agora não" (Task 8)
- [x] `PerformanceSettings` modelo + persistência SharedPreferences (Tasks 2, 4)
- [x] `TileQuality.full/fullOpacity/simple` (Task 7)
- [x] Blur toggle substituindo `reduceEffectsProvider` (Task 5)
- [x] Animations toggle (Task 11)
- [x] Seção Performance em Configurações com SegmentedButton (Task 12)
- [x] Fix do threshold de swipe 100→50 (Task 6)
- [x] `reduceEffectsProvider` removido (Task 5)
- [x] `device_info_plus` adicionado ao pubspec (Task 1)

**Placeholder scan:** nenhum TBD ou TODO no plano.

**Type consistency:**
- `performanceSettingsProvider` definido em Task 4, usado em Tasks 5, 7, 9, 10, 11, 12 — consistente.
- `TileQuality` definido em Task 2, usado em Tasks 7, 12 — consistente.
- `showPerformanceSuggestionDialog(context, ref)` definido em Task 8, chamado em Tasks 9 e 10 — consistente.
- `fpsMonitorProvider` definido em Task 9, usado em Task 9 (GameScreen) — consistente.
- `DeviceCapabilityDetector.isLowEndDevice()` definido em Task 3, chamado em Task 10 — consistente.
