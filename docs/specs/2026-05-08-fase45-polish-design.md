# Design — Fase 4.5: Polimento de Jogo e IAP Completo

**Data:** 2026-05-08
**Status:** Aprovado — aguardando implementação
**Fase:** 4.5

---

## 1. Escopo

| #   | Feature                                                      | Área            |
| --- | ------------------------------------------------------------ | --------------- |
| 1   | Bomba 3 requer ≥ 5 peças no tabuleiro + aviso visual         | Game rules / UI |
| 2   | Shop overlay com IAP real (mesmo fluxo da loja principal)    | IAP / Shop      |
| 3   | Loja principal — itens avulsos com IAP real em `dev`         | IAP / Shop      |
| 4   | Texto "Ok" após assistir anúncio e dobrar recompensa         | UI (1 linha)    |
| 5   | Haptic feedback graduado em level-up, milestones e game over | Feedback tátil  |

---

## 2. Feature 4 — Texto "Ok" pós-recompensa dobrada

**Arquivo:** `lib/presentation/widgets/daily_reward_overlay.dart`

### Mudança

O `TextButton` de dismiss usa texto condicional:

```dart
Text(
  _doubled ? 'Ok' : 'Não, obrigado',
  style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 15),
)
```

- Antes de assistir: `'Não, obrigado'` — semântica de recusa
- Após dobrar (`_doubled == true`): `'Ok'` — confirmação de fechamento

**Sem outras mudanças.** `onPressed` continua `widget.onDismiss`.

---

## 3. Feature 1 — Bomba 3 requer ≥ 5 peças

### Regra

A Bomba 3 remove 3 peças escolhidas pelo jogador. Se o tabuleiro tiver menos de 5 peças, sobrariam menos de 2 peças após o uso — estado inviável. Portanto, a Bomba 3 só pode ser usada com **no mínimo 5 peças** no tabuleiro.

### Implementação

**Arquivo:** `lib/presentation/widgets/inventory_bar.dart`

Calcular contagem de peças a partir do `GameState` lido via `ref.watch(gameProvider)`:

```dart
final tileCount = ref.watch(
  gameProvider.select((s) =>
    s.board.expand((row) => row).whereType<Tile>().length),
);
```

Botão Bomba 3 recebe `forceDisabled` e `onTapWhenDisabled` espelhando o padrão do Desfazer 3:

```dart
InventoryItemButton(
  key: const Key('inventory_bomb3'),
  label: 'Bomba 3',
  pngPath: 'assets/images/inventory/bomb_3.png',
  count: inventory.bomb3,
  size: iconSize,
  onPressed: inventory.bomb3 > 0 && tileCount >= 5 ? useBomb3 : null,
  forceDisabled: inventory.bomb3 > 0 && tileCount < 5,
  onTapWhenDisabled: () => showCannotUseItemDialog(
    context: context,
    message: 'São necessárias pelo menos 5 peças no tabuleiro para usar a Bomba 3.',
    pngPath: 'assets/images/inventory/bomb_3.png',
  ),
  onTapWhenEmpty: inventory.bomb3 == 0 && onTapWhenEmpty != null
      ? () => onTapWhenEmpty!(ItemType.bomb3)
      : null,
  shouldPulse: pulsingItems.contains(ItemType.bomb3),
)
```

### Visual do aviso

Usa `showCannotUseItemDialog` existente em `lib/presentation/widgets/cannot_use_item_dialog.dart`:

- Ícone de bomba (`bomb_3.png`) em grayscale na esquerda do título
- Título "Ops! 🙈" (Fredoka bold laranja)
- Mensagem com o texto acima (Nunito 16)
- Borda laranja, botão "Entendi!" — **idêntico** ao aviso do Desfazer 3

**Nenhuma mudança** no `GameEngine` nem no `GameNotifier`.

---

## 4. Feature 5 — Haptic feedback graduado

### 4.1 Extensão de `haptic_utils.dart`

**Arquivo:** `lib/core/utils/haptic_utils.dart`

```dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/controllers/settings_notifier.dart';

enum HapticIntensity { light, medium, heavy }

/// Dispara haptic respeitando o toggle de vibração nas Configurações.
/// Compatível com WidgetRef e Ref (GameNotifier usa Ref).
void maybeHaptic(Ref ref, {HapticIntensity intensity = HapticIntensity.light}) {
  if (!ref.read(settingsProvider).hapticEnabled) return;
  switch (intensity) {
    case HapticIntensity.light:  HapticFeedback.lightImpact();
    case HapticIntensity.medium: HapticFeedback.mediumImpact();
    case HapticIntensity.heavy:  HapticFeedback.heavyImpact();
  }
}
```

