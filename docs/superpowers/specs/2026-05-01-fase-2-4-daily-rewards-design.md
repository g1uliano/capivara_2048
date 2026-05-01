# Spec — Fase 2.4: Recompensas Diárias (ciclo 7 dias)

**Data:** 2026-05-01  
**Versão alvo:** v0.9.0  
**Fase anterior concluída:** Fase 2.3.12 (v0.8.4)  
**Próxima fase:** 2.5 — Home definitiva + Coleção + Configurações

---

## Decisões tomadas

| Ponto | Decisão |
|-------|---------|
| Representação de data | `DateTime` normalizado para meia-noite local (`DateTime(y, m, d)`) |
| Injeção de tempo | Parâmetro `now` explícito — consistente com `LivesNotifier` |
| Streak quebrada | Estado visível (`streakBroken`) com feedback antes de coletar |
| Anti-retrocesso de relógio | Tratar como `alreadyClaimed` — não punir usuário |
| Cap de vidas cheio | Dialog de confirmação antes de coletar |
| Não coletou no dia | Recompensa perdida — sem acúmulo |
| Atomicidade | Entregar primeiro, gravar `claimedThisCycle=true` depois |
| Arquitetura | `DailyRewardsState` standalone (typeId 3), notifier independente |
| Entry point provisório | Tile na barra superior da `HomeScreen` atual |
| Primeira abertura do dia | Badge + toast único por sessão |
| Mock de anúncio | `AdService` interface + `FakeAdService` (fake delay 1s) |
| Áudio | Nenhum — reposicionado para Fase 5 |

---

## Tabela de recompensas (§8.1)

| Dia | Recompensa |
|-----|------------|
| 1 | 1× Desfazer 1 |
| 2 | 1× Bomba 2 |
| 3 | +1 vida |
| 4 | 2× Desfazer 1 |
| 5 | 2× Bomba 2 |
| 6 | +2 vidas |
| 7 | 2× Desfazer 1 + 2× Bomba 2 + 2 vidas |

Vidas recebidas contam como "ganhas" — entram no cap de 15 (`earnedCap`).

---

## A — Modelo e Persistência

### `DailyRewardsState` (Hive typeId: 3)

```dart
class DailyRewardsState {
  final int currentDay;           // 1–7: dia que será coletado na próxima coleta disponível
  final DateTime lastClaimedDate; // meia-noite local do último dia coletado; sentinel: DateTime(1970)
  final bool claimedThisCycle;    // true se o dia atual já foi coletado
}
```

**`DailyRewardsState.initial()`:**
```dart
factory DailyRewardsState.initial() => DailyRewardsState(
  currentDay: 1,
  lastClaimedDate: DateTime(1970),
  claimedThisCycle: false,
);
```

`lastClaimedDate` é sempre normalizado para `DateTime(y, m, d)` antes de salvar — sem ambiguidade de horário.

### `DailyRewardsStateAdapter` (typeId: 3)

Adapter manual, mesmo padrão do `InventoryHiveAdapter`. Campos indexados:

| Índice | Campo |
|--------|-------|
| 0 | `currentDay` (int) |
| 1 | `lastClaimedDate` (DateTime) |
| 2 | `claimedThisCycle` (bool) |

### `DailyRewardsRepository`

```dart
class DailyRewardsRepository {
  Future<DailyRewardsState> load();
  Future<void> save(DailyRewardsState state);
  Future<void> reset();  // debug only — volta ao initial
}
```

Chave Hive: `'daily_rewards'`. Mesma box padrão do app.

### Registro em `main.dart`

```dart
Hive.registerAdapter(DailyRewardsStateAdapter());
// + inicializar dailyRewardsProvider no ProviderContainer inicial
```

### Arquivos a criar

| Arquivo | Descrição |
|---------|-----------|
| `lib/data/models/daily_rewards_state.dart` | Modelo imutável + copyWith + initial |
| `lib/data/models/daily_rewards_state_adapter.dart` | Hive adapter (typeId 3) |
| `lib/data/repositories/daily_rewards_repository.dart` | load/save/reset |

### Arquivos a modificar

| Arquivo | Mudança |
|---------|---------|
| `lib/main.dart` | Registrar adapter + inicializar provider |

---

## B — Lógica de Streak/Ciclo (domínio puro)

### Enum

