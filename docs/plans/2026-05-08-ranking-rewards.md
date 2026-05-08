# Ranking Global, Recompensas e Auditoria de Flavors — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar Ranking Global com dialogs pós-milestone, recompensas por recorde pessoal e convite, tabela de prêmios semanais revisada, e corrigir providers que usam Fake em flavor `dev`.

**Architecture:** Um novo `PostGameController` (Riverpod Notifier) observa `gameNotifierProvider`, detecta milestones, calcula recordes pessoais, entrega combos via notifiers existentes e consulta Firestore para posição no ranking global. A `GameScreen` observa o controller e exibe `MilestoneRankingDialog`. A `RankingScreen` ganha uma 3ª aba Global. Toda lógica de reward usa `LivesNotifier.addEarned()` e `InventoryNotifier.add()` já existentes.

**Tech Stack:** Flutter/Dart, Riverpod, Hive, Cloud Firestore, flutter_test

**Spec:** `docs/specs/2026-05-08-ranking-rewards-design.md`

---

## Mapa de arquivos

| Arquivo | Ação |
|---------|------|
| `lib/data/models/personal_records.dart` | Modificar — add `bestTimeMs2048` |
| `lib/data/models/personal_records_hive_adapter.dart` | Modificar — add campo no adapter |
| `lib/presentation/controllers/personal_records_notifier.dart` | Modificar — add `updateBestTime2048()` |
| `lib/domain/ranking/weekly_reward_result.dart` | Modificar — nova tabela `forPosition()` |
| `lib/data/repositories/firestore_invite_repository.dart` | Modificar — reward do convidador + `pendingLives` |
| `lib/data/repositories/firebase_sync_engine.dart` | Modificar — creditar `pendingLives` em `syncProfile()` |
| `lib/data/repositories/firestore_ranking_repository.dart` | Modificar — add `maxTile` como tiebreaker |
| `lib/presentation/controllers/post_game_controller.dart` | **Criar** — PostGameController + PostGameSummary |
| `lib/presentation/widgets/milestone_ranking_dialog.dart` | **Criar** — MilestoneRankingDialog |
| `lib/presentation/screens/ranking_screen.dart` | Modificar — 3 tabs (add Global) |
| `lib/presentation/screens/game/game_screen.dart` | Modificar — ref.listen PostGameController |
| `lib/core/providers/ranking_provider.dart` | Modificar — flavor: fake só em `tst` |
| `lib/domain/invites/invite_service.dart` | Modificar — flavor: fake só em `tst` |
| `lib/domain/shop/iap_service.dart` | Modificar — flavor: dev usa real (sandbox) |
| `lib/data/repositories/iap_startup_service.dart` | Modificar — flavor: dev usa real (sandbox) |
| `README.md` | Modificar — builds table + roadmap |
| `test/domain/personal_records_test.dart` | **Criar** — testes `bestTimeMs2048` |
| `test/ranking/weekly_reward_test.dart` | Modificar — novos valores |
| `test/presentation/controllers/post_game_controller_test.dart` | **Criar** — testes do controller |
| `test/presentation/widgets/milestone_ranking_dialog_test.dart` | **Criar** — widget tests |

---

## Task 1 — `PersonalRecords`: adicionar `bestTimeMs2048`

**Files:**
- Modify: `lib/data/models/personal_records.dart`
- Modify: `lib/data/models/personal_records_hive_adapter.dart`
- Modify: `lib/presentation/controllers/personal_records_notifier.dart`
- Create: `test/domain/personal_records_test.dart`

- [ ] **Step 1.1: Escrever testes que falham**

```dart
// test/domain/personal_records_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/personal_records.dart';
import 'package:capivara_2048/data/models/personal_records_hive_adapter.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  group('PersonalRecords.bestTimeMs2048', () {
    test('default é 0', () {
      const r = PersonalRecords();
      expect(r.bestTimeMs2048, 0);
    });

    test('copyWith preserva bestTimeMs2048', () {
      const r = PersonalRecords(bestTimeMs2048: 12345);
      final r2 = r.copyWith(timesReached2048: 1);
      expect(r2.bestTimeMs2048, 12345);
    });

    test('copyWith atualiza bestTimeMs2048', () {
      const r = PersonalRecords(bestTimeMs2048: 12345);
      final r2 = r.copyWith(bestTimeMs2048: 9999);
      expect(r2.bestTimeMs2048, 9999);
    });

    test('HiveAdapter — round-trip salva e lê bestTimeMs2048', () {
      final adapter = PersonalRecordsHiveAdapter();
      const original = PersonalRecords(bestTimeMs2048: 54321, timesReached2048: 3);
      final buffer = BinaryWriter()..write(null); // warm up
      final writer = BinaryWriter();
      adapter.write(writer, original);
      final reader = BinaryReader(writer.toBytes());
      final restored = adapter.read(reader);
      expect(restored.bestTimeMs2048, 54321);
      expect(restored.timesReached2048, 3);
    });

    test('HiveAdapter — compatibilidade retroativa: bytes antigos retornam 0', () {
      // Simula registro antigo (sem bestTimeMs2048) usando writer sem o campo
      final writer = BinaryWriter();
      // Escreve apenas os campos originais (sem bestTimeMs2048)
      writer.writeInt(2);    // timesReached2048
      writer.writeInt(1);    // timesReached4096
      writer.writeInt(0);    // timesReached8192
      writer.writeBool(true); writer.writeInt(1700000000000); // firstReached2048At
      writer.writeBool(false); // firstReached4096At null
      writer.writeBool(false); // firstReached8192At null
      writer.writeBool(true);  // rewardCollected4096
      writer.writeBool(false); // rewardCollected8192
      writer.writeInt(12);   // highestLevelEver
      // Sem bestTimeMs2048

      final reader = BinaryReader(writer.toBytes());
      final restored = PersonalRecordsHiveAdapter().read(reader);
      expect(restored.bestTimeMs2048, 0);
      expect(restored.timesReached2048, 2);
      expect(restored.highestLevelEver, 12);
    });
  });
}
```

- [ ] **Step 1.2: Rodar para confirmar falha**

```bash
flutter test test/domain/personal_records_test.dart --no-pub
```
Esperado: FAIL (campo não existe ainda)

- [ ] **Step 1.3: Adicionar `bestTimeMs2048` ao model**

Em `lib/data/models/personal_records.dart`, adicionar o campo na classe e no `copyWith`:

```dart
class PersonalRecords {
  // ... campos existentes ...
  final int bestTimeMs2048;

  const PersonalRecords({
    this.timesReached2048 = 0,
    this.timesReached4096 = 0,
    this.timesReached8192 = 0,
    this.firstReached2048At,
    this.firstReached4096At,
    this.firstReached8192At,
    this.rewardCollected4096 = false,
    this.rewardCollected8192 = false,
    this.highestLevelEver = 0,
    this.bestTimeMs2048 = 0,   // NOVO
  });

  PersonalRecords copyWith({
    int? timesReached2048,
    int? timesReached4096,
    int? timesReached8192,
    Object? firstReached2048At = _sentinel,
    Object? firstReached4096At = _sentinel,
    Object? firstReached8192At = _sentinel,
    bool? rewardCollected4096,
    bool? rewardCollected8192,
    int? highestLevelEver,
    int? bestTimeMs2048,      // NOVO
  }) => PersonalRecords(
    timesReached2048: timesReached2048 ?? this.timesReached2048,
    timesReached4096: timesReached4096 ?? this.timesReached4096,
    timesReached8192: timesReached8192 ?? this.timesReached8192,
    firstReached2048At: firstReached2048At == _sentinel
        ? this.firstReached2048At
        : firstReached2048At as DateTime?,
    firstReached4096At: firstReached4096At == _sentinel
        ? this.firstReached4096At
        : firstReached4096At as DateTime?,
    firstReached8192At: firstReached8192At == _sentinel
        ? this.firstReached8192At
        : firstReached8192At as DateTime?,
    rewardCollected4096: rewardCollected4096 ?? this.rewardCollected4096,
    rewardCollected8192: rewardCollected8192 ?? this.rewardCollected8192,
    highestLevelEver: highestLevelEver ?? this.highestLevelEver,
    bestTimeMs2048: bestTimeMs2048 ?? this.bestTimeMs2048,  // NOVO
  );
}
```

