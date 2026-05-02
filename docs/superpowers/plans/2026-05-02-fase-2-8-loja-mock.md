# Fase 2.8 — Loja Mock: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar ShopScreen com 6 pacotes compráveis localmente, bottom sheet de código presente, e persistência de ShareCode em SharedPreferences.

**Architecture:** Modelos imutáveis (`ShopPackage`, `RewardBundle`, `ShareCode`) definidos em `data/models/`, lista estática em `shop_data.dart`, persistência via `ShareCodesRepository` + `ShareCodesNotifier`, e toda lógica de UI (confirmação, entrega de itens, geração de código) como método `_onBuy` diretamente no `ConsumerWidget`.

**Tech Stack:** Flutter 3.x, Riverpod `StateNotifierProvider`, `SharedPreferences`, `uuid: ^4.5.1`, `google_fonts`, `flutter_test`

---

## File Map

| Ação | Arquivo | Responsabilidade |
|------|---------|-----------------|
| Criar | `lib/data/models/shop_package.dart` | `RewardBundle` + `ShopPackage` imutáveis |
| Criar | `lib/data/models/share_code.dart` | `ShareCode` + `ShareCodeStatus` + JSON |
| Criar | `lib/data/shop_data.dart` | Lista estática `kShopPackages` + `shopPackagesProvider` |
| Criar | `lib/data/repositories/share_codes_repository.dart` | SharedPreferences CRUD para `List<ShareCode>` |
| Criar | `lib/domain/shop/share_codes_notifier.dart` | `ShareCodesNotifier` + providers |
| Reescrever | `lib/presentation/screens/shop_screen.dart` | `ShopScreen`, `_ShopPackageCard`, `_GiftCodeSheet`, `_onBuy` |
| Criar | `test/domain/shop/share_codes_notifier_test.dart` | Testes unitários do notifier e modelos |
| Criar | `test/presentation/shop_screen_test.dart` | Widget tests da tela |

---

## Task 1: `RewardBundle` e `ShopPackage`

**Files:**
- Create: `lib/data/models/shop_package.dart`

- [ ] **Step 1: Criar o arquivo**

```dart
// lib/data/models/shop_package.dart

class RewardBundle {
  final int lives;
  final int bomb2;
  final int bomb3;
  final int undo1;
  final int undo3;

  const RewardBundle({
    required this.lives,
    required this.bomb2,
    required this.bomb3,
    required this.undo1,
    required this.undo3,
  });

  static const empty = RewardBundle(
    lives: 0, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0,
  );
}

class ShopPackage {
  final String id;
  final String name;
  final String description;
  final double originalPrice;
  final double currentPrice;
  final int discountPercent;
  final RewardBundle contents;
  final RewardBundle giftContents;

  const ShopPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.originalPrice,
    required this.currentPrice,
    required this.discountPercent,
    required this.contents,
    required this.giftContents,
  });
}
```

- [ ] **Step 2: Verificar que compila**

```bash
flutter analyze lib/data/models/shop_package.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/data/models/shop_package.dart
git commit -m "feat(shop): add RewardBundle and ShopPackage models"
```

---

## Task 2: `ShareCode` com JSON

**Files:**
- Create: `lib/data/models/share_code.dart`

- [ ] **Step 1: Escrever teste para toJson/fromJson**

Criar `test/domain/shop/share_codes_notifier_test.dart` (arquivo parcial, vamos adicionar mais testes nele depois):

```dart
// test/domain/shop/share_codes_notifier_test.dart

import 'package:capivara_2048/data/models/share_code.dart';
import 'package:capivara_2048/data/models/shop_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShareCode JSON', () {
    test('toJson / fromJson são inversos', () {
      final original = ShareCode(
        code: 'abc-123',
        packageId: 'p1',
        giftContents: const RewardBundle(
          lives: 0, bomb2: 0, bomb3: 2, undo1: 0, undo3: 0,
        ),
        status: ShareCodeStatus.pending,
        createdAt: DateTime(2026, 5, 2, 12, 0),
      );

      final roundTripped = ShareCode.fromJson(original.toJson());

      expect(roundTripped.code, original.code);
      expect(roundTripped.packageId, original.packageId);
      expect(roundTripped.giftContents.bomb3, original.giftContents.bomb3);
      expect(roundTripped.status, original.status);
      expect(roundTripped.createdAt, original.createdAt);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste para ver falhar**

```bash
flutter test test/domain/shop/share_codes_notifier_test.dart
```
Expected: FAIL com `Target of URI doesn't exist`