```dart
enum DailyRewardStatus {
  available,       // pode coletar hoje (inclui primeiro acesso e pós-streakBroken)
  alreadyClaimed,  // já coletou hoje (ou relógio retrocedeu)
  streakBroken,    // gap >= 2 dias — feedback obrigatório antes de coletar
  cycleCompleted,  // coletou Dia 7, aguarda próximo ciclo
}
```

### `DailyReward`

```dart
class DailyReward {
  final int lives;
  final int undo1;
  final int bomb2;
}

const List<DailyReward> kDailyRewards = [
  DailyReward(lives: 0, undo1: 1, bomb2: 0),  // Dia 1
  DailyReward(lives: 0, undo1: 0, bomb2: 1),  // Dia 2
  DailyReward(lives: 1, undo1: 0, bomb2: 0),  // Dia 3
  DailyReward(lives: 0, undo1: 2, bomb2: 0),  // Dia 4
  DailyReward(lives: 0, undo1: 0, bomb2: 2),  // Dia 5
  DailyReward(lives: 2, undo1: 0, bomb2: 0),  // Dia 6
  DailyReward(lives: 2, undo1: 2, bomb2: 2),  // Dia 7
];

DailyReward rewardForDay(int day) => kDailyRewards[day - 1];
```

### `computeDailyRewardStatus`

```dart
DailyRewardStatus computeDailyRewardStatus(DateTime now, DailyRewardsState state) {
  final today = DateTime(now.year, now.month, now.day);
  final last  = state.lastClaimedDate;  // já normalizado

  // anti-retrocesso
  if (today.isBefore(last)) return DailyRewardStatus.alreadyClaimed;

  final gap = today.difference(last).inDays;

  if (gap == 0) return DailyRewardStatus.alreadyClaimed;

  if (gap >= 2) return DailyRewardStatus.streakBroken;

  // gap == 1
  if (!state.claimedThisCycle) return DailyRewardStatus.available;
  if (state.currentDay == 7)   return DailyRewardStatus.cycleCompleted;
  return DailyRewardStatus.available;
}
```

**Nota:** `streakBroken` não impede coleta — o notifier usa `applyStreakReset` antes de entregar (reseta para Dia 1 e procede com `available`).

### Funções auxiliares

```dart
// Reseta streak: currentDay=1, claimedThisCycle=false
DailyRewardsState applyStreakReset(DailyRewardsState state);

// Marca coleta: claimedThisCycle=true, lastClaimedDate=today, currentDay avança
// Se currentDay==7 após coleta, permanece em 7 até próximo reset
DailyRewardsState applyClaim(DateTime now, DailyRewardsState state);

// Retorna dia efetivo considerando streak quebrada
int effectiveDay(DailyRewardStatus status, DailyRewardsState state) =>
    status == streakBroken ? 1 : state.currentDay;
```

### Arquivos a criar

| Arquivo | Descrição |
|---------|-----------|
| `lib/domain/daily_rewards/daily_rewards_engine.dart` | Todas as funções puras acima |

### Casos de teste obrigatórios (`test/domain/daily_rewards_engine_test.dart`)

| # | Caso | Entrada | Esperado |
|---|------|---------|----------|
| 1 | Nunca coletou | `initial()`, `now` qualquer > 1970 | `available` |
| 2 | Coletou hoje | `gap=0` | `alreadyClaimed` |
| 3 | Coletou ontem, dia 1–6 | `gap=1`, `currentDay<7` | `available` |
| 4 | Coletou Dia 7 ontem | `gap=1`, `currentDay=7` | `cycleCompleted` |
| 5 | Gap 2 dias | `gap=2` | `streakBroken` |
| 6 | Gap 10 dias | `gap=10` | `streakBroken` |
| 7 | Relógio retrocedeu | `now < last` | `alreadyClaimed` |
| 8 | Meia-noite: coletou 23:59, abre 00:01 | `gap=1`, `claimedThisCycle=true`, `currentDay=3` | `available` |
| 9 | 7 dias consecutivos — ciclo completo | loop simulado | Dia 8: `cycleCompleted`; Dia 9: `available` (Dia 1) |
| 10 | `applyStreakReset` | qualquer state | `currentDay=1, claimedThisCycle=false` |
| 11 | `applyClaim` Dia 6 | `currentDay=6` | `currentDay=7, claimedThisCycle=true` |
| 12 | `applyClaim` Dia 7 | `currentDay=7` | `currentDay=7, claimedThisCycle=true` (permanece) |

---

## C — Tela `DailyRewardsScreen`

### Layout

Tela modal (`Navigator.push`) — não substitui a home.