- [ ] **Step 1.4: Atualizar o Hive adapter**

Em `lib/data/models/personal_records_hive_adapter.dart`, adicionar leitura/escrita do novo campo. O campo `highestLevelEver` já usa `numFields > 0` (capturado no início — todos os registros existentes têm esse campo). Para `bestTimeMs2048`, usar `reader.availableBytes > 0` capturado **após** ler `highestLevelEver`:

```dart
@override
PersonalRecords read(BinaryReader reader) {
  final numFields = reader.availableBytes;
  final timesReached2048 = reader.readInt();
  final timesReached4096 = reader.readInt();
  final timesReached8192 = reader.readInt();
  final has2048At = reader.readBool();
  final firstReached2048At = has2048At
      ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
      : null;
  final has4096At = reader.readBool();
  final firstReached4096At = has4096At
      ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
      : null;
  final has8192At = reader.readBool();
  final firstReached8192At = has8192At
      ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
      : null;
  final rewardCollected4096 = reader.readBool();
  final rewardCollected8192 = reader.readBool();
  final highestLevelEver = numFields > 0 ? reader.readInt() : 0;
  // Campo novo — verificar bytes restantes APÓS ler highestLevelEver
  final bestTimeMs2048 = reader.availableBytes > 0 ? reader.readInt() : 0;
  return PersonalRecords(
    timesReached2048: timesReached2048,
    timesReached4096: timesReached4096,
    timesReached8192: timesReached8192,
    firstReached2048At: firstReached2048At,
    firstReached4096At: firstReached4096At,
    firstReached8192At: firstReached8192At,
    rewardCollected4096: rewardCollected4096,
    rewardCollected8192: rewardCollected8192,
    highestLevelEver: highestLevelEver,
    bestTimeMs2048: bestTimeMs2048,
  );
}

@override
void write(BinaryWriter writer, PersonalRecords obj) {
  writer.writeInt(obj.timesReached2048);
  writer.writeInt(obj.timesReached4096);
  writer.writeInt(obj.timesReached8192);
  writer.writeBool(obj.firstReached2048At != null);
  if (obj.firstReached2048At != null) writer.writeInt(obj.firstReached2048At!.millisecondsSinceEpoch);
  writer.writeBool(obj.firstReached4096At != null);
  if (obj.firstReached4096At != null) writer.writeInt(obj.firstReached4096At!.millisecondsSinceEpoch);
  writer.writeBool(obj.firstReached8192At != null);
  if (obj.firstReached8192At != null) writer.writeInt(obj.firstReached8192At!.millisecondsSinceEpoch);
  writer.writeBool(obj.rewardCollected4096);
  writer.writeBool(obj.rewardCollected8192);
  writer.writeInt(obj.highestLevelEver);
  writer.writeInt(obj.bestTimeMs2048); // NOVO
}
```

- [ ] **Step 1.5: Adicionar `updateBestTime2048` ao notifier**

Em `lib/presentation/controllers/personal_records_notifier.dart`, adicionar após `updateHighestLevel`:

```dart
/// Atualiza o melhor tempo para atingir 2048.
/// Só salva se [timeMs] for melhor que o anterior (ou se for o primeiro).
/// Retorna true se o recorde foi quebrado.
Future<bool> updateBestTime2048(int timeMs) async {
  if (timeMs <= 0) return false;
  final isNewRecord = state.bestTimeMs2048 == 0 || timeMs < state.bestTimeMs2048;
  if (isNewRecord) {
    state = state.copyWith(bestTimeMs2048: timeMs);
    await _save();
  }
  return isNewRecord;
}
```

- [ ] **Step 1.6: Rodar testes**

```bash
flutter test test/domain/personal_records_test.dart --no-pub
```
Esperado: All tests passed

- [ ] **Step 1.7: Garantir que testes existentes continuam passando**

```bash
flutter test test/domain/personal_records_notifier_test.dart --no-pub
```
Esperado: All tests passed

- [ ] **Step 1.8: Commit**

```bash
git add lib/data/models/personal_records.dart \
        lib/data/models/personal_records_hive_adapter.dart \
        lib/presentation/controllers/personal_records_notifier.dart \
        test/domain/personal_records_test.dart
git commit -m "feat: add bestTimeMs2048 to PersonalRecords for personal record detection"
```

---

## Task 2 — `WeeklyRewardResult`: nova tabela de prêmios

**Files:**
- Modify: `lib/domain/ranking/weekly_reward_result.dart`
- Modify: `test/ranking/weekly_reward_test.dart`

- [ ] **Step 2.1: Atualizar os testes primeiro**

Substituir todo o conteúdo de `test/ranking/weekly_reward_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/ranking/weekly_reward_result.dart';

void main() {
  group('WeeklyRewardResult.forPosition', () {
    test('1º → 10 vidas + 10 desfazer + 10 bomba3', () {
      final r = WeeklyRewardResult.forPosition(1, weekId: '2026-W19');
      expect(r.lives, 10);
      expect(r.undo1, 10);
      expect(r.bomb3, 10);
      expect(r.bomb2, 0);
      expect(r.hasReward, true);
    });

    test('2º → 5 vidas + 5 desfazer + 5 bomba3', () {
      final r = WeeklyRewardResult.forPosition(2, weekId: '2026-W19');
      expect(r.lives, 5);
      expect(r.undo1, 5);
      expect(r.bomb3, 5);
      expect(r.bomb2, 0);
    });

    test('3º → 3 vidas + 3 desfazer + 3 bomba3', () {
      final r = WeeklyRewardResult.forPosition(3, weekId: '2026-W19');
      expect(r.lives, 3);
      expect(r.undo1, 3);
      expect(r.bomb3, 3);
      expect(r.bomb2, 0);
    });

    test('4º → 3 vidas + 0 desfazer + 3 bomba3', () {
      final r = WeeklyRewardResult.forPosition(4, weekId: '2026-W19');
      expect(r.lives, 3);
      expect(r.undo1, 0);
      expect(r.bomb3, 3);
      expect(r.bomb2, 0);
    });

    test('5º → 3 vidas + 0 desfazer + 3 bomba3', () {
      final r = WeeklyRewardResult.forPosition(5, weekId: '2026-W19');
      expect(r.lives, 3);
      expect(r.undo1, 0);
      expect(r.bomb3, 3);
    });

    test('6º → 3 vidas + 0 desfazer + 3 bomba3', () {
      final r = WeeklyRewardResult.forPosition(6, weekId: '2026-W19');
      expect(r.lives, 3);
      expect(r.undo1, 0);
      expect(r.bomb3, 3);
    });

    test('7º → 3 vidas + 3 desfazer + 0 bomba', () {
      final r = WeeklyRewardResult.forPosition(7, weekId: '2026-W19');
      expect(r.lives, 3);
      expect(r.undo1, 3);
      expect(r.bomb3, 0);
      expect(r.bomb2, 0);
    });

    test('8º → 3 vidas + 3 desfazer + 0 bomba', () {
      final r = WeeklyRewardResult.forPosition(8, weekId: '2026-W19');
      expect(r.lives, 3);
      expect(r.undo1, 3);
      expect(r.bomb3, 0);
    });

    test('9º → 3 vidas + 3 desfazer + 0 bomba', () {
      final r = WeeklyRewardResult.forPosition(9, weekId: '2026-W19');
      expect(r.lives, 3);
      expect(r.undo1, 3);
      expect(r.bomb3, 0);
    });

    test('10º → 3 vidas + 0 desfazer + 0 bomba', () {
      final r = WeeklyRewardResult.forPosition(10, weekId: '2026-W19');
      expect(r.lives, 3);
      expect(r.undo1, 0);
      expect(r.bomb3, 0);
      expect(r.hasReward, true);
    });

    test('11º → sem recompensa', () {
      final r = WeeklyRewardResult.forPosition(11, weekId: '2026-W19');
      expect(r.hasReward, false);
    });

    test('50º → sem recompensa', () {
      final r = WeeklyRewardResult.forPosition(50, weekId: '2026-W19');
      expect(r.hasReward, false);
    });
  });
}
```