- [ ] **Step 3: Criar `share_code.dart`**

```dart
// lib/data/models/share_code.dart

import 'shop_package.dart';

enum ShareCodeStatus { pending, redeemed, expired }

class ShareCode {
  final String code;
  final String packageId;
  final RewardBundle giftContents;
  final ShareCodeStatus status;
  final DateTime createdAt;

  const ShareCode({
    required this.code,
    required this.packageId,
    required this.giftContents,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'packageId': packageId,
        'giftContents': {
          'lives': giftContents.lives,
          'bomb2': giftContents.bomb2,
          'bomb3': giftContents.bomb3,
          'undo1': giftContents.undo1,
          'undo3': giftContents.undo3,
        },
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ShareCode.fromJson(Map<String, dynamic> json) {
    final g = json['giftContents'] as Map<String, dynamic>;
    return ShareCode(
      code: json['code'] as String,
      packageId: json['packageId'] as String,
      giftContents: RewardBundle(
        lives: g['lives'] as int,
        bomb2: g['bomb2'] as int,
        bomb3: g['bomb3'] as int,
        undo1: g['undo1'] as int,
        undo3: g['undo3'] as int,
      ),
      status: ShareCodeStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
```

- [ ] **Step 4: Rodar o teste para ver passar**

```bash
flutter test test/domain/shop/share_codes_notifier_test.dart
```
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/share_code.dart test/domain/shop/share_codes_notifier_test.dart
git commit -m "feat(shop): add ShareCode model with JSON serialization"
```

---

## Task 3: `shop_data.dart` com os 6 pacotes

**Files:**
- Create: `lib/data/shop_data.dart`

- [ ] **Step 1: Criar a lista estática e o provider**

```dart
// lib/data/shop_data.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/shop_package.dart';

final shopPackagesProvider = Provider<List<ShopPackage>>((_) => kShopPackages);

const List<ShopPackage> kShopPackages = [
  ShopPackage(
    id: 'p1',
    name: '4× Bomba 3',
    description: '4 bombas que explodem 3 casas',
    originalPrice: 7.99,
    currentPrice: 3.99,
    discountPercent: 50,
    contents: RewardBundle(lives: 0, bomb2: 0, bomb3: 4, undo1: 0, undo3: 0),
    giftContents: RewardBundle(lives: 0, bomb2: 0, bomb3: 2, undo1: 0, undo3: 0),
  ),
  ShopPackage(
    id: 'p2',
    name: '4× Desfazer 3',
    description: '4 desfazeres de 3 jogadas',
    originalPrice: 3.99,
    currentPrice: 1.99,
    discountPercent: 50,
    contents: RewardBundle(lives: 0, bomb2: 0, bomb3: 0, undo1: 0, undo3: 4),
    giftContents: RewardBundle(lives: 0, bomb2: 0, bomb3: 0, undo1: 0, undo3: 2),
  ),
  ShopPackage(
    id: 'p3',
    name: '6 Vidas',
    description: 'Direto no inventário',
    originalPrice: 9.99,
    currentPrice: 2.49,
    discountPercent: 75,
    contents: RewardBundle(lives: 6, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0),
    giftContents: RewardBundle(lives: 3, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0),
  ),
  ShopPackage(
    id: 'p4',
    name: '10 Vidas',
    description: 'Direto no inventário',
    originalPrice: 19.99,
    currentPrice: 4.99,
    discountPercent: 75,
    contents: RewardBundle(lives: 10, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0),
    giftContents: RewardBundle(lives: 5, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0),
  ),
  ShopPackage(
    id: 'p5',
    name: 'Combo Mata Atlântica',
    description: '6 vidas + 2 Bomba 2 + 2 Desfazer 3',
    originalPrice: 10.99,
    currentPrice: 4.99,
    discountPercent: 50,
    contents: RewardBundle(lives: 6, bomb2: 2, bomb3: 0, undo1: 0, undo3: 2),
    giftContents: RewardBundle(lives: 3, bomb2: 1, bomb3: 0, undo1: 0, undo3: 1),
  ),
  ShopPackage(
    id: 'p6',
    name: 'Combo Floresta Amazônica',
    description: '10 vidas + 4 Bomba 3 + 4 Desfazer 3',
    originalPrice: 31.99,
    currentPrice: 9.99,
    discountPercent: 50,
    contents: RewardBundle(lives: 10, bomb2: 0, bomb3: 4, undo1: 0, undo3: 4),
    giftContents: RewardBundle(lives: 5, bomb2: 0, bomb3: 2, undo1: 0, undo3: 2),
  ),
];
```

- [ ] **Step 2: Verificar que compila**

```bash
flutter analyze lib/data/shop_data.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/data/shop_data.dart
git commit -m "feat(shop): add static shop packages data"
```

---

## Task 4: `ShareCodesRepository`

**Files:**
- Create: `lib/data/repositories/share_codes_repository.dart`

- [ ] **Step 1: Criar o repositório**

```dart
// lib/data/repositories/share_codes_repository.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/share_code.dart';

