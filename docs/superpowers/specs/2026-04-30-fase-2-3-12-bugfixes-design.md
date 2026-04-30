# Fase 2.3.12 — Bugfixes de Layout, Regen e Ícones do Inventário

**Data:** 2026-04-30
**Versão alvo:** v0.8.1
**Fase anterior:** 2.3.11 (Tanajura como anfitrião desde boot, fundo.png na HomeScreen)

---

## Visão Geral

Quatro correções identificadas em uso real após a 2.3.11:

| ID | Título | Arquivo(s) principal |
|----|--------|----------------------|
| A | Centralizar `LivesIndicator` no topo | `game_header.dart`, `home_screen.dart` |
| B | Colar `HostBanner` à coluna 1 (eliminar gap) | `game_header.dart` |
| C | Implementar timer de regeneração de vidas | `lives_notifier.dart` |
| D | Integrar PNGs finais dos ícones do inventário | `inventory_bar.dart`, `confirm_use_dialog.dart`, `app.dart` |

Ordem de entrega recomendada: A → B → C → D (do mais simples ao mais complexo).

---

## Item A — Centralizar `LivesIndicator`

### Diagnóstico

- **`game_header.dart`**: `LivesIndicator` é primeiro filho de `Column(crossAxisAlignment: CrossAxisAlignment.stretch)` sem wrapper `Center`. Resultado: alinhado à esquerda.
- **`home_screen.dart`**: `LivesIndicator` está em `Align(alignment: Alignment.centerRight)`. Resultado: alinhado à direita.

### Fix

**`game_header.dart`** — envolver em `Center`:
```dart
Center(child: const LivesIndicator()),
```

**`home_screen.dart`** — trocar `Align(centerRight)` por `Center`:
```dart
Center(child: const LivesIndicator()),
```

### Critérios de aceite

- `LivesIndicator` centralizado horizontalmente em `GameScreen` e `HomeScreen`.
- Funciona em qualquer largura de dispositivo (320px a 430px).
- Não afeta posicionamento do `HostBanner` nem do `PauseButtonTile`.

### Testes

- Regenerar snapshots de `GameHeader` e `HomeScreen` após o fix.
- Verificar em dispositivo estreito (320px) que não ocorre overflow.

---

## Item B — Colar `HostBanner` à borda esquerda

### Diagnóstico

`game_header.dart` linha C (Row host/pause):
```dart
Row(
  children: [
    Expanded(flex: 2, child: HostBanner()),       // 50% da largura
    Expanded(flex: 2, child: Column(...)),         // 50% da largura
  ],
)
```
O `Expanded(flex: 2)` faz `HostBanner` ocupar metade do espaço disponível mas não toca a borda — o conteúdo interno do `HostBanner` fica centrado dentro do `Expanded`. O outer `Padding(horizontal: 12)` é compartilhado com o tabuleiro, então o gap vem do `Expanded`, não do padding externo.

### Fix

**`game_header.dart`** — remover `Expanded`, usar `Spacer()`:
```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    HostBanner(),
    Spacer(),
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        StatusPanel(),
        SizedBox(height: 6),
        PauseButtonTile(tileSize: tileSize, onTap: onPauseTap),
      ],
    ),
  ],
)
```

`StatusPanel` sai do `Expanded` e fica em `Column` alinhada à direita, acima do `PauseButtonTile`.

### Critérios de aceite

- Borda esquerda do `HostBanner` alinhada com borda esquerda da coluna 1 do tabuleiro (mesma linha vertical).
- `PauseButtonTile` permanece flush-right.
- `StatusPanel` (score) visível e não cortado em tela 320px.
- Nenhum overflow em telas estreitas.

### Testes

- Regenerar snapshots de `GameHeader` após o fix.
- Testar em 320px de largura para confirmar que `StatusPanel` não transborda.

---

## Item C — Timer de Regeneração de Vidas

### Diagnóstico