> `WidgetRef extends Ref` no Riverpod — call sites existentes que passam `WidgetRef` continuam funcionando sem alteração.

### 4.2 Triggers em `GameNotifier`

**Arquivo:** `lib/presentation/controllers/game_notifier.dart`

No método `move()`, após calcular `after` e antes de `state = after`:

| Evento                              | Condição                                                           | Intensidade |
| ----------------------------------- | ------------------------------------------------------------------ | ----------- |
| Troca de anfitrião (level-up)       | `after.maxLevel > state.maxLevel`                                  | `light`     |
| Milestone atingido (2048/4096/8192) | `after.pendingMilestone != null && state.pendingMilestone == null` | `medium`    |
| Game over                           | `after.isGameOver && !state.isGameOver`                            | `heavy`     |

```dart
// Em move(), antes de state = after:
if (after.maxLevel > state.maxLevel) {
  maybeHaptic(ref, intensity: HapticIntensity.light);
}
if (after.pendingMilestone != null && state.pendingMilestone == null) {
  maybeHaptic(ref, intensity: HapticIntensity.medium);
}
if (after.isGameOver && !state.isGameOver) {
  maybeHaptic(ref, intensity: HapticIntensity.heavy);
}
```

### 4.3 Respeita configuração do usuário

Se `settingsProvider.hapticEnabled == false`, `maybeHaptic` retorna imediatamente — nenhum feedback disparado. O toggle já existe na tela de Configurações.

**Nenhum pacote novo** — usa `HapticFeedback` do `flutter/services.dart` já presente.

---

## 5. Features 2+3 — IAP real na loja e no overlay

### 5.1 Novos produtos unitários em `shop_data.dart`

**Arquivo:** `lib/data/shop_data.dart`

4 novos `ShopPackage` com IDs `u_bomb3`, `u_undo3`, `u_bomb2`, `u_undo1`. Preços espelham `kItemUnitPrices`:

```dart
const List<ShopPackage> kShopUnitPackages = [
  ShopPackage(
    id: 'u_bomb3',
    name: '1× Bomba 3',
    description: '1 bomba que remove 3 peças à sua escolha',
    originalPrice: 1.99,
    currentPrice: 1.99,
    discountPercent: 0,
    contents: RewardBundle(lives: 0, bomb2: 0, bomb3: 1, undo1: 0, undo3: 0),
    giftContents: RewardBundle(lives: 0, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0),
  ),
  ShopPackage(
    id: 'u_undo3',
    name: '1× Desfazer 3',
    description: '1 desfazer de 3 jogadas',
    originalPrice: 0.99,
    currentPrice: 0.99,
    discountPercent: 0,
    contents: RewardBundle(lives: 0, bomb2: 0, bomb3: 0, undo1: 0, undo3: 1),
    giftContents: RewardBundle(lives: 0, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0),
  ),
  ShopPackage(
    id: 'u_bomb2',
    name: '1× Bomba 2',
    description: '1 bomba que remove 2 peças adjacentes',
    originalPrice: 1.19,
    currentPrice: 1.19,
    discountPercent: 0,
    contents: RewardBundle(lives: 0, bomb2: 1, bomb3: 0, undo1: 0, undo3: 0),
    giftContents: RewardBundle(lives: 0, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0),
  ),
  ShopPackage(
    id: 'u_undo1',
    name: '1× Desfazer 1',
    description: '1 desfazer de 1 jogada',
    originalPrice: 0.49,
    currentPrice: 0.49,
    discountPercent: 0,
    contents: RewardBundle(lives: 0, bomb2: 0, bomb3: 0, undo1: 1, undo3: 0),
    giftContents: RewardBundle(lives: 0, bomb2: 0, bomb3: 0, undo1: 0, undo3: 0),
  ),
];

/// Mapa de conveniência: ItemType → ShopPackage unitário.
final Map<ItemType, ShopPackage> kUnitPackageByType = {
  ItemType.bomb3: kShopUnitPackages[0],
  ItemType.undo3: kShopUnitPackages[1],
  ItemType.bomb2: kShopUnitPackages[2],
  ItemType.undo1: kShopUnitPackages[3],
};
```