class ShareCodesRepository {
  static const _key = 'generated_share_codes';

  Future<List<ShareCode>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => ShareCode.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<ShareCode> codes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      codes.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }
}
```

- [ ] **Step 2: Verificar que compila**

```bash
flutter analyze lib/data/repositories/share_codes_repository.dart
```
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/data/repositories/share_codes_repository.dart
git commit -m "feat(shop): add ShareCodesRepository with SharedPreferences persistence"
```

---

## Task 5: `ShareCodesNotifier` + testes

**Files:**
- Create: `lib/domain/shop/share_codes_notifier.dart`
- Modify: `test/domain/shop/share_codes_notifier_test.dart`

- [ ] **Step 1: Adicionar testes do notifier ao arquivo existente**

Abrir `test/domain/shop/share_codes_notifier_test.dart` e adicionar um novo grupo ao final do `main()`:

```dart
// Adicionar imports no topo:
import 'package:capivara_2048/data/repositories/share_codes_repository.dart';
import 'package:capivara_2048/domain/shop/share_codes_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Adicionar grupo no main():
  group('ShareCodesNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('add() appenda código e persiste na lista', () async {
      final container = ProviderContainer(overrides: [
        shareCodesRepositoryProvider
            .overrideWithValue(ShareCodesRepository()),
      ]);
      addTearDown(container.dispose);

      final code = ShareCode(
        code: 'test-code-0001',
        packageId: 'p1',
        giftContents: const RewardBundle(
          lives: 0, bomb2: 0, bomb3: 2, undo1: 0, undo3: 0,
        ),
        status: ShareCodeStatus.pending,
        createdAt: DateTime(2026, 5, 2),
      );

      await container.read(shareCodesProvider.notifier).add(code);
      expect(container.read(shareCodesProvider).length, 1);
      expect(container.read(shareCodesProvider).first.code, 'test-code-0001');
    });

    test('load() restaura lista após reinício simulado', () async {
      final repo = ShareCodesRepository();
      final code = ShareCode(
        code: 'persist-test',
        packageId: 'p2',
        giftContents: const RewardBundle(
          lives: 0, bomb2: 0, bomb3: 0, undo1: 0, undo3: 2,
        ),
        status: ShareCodeStatus.pending,
        createdAt: DateTime(2026, 5, 2),
      );
      await repo.save([code]);

      final container = ProviderContainer(overrides: [
        shareCodesRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);

      await container.read(shareCodesProvider.notifier).load();
      expect(container.read(shareCodesProvider).length, 1);
      expect(container.read(shareCodesProvider).first.code, 'persist-test');
    });
  });
```