```
┌─────────────────────────────┐
│     Recompensa Diária       │  ← título
│                             │
│  [1][2][3][4]               │  ← linha 1: dias 1–4
│     [5][6][7]               │  ← linha 2: dias 5–7 centralizados
│                             │
│  [banner streak — se aplicável]
│                             │
│      [ Coletar ]            │  ← botão central
│  ou "Volte amanhã HH:MM:SS" │
└─────────────────────────────┘
```

Grid layout: `Wrap` ou `Row` explícita com `MainAxisAlignment.center` nas duas linhas.

### Estados dos tiles

| Estado | Visual |
|--------|--------|
| Futuro | Fundo neutro, ícone opacidade 40% |
| Atual disponível | Borda animada + glow cor primária, opacidade 100% |
| Já coletado | Check verde sobreposto, opacidade 60% |
| Dia 7 (qualquer estado) | Borda/destaque dourado adicional |

### Estados da tela

**`available`:**
- Dia atual destacado, botão "Coletar" habilitado

**`streakBroken`:**
- Banner topo: "Você perdeu a streak! Recomeçando do Dia 1."
- Tile do Dia 1 destacado (mesmo que `currentDay > 1`)
- Botão "Coletar" habilitado

**`alreadyClaimed`:**
- Tile do dia atual com check
- Botão desabilitado
- Timer regressivo: "Volte amanhã — HH:MM:SS" (`Timer.periodic(1s)`, mesmo padrão do `LivesStatusBanner`)

**`cycleCompleted`:**
- Todos os 7 tiles com check
- Mensagem: "Ciclo completo!"
- Botão "Iniciar novo ciclo" habilitado (entrega Dia 1 do próximo ciclo)

### Fluxo pós-coleta

1. Animação no tile: scale 1.0 → 1.3 → 1.0 + fade (via `flutter_animate`)
2. Overlay "Dobrar recompensa":
   - Exibe recompensa recebida
   - Botão "Assistir 30s e dobrar" → `AdService.showRewardedAd()` → entrega delta 2x
   - Botão "Não, obrigado" → fecha overlay
3. Tela volta para estado `alreadyClaimed`

### Aviso de cap de vidas

Se recompensa do dia inclui vidas **e** `lives >= earnedCap`:
- Dialog antes de coletar: "Você já tem o máximo de vidas (15). As vidas desta recompensa serão descartadas. Coletar mesmo assim?"
- Botões: "Coletar" / "Cancelar"
- Se confirmar: coleta normalmente (cap de vidas aplicado pelo `LivesNotifier.addEarned`)

### Ícones

| Item | Asset |
|------|-------|
| Desfazer 1 | `assets/icons/inventory/undo_1.png` |
| Bomba 2 | `assets/icons/inventory/bomb_2.png` |
| Vida | `Icons.favorite` (provisório — substituir por asset na Fase 4) |

### Arquivos a criar

| Arquivo | Descrição |
|---------|-----------|
| `lib/presentation/screens/daily_rewards/daily_rewards_screen.dart` | Tela principal |
| `lib/presentation/widgets/daily_reward_tile.dart` | Tile individual do grid |
| `lib/presentation/widgets/daily_reward_overlay.dart` | Overlay "Dobrar" pós-coleta |

### Testes de widget (`test/presentation/`)

| Arquivo | Estados cobertos |
|---------|-----------------|
| `daily_rewards_screen_available_test.dart` | `available` |
| `daily_rewards_screen_claimed_test.dart` | `alreadyClaimed` + timer |
| `daily_rewards_screen_streak_broken_test.dart` | `streakBroken` + banner |
| `daily_rewards_screen_cycle_completed_test.dart` | `cycleCompleted` |

---

## D — Integração com Vidas e Inventário

### `DailyRewardsNotifier`