- [ ] **Step 2.2: Rodar para confirmar falha**

```bash
flutter test test/ranking/weekly_reward_test.dart --no-pub
```
Esperado: FAIL (valores diferentes dos atuais)

- [ ] **Step 2.3: Atualizar `forPosition()` em `weekly_reward_result.dart`**

Substituir o método `forPosition` completo:

```dart
factory WeeklyRewardResult.forPosition(int position, {String weekId = 'unknown'}) {
  if (position == 1) {
    return WeeklyRewardResult(
      position: position, weekId: weekId,
      lives: 10, undo1: 10, bomb3: 10,
    );
  } else if (position == 2) {
    return WeeklyRewardResult(
      position: position, weekId: weekId,
      lives: 5, undo1: 5, bomb3: 5,
    );
  } else if (position == 3) {
    return WeeklyRewardResult(
      position: position, weekId: weekId,
      lives: 3, undo1: 3, bomb3: 3,
    );
  } else if (position >= 4 && position <= 6) {
    return WeeklyRewardResult(
      position: position, weekId: weekId,
      lives: 3, bomb3: 3,
    );
  } else if (position >= 7 && position <= 9) {
    return WeeklyRewardResult(
      position: position, weekId: weekId,
      lives: 3, undo1: 3,
    );
  } else if (position == 10) {
    return WeeklyRewardResult(
      position: position, weekId: weekId,
      lives: 3,
    );
  } else {
    return WeeklyRewardResult(position: position, weekId: weekId);
  }
}
```

- [ ] **Step 2.4: Rodar testes**

```bash
flutter test test/ranking/weekly_reward_test.dart --no-pub
```
Esperado: All tests passed

- [ ] **Step 2.5: Commit**

```bash
git add lib/domain/ranking/weekly_reward_result.dart \
        test/ranking/weekly_reward_test.dart
git commit -m "feat: update weekly ranking reward table (positions 1-10)"
```

---

## Task 3 — Auditoria de flavors: Fake* exclusivo para `tst`

**Files:**
- Modify: `lib/core/providers/ranking_provider.dart`
- Modify: `lib/domain/invites/invite_service.dart`
- Modify: `lib/domain/shop/iap_service.dart`
- Modify: `lib/data/repositories/iap_startup_service.dart`

- [ ] **Step 3.1: Corrigir `rankingRepositoryProvider`**

Em `lib/core/providers/ranking_provider.dart`, a condição atual é:
```dart
if (kDebugMode || flavor != 'prd') return FakeRankingService();
```

Substituir o provider completo:

```dart
final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  if (flavor == 'tst') return FakeRankingService();

  final profile = ref.watch(authControllerProvider);
  if (profile == null) return FakeRankingService();

  return FirestoreRankingRepository(userId: profile.userId);
});
```

- [ ] **Step 3.2: Corrigir `inviteServiceProvider`**

Em `lib/domain/invites/invite_service.dart`, a condição atual é:
```dart
if (flavor == 'prd') { ... return FirestoreInviteRepository(...); }
return FakeInviteService();
```

Substituir:

```dart
final inviteServiceProvider = Provider<InviteService>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  if (flavor == 'tst') return FakeInviteService();

  final profile = ref.watch(authControllerProvider);
  if (profile == null) {
    throw StateError(
      'inviteServiceProvider acessado sem usuário logado. '
      'A UI deve checar authControllerProvider antes de usar convites.',
    );
  }
  return FirestoreInviteRepository(
    userId: profile.userId,
    displayName: profile.displayName,
  );
});
```

- [ ] **Step 3.3: Corrigir `iapServiceProvider` e `iapStartupServiceProvider`**

Em `lib/domain/shop/iap_service.dart`, a condição atual é:
```dart
if (flavor == 'prd' || (flavor == 'tst' && useRealIap)) {
```

Substituir para incluir `dev`:

```dart
if (flavor == 'prd' || flavor == 'dev' || (flavor == 'tst' && useRealIap)) {
```

Em `lib/data/repositories/iap_startup_service.dart`, aplicar o mesmo padrão:
```dart
if (flavor == 'prd' || flavor == 'dev' || (flavor == 'tst' && useRealIap)) {
```

- [ ] **Step 3.4: Verificar que os testes existentes usam overrides corretos**

```bash
flutter test test/domain/auth/auth_controller_test.dart \
             test/presentation/home_screen_test.dart \
             test/presentation/profile_screen_test.dart \
             --no-pub
```
Esperado: All tests passed (os testes já usam overrides explícitos de providers, não dependem do flavor)

- [ ] **Step 3.5: Commit**

```bash
git add lib/core/providers/ranking_provider.dart \
        lib/domain/invites/invite_service.dart \
        lib/domain/shop/iap_service.dart \
        lib/data/repositories/iap_startup_service.dart
git commit -m "fix: Fake* providers exclusivos para flavor tst (dev usa serviços reais)"
```

---

## Task 4 — Invite reward: atualizar recompensa do convidador + `pendingLives`

O convidador está em outro dispositivo — inventory (bomb3, undo1) pode ser entregue via Firestore (synced por `_mergeRemoteInventory`). Vidas precisam de um mecanismo `pendingLives` creditado em `syncProfile()`.

**Files:**
- Modify: `lib/data/repositories/firestore_invite_repository.dart`
- Modify: `lib/data/repositories/firebase_sync_engine.dart`

- [ ] **Step 4.1: Atualizar reward do convidador em `completeInviteReward`**

Em `lib/data/repositories/firestore_invite_repository.dart`, dentro da transação, substituir o bloco "Deliver reward to inviter (Firestore — remote)":

```dart
// Deliver reward to inviter: 1 vida (pendingLives) + 1 bomb3 + 1 undo1
final inviterRef = _firestore.collection('users').doc(inviterId);
tx.set(inviterRef, {
  'inventory': {
    'bomb3': FieldValue.increment(1),
    'undo1': FieldValue.increment(1),
  },
  'pendingLives': FieldValue.increment(1),
}, SetOptions(merge: true));
```

- [ ] **Step 4.2: Creditar `pendingLives` em `syncProfile()`**