- [ ] **Step 2: Rodar para ver falhar**

```bash
flutter test test/domain/shop/share_codes_notifier_test.dart
```
Expected: FAIL com `Target of URI doesn't exist` no import do notifier.

- [ ] **Step 3: Criar o notifier**

```dart
// lib/domain/shop/share_codes_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/share_code.dart';
import '../../data/repositories/share_codes_repository.dart';

class ShareCodesNotifier extends StateNotifier<List<ShareCode>> {
  ShareCodesNotifier(this._repo) : super([]);

  final ShareCodesRepository _repo;

  Future<void> load() async {
    state = await _repo.load();
  }

  Future<void> add(ShareCode code) async {
    state = [...state, code];
    await _repo.save(state);
  }
}

final shareCodesRepositoryProvider = Provider<ShareCodesRepository>(
  (_) => ShareCodesRepository(),
);

final shareCodesProvider =
    StateNotifierProvider<ShareCodesNotifier, List<ShareCode>>(
  (ref) => ShareCodesNotifier(ref.read(shareCodesRepositoryProvider)),
);
```

- [ ] **Step 4: Rodar todos os testes do arquivo**

```bash
flutter test test/domain/shop/share_codes_notifier_test.dart
```
Expected: `All tests passed!` (3 testes: JSON roundtrip + add + load)

- [ ] **Step 5: Commit**

```bash
git add lib/domain/shop/share_codes_notifier.dart test/domain/shop/share_codes_notifier_test.dart
git commit -m "feat(shop): add ShareCodesNotifier with persistence"
```

---

## Task 6: `ShopScreen` — estrutura e cards

**Files:**
- Modify: `lib/presentation/screens/shop_screen.dart`

- [ ] **Step 1: Escrever os widget tests de estrutura**

Criar `test/presentation/shop_screen_test.dart`:

```dart
// test/presentation/shop_screen_test.dart

import 'package:capivara_2048/data/models/inventory.dart';
import 'package:capivara_2048/data/models/inventory_hive_adapter.dart';
import 'package:capivara_2048/data/models/lives_state.dart';
import 'package:capivara_2048/data/models/lives_state_adapter.dart';
import 'package:capivara_2048/data/repositories/inventory_repository.dart';
import 'package:capivara_2048/data/repositories/lives_repository.dart';
import 'package:capivara_2048/data/repositories/share_codes_repository.dart';
import 'package:capivara_2048/domain/inventory/inventory_notifier.dart';
import 'package:capivara_2048/domain/lives/lives_notifier.dart';
import 'package:capivara_2048/domain/shop/share_codes_notifier.dart';
import 'package:capivara_2048/presentation/screens/shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

late Directory _tempDir;

Future<void> _initHive() async {
  _tempDir = await Directory.systemTemp.createTemp('shop_test');
  Hive.init(_tempDir.path);
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(LivesStateAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InventoryHiveAdapter());
}

Future<void> _teardownHive() async {
  await Hive.close();
  await _tempDir.delete(recursive: true);
}

Widget _buildShop() {
  return ProviderScope(
    overrides: [
      inventoryRepositoryProvider.overrideWithValue(InventoryRepository()),
      livesRepositoryProvider.overrideWithValue(LivesRepository()),
      shareCodesRepositoryProvider.overrideWithValue(ShareCodesRepository()),
    ],
    child: const MaterialApp(home: ShopScreen()),
  );
}
```dart
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _initHive();
  });

  tearDown(_teardownHive);

  testWidgets('6 cards de pacotes presentes no widget tree', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();

    expect(find.text('4× Bomba 3'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Combo Floresta Amazônica'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.text('Combo Floresta Amazônica'), findsOneWidget);
  });

  testWidgets('badges 75% presentes (p3 e p4)', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();
    expect(find.text('75%'), findsWidgets);
  });

  testWidgets('badges 50% presentes (p1, p2, p5, p6)', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();
    expect(find.text('50%'), findsWidgets);
  });

  testWidgets('tap Comprar → AlertDialog de confirmação aparece', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Comprar').first);
    await tester.pumpAndSettle();

    expect(find.text('Confirmar compra'), findsOneWidget);
  });

  testWidgets('cancelar AlertDialog → sem sheet aberto', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Comprar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Presente gerado!'), findsNothing);
  });

  testWidgets('confirmar compra p1 → GiftCodeSheet aparece (compra processada)', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Comprar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(find.text('Presente gerado!'), findsOneWidget);
  });

  testWidgets('_GiftCodeSheet → código em formato xxxx-xxxx-xxxx', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Comprar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();

    final codePattern = RegExp(r'^[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}$');
    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    final codeText = textWidgets
        .map((t) => t.data ?? '')
        .where((s) => codePattern.hasMatch(s))
        .firstOrNull;
    expect(codeText, isNotNull);
  });

  testWidgets('botão Copiar → snackbar "Copiado!" aparece', (tester) async {
    await tester.pumpWidget(_buildShop());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Comprar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.copy_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Copiado!'), findsOneWidget);
  });
}
```

flutter test test/presentation/shop_screen_test.dart
```
Expected: FAIL (ShopScreen ainda é o stub "Em breve")