### 5.2 Helper compartilhado `deliverIAPItems`

**Arquivo novo:** `lib/core/utils/iap_delivery.dart`

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/item_type.dart';
import '../../data/models/shop_package.dart';
import '../../domain/inventory/inventory_notifier.dart';
import '../../domain/lives/lives_notifier.dart';

/// Entrega local os itens de um ShopPackage após IAP bem-sucedido.
/// Usado por ShopScreen, ShopUnitItemCard e ShopOverlay.
void deliverIAPItems(WidgetRef ref, ShopPackage package) {
  final c = package.contents;
  if (c.lives > 0)  unawaited(ref.read(livesProvider.notifier).addPurchased(c.lives));
  if (c.bomb2 > 0)  unawaited(ref.read(inventoryProvider.notifier).add(ItemType.bomb2, c.bomb2));
  if (c.bomb3 > 0)  unawaited(ref.read(inventoryProvider.notifier).add(ItemType.bomb3, c.bomb3));
  if (c.undo1 > 0)  unawaited(ref.read(inventoryProvider.notifier).add(ItemType.undo1, c.undo1));
  if (c.undo3 > 0)  unawaited(ref.read(inventoryProvider.notifier).add(ItemType.undo3, c.undo3));
}
```

`ShopScreen._deliverItemsLocally` é **removido** e substituído por `deliverIAPItems`.

### 5.3 `ShopUnitItemCard` — Feature 3

**Arquivo:** `lib/presentation/widgets/shop_unit_item_card.dart`

O método `_buy` passa a usar o fluxo IAP completo:

```dart
Future<void> _buy(BuildContext context, WidgetRef ref) async {
  final package = kUnitPackageByType[item]!;

  // 1. Confirmation sheet (mesma da loja principal)
  final confirmed = await IAPConfirmationSheet.show(context, package);
  if (!confirmed || !context.mounted) return;

  // 2. IAP real (IAPServiceImpl em dev/prd; FakeIAPService em tst)
  final iapService = ref.read(iapServiceProvider);
  final result = await iapService.buyPackage(package);
  if (!context.mounted) return;

  if (result.success) {
    deliverIAPItems(ref, package);
    if (result.shareCode != null && context.mounted) {
      await PurchaseSuccessSheet.show(context, result.shareCode!);
    }
  } else if (result.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro na compra: ${result.error}')),
    );
  }
  // cancelled → do nothing
}
```

### 5.4 `ShopOverlay` — Feature 2

**Arquivo:** `lib/presentation/widgets/shop_overlay.dart`

O método `_onBuy` substitui a entrega direta pelo fluxo IAP:

```dart
Future<void> _onBuy(ShopPackage package) async {
  // 1. Confirmation sheet
  final confirmed = await IAPConfirmationSheet.show(context, package);
  if (!confirmed || !mounted) return;

  // 2. IAP real
  final iapService = ref.read(iapServiceProvider);
  final result = await iapService.buyPackage(package);
  if (!mounted) return;

  if (result.success) {
    deliverIAPItems(ref, package);
    if (result.shareCode != null && mounted) {
      await PurchaseSuccessSheet.show(context, result.shareCode!);
    }
    widget.onItemPurchased(widget.itemType);
  } else if (result.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro na compra: ${result.error}')),
    );
  }
}
```

### 5.5 Flavor rules (resultado final)

| Flavor                      | `IAPService`     | Comportamento                           |
| --------------------------- | ---------------- | --------------------------------------- |
| `prd`                       | `IAPServiceImpl` | IAP real (Google Play / App Store)      |
| `dev`                       | `IAPServiceImpl` | IAP real (sandbox Google Play)          |
| `tst`                       | `FakeIAPService` | Fake — sucesso instantâneo, sem network |
| `tst` + `USE_REAL_IAP=true` | `IAPServiceImpl` | Real (smoke em CI)                      |

`iapServiceProvider` já implementa essa lógica — **nenhuma mudança** no provider.

### 5.6 `ShopScreen` — limpeza

- Remover `_deliverItemsLocally` (substituído por `deliverIAPItems`)
- Atualizar `_onBuy` para chamar `deliverIAPItems(ref, package)` no lugar

---

## 6. `docs/IAP.md` — Configuração de produtos IAP

**Arquivo novo:** `docs/IAP.md`

Conteúdo:

### Produtos registrados

| ID do produto | Tipo       | Preço   | Conteúdo                 |
| ------------- | ---------- | ------- | ------------------------ |
| `p1`          | Consumível | R$ 3,99 | 4× Bomba 3               |
| `p2`          | Consumível | R$ 1,99 | 4× Desfazer 3            |
| `p3`          | Consumível | R$ 2,49 | 6 Vidas                  |
| `p4`          | Consumível | R$ 4,99 | 10 Vidas                 |
| `p5`          | Consumível | R$ 4,99 | Combo Mata Atlântica     |
| `p6`          | Consumível | R$ 9,99 | Combo Floresta Amazônica |
| `u_bomb3`     | Consumível | R$ 1,99 | 1× Bomba 3               |
| `u_undo3`     | Consumível | R$ 0,99 | 1× Desfazer 3            |
| `u_bomb2`     | Consumível | R$ 1,19 | 1× Bomba 2               |
| `u_undo1`     | Consumível | R$ 0,49 | 1× Desfazer 1            |

### Google Play Console

1. Acesse **Monetização → Produtos in-app → Produtos gerenciados**
2. Para cada ID acima: **Criar produto**, tipo **Consumível**
3. Preencha ID, nome, descrição e preço conforme tabela
4. Status: **Ativo**
5. Salvar e publicar (produtos precisam de app publicado no mínimo em teste interno)

### App Store Connect

1. Acesse **Recursos → Compras no app**
2. Para cada ID: **+** → **Consumível**
3. ID do produto deve ser o mesmo (ex: `u_bomb3`)
4. Preencha localização PT-BR, preço e screenshot de revisão
5. Submeter junto com a próxima versão do app

### Sandbox (flavor `dev`)

- Android: usar conta de teste Google Play (Configurações do Play Console → Licenciamento e testes in-app)
- iOS: usar Sandbox Tester no App Store Connect → Usuários e acesso → Sandbox

### Flavor `tst`

Usa `FakeIAPService` — nenhuma configuração de loja necessária. Para smoke test com IAP real, passar `--dart-define=USE_REAL_IAP=true`.

---

## 7. Mapa de arquivos

| Arquivo                                              | Ação                                                     |
| ---------------------------------------------------- | -------------------------------------------------------- |
| `lib/presentation/widgets/daily_reward_overlay.dart` | Modificar — texto condicional Ok/Não obrigado            |
| `lib/presentation/widgets/inventory_bar.dart`        | Modificar — forceDisabled + onTapWhenDisabled na Bomba 3 |
| `lib/core/utils/haptic_utils.dart`                   | Modificar — enum HapticIntensity + assinatura Ref        |
| `lib/presentation/controllers/game_notifier.dart`    | Modificar — 3 triggers de haptic em move()               |
| `lib/data/shop_data.dart`                            | Modificar — kShopUnitPackages + kUnitPackageByType       |
| `lib/core/utils/iap_delivery.dart`                   | **Criar** — deliverIAPItems helper                       |
| `lib/presentation/widgets/shop_unit_item_card.dart`  | Modificar — fluxo IAP completo                           |
| `lib/presentation/widgets/shop_overlay.dart`         | Modificar — fluxo IAP completo                           |
| `lib/presentation/screens/shop_screen.dart`          | Modificar — remover \_deliverItemsLocally, usar helper   |
| `docs/IAP.md`                                        | **Criar** — documentação de configuração IAP             |

---

## 8. Testes

- `test/presentation/widgets/inventory_bar_test.dart` — verificar `forceDisabled` da Bomba 3 com < 5 peças e dialog ao tocar
- `test/core/utils/haptic_utils_test.dart` — `maybeHaptic` com `hapticEnabled=false` não dispara; com `true` dispara correto
- `test/data/shop_data_test.dart` — `kShopUnitPackages` tem 4 itens; `kUnitPackageByType` mapeia todos os `ItemType`
- `test/presentation/widgets/shop_unit_item_card_test.dart` — compra chama `iapService.buyPackage`, entrega itens, mostra `PurchaseSuccessSheet`

---

## 9. Não-objetivos

- Não implementar IAP de assinatura (apenas consumíveis)
- Não alterar `giftContents` dos pacotes unitários (nenhum brinde avulso)
- Não alterar UI visual dos cards de itens avulsos na loja (só o fluxo de compra muda)
- Não adicionar novos itens de inventário além dos 4 existentes