Em `lib/data/repositories/firebase_sync_engine.dart`, dentro de `syncProfile()`, após `_remoteDisplayName = data['displayName']`, adicionar:

```dart
// Creditar vidas pendentes (reward de convite para o convidador)
final pendingLives = (data['pendingLives'] as num?)?.toInt() ?? 0;
if (pendingLives > 0) {
  await _creditPendingLives(pendingLives);
}
```

E adicionar o método privado:

```dart
Future<void> _creditPendingLives(int amount) async {
  if (_userId == null) return;
  try {
    // Creditar localmente
    final livesBox = await Hive.openBox<dynamic>('lives');
    // Usar raw map pois LivesState pode não estar importado aqui
    // — escritura direta do campo 'lives' no objeto existente
    // (pattern já usado em _deliverLocalReward de firestore_invite_repository)
    // Zerar pendingLives no Firestore atomicamente
    await _firestore.collection('users').doc(_userId).update({
      'pendingLives': 0,
    });
    // Adicionar vidas via Hive diretamente
    final box = await Hive.openBox<dynamic>('lives');
    final existing = box.get('state');
    if (existing != null) {
      // LivesState é um objeto Hive — manipulamos via dynamic cast
      // O campo 'lives' é incrementado com clamp(0, 15)
      // Nota: imports de LivesState aqui criariam dependência circular.
      // Usar o mesmo padrão do firestore_invite_repository:
      // abrir box 'lives' e fazer put com copyWith
    }
  } catch (_) {
    // Non-fatal — pendingLives permanece no Firestore para próxima sync
  }
}
```

**Nota de implementação:** Para evitar dependência circular (firebase_sync_engine → lives_state), adicionar import de `LivesState` e usar o mesmo padrão do `firestore_invite_repository._deliverLocalReward()`:

```dart
// Adicionar import no topo do firebase_sync_engine.dart:
import '../models/lives_state.dart';

// Implementação completa de _creditPendingLives:
Future<void> _creditPendingLives(int amount) async {
  if (_userId == null || amount <= 0) return;
  try {
    // 1. Zerar no Firestore (antes de creditar localmente — evita duplo crédito)
    await _firestore.collection('users').doc(_userId).update({
      'pendingLives': 0,
    });
    // 2. Creditar localmente
    final livesBox = await Hive.openBox<LivesState>('lives');
    final ls = livesBox.get('state') ?? LivesState.initial();
    await livesBox.put('state', ls.copyWith(lives: (ls.lives + amount).clamp(0, 15)));
  } catch (_) {
    // Non-fatal — pendingLives permanece > 0 no Firestore para tentar na próxima abertura
  }
}
```

- [ ] **Step 4.3: Rodar testes de invite existentes**

```bash
flutter test test/domain/invite_service_test.dart --no-pub
```
Esperado: All tests passed (FakeInviteService não é afetado)

- [ ] **Step 4.4: Commit**

```bash
git add lib/data/repositories/firestore_invite_repository.dart \
        lib/data/repositories/firebase_sync_engine.dart
git commit -m "feat: inviter receives 1 combo (vida+bomb3+undo1) when invitee plays first game"
```

---

## Task 5 — Ranking Global: adicionar `maxTile` como tiebreaker

**Files:**
- Modify: `lib/data/repositories/firestore_ranking_repository.dart`
- Modify: `lib/presentation/controllers/game_notifier.dart`

Firestore não suporta tiebreaker sem índice composto. Precisamos:
1. Salvar `maxTile` no documento de ranking
2. Criar índice composto: `bestTimeMs ASC, maxTile DESC`

**⚠️ Índice Firestore:** Adicionar ao `firestore.indexes.json` (ou criar via console). Enquanto o índice não existir, a query de `watchWeeklyTop(globalTime)` usará apenas `bestTimeMs`. O tiebreaker por `maxTile` só entra em vigor após deploy do índice.

- [ ] **Step 5.1: Passar `maxTile` ao `submitScore` em `game_notifier.dart`**

Localizar o bloco de submit no `game_notifier.dart`:

```dart
// Submit time only when player won (reached level 11 = 2048)
if (state.hasWon && state.elapsedMs > 0) {
  unawaited(
    rankingRepo.submitScore(
      RankingType.globalTime,
      state.elapsedMs,
      displayName: displayName,
    ),
  );
}
```

Alterar a assinatura da chamada (o repositório será atualizado no próximo passo):

```dart
if (state.hasWon && state.elapsedMs > 0) {
  unawaited(
    rankingRepo.submitScore(
      RankingType.globalTime,
      state.elapsedMs,
      displayName: displayName,
      maxTile: state.maxTile, // tiebreaker
    ),
  );
}
```

- [ ] **Step 5.2: Atualizar interface `RankingRepository`**

Em `lib/domain/ranking/ranking_repository.dart`:

```dart
Future<void> submitScore(RankingType type, int value, {String? displayName, int? maxTile});
```

- [ ] **Step 5.3: Atualizar `submitScore` em `FirestoreRankingRepository`**

Em `lib/data/repositories/firestore_ranking_repository.dart`, atualizar a assinatura e salvar `maxTile`:

```dart
@override
Future<void> submitScore(
  RankingType type,
  int value, {
  String? displayName,
  int? maxTile,
}) async {
  if (type == RankingType.legends4096Time ||
      type == RankingType.legends8192Count) {
    return;
  }

  final weekId = WeekId.fromUtc(DateTime.now().toUtc());
  final col = _weeklyCollection(weekId, type);
  final docRef = col.doc(userId);
  final snap = await docRef.get();

  if (!snap.exists) {
    final data = <String, dynamic>{
      'userId': userId,
      'displayName': displayName ?? userId,
      'submittedAt': FieldValue.serverTimestamp(),
    };
    if (type == RankingType.globalTime) {
      data['bestTimeMs'] = value;
      if (maxTile != null) data['maxTile'] = maxTile;
    } else {
      data['value'] = value;
    }
    await docRef.set(data);
  } else {
    final existing = snap.data()!;
    if (type == RankingType.globalTime) {
      final current = (existing['bestTimeMs'] as num?)?.toInt() ?? 0;
      if (value < current) {
        await docRef.update({
          'bestTimeMs': value,
          if (maxTile != null) 'maxTile': maxTile,
          'submittedAt': FieldValue.serverTimestamp(),
          if (displayName != null) 'displayName': displayName,
        });
      }
    } else {
      final current = (existing['value'] as num?)?.toInt() ?? 0;
      if (value > current) {
        await docRef.update({
          'value': value,
          'submittedAt': FieldValue.serverTimestamp(),
          if (displayName != null) 'displayName': displayName,
        });
      }
    }
  }
}
```

- [ ] **Step 5.4: Atualizar query para ordenar por `maxTile` como tiebreaker**

Em `_buildQuery`, para `globalTime`:

```dart
case RankingType.globalTime:
  return _weeklyCollection(
    weekId,
    type,
  ).orderBy('bestTimeMs', descending: false)
   .orderBy('maxTile', descending: true)
   .limit(50);
```

- [ ] **Step 5.5: Atualizar `FakeRankingService`**

Em `lib/data/repositories/fake_ranking_service.dart`, atualizar a assinatura de `submitScore`:

```dart
@override
Future<void> submitScore(RankingType type, int value, {String? displayName, int? maxTile}) async {}
```

- [ ] **Step 5.6: Verificar que `state.maxTile` existe no `GameState`**

```bash
grep -n "maxTile\|maxLevel" lib/data/models/game_state.dart | head -10
```