`LivesNotifier._init()` chama `calcRegen` uma vez no boot (offline recalc correto), mas **não há `Timer.periodic`**. Durante a sessão, `lives` nunca incrementa. O display visual (`LivesStatusBanner`) atualiza a cada frame via Ticker do widget, mas o domínio fica estático.

Bug secundário: quando `remaining` fica negativo, o banner exibe "00:00" preso — porque nada aciona `calcRegen` para avançar `lastRegenAt`.

### Convenção de campo

O código usa `lastRegenAt: DateTime` (não nullable). O próximo regen é derivado como `lastRegenAt + 30min`. A spec usa `nextRegenAt` em alguns lugares — ignorar essa nomenclatura, seguir o código.

### Fix em `lives_notifier.dart`

**1. Campo de timer:**
```dart
Timer? _regenTimer;
AppLifecycleListener? _lifecycleListener;
```

**2. `_init()` — após `_ready.complete()`:**
```dart
_startRegenTimer();
_lifecycleListener = AppLifecycleListener(
  onPause: _pauseRegen,
  onResume: _resumeRegen,
);
```

**3. Métodos auxiliares:**
```dart
void _startRegenTimer() {
  _regenTimer = Timer.periodic(const Duration(seconds: 30), (_) => _onTick());
}

void _onTick() {
  final result = calcRegen(state: state as LivesLoaded, now: DateTime.now());
  if (result.gained > 0) {
    state = result.newState;
    _persist(result.newState);
  }
}

void _pauseRegen() {
  _regenTimer?.cancel();
  _regenTimer = null;
}

void _resumeRegen() {
  // Recalcula offline antes de reativar
  final result = calcRegen(state: state as LivesLoaded, now: DateTime.now());
  if (result.gained > 0) {
    state = result.newState;
    _persist(result.newState);
  }
  _startRegenTimer();
}
```

**4. `dispose()`:**
```dart
_regenTimer?.cancel();
_lifecycleListener?.dispose();
```

### Assinatura de `calcRegen`

Se `calcRegen` não retorna um objeto com `gained` e `newState`, adaptar para retornar um record:
```dart
({int gained, LivesLoaded newState}) calcRegen({required LivesLoaded state, required DateTime now})
```
(Ou adaptar `_onTick` para comparar `state.lives` antes e depois.)

### Edge cases

| Cenário | Comportamento esperado |
|---------|------------------------|
| `lives >= regenCap` | `calcRegen` retorna `gained == 0`, sem emit |
| App offline 6h, `lives == 0` | `_resumeRegen` → `lives = 5`, `lastRegenAt` avança |
| Banner "00:00" preso | Próximo tick (≤30s) resolve `remaining` negativo |
| `remaining` formato | `MM:SS` sempre (ex: `90:00` para 90min restantes) |

### Critérios de aceite

- `lives` incrementa corretamente durante sessão ativa após 30min.
- Ao retornar do background com tempo offline ≥ 30min, `lives` é atualizado imediatamente.
- Timer cancelado no `dispose()` — sem leak.
- Banner nunca fica preso em "00:00" por mais de 30s.

### Testes obrigatórios

- `FakeAsync`: avançar 30min → confirmar `state.lives` incrementa de N para N+1.
- `FakeAsync`: avançar 60min com `lives = 3` → confirmar `lives = 5` (não ultrapassa `regenCap`).
- Simular `paused` + 6h + `resumeRegen` → confirmar `lives == regenCap`.
- `lives == regenCap` → timer ticking 30s → confirmar **sem** emit de estado.
- `FakeAsync`: verificar que `_regenTimer` é cancelado no `dispose()`.

---

## Item D — PNGs do Inventário

### Diagnóstico

- `InventoryItemButton` já suporta `pngPath: String?` com fallback para `Icon`.
- `InventoryBar` nunca passa `pngPath` — todos os botões usam `Icon` placeholder.
- `ConfirmUseDialog` não exibe ícone algum.
- PNGs já estão em `assets/icons/inventory/` e declarados em `pubspec.yaml`.