- [ ] **Step 3: Reescrever `shop_screen.dart`**

```dart
// lib/presentation/screens/shop_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/item_type.dart';
import '../../data/models/share_code.dart';
import '../../data/shop_data.dart';
import '../../data/models/shop_package.dart';
import '../../domain/inventory/inventory_notifier.dart';
import '../../domain/lives/lives_notifier.dart';
import '../../domain/shop/share_codes_notifier.dart';
import '../widgets/game_background.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packages = ref.watch(shopPackagesProvider);

    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Loja',
            style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: packages.length,
          itemBuilder: (context, index) {
            final pkg = packages[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShopPackageCard(
                package: pkg,
                onBuy: () => _onBuy(context, ref, pkg),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onBuy(
    BuildContext context,
    WidgetRef ref,
    ShopPackage package,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar compra'),
        content: Text(
          'Comprar ${package.name} por R\$ ${package.currentPrice.toStringAsFixed(2).replaceAll('.', ',')}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final c = package.contents;
    if (c.lives > 0) {
      await ref.read(livesProvider.notifier).addPurchased(c.lives);
    }
    if (c.bomb2 > 0) {
      await ref.read(inventoryProvider.notifier).add(ItemType.bomb2, c.bomb2);
    }
    if (c.bomb3 > 0) {
      await ref.read(inventoryProvider.notifier).add(ItemType.bomb3, c.bomb3);
    }
    if (c.undo1 > 0) {
      await ref.read(inventoryProvider.notifier).add(ItemType.undo1, c.undo1);
    }
    if (c.undo3 > 0) {
      await ref.read(inventoryProvider.notifier).add(ItemType.undo3, c.undo3);
    }

    final rawCode = const Uuid().v4().replaceAll('-', '');
    final truncated =
        '${rawCode.substring(0, 4)}-${rawCode.substring(4, 8)}-${rawCode.substring(8, 12)}';

    final shareCode = ShareCode(
      code: truncated,
      packageId: package.id,
      giftContents: package.giftContents,
      status: ShareCodeStatus.pending,
      createdAt: DateTime.now(),
    );

    await ref.read(shareCodesProvider.notifier).add(shareCode);

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _GiftCodeSheet(code: shareCode),
      );
    }
  }
}

class _ShopPackageCard extends StatelessWidget {
  const _ShopPackageCard({
    required this.package,
    required this.onBuy,
  });

  final ShopPackage package;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black26,
      color: Colors.white.withOpacity(0.92),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    package.name,
                    style: GoogleFonts.fredoka(fontSize: 18),
                  ),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFFF8C42),
                  child: Text(
                    '${package.discountPercent}%',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              package.description,
              style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'De R\$ ${package.originalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: const Color(0xFF9E9E9E),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Por R\$ ${package.currentPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: GoogleFonts.fredoka(
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Comprar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftCodeSheet extends StatelessWidget {
  const _GiftCodeSheet({required this.code});

  final ShareCode code;

  String _describeBundle(RewardBundle b) {
    final parts = <String>[];
    if (b.lives > 0) parts.add('${b.lives} vida${b.lives > 1 ? 's' : ''}');
    if (b.bomb2 > 0) parts.add('${b.bomb2} Bomba 2');
    if (b.bomb3 > 0) parts.add('${b.bomb3} Bomba 3');
    if (b.undo1 > 0) parts.add('${b.undo1} Desfazer 1');
    if (b.undo3 > 0) parts.add('${b.undo3} Desfazer 3');
    return parts.join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Presente gerado!',
                style: GoogleFonts.fredoka(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Compartilhe este código com um amigo:',
                style: GoogleFonts.nunito(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Text(
                  code.code,
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copiado!')),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Seu amigo recebe: ${_describeBundle(code.giftContents)}',
                style: GoogleFonts.nunito(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Fechar'),
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

- [ ] **Step 4: Rodar os widget tests**

```bash
flutter test test/presentation/shop_screen_test.dart
```
Expected: `All tests passed!`

- [ ] **Step 5: Rodar todos os testes do projeto**

```bash
flutter test
```
Expected: todos passam, sem regressões.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/screens/shop_screen.dart test/presentation/shop_screen_test.dart
git commit -m "feat(shop): implement ShopScreen with 6 packages, purchase flow, and GiftCodeSheet"
```