Se `GameState` tiver apenas `maxLevel` (nível 1–13) e não `maxTile` (valor 2–8192), calcular via `pow(2, maxLevel)`. Verificar e ajustar a chamada em Step 5.1 conforme necessário. O tile correspondente ao nível N é `2^N` (level 11 → 2048).

Se `maxTile` não existir, usar: `maxTile: state.maxLevel > 0 ? (1 << state.maxLevel) : null`

- [ ] **Step 5.7: Rodar testes**

```bash
flutter test test/domain/ --no-pub
```
Esperado: All tests passed

- [ ] **Step 5.8: Commit**

```bash
git add lib/domain/ranking/ranking_repository.dart \
        lib/data/repositories/firestore_ranking_repository.dart \
        lib/data/repositories/fake_ranking_service.dart \
        lib/presentation/controllers/game_notifier.dart
git commit -m "feat: add maxTile tiebreaker to global time ranking submission"
```

---

## Task 6 — `PostGameController` + `PostGameSummary`

**Files:**
- Create: `lib/presentation/controllers/post_game_controller.dart`
- Create: `test/presentation/controllers/post_game_controller_test.dart`

- [ ] **Step 6.1: Escrever testes que falham**

```dart
// test/presentation/controllers/post_game_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:capivara_2048/presentation/controllers/post_game_controller.dart';
import 'package:capivara_2048/presentation/controllers/personal_records_notifier.dart';
import 'package:capivara_2048/data/models/personal_records.dart';
import 'package:capivara_2048/domain/sync/sync_engine.dart';
import 'package:capivara_2048/presentation/controllers/auth_controller.dart';
import 'package:capivara_2048/domain/auth/auth_service.dart';
import 'package:capivara_2048/domain/ranking/ranking_repository.dart';
import 'package:capivara_2048/core/providers/ranking_provider.dart';

void main() {
  setUpAll(() async {
    Hive.init('/tmp/capivara_post_game_test');
  });
  tearDownAll(() async {
    await Hive.close();
  });

  ProviderContainer makeContainer({
    PersonalRecords initialRecords = const PersonalRecords(),
    FakeRankingService? ranking,
    bool loggedIn = false,
  }) {
    final fakeAuth = FakeAuthService(
      initialProfile: loggedIn ? null : null, // null = not logged in by default
    );
    return ProviderContainer(
      overrides: [
        personalRecordsProvider.overrideWith(() {
          final n = PersonalRecordsNotifier();
          // pre-load state
          return n;
        }),
        rankingRepositoryProvider.overrideWithValue(ranking ?? FakeRankingService()),
        authServiceProvider.overrideWithValue(fakeAuth),
        syncEngineProvider.overrideWithValue(FakeSyncEngine()),
        authControllerProvider.overrideWith(() => AuthController()),
      ],
    );
  }

  group('PostGameController — milestone 11 (2048)', () {
    test('estado inicial é null', () {
      final c = makeContainer();
      addTearDown(c.dispose);
      expect(c.read(postGameControllerProvider), isNull);
    });

    test('detecta recorde de tempo (primeiro 2048 — bestTimeMs2048 == 0)', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await c.read(postGameControllerProvider.notifier).onMilestone(
        milestone: 11,
        timeMs: 27000,
        maxLevel: 11,
        timesReached8192: 0,
      );

      final summary = c.read(postGameControllerProvider);
      expect(summary, isNotNull);
      expect(summary!.milestone, 11);
      expect(summary.timeMs, 27000);
      expect(summary.earnedCombo, true); // primeiro 2048 = recorde
    });

    test('detecta recorde de tempo (melhora tempo anterior)', () async {
      final c = ProviderContainer(
        overrides: [
          personalRecordsProvider.overrideWith(() => PersonalRecordsNotifier()),
          rankingRepositoryProvider.overrideWithValue(FakeRankingService()),
          authServiceProvider.overrideWithValue(FakeAuthService()),
          syncEngineProvider.overrideWithValue(FakeSyncEngine()),
          authControllerProvider.overrideWith(() => AuthController()),
        ],
      );
      addTearDown(c.dispose);
      // Simular recorde anterior de 30000ms
      await c.read(personalRecordsProvider.notifier).updateBestTime2048(30000);

      await c.read(postGameControllerProvider.notifier).onMilestone(
        milestone: 11,
        timeMs: 25000, // melhor que 30000
        maxLevel: 11,
        timesReached8192: 0,
      );

      final summary = c.read(postGameControllerProvider);
      expect(summary!.earnedCombo, true);
    });

    test('não detecta recorde quando tempo é pior', () async {
      final c = ProviderContainer(
        overrides: [
          personalRecordsProvider.overrideWith(() => PersonalRecordsNotifier()),
          rankingRepositoryProvider.overrideWithValue(FakeRankingService()),
          authServiceProvider.overrideWithValue(FakeAuthService()),
          syncEngineProvider.overrideWithValue(FakeSyncEngine()),
          authControllerProvider.overrideWith(() => AuthController()),
        ],
      );
      addTearDown(c.dispose);
      await c.read(personalRecordsProvider.notifier).updateBestTime2048(20000);

      await c.read(postGameControllerProvider.notifier).onMilestone(
        milestone: 11,
        timeMs: 25000, // pior que 20000
        maxLevel: 11,
        timesReached8192: 0,
      );

      final summary = c.read(postGameControllerProvider);
      expect(summary!.earnedCombo, false);
    });
  });

  group('PostGameController — milestone 12 (4096)', () {
    test('detecta recorde de tile (primeiro 4096)', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await c.read(postGameControllerProvider.notifier).onMilestone(
        milestone: 12,
        timeMs: 50000,
        maxLevel: 12,
        timesReached8192: 0,
      );

      final summary = c.read(postGameControllerProvider);
      expect(summary!.milestone, 12);
      expect(summary.timeMs, 50000);
      expect(summary.earnedCombo, true); // primeiro 4096 = recorde de tile
    });

    test('não detecta recorde de tile quando 4096 já foi atingido antes', () async {
      final c = ProviderContainer(
        overrides: [
          personalRecordsProvider.overrideWith(() => PersonalRecordsNotifier()),
          rankingRepositoryProvider.overrideWithValue(FakeRankingService()),
          authServiceProvider.overrideWithValue(FakeAuthService()),
          syncEngineProvider.overrideWithValue(FakeSyncEngine()),
          authControllerProvider.overrideWith(() => AuthController()),
        ],
      );
      addTearDown(c.dispose);
      // Simular que já atingiu 4096 antes (highestLevelEver = 12)
      await c.read(personalRecordsProvider.notifier).updateHighestLevel(12);

      await c.read(postGameControllerProvider.notifier).onMilestone(
        milestone: 12,
        timeMs: 50000,
        maxLevel: 12,
        timesReached8192: 0,
      );

      final summary = c.read(postGameControllerProvider);
      expect(summary!.earnedCombo, false);
    });
  });

  group('PostGameController — milestone 13 (8192)', () {
    test('emite timesReached8192 correto', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await c.read(postGameControllerProvider.notifier).onMilestone(
        milestone: 13,
        timeMs: 90000,
        maxLevel: 13,
        timesReached8192: 3,
      );

      final summary = c.read(postGameControllerProvider);
      expect(summary!.milestone, 13);
      expect(summary.timesReached8192, 3);
      expect(summary.earnedCombo, true); // primeiro 8192 = recorde de tile
    });
  });

  test('dismiss() limpa o estado', () async {
    final c = makeContainer();
    addTearDown(c.dispose);

    await c.read(postGameControllerProvider.notifier).onMilestone(
      milestone: 11,
      timeMs: 27000,
      maxLevel: 11,
      timesReached8192: 0,
    );
    expect(c.read(postGameControllerProvider), isNotNull);

    c.read(postGameControllerProvider.notifier).dismiss();
    expect(c.read(postGameControllerProvider), isNull);
  });
}
```