### Mapeamento de assets

| Item | PNG | Animal temático |
|------|-----|-----------------|
| `bomb_2` | `assets/icons/inventory/bomb_2.png` | Sucuri |
| `bomb_3` | `assets/icons/inventory/bomb_3.png` | Mico-leão-dourado |
| `undo_1` | `assets/icons/inventory/undo_1.png` | Capivara |
| `undo_3` | `assets/icons/inventory/undo_3.png` | Onça-pintada |

### Fix 1 — `inventory_bar.dart`

Adicionar `pngPath` em cada `InventoryItemButton(...)`:
```dart
InventoryItemButton(
  icon: Icons.bolt,  // mantém como fallback
  pngPath: 'assets/icons/inventory/bomb_2.png',
  ...
)
```
(Repetir para os outros 3 itens com seus respectivos paths.)

### Fix 2 — `confirm_use_dialog.dart`

Adicionar parâmetro `String? pngPath` em `showConfirmUseDialog`. Alterar `title` do `AlertDialog`:
```dart
title: Row(
  children: [
    if (pngPath != null) ...[
      Image.asset(pngPath, width: 40, height: 40),
      const SizedBox(width: 8),
    ],
    Flexible(child: Text('Usar $itemName?')),
  ],
),
```

Todos os call sites de `showConfirmUseDialog` em `InventoryBar` devem passar o `pngPath` correspondente.

### Fix 3 — `app.dart`

Adicionar ao bloco `precacheImage` no boot:
```dart
precacheImage(const AssetImage('assets/icons/inventory/bomb_2.png'), context);
precacheImage(const AssetImage('assets/icons/inventory/bomb_3.png'), context);
precacheImage(const AssetImage('assets/icons/inventory/undo_1.png'), context);
precacheImage(const AssetImage('assets/icons/inventory/undo_3.png'), context);
```

### Estado disabled

`ColorFilter.matrix` (grayscale) já implementado em `InventoryItemButton` — funciona corretamente com PNGs coloridos e transparência. Não alterar.

### Ícones antigos

Material Icons (`Icons.bolt`, etc.) permanecem como `icon:` fallback — não remover.

### Critérios de aceite

- Botões do inventário exibem PNGs temáticos em estado enabled.
- Estado disabled dessatura visualmente via `ColorFilter.matrix`.
- `ConfirmUseDialog` exibe ícone 40x40 no título, consistente com o botão.
- Sem erro de asset em nenhum dos 4 itens.
- PNGs pré-carregados no boot (sem flash de carregamento na primeira exibição).

### Testes

- Widget test: `InventoryItemButton` com `pngPath` renderiza `Image.asset`, não `Icon`.
- Widget test: `InventoryItemButton` sem `pngPath` renderiza `Icon` (fallback).
- Widget test: `showConfirmUseDialog` com `pngPath` exibe `Image.asset` no título.

---

## Testes existentes que precisam ser ajustados

| Arquivo de teste | Motivo |
|-----------------|--------|
| Snapshots de `GameHeader` | Items A e B alteram layout |
| Snapshots de `HomeScreen` | Item A altera posição do `LivesIndicator` |
| Qualquer golden test de `InventoryBar` | Item D altera visual dos botões |

Regenerar com `flutter test --update-goldens` após cada item concluído (não ao final de todos).

---

## Estratégia de implementação

1. **Item A** — 1 arquivo de widget, 1 de screen. Baixíssimo risco. Regenerar goldens.
2. **Item B** — Refator de layout em `game_header.dart`. Testar em 320px. Regenerar goldens.
3. **Item C** — Mudança de domínio. Escrever testes unitários com `FakeAsync` ANTES de implementar (TDD). Lifecycle observer requer teste manual em dispositivo/emulador.
4. **Item D** — Mudanças de apresentação puras. Sem risco de regressão em lógica. Testar visualmente.