```dart
class DailyRewardsNotifier extends StateNotifier<DailyRewardsState> {
  DailyRewardsNotifier(this._repo, this._ref) : super(DailyRewardsState.initial());

  final DailyRewardsRepository _repo;
  final Ref _ref;

  Future<void> load() async { state = await _repo.load(); }

  DailyRewardStatus get status => computeDailyRewardStatus(DateTime.now(), state);

  Future<void> claim(DateTime now) async {
    final s = computeDailyRewardStatus(now, state);
    final claimable = s == DailyRewardStatus.available ||
                      s == DailyRewardStatus.streakBroken ||
                      s == DailyRewardStatus.cycleCompleted;
    if (!claimable) return;

    var current = state;
    if (s == DailyRewardStatus.streakBroken || s == DailyRewardStatus.cycleCompleted) {
      current = applyStreakReset(current);  // currentDay=1 para ambos
    }

    final day = current.currentDay;
    final reward = rewardForDay(day);

    // Entregar primeiro (atomicidade B)
    if (reward.lives > 0) await _ref.read(livesProvider.notifier).addEarned(reward.lives);
    if (reward.undo1  > 0) await _ref.read(inventoryProvider.notifier).add(ItemType.undo1, reward.undo1);
    if (reward.bomb2  > 0) await _ref.read(inventoryProvider.notifier).add(ItemType.bomb2, reward.bomb2);

    // Gravar depois
    final next = applyClaim(now, current);
    state = next;
    await _repo.save(state);
  }

  Future<void> claimDouble(DailyReward original) async {
    // Entrega delta (2x - base já entregue = 1x extra)
    if (original.lives > 0) await _ref.read(livesProvider.notifier).addEarned(original.lives);
    if (original.undo1  > 0) await _ref.read(inventoryProvider.notifier).add(ItemType.undo1, original.undo1);
    if (original.bomb2  > 0) await _ref.read(inventoryProvider.notifier).add(ItemType.bomb2, original.bomb2);
    // Não altera DailyRewardsState
  }
}

final dailyRewardsProvider = StateNotifierProvider<DailyRewardsNotifier, DailyRewardsState>(
  (ref) => DailyRewardsNotifier(DailyRewardsRepository(), ref),
);
```

### `AdService`

```dart
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

### Arquivos a criar

| Arquivo | Descrição |
|---------|-----------|
| `lib/domain/daily_rewards/daily_rewards_notifier.dart` | Notifier + provider |
| `lib/domain/daily_rewards/ad_service.dart` | Interface + FakeAdService |

### Testes de integração (`test/domain/daily_rewards_notifier_test.dart`)

| # | Caso | Verificação |
|---|------|-------------|
| 1 | Dia 3 (+1 vida): lives=14 | lives=15 após claim |
| 2 | Dia 3 (+1 vida): lives=15 | aviso UI, sem entrega de vida |
| 3 | Dia 7 (combo) | inventory e lives corretos |
| 4 | Dobrar Dia 2 (+1 bomba base → +1 delta) | total bomb2=2 |
| 5 | streakBroken → claim | reseta para Dia 1, entrega recompensa do Dia 1 |
| 6 | 7 dias consecutivos | currentDay reseta para 7+claimedThisCycle; Dia 9: Dia 1 disponível |

---

## E — Entry Point e Indicação Visual

### `DailyRewardTile` (barra superior `HomeScreen`)

```
HomeScreen barra superior:
[ LivesIndicator ]  [ DailyRewardTile ]
```

`DailyRewardTile` é um `ConsumerWidget` que observa `dailyRewardsProvider`:
- Ícone `Icons.card_giftcard` (provisório)
- Badge vermelho "!" quando `status == available`
- `onTap` → `Navigator.push(DailyRewardsScreen)`

### Toast na primeira abertura

Em `HomeScreen._init()` via `addPostFrameCallback`:
```dart
if (status == DailyRewardStatus.available && !_toastShown) {
  _toastShown = true;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Sua recompensa diária está disponível!')),
  );
}
```

`_toastShown` é flag em memória (não persistida) — reset ao matar o app.

### Arquivos a criar

| Arquivo | Descrição |
|---------|-----------|
| `lib/presentation/widgets/daily_reward_tile.dart` | Tile + badge |

### Arquivos a modificar

| Arquivo | Mudança |
|---------|---------|
| `lib/presentation/screens/home_screen.dart` | Adicionar `DailyRewardTile` na barra superior + toast |

---

## Estratégia de testes de tempo

Todas as funções puras recebem `DateTime now` explicitamente — zero `DateTime.now()` interno no domínio. Nos testes:

```dart
DateTime day(int n) => DateTime(2026, 5, n);