- [ ] **Step 6.2: Rodar para confirmar falha**

```bash
flutter test test/presentation/controllers/post_game_controller_test.dart --no-pub
```
Esperado: FAIL (arquivo não existe)

- [ ] **Step 6.3: Criar `PostGameSummary` e `PostGameController`**

```dart
// lib/presentation/controllers/post_game_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/ranking/ranking_repository.dart';
import '../../core/providers/ranking_provider.dart';
import '../../data/models/item_type.dart';
import '../controllers/auth_controller.dart';
import '../controllers/personal_records_notifier.dart';
import '../../domain/lives/lives_notifier.dart';
import '../../domain/inventory/inventory_notifier.dart';

class PostGameSummary {
  final int milestone;         // 11 = 2048, 12 = 4096, 13 = 8192
  final int? rankingPosition;  // só milestone 11; null se não logado ou erro
  final int timeMs;            // tempo até o milestone
  final int timesReached8192;  // só milestone 13
  final bool earnedCombo;      // true se combo de recorde foi concedido

  const PostGameSummary({
    required this.milestone,
    this.rankingPosition,
    required this.timeMs,
    this.timesReached8192 = 0,
    required this.earnedCombo,
  });
}

class PostGameController extends Notifier<PostGameSummary?> {
  @override
  PostGameSummary? build() => null;

  /// Chamado pelo GameScreen quando game_notifier emite pendingMilestone.
  /// [timesReached8192] deve ser lido de PersonalRecordsNotifier APÓS recordMilestone().
  Future<void> onMilestone({
    required int milestone,
    required int timeMs,
    required int maxLevel,
    required int timesReached8192,
  }) async {
    final records = ref.read(personalRecordsProvider);
    final isLoggedIn = ref.read(authControllerProvider) != null;

    // Detectar recorde pessoal
    bool earnedCombo = false;
    if (milestone == 11) {
      // Critério A: novo melhor tempo para 2048
      final isNewTime = await ref
          .read(personalRecordsProvider.notifier)
          .updateBestTime2048(timeMs);
      if (isNewTime) earnedCombo = true;
    }
    // Critério B: novo tile máximo histórico (qualquer milestone)
    if (maxLevel > records.highestLevelEver) {
      earnedCombo = true;
      // highestLevelEver é atualizado pelo game_notifier via updateHighestLevel()
    }

    // Conceder combo se houve recorde
    if (earnedCombo) {
      await _grantCombo();
    }

    // Consultar posição no ranking global (só milestone 11, logado)
    int? rankingPosition;
    if (milestone == 11 && isLoggedIn) {
      rankingPosition = await _fetchRankingPosition();
    }

    state = PostGameSummary(
      milestone: milestone,
      rankingPosition: rankingPosition,
      timeMs: timeMs,
      timesReached8192: timesReached8192,
      earnedCombo: earnedCombo,
    );
  }

  void dismiss() => state = null;

  Future<void> _grantCombo() async {
    try {
      await ref.read(livesNotifierProvider.notifier).addEarned(1);
      await ref.read(inventoryProvider.notifier).add(ItemType.bomb3, 1);
      await ref.read(inventoryProvider.notifier).add(ItemType.undo1, 1);
    } catch (_) {
      // Non-fatal
    }
  }

  Future<int?> _fetchRankingPosition() async {
    try {
      final entry = await ref
          .read(rankingRepositoryProvider)
          .getPlayerEntry(RankingType.globalTime)
          .timeout(const Duration(seconds: 5));
      return entry?.rank;
    } catch (_) {
      return null;
    }
  }
}

final postGameControllerProvider =
    NotifierProvider<PostGameController, PostGameSummary?>(
      PostGameController.new,
    );
```

**Providers confirmados:** `livesProvider` (em `lib/domain/lives/lives_notifier.dart`) e `inventoryProvider` (em `lib/domain/inventory/inventory_notifier.dart`). Substituir nos imports e chamadas conforme abaixo:

```dart
import '../../domain/lives/lives_notifier.dart';
import '../../domain/inventory/inventory_notifier.dart';

// uso:
await ref.read(livesProvider.notifier).addEarned(1);
await ref.read(inventoryProvider.notifier).add(ItemType.bomb3, 1);
await ref.read(inventoryProvider.notifier).add(ItemType.undo1, 1);
```

- [ ] **Step 6.4: Verificar nomes dos providers de lives e inventory**

```bash
grep -rn "final livesNotifierProvider\|final inventoryProvider\|NotifierProvider.*Lives\|NotifierProvider.*Inventory" lib --include="*.dart" | head -10
```

Ajustar os nomes no `post_game_controller.dart` conforme o output.

- [ ] **Step 6.5: Rodar testes**

```bash
flutter test test/presentation/controllers/post_game_controller_test.dart --no-pub
```
Esperado: All tests passed

- [ ] **Step 6.6: Commit**

```bash
git add lib/presentation/controllers/post_game_controller.dart \
        test/presentation/controllers/post_game_controller_test.dart
git commit -m "feat: PostGameController — detecta recordes, concede combo, consulta ranking"
```

---

## Task 7 — `MilestoneRankingDialog`

**Files:**
- Create: `lib/presentation/widgets/milestone_ranking_dialog.dart`
- Create: `test/presentation/widgets/milestone_ranking_dialog_test.dart`

- [ ] **Step 7.1: Escrever testes que falham**

```dart
// test/presentation/widgets/milestone_ranking_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/presentation/widgets/milestone_ranking_dialog.dart';
import 'package:capivara_2048/presentation/controllers/post_game_controller.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('MilestoneRankingDialog', () {
    testWidgets('milestone 11 com posição exibe ranking e tempo', (tester) async {
      const summary = PostGameSummary(
        milestone: 11,
        rankingPosition: 3,
        timeMs: 277000, // 4 min 37 s
        earnedCombo: false,
      );
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        return ElevatedButton(
          onPressed: () => MilestoneRankingDialog.show(ctx, summary),
          child: const Text('Open'),
        );
      })));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('🏆 Ranking Global'), findsOneWidget);
      expect(find.textContaining('3º'), findsOneWidget);
      expect(find.textContaining('04:37'), findsOneWidget);
      expect(find.text('Ver Ranking'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('milestone 11 sem posição (offline) omite linha de ranking', (tester) async {
      const summary = PostGameSummary(
        milestone: 11,
        rankingPosition: null,
        timeMs: 180000,
        earnedCombo: false,
      );
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        return ElevatedButton(
          onPressed: () => MilestoneRankingDialog.show(ctx, summary),
          child: const Text('Open'),
        );
      })));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('lugar'), findsNothing);
      expect(find.textContaining('03:00'), findsOneWidget);
    });

    testWidgets('milestone 12 exibe tempo e nome do animal', (tester) async {
      const summary = PostGameSummary(
        milestone: 12,
        timeMs: 734000, // 12 min 14 s
        earnedCombo: false,
      );
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        return ElevatedButton(
          onPressed: () => MilestoneRankingDialog.show(ctx, summary),
          child: const Text('Open'),
        );
      })));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Peixe-boi'), findsOneWidget);
      expect(find.textContaining('12:14'), findsOneWidget);
      expect(find.text('Ver Ranking'), findsNothing); // só no 2048
    });

    testWidgets('milestone 13 exibe contagem de vezes', (tester) async {
      const summary = PostGameSummary(
        milestone: 13,
        timeMs: 0,
        timesReached8192: 3,
        earnedCombo: false,
      );
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        return ElevatedButton(
          onPressed: () => MilestoneRankingDialog.show(ctx, summary),
          child: const Text('Open'),
        );
      })));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Jacaré'), findsOneWidget);
      expect(find.textContaining('3'), findsWidgets);
    });

    testWidgets('earnedCombo true exibe linha de recompensa', (tester) async {
      const summary = PostGameSummary(
        milestone: 11,
        rankingPosition: 5,
        timeMs: 120000,
        earnedCombo: true,
      );
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        return ElevatedButton(
          onPressed: () => MilestoneRankingDialog.show(ctx, summary),
          child: const Text('Open'),
        );
      })));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Recorde'), findsOneWidget);
      expect(find.textContaining('vida'), findsOneWidget);
    });

    testWidgets('earnedCombo false não exibe linha de recompensa', (tester) async {
      const summary = PostGameSummary(
        milestone: 11,
        rankingPosition: 5,
        timeMs: 120000,
        earnedCombo: false,
      );
      await tester.pumpWidget(wrap(Builder(builder: (ctx) {
        return ElevatedButton(
          onPressed: () => MilestoneRankingDialog.show(ctx, summary),
          child: const Text('Open'),
        );
      })));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Recorde'), findsNothing);
    });
  });
}
```