---

## Task 7: Documentação e marcação de fase

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `README.md`
- Modify: `CLAUDE.md`
- Modify: `CAPIVARA_2048_DESIGN.md`

- [ ] **Step 1: Atualizar `CHANGELOG.md`**

Adicionar no topo (antes da entrada mais recente):

```markdown
## [0.9.4] — 2026-05-02

### Added
- ShopScreen com 6 pacotes compráveis (Fase 2.8)
- Compra simulada entrega itens localmente sem IAP real
- Bottom sheet "Código para presentear" com UUID truncado e botão copiar
- ShareCode persistido em SharedPreferences (migração Firestore na Fase 3)
```

- [ ] **Step 2: Atualizar `README.md`**

Localizar a tabela de fases/roadmap e marcar Fase 2.8 como ✅.

- [ ] **Step 3: Atualizar `CLAUDE.md`**

Localizar a linha `Fase atual:` e atualizar para:
```
Fase atual: **Fase 2.8 concluída (v0.9.4) — próximo: Fase 3**
```

- [ ] **Step 4: Marcar Fase 2.8 no design spec**

Em `CAPIVARA_2048_DESIGN.md` §15, localizar `🔜 Fase 2.8` e substituir `🔜` por `✅`.

- [ ] **Step 5: Commit**

```bash
git add CHANGELOG.md README.md CLAUDE.md CAPIVARA_2048_DESIGN.md
git commit -m "docs: Fase 2.8 concluída — marcar ✅ e atualizar changelogs"
```

---

## Task 8: Validação manual

- [ ] **Step 1: Rodar no emulador 360×640**

```bash
flutter run
```

Verificar:
- 6 cards visíveis com scroll sem overflow horizontal
- Badge 50% em p1, p2, p5, p6
- Badge 75% em p3, p4
- Preço "De" riscado, "Por" em verde

- [ ] **Step 2: Testar fluxo de compra**

- Tap "Comprar" em p1 → AlertDialog aparece
- Tap "Cancelar" → dialog fecha, nada muda
- Tap "Comprar" novamente → "Confirmar" → sheet abre com código `xxxx-xxxx-xxxx`
- Tap ícone copiar → snackbar "Copiado!" aparece
- Tap "Fechar" → volta à lista sem erro

- [ ] **Step 3: Verificar persistência**

- Comprar um pacote
- Hot restart (`R` no terminal)
- Vidas/inventário devem manter os valores

- [ ] **Step 4: Bump de versão**

Em `pubspec.yaml`, atualizar `version:` para `0.9.4+27` (ou próximo build number disponível).

```bash
git add pubspec.yaml
git commit -m "chore: bump v0.9.4"
```