test('ciclo completo 7 dias', () {
  var state = DailyRewardsState.initial();
  for (int d = 1; d <= 7; d++) {
    expect(computeDailyRewardStatus(day(d), state), DailyRewardStatus.available);
    state = applyClaim(day(d), state);
  }
  // Dia 8: gap=1, currentDay=7, claimedThisCycle=true → cycleCompleted (novo ciclo disponível)
  expect(computeDailyRewardStatus(day(8), state), DailyRewardStatus.cycleCompleted);
  // Dia 9: gap=2 → streakBroken (jogador não iniciou novo ciclo no Dia 8)
  expect(computeDailyRewardStatus(day(9), state), DailyRewardStatus.streakBroken);
});
```

**Semântica de `cycleCompleted`:** `gap=1, currentDay=7, claimedThisCycle=true` — o ciclo completou E o próximo já pode ser iniciado. Botão "Iniciar novo ciclo" habilitado. `claim()` detecta este estado, aplica `applyStreakReset` (currentDay=1) e entrega Dia 1.

**`claim()` trata 3 estados com botão habilitado:** `available`, `streakBroken`, `cycleCompleted`.

**Streak automático após `cycleCompleted`:** se o jogador não clicar "Iniciar novo ciclo" no Dia 8 e voltar no Dia 9, status será `streakBroken` → reinicia do Dia 1 igualmente (sem penalidade extra — o reset já é o "reinício").

---

## Mocks ASCII dos 4 estados visuais

### Estado: `available` (Dia 3)

```
╔════════════════════════════╗
║    Recompensa Diária       ║
║                            ║
║  [✓][✓][★][·]             ║  ← ✓=coletado, ★=atual, ·=futuro
║     [·][·][7]              ║  ← [7]=borda dourada
║                            ║
║       [ Coletar ]          ║
╚════════════════════════════╝
```

### Estado: `alreadyClaimed` (Dia 3 já coletado)

```
╔════════════════════════════╗
║    Recompensa Diária       ║
║                            ║
║  [✓][✓][✓][·]             ║
║     [·][·][7]              ║
║                            ║
║   Volte amanhã 11:23:45    ║
╚════════════════════════════╝
```

### Estado: `streakBroken`

```
╔════════════════════════════╗
║ ⚠ Você perdeu a streak!   ║
║   Recomeçando do Dia 1.    ║
║                            ║
║  [★][·][·][·]             ║  ← Dia 1 destacado
║     [·][·][7]              ║
║                            ║
║       [ Coletar ]          ║
╚════════════════════════════╝
```

### Estado: `cycleCompleted` (Dia 8 — novo ciclo disponível)

```
╔════════════════════════════╗
║    Recompensa Diária       ║
║                            ║
║  [✓][✓][✓][✓]             ║
║     [✓][✓][✓]             ║
║                            ║
║   Ciclo completo!          ║
║  [ Iniciar novo ciclo ]    ║
╚════════════════════════════╝
```

---

## Ordem de implementação (TDD-friendly)

```
A → B → D → C → E
```

| Etapa | Entrega | Testes primeiro |
|-------|---------|-----------------|
| A | Modelo + adapter + repositório | Testes de serialização Hive |
| B | Engine puro (computeStatus, apply*) | 12 casos unitários |
| D | Notifier + AdService + integração | Testes de integração com mocks |
| C | Tela + widgets | Testes de widget (4 estados) |
| E | DailyRewardTile + toast na Home | Testes de widget HomeScreen |

---

## Pontos a sincronizar com Fase 2.5

| Item | Ação na 2.5 |
|------|-------------|
| `DailyRewardTile` posição | Reposicionar na Home redesenhada — sem reescrever o widget |
| Toast | Pode mover para `AppStartupController` ou equivalente |
| Navegação | Converter para rota nomeada se 2.5 adotar `go_router` |
| `AdService` | Substituir `FakeAdService` por implementação real na Fase 3 |

---

## Critérios de aceite da Fase 2.4

- [ ] `DailyRewardsState` persiste e carrega corretamente via Hive
- [ ] Streak quebra ao pular 1 dia (gap ≥ 2)
- [ ] Ciclo de 7 dias completa e reinicia corretamente
- [ ] Relógio retrocedido não libera recompensa nem pune usuário
- [ ] Cap de 15 vidas respeitado com aviso de confirmação
- [ ] Recompensa não acumula (perdeu o dia = perdeu)
- [ ] Atomicidade: entrega antes de gravar estado
- [ ] `DailyRewardTile` com badge na barra superior da Home
- [ ] Toast uma vez por sessão quando disponível
- [ ] Overlay "Dobrar" entrega delta correto (não duplica base)
- [ ] `FakeAdService` com delay de 1s funcionando
- [ ] Testes unitários: 12 casos do engine
- [ ] Testes de integração: 6 casos do notifier
- [ ] Testes de widget: 4 estados da tela
- [ ] Sem SFX/música (áudio reposicionado para Fase 5)