- [ ] **Step 7.2: Rodar para confirmar falha**

```bash
flutter test test/presentation/widgets/milestone_ranking_dialog_test.dart --no-pub
```
Esperado: FAIL

- [ ] **Step 7.3: Criar `MilestoneRankingDialog`**

```dart
// lib/presentation/widgets/milestone_ranking_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/post_game_controller.dart';

class MilestoneRankingDialog extends StatelessWidget {
  const MilestoneRankingDialog({
    super.key,
    required this.summary,
    this.onViewRanking,
    this.onDismiss,
  });

  final PostGameSummary summary;
  final VoidCallback? onViewRanking;
  final VoidCallback? onDismiss;

  static Future<void> show(
    BuildContext context,
    PostGameSummary summary, {
    VoidCallback? onViewRanking,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MilestoneRankingDialog(
        summary: summary,
        onViewRanking: onViewRanking,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  String _formatMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rem = s % 60;
    return '${m.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitle(),
            const SizedBox(height: 8),
            _buildBody(),
            if (summary.earnedCombo) ...[
              const Divider(height: 24),
              _buildComboReward(),
            ],
            const SizedBox(height: 20),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final (emoji, text) = switch (summary.milestone) {
      11 => ('🏆', 'Ranking Global'),
      12 => ('🌊', 'Peixe-boi atingido!'),
      13 => ('🐊', 'Jacaré atingido!'),
      _ => ('🎯', 'Marco atingido!'),
    };
    return Text(
      '$emoji $text',
      style: GoogleFonts.fredoka(
        fontSize: 22,
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBody() {
    if (summary.milestone == 11) {
      return Column(
        children: [
          if (summary.rankingPosition != null)
            Text(
              'Você está em ${summary.rankingPosition}º lugar!',
              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          Text(
            'Tempo: ${_formatMs(summary.timeMs)}',
            style: GoogleFonts.nunito(fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (summary.milestone == 12) {
      return Text(
        'Seu tempo: ${_formatMs(summary.timeMs)}',
        style: GoogleFonts.nunito(fontSize: 15),
        textAlign: TextAlign.center,
      );
    } else {
      return Text(
        'Você chegou aqui ${summary.timesReached8192} '
        '${summary.timesReached8192 == 1 ? 'vez' : 'vezes'}!',
        style: GoogleFonts.nunito(fontSize: 15),
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _buildComboReward() {
    return Column(
      children: [
        Text(
          '🎁 Recorde pessoal!',
          style: GoogleFonts.fredoka(
            fontSize: 16,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '+1 vida  •  +1 bomba  •  +1 desfazer',
          style: GoogleFonts.nunito(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final dismiss = onDismiss ?? () => Navigator.of(context).pop();
    if (summary.milestone == 11) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onViewRanking?.call();
              },
              child: Text('Ver Ranking', style: GoogleFonts.fredoka(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: dismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('Continuar', style: GoogleFonts.fredoka(fontSize: 16)),
            ),
          ),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: dismiss,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text('Continuar', style: GoogleFonts.fredoka(fontSize: 18)),
      ),
    );
  }
}
```

- [ ] **Step 7.4: Rodar testes**

```bash
flutter test test/presentation/widgets/milestone_ranking_dialog_test.dart --no-pub
```
Esperado: All tests passed

- [ ] **Step 7.5: Commit**

```bash
git add lib/presentation/widgets/milestone_ranking_dialog.dart \
        test/presentation/widgets/milestone_ranking_dialog_test.dart
git commit -m "feat: MilestoneRankingDialog para 2048/4096/8192 com variações de conteúdo"
```

---

## Task 8 — `RankingScreen`: adicionar aba Global

**Files:**
- Modify: `lib/presentation/screens/ranking_screen.dart`

- [ ] **Step 8.1: Alterar `DefaultTabController` de `length: 2` para `length: 3`**

Localizar:
```dart
DefaultTabController(
  length: 2,
```
Alterar para:
```dart
DefaultTabController(
  length: 3,
```

- [ ] **Step 8.2: Adicionar tab "Global" entre "Pessoal" e "Lendas"**

Localizar:
```dart
tabs: const [
  Tab(text: 'Pessoal'),
  Tab(text: 'Lendas'),
],
```
Alterar para:
```dart
tabs: const [
  Tab(text: 'Pessoal'),
  Tab(text: 'Global'),
  Tab(text: 'Lendas'),
],
```

- [ ] **Step 8.3: Adicionar `_GlobalRankingTab` no `TabBarView`**

Localizar:
```dart
body: const TabBarView(
  children: [_PersonalRankingTab(), _LegendsRankingTab()],
),
```
Alterar para:
```dart
body: const TabBarView(
  children: [_PersonalRankingTab(), _GlobalRankingTab(), _LegendsRankingTab()],
),
```

- [ ] **Step 8.4: Implementar `_GlobalRankingTab`**

Adicionar a classe ao final do arquivo `ranking_screen.dart`:

```dart
class _GlobalRankingTab extends ConsumerWidget {
  const _GlobalRankingTab();

  String _formatMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rem = s % 60;
    return '${m.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}';
  }

  String _timeUntilReset() {
    final now = DateTime.now().toUtc();
    final end = WeekId.weekEndsAt(now);
    final diff = end.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (diff.inDays >= 1) return '${diff.inDays}d ${h % 24}h';
    return '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authControllerProvider) != null;
    final entriesAsync = ref.watch(
      StreamProvider((_) => ref
          .read(rankingRepositoryProvider)
          .watchWeeklyTop(RankingType.globalTime)),
    );

    return Column(
      children: [
        ColoredBox(
          color: AppColors.primary.withValues(alpha: 0.85),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Reinício em ${_timeUntilReset()}',
                  style: GoogleFonts.fredoka(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        if (!isLoggedIn)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Entre na sua conta para ver e participar do Ranking Global.',
                  style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Erro ao carregar ranking.',
                    style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white)),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Forme o 2048 para entrar no ranking desta semana!',
                        style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: e.isLocalPlayer
                            ? AppColors.primary.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Text(
                          '${e.rank}º',
                          style: GoogleFonts.fredoka(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: e.rank <= 3 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        title: Text(
                          e.playerName,
                          style: GoogleFonts.fredoka(fontSize: 15, color: Colors.white),
                        ),
                        trailing: Text(
                          _formatMs(e.value),
                          style: GoogleFonts.fredoka(fontSize: 15, color: Colors.white70),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
```

**Nota:** Adicionar os imports necessários: `WeekId`, `RankingType`, `rankingRepositoryProvider`, `AppColors`, `GoogleFonts`, `authControllerProvider`. Verificar quais já existem no arquivo.

- [ ] **Step 8.5: Verificar imports e análise estática**

```bash
dart analyze lib/presentation/screens/ranking_screen.dart
```
Corrigir eventuais erros de import.

- [ ] **Step 8.6: Commit**

```bash
git add lib/presentation/screens/ranking_screen.dart
git commit -m "feat: add Global tab to RankingScreen (weekly time ranking)"
```

---

## Task 9 — `GameScreen`: acionar `PostGameController` no milestone

**Files:**
- Modify: `lib/presentation/screens/game/game_screen.dart`

O `GameScreen` já escuta `pendingMilestone` do `gameNotifier` para exibir o overlay de vitória. Precisamos também acionar o `PostGameController` quando o milestone é detectado.

- [ ] **Step 9.1: Localizar onde `pendingMilestone` é tratado**

```bash
grep -n "pendingMilestone\|milestone" lib/presentation/screens/game/game_screen.dart | head -20
```

- [ ] **Step 9.2: Adicionar `ref.listen` para o PostGameController**

Dentro do método `build` do `GameScreen` (ou do `ConsumerStatefulWidget` correspondente), adicionar após os listeners existentes:

```dart
// Escutar PostGameController para exibir dialogs de milestone
ref.listen<PostGameSummary?>(postGameControllerProvider, (previous, summary) {
  if (summary == null) return;
  MilestoneRankingDialog.show(
    context,
    summary,
    onViewRanking: () {
      // Navegar para RankingScreen, aba Global (índice 1)
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RankingScreen(initialTab: 1)),
      );
    },
  ).then((_) {
    if (context.mounted) {
      ref.read(postGameControllerProvider.notifier).dismiss();
    }
  });
});
```

- [ ] **Step 9.3: Acionar `PostGameController.onMilestone()` quando milestone é detectado**

Localizar onde o `game_notifier` emite `pendingMilestone` (provavelmente um listener existente que exibe o overlay). Após o overlay ser apresentado (ou no mesmo listener), chamar o PostGameController:

```dart
ref.listen<GameState>(gameNotifierProvider, (previous, current) {
  // Lógica existente de overlay...

  // Novo: acionar PostGameController quando milestone muda de null para não-null
  if (previous?.pendingMilestone == null && current.pendingMilestone != null) {
    final milestone = current.pendingMilestone!;
    final records = ref.read(personalRecordsProvider);
    ref.read(postGameControllerProvider.notifier).onMilestone(
      milestone: milestone,
      timeMs: switch (milestone) {
        11 => current.bestTimeMs2048 ?? current.elapsedMs,
        12 => current.bestTimeMs4096 ?? current.elapsedMs,
        _ => current.elapsedMs,
      },
      maxLevel: current.maxLevel,
      timesReached8192: records.timesReached8192,
    );
  }
});
```

**Campos confirmados no `GameState`:** `pendingMilestone` (int?), `bestTimeMs2048` (int? — capturado ao atingir nível 11), `bestTimeMs4096` (int? — nível 12), `maxLevel` (int, sem `maxTile`). Para o tiebreaker usar `1 << current.maxLevel` (level 11 → 2048, level 12 → 4096, etc.).

- [ ] **Step 9.4: Adicionar `initialTab` ao `RankingScreen` (se necessário)**

Se `RankingScreen` não aceitar `initialTab`, adicionar o parâmetro:

```dart
class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key, this.initialTab = 0});
  final int initialTab;
  // ...
  // No DefaultTabController:
  DefaultTabController(
    length: 3,
    initialIndex: initialTab,
    // ...
  )
}
```

- [ ] **Step 9.5: Verificar análise estática**

```bash
dart analyze lib/presentation/screens/game/game_screen.dart
```

- [ ] **Step 9.6: Rodar testes da game screen**

```bash
flutter test test/presentation/game_screen_211_test.dart --no-pub
```
Esperado: All tests passed

- [ ] **Step 9.7: Commit**

```bash
git add lib/presentation/screens/game/game_screen.dart \
        lib/presentation/screens/ranking_screen.dart
git commit -m "feat: wire PostGameController to GameScreen milestone events"
```

---

## Task 10 — README: atualizar tabela de builds e roadmap

**Files:**
- Modify: `README.md`

- [ ] **Step 10.1: Atualizar tabela de builds**

Localizar a tabela de builds e substituir:

```markdown
| Comando | Flavor | Serviços | Uso |
|---------|--------|----------|-----|
| `flutter run --dart-define=FLAVOR=dev` | dev | Reais (Firebase dev / sandbox) | Desenvolvimento local |
| `flutter build apk --dart-define=FLAVOR=tst` | tst | Fake (sem Firebase) | QA — testes sem lojas |
| `flutter build apk --dart-define=FLAVOR=tst --dart-define=USE_REAL_IAP=true` | tst | IAP Real (sandbox) | QA com Play Store sandbox |
| `flutter build apk --dart-define=FLAVOR=prd` | prd | Reais (produção) | Release |
```

- [ ] **Step 10.2: Adicionar Fase 4.3 ao roadmap**

Após a linha de Fase 4.2 (ou 4B/4C/gaps/4.1/4.1.1/4.2), adicionar:

```markdown
- **Fase 4.3** — Ranking Global, Recompensas e Auditoria de Flavors
  - Aba Global no Ranking (tempo até 2048, reinício semanal)
  - Dialogs pós-milestone: posição no ranking (2048), tempo (4096), contagem (8192)
  - Recompensas por recorde pessoal (combo: vida + bomba3 + desfazer)
  - Recompensas por convite (convidador recebe combo quando convidado joga 1ª partida)
  - Tabela de prêmios semanais revisada (top 10)
  - Fake* providers exclusivos para flavor `tst`
```

- [ ] **Step 10.3: Commit**

```bash
git add README.md
git commit -m "docs: update README builds table and roadmap for Fase 4.3"
```

---

## Task 11 — Verificação final e atualização de AGENTS.md

- [ ] **Step 11.1: Rodar suite completa de testes (excluindo goldens)**

```bash
flutter test --no-pub --exclude-tags golden
```
Esperado: sem regressões nas tasks existentes; novos testes passando

- [ ] **Step 11.2: Análise estática global**

```bash
dart analyze lib/
```
Esperado: No issues found

- [ ] **Step 11.3: Atualizar AGENTS.md**

Atualizar a linha de fase atual:
```
Fase atual: **Fase 4.3 em andamento — Ranking Global, Recompensas e Auditoria de Flavors**
```

E adicionar a linha `4.3` na tabela de fases:
```
| 4.3       | Ranking Global (aba + dialogs pós-milestone), recompensas por recorde pessoal/convite, tabela semanal revisada, flavor audit |
```

- [ ] **Step 11.4: Commit final**

```bash
git add AGENTS.md
git commit -m "chore: mark Fase 4.3 as in-progress in AGENTS.md"
git push
```
