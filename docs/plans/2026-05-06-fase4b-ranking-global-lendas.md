# Fase 4B — Ranking Global Semanal + Ranking Lendas

> **For agentic workers:** Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task.

**Data:** 2026-05-06  
**Versão alvo:** v1.4.1  
**Status:** Aguardando execução  
**Pré-requisito:** Fase 4A concluída (v1.4.0) — Firebase, Auth e SyncEngine operacionais.

---

## Escopo

| Sub-entrega | Nome                   | Dependências |
| ----------- | ---------------------- | ------------ |
| B           | Ranking Global Semanal | 4A ✅        |
| C           | Ranking Lendas         | 4A ✅        |

---

## Mapa de arquivos

### Criados

| Arquivo                                                   | Responsabilidade                                    |
| --------------------------------------------------------- | --------------------------------------------------- |
| `lib/domain/ranking/week_id.dart`                         | Cálculo determinístico do `weekId` (Dart puro)      |
| `lib/domain/ranking/weekly_reward_result.dart`            | Model imutável para resultado de recompensa semanal |
| `lib/data/repositories/firestore_ranking_repository.dart` | Implementação Firestore de `RankingRepository`      |
| `lib/presentation/widgets/weekly_reward_modal.dart`       | Modal exibido ao receber recompensa semanal         |
| `lib/presentation/controllers/ranking_controller.dart`    | Riverpod notifier para gerenciar estado do ranking  |
| `test/ranking/week_id_test.dart`                          | Testes unitários do cálculo do weekId               |
| `test/ranking/weekly_reward_test.dart`                    | Testes unitários da tabela de recompensas           |
| `test/presentation/weekly_reward_modal_test.dart`         | Widget test do modal de recompensa                  |

### Modificados

| Arquivo                                           | Mudança                                                                                       |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `lib/domain/ranking/ranking_repository.dart`      | Adicionar `checkAndClaimWeeklyReward()`, `watchWeeklyTop()`, campo `userId` em `RankingEntry` |
| `lib/data/repositories/fake_ranking_service.dart` | Implementar novos métodos (mock no-op)                                                        |
| `lib/core/providers/ranking_provider.dart`        | Usar `FirestoreRankingRepository` no flavor `prd`                                             |
| `lib/presentation/controllers/game_notifier.dart` | Submeter score ao ranking no game over                                                        |
| `lib/data/repositories/firebase_sync_engine.dart` | Usar displayName real do auth no `_applyEvent` (legendReached)                                |

---

## Task 1: `weekId` utilitário (Dart puro)

**Files:**

- Create: `lib/domain/ranking/week_id.dart`
- Create: `test/ranking/week_id_test.dart`

- [ ] **Step 1: Escrever os testes primeiro**

```dart
// test/ranking/week_id_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/ranking/week_id.dart';

void main() {
  group('WeekId', () {
    test('sexta-feira 20h BRT → mesmo weekId da semana corrente', () {
      // Sábado 21h UTC = sábado 18h BRT = reset
      // Sexta-feira 20h BRT = sexta 23h UTC → ainda na mesma semana
      final beforeReset = DateTime.utc(2025, 5, 9, 23, 0); // sexta 23h UTC
      final id = WeekId.fromUtc(beforeReset);
      expect(id, '2025-W19');
    });

    test('sábado 22h UTC → novo weekId (após reset 21h UTC)', () {
      final afterReset = DateTime.utc(2025, 5, 10, 22, 0); // sáb 22h UTC
      final id = WeekId.fromUtc(afterReset);
      expect(id, '2025-W20');
    });

    test('sábado 21h UTC exato → novo weekId', () {
      final exactReset = DateTime.utc(2025, 5, 10, 21, 0);
      final id = WeekId.fromUtc(exactReset);
      expect(id, '2025-W20');
    });

    test('dois devices no mesmo instante produzem o mesmo weekId', () {
      final now = DateTime.utc(2025, 5, 7, 12, 0);
      expect(WeekId.fromUtc(now), WeekId.fromUtc(now));
    });

    test('weekEndsAt retorna sábado 21h UTC da semana corrente', () {
      final wednesday = DateTime.utc(2025, 5, 7, 12, 0);
      final endsAt = WeekId.weekEndsAt(wednesday);
      expect(endsAt, DateTime.utc(2025, 5, 10, 21, 0)); // sáb 10/5 21h UTC
    });

    test('weekStartsAt retorna domingo 21h UTC da semana anterior', () {
      final wednesday = DateTime.utc(2025, 5, 7, 12, 0);
      final startsAt = WeekId.weekStartsAt(wednesday);
      expect(startsAt, DateTime.utc(2025, 5, 3, 21, 0)); // dom 3/5 21h UTC
    });
  });
}
```

- [ ] **Step 2: Rodar para confirmar falha**

```bash
flutter test test/ranking/week_id_test.dart
```

Esperado: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar**

```dart
// lib/domain/ranking/week_id.dart

/// Calcula o identificador de semana determinístico para o ranking global.
///
/// **Semana de ranking:** sábado 21h UTC → sábado seguinte 20:59h UTC.
/// (Equivale a sábado 18h BRT → sábado seguinte 17:59h BRT.)
///
/// Formato: "yyyy-Www" (ex: "2025-W19").
class WeekId {
  WeekId._();

  static const int _resetDayOfWeek = DateTime.saturday; // 6
  static const int _resetHourUtc = 21;

  /// Calcula o weekId para o instante [now] em UTC.
  static String fromUtc(DateTime now) {
    assert(now.isUtc, 'now must be UTC');
    final boundary = _currentPeriodStart(now);
    // Usamos o domingo imediatamente após o início do período para calcular
    // a semana ISO. Como o período começa no sábado 21h UTC, o domingo
    // seguinte (+3h) é um proxy seguro para a semana ISO.
    final anchor = boundary.add(const Duration(hours: 3));
    return _toIsoWeekString(anchor);
  }

  /// Retorna o instante UTC em que a semana corrente termina (sábado 21h UTC).
  static DateTime weekEndsAt(DateTime now) {
    assert(now.isUtc);
    return _nextResetAfterOrAt(now);
  }

  /// Retorna o instante UTC em que a semana corrente começou (sábado 21h UTC anterior).
  static DateTime weekStartsAt(DateTime now) {
    assert(now.isUtc);
    return _currentPeriodStart(now);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  static DateTime _currentPeriodStart(DateTime now) {
    var candidate = DateTime.utc(
      now.year,
      now.month,
      now.day,
      _resetHourUtc,
    );
    // Recua para o sábado 21h UTC mais recente (inclusive)
    while (candidate.weekday != _resetDayOfWeek ||
        candidate.isAfter(now)) {
      candidate = candidate.subtract(const Duration(days: 1));
    }
    return candidate;
  }

  static DateTime _nextResetAfterOrAt(DateTime now) {
    var candidate = DateTime.utc(
      now.year,
      now.month,
      now.day,
      _resetHourUtc,
    );
    while (candidate.weekday != _resetDayOfWeek ||
        candidate.isBefore(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  static String _toIsoWeekString(DateTime d) {
    // Algoritmo ISO 8601: semana começa na segunda-feira.
    final thursday = d.add(Duration(days: DateTime.thursday - d.weekday));
    final year = thursday.year;
    final jan1 = DateTime.utc(year, 1, 1);
    final jan1Weekday = jan1.weekday;
    final dayOfYear = d.difference(jan1).inDays + 1;
    final offset = (jan1Weekday <= DateTime.thursday) ? jan1Weekday - 1 : jan1Weekday - 8;
    final week = ((dayOfYear + offset - 1) ~/ 7) + 1;
    return '$year-W${week.toString().padLeft(2, '0')}';
  }
}
```

- [ ] **Step 4: Rodar testes**

```bash
flutter test test/ranking/week_id_test.dart
```

Esperado: todos passam.

- [ ] **Step 5: Suite completa**

```bash
flutter test --reporter=compact
```

Esperado: todos passam.

- [ ] **Step 6: Commit**

```bash
git add lib/domain/ranking/week_id.dart test/ranking/week_id_test.dart
git commit -m "feat(ranking): add WeekId utility with ISO week calculation and reset logic"
```

---

## Task 2: `WeeklyRewardResult` model + tabela de recompensas

**Files:**

- Create: `lib/domain/ranking/weekly_reward_result.dart`
- Create: `test/ranking/weekly_reward_test.dart`

- [ ] **Step 1: Escrever os testes**

```dart
// test/ranking/weekly_reward_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/ranking/weekly_reward_result.dart';

void main() {
  group('WeeklyRewardResult.forPosition', () {
    test('1º lugar recebe recompensa máxima', () {
      final r = WeeklyRewardResult.forPosition(1);
      expect(r.lives, 5);
      expect(r.bomb3, 3);
      expect(r.undo1, 3);
    });

    test('2º lugar recebe segunda recompensa', () {
      final r = WeeklyRewardResult.forPosition(2);
      expect(r.lives, 4);
      expect(r.bomb3, 2);
      expect(r.undo1, 2);
    });

    test('3º lugar recebe terceira recompensa', () {
      final r = WeeklyRewardResult.forPosition(3);
      expect(r.lives, 3);
      expect(r.bomb2, 2);
      expect(r.undo1, 1);
    });

    test('4º lugar recebe recompensa 4-10', () {
      final r = WeeklyRewardResult.forPosition(4);
      expect(r.lives, 2);
      expect(r.bomb2, 1);
    });

    test('10º lugar recebe recompensa 4-10', () {
      final r = WeeklyRewardResult.forPosition(10);
      expect(r.lives, 2);
      expect(r.bomb2, 1);
    });

    test('11º lugar recebe 1 vida', () {
      final r = WeeklyRewardResult.forPosition(11);
      expect(r.lives, 1);
      expect(r.bomb2, 0);
      expect(r.bomb3, 0);
    });

    test('50º lugar recebe 1 vida', () {
      final r = WeeklyRewardResult.forPosition(50);
      expect(r.lives, 1);
    });

    test('51º lugar não recebe nada', () {
      final r = WeeklyRewardResult.forPosition(51);
      expect(r.hasReward, isFalse);
    });

    test('posição 0 (não encontrado) não recebe nada', () {
      final r = WeeklyRewardResult.forPosition(0);
      expect(r.hasReward, isFalse);
    });
  });

  group('WeeklyRewardResult.hasReward', () {
    test('resultado vazio não tem recompensa', () {
      const r = WeeklyRewardResult(position: 100, weekId: 'x');
      expect(r.hasReward, isFalse);
    });

    test('resultado com vidas tem recompensa', () {
      const r = WeeklyRewardResult(position: 1, weekId: 'x', lives: 5);
      expect(r.hasReward, isTrue);
    });
  });
}
```

- [ ] **Step 2: Rodar para confirmar falha**

```bash
flutter test test/ranking/weekly_reward_test.dart
```

Esperado: FAIL.

- [ ] **Step 3: Implementar**

```dart
// lib/domain/ranking/weekly_reward_result.dart

/// Resultado da verificação de recompensa semanal.
///
/// Tabela de recompensas por posição:
/// | Posição | Vidas | Bomb3 | Bomb2 | Undo1 |
/// |---------|-------|-------|-------|-------|
/// | 1       | 5     | 3     | 0     | 3     |
/// | 2       | 4     | 2     | 0     | 2     |
/// | 3       | 3     | 0     | 2     | 1     |
/// | 4–10    | 2     | 0     | 1     | 0     |
/// | 11–50   | 1     | 0     | 0     | 0     |
/// | >50 / 0 | 0     | 0     | 0     | 0     |
class WeeklyRewardResult {
  final int position;
  final String weekId;
  final int lives;
  final int bomb3;
  final int bomb2;
  final int undo1;

  const WeeklyRewardResult({
    required this.position,
    required this.weekId,
    this.lives = 0,
    this.bomb3 = 0,
    this.bomb2 = 0,
    this.undo1 = 0,
  });

  bool get hasReward => lives > 0 || bomb3 > 0 || bomb2 > 0 || undo1 > 0;

  factory WeeklyRewardResult.forPosition(int position, {String weekId = ''}) {
    if (position <= 0 || position > 50) {
      return WeeklyRewardResult(position: position, weekId: weekId);
    }
    if (position == 1) {
      return WeeklyRewardResult(
        position: position,
        weekId: weekId,
        lives: 5,
        bomb3: 3,
        undo1: 3,
      );
    }
    if (position == 2) {
      return WeeklyRewardResult(
        position: position,
        weekId: weekId,
        lives: 4,
        bomb3: 2,
        undo1: 2,
      );
    }
    if (position == 3) {
      return WeeklyRewardResult(
        position: position,
        weekId: weekId,
        lives: 3,
        bomb2: 2,
        undo1: 1,
      );
    }
    if (position <= 10) {
      return WeeklyRewardResult(
        position: position,
        weekId: weekId,
        lives: 2,
        bomb2: 1,
      );
    }
    // 11–50
    return WeeklyRewardResult(
      position: position,
      weekId: weekId,
      lives: 1,
    );
  }

  WeeklyRewardResult copyWith({
    int? position,
    String? weekId,
    int? lives,
    int? bomb3,
    int? bomb2,
    int? undo1,
  }) =>
      WeeklyRewardResult(
        position: position ?? this.position,
        weekId: weekId ?? this.weekId,
        lives: lives ?? this.lives,
        bomb3: bomb3 ?? this.bomb3,
        bomb2: bomb2 ?? this.bomb2,
        undo1: undo1 ?? this.undo1,
      );
}
```

- [ ] **Step 4: Rodar testes**

```bash
flutter test test/ranking/weekly_reward_test.dart
```

Esperado: todos passam.

- [ ] **Step 5: Suite completa**

```bash
flutter test --reporter=compact
```

- [ ] **Step 6: Commit**

```bash
git add lib/domain/ranking/weekly_reward_result.dart test/ranking/weekly_reward_test.dart
git commit -m "feat(ranking): add WeeklyRewardResult model with reward table"
```

---

## Task 3: Atualizar `RankingRepository` e `FakeRankingService`

**Files:**

- Modify: `lib/domain/ranking/ranking_repository.dart`
- Modify: `lib/data/repositories/fake_ranking_service.dart`

- [ ] **Step 1: Atualizar `RankingRepository`**

Substituir conteúdo de `lib/domain/ranking/ranking_repository.dart`:

```dart
import 'weekly_reward_result.dart';

enum RankingType { globalTime, globalScore, legends4096Time, legends8192Count }

class RankingEntry {
  final int rank;
  final String playerName;
  final String? userId;
  final int value;
  final bool isLocalPlayer;

  const RankingEntry({
    required this.rank,
    required this.playerName,
    this.userId,
    required this.value,
    this.isLocalPlayer = false,
  });
}

abstract class RankingRepository {
  Future<List<RankingEntry>> getWeeklyTop(RankingType type);
  Future<RankingEntry?> getPlayerEntry(RankingType type);
  Future<void> submitScore(RankingType type, int value, {String? displayName});

  /// Verifica se há recompensa semanal a receber e a entrega.
  /// Retorna null se não há recompensa (jogador fora do top 50 ou já coletou).
  Future<WeeklyRewardResult?> checkAndClaimWeeklyReward(String weekId);

  /// Stream do top do ranking (atualização em tempo real).
  Stream<List<RankingEntry>> watchWeeklyTop(RankingType type);
}
```

- [ ] **Step 2: Atualizar `FakeRankingService`**

Adicionar os dois métodos novos ao `FakeRankingService`:

```dart
@override
Future<WeeklyRewardResult?> checkAndClaimWeeklyReward(String weekId) async {
  return null; // Sem recompensa no fake
}

@override
Stream<List<RankingEntry>> watchWeeklyTop(RankingType type) {
  return Stream.fromFuture(getWeeklyTop(type));
}
```

Também atualizar a assinatura de `submitScore` para incluir `displayName`:

```dart
@override
Future<void> submitScore(RankingType type, int value, {String? displayName}) async {}
```

Adicionar o import no topo:

```dart
import '../../domain/ranking/weekly_reward_result.dart';
```

- [ ] **Step 3: Verificar compilação**

```bash
flutter build apk --debug --dart-define=FLAVOR=dev 2>&1 | tail -5
```

Esperado: sem erros.

- [ ] **Step 4: Suite completa**

```bash
flutter test --reporter=compact
```

Esperado: todos passam.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/ranking/ranking_repository.dart lib/data/repositories/fake_ranking_service.dart
git commit -m "feat(ranking): extend RankingRepository with weekly reward and stream methods"
```

---

## Task 4: `FirestoreRankingRepository`

**Files:**

- Create: `lib/data/repositories/firestore_ranking_repository.dart`

- [ ] **Step 1: Implementar**

```dart
// lib/data/repositories/firestore_ranking_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/ranking/ranking_repository.dart';
import '../../domain/ranking/week_id.dart';
import '../../domain/ranking/weekly_reward_result.dart';
import '../models/inventory.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FirestoreRankingRepository implements RankingRepository {
  final FirebaseFirestore _firestore;
  final String userId;
  static const _rewardClaimedBox = 'ranking_rewards';

  FirestoreRankingRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────────────────────
  // Ranking Global Semanal
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<List<RankingEntry>> getWeeklyTop(RankingType type) async {
    final weekId = WeekId.fromUtc(DateTime.now().toUtc());
    final entries = await _getTopEntries(type, weekId, limit: 50);
    return _toRankingEntries(entries, type);
  }

  @override
  Stream<List<RankingEntry>> watchWeeklyTop(RankingType type) {
    final weekId = WeekId.fromUtc(DateTime.now().toUtc());
    final collection = _collectionFor(type, weekId);
    final query = type == RankingType.globalTime || type == RankingType.legends4096Time
        ? collection.orderBy('bestTimeMs').limit(50)
        : collection.orderBy('value', descending: true).limit(50);
    return query.snapshots().map((snap) {
      final entries = snap.docs.map((d) => d.data()).toList();
      return _toRankingEntries(entries, type);
    });
  }

  @override
  Future<RankingEntry?> getPlayerEntry(RankingType type) async {
    final weekId = WeekId.fromUtc(DateTime.now().toUtc());
    if (type == RankingType.legends8192Count) {
      // Lendas não têm weekId — lê do legendsRankings
      final doc = await _firestore
          .collection('legendsRankings/8192/entries')
          .doc(userId)
          .get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      final allEntries = await _getLegendsEntries(8192, limit: 200);
      final rank = allEntries.indexWhere((e) => e['userId'] == userId) + 1;
      return RankingEntry(
        rank: rank > 0 ? rank : 999,
        playerName: data['displayName'] as String? ?? 'Você',
        userId: userId,
        value: (data['timesReached'] as int?) ?? 0,
        isLocalPlayer: true,
      );
    }
    final doc = await _collectionFor(type, weekId).doc(userId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    final allEntries = await _getTopEntries(type, weekId, limit: 200);
    final rank = allEntries.indexWhere((e) => e['userId'] == userId) + 1;
    return RankingEntry(
      rank: rank > 0 ? rank : 999,
      playerName: data['displayName'] as String? ?? 'Você',
      userId: userId,
      value: _valueFrom(data, type),
      isLocalPlayer: true,
    );
  }

  @override
  Future<void> submitScore(RankingType type, int value,
      {String? displayName}) async {
    if (type == RankingType.legends8192Count) return; // Gerido via SyncEngine

    final weekId = WeekId.fromUtc(DateTime.now().toUtc());
    final collection = _collectionFor(type, weekId);
    final ref = collection.doc(userId);

    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'userId': userId,
        'displayName': displayName ?? 'Jogador',
        _fieldFor(type): value,
        'submittedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final existing = _valueFrom(snap.data()!, type);
      // Para tempo: menor é melhor; para score: maior é melhor
      final isBetter = (type == RankingType.globalTime ||
              type == RankingType.legends4096Time)
          ? value < existing
          : value > existing;
      if (isBetter) {
        await ref.update({
          _fieldFor(type): value,
          'submittedAt': FieldValue.serverTimestamp(),
          if (displayName != null) 'displayName': displayName,
        });
      }
    }
  }

  @override
  Future<WeeklyRewardResult?> checkAndClaimWeeklyReward(
      String weekId) async {
    // Verifica se já coletou
    final box = await Hive.openBox<String>(_rewardClaimedBox);
    if (box.get(weekId) != null) return null;

    // Busca entry do jogador na semana passada
    final previousWeekId = _previousWeekId(weekId);
    final collection = _collectionFor(RankingType.globalTime, previousWeekId);
    final allEntries = await _getTopEntries(
        RankingType.globalTime, previousWeekId,
        limit: 200);
    final rank = allEntries.indexWhere((e) => e['userId'] == userId) + 1;
    if (rank == 0) {
      // Também tenta por score
      final allScore = await _getTopEntries(
          RankingType.globalScore, previousWeekId,
          limit: 200);
      // Usa melhor posição entre tempo e score
      final rankScore = allScore.indexWhere((e) => e['userId'] == userId) + 1;
      final bestRank =
          rankScore > 0 ? (rank > 0 ? (rank < rankScore ? rank : rankScore) : rankScore) : rank;
      if (bestRank == 0) return null;
    }

    final reward = WeeklyRewardResult.forPosition(rank, weekId: previousWeekId);
    if (!reward.hasReward) return null;

    // Entrega os itens ao inventário local (Hive)
    await _deliverReward(reward);

    // Marca como coletado
    await box.put(weekId, 'claimed');

    return reward;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _collectionFor(
      RankingType type, String weekId) {
    switch (type) {
      case RankingType.globalTime:
        return _firestore.collection('rankings/$weekId/globalTime');
      case RankingType.globalScore:
        return _firestore.collection('rankings/$weekId/globalScore');
      case RankingType.legends4096Time:
        return _firestore.collection('legendsRankings/4096/entries');
      case RankingType.legends8192Count:
        return _firestore.collection('legendsRankings/8192/entries');
    }
  }

  String _fieldFor(RankingType type) {
    switch (type) {
      case RankingType.globalTime:
      case RankingType.legends4096Time:
        return 'bestTimeMs';
      case RankingType.globalScore:
        return 'value';
      case RankingType.legends8192Count:
        return 'timesReached';
    }
  }

  int _valueFrom(Map<String, dynamic> data, RankingType type) {
    final field = _fieldFor(type);
    return (data[field] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> _getTopEntries(
    RankingType type,
    String weekId, {
    required int limit,
  }) async {
    final collection = _collectionFor(type, weekId);
    final Query<Map<String, dynamic>> query;
    if (type == RankingType.globalTime ||
        type == RankingType.legends4096Time) {
      query = collection.orderBy('bestTimeMs').limit(limit);
    } else {
      query = collection.orderBy('value', descending: true).limit(limit);
    }
    final snap = await query.get();
    return snap.docs.map((d) => {...d.data(), 'userId': d.id}).toList();
  }

  Future<List<Map<String, dynamic>>> _getLegendsEntries(int level,
      {required int limit}) async {
    final snap = await _firestore
        .collection('legendsRankings/$level/entries')
        .orderBy('timesReached', descending: true)
        .orderBy('firstReachedAt')
        .limit(limit)
        .get();
    return snap.docs.map((d) => {...d.data(), 'userId': d.id}).toList();
  }

  List<RankingEntry> _toRankingEntries(
      List<Map<String, dynamic>> entries, RankingType type) {
    final result = <RankingEntry>[];
    int rank = 1;
    for (var i = 0; i < entries.length; i++) {
      if (i > 0) {
        final prev = _valueFrom(entries[i - 1], type);
        final cur = _valueFrom(entries[i], type);
        if (cur != prev) rank = i + 1;
      }
      final e = entries[i];
      result.add(RankingEntry(
        rank: rank,
        playerName: e['displayName'] as String? ?? 'Jogador',
        userId: e['userId'] as String?,
        value: _valueFrom(e, type),
        isLocalPlayer: e['userId'] == userId,
      ));
    }
    return result;
  }

  String _previousWeekId(String currentWeekId) {
    // currentWeekId formato "yyyy-Www" — subtrai 1 semana
    final now = DateTime.now().toUtc();
    final prevWeek = now.subtract(const Duration(days: 7));
    return WeekId.fromUtc(prevWeek);
  }

  Future<void> _deliverReward(WeeklyRewardResult reward) async {
    final box = await Hive.openBox<Inventory>('inventory');
    final current = box.get('inventory') ?? Inventory.empty();
    final updated = Inventory(
      bomb2: current.bomb2 + reward.bomb2,
      bomb3: current.bomb3 + reward.bomb3,
      undo1: current.undo1 + reward.undo1,
      undo3: current.undo3,
    );
    await box.put('inventory', updated);
    // Vidas são gerenciadas separadamente via LivesNotifier — usar Hive direto
    if (reward.lives > 0) {
      final livesBox = await Hive.openBox('lives');
      final currentLives = (livesBox.get('lives_count') as int?) ?? 3;
      final newLives = (currentLives + reward.lives).clamp(0, 15);
      await livesBox.put('lives_count', newLives);
    }
  }
}
```

- [ ] **Step 2: Verificar compilação**

```bash
flutter build apk --debug --dart-define=FLAVOR=dev 2>&1 | tail -5
```

Esperado: sem erros.

- [ ] **Step 3: Commit**

```bash
git add lib/data/repositories/firestore_ranking_repository.dart
git commit -m "feat(ranking): add FirestoreRankingRepository with weekly and legends support"
```

---

## Task 5: Atualizar `rankingRepositoryProvider`

**Files:**

- Modify: `lib/core/providers/ranking_provider.dart`

- [ ] **Step 1: Atualizar provider**

Substituir conteúdo de `lib/core/providers/ranking_provider.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/fake_ranking_service.dart';
import '../../data/repositories/firestore_ranking_repository.dart';
import '../../domain/ranking/ranking_repository.dart';
import '../presentation/controllers/auth_controller.dart';

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  if (kDebugMode || flavor != 'prd') return FakeRankingService();

  final profile = ref.watch(authControllerProvider);
  if (profile == null) return FakeRankingService();

  return FirestoreRankingRepository(userId: profile.userId);
});
```

> **Nota:** o import de `auth_controller.dart` requer ajuste de caminho relativo.
> O path correto é `../../presentation/controllers/auth_controller.dart`.

- [ ] **Step 2: Verificar compilação**

```bash
flutter build apk --debug --dart-define=FLAVOR=dev 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/providers/ranking_provider.dart
git commit -m "feat(ranking): wire FirestoreRankingRepository in prd flavor"
```

---

## Task 6: Submeter score no game over

**Files:**

- Modify: `lib/presentation/controllers/game_notifier.dart`

- [ ] **Step 1: Identificar onde adicionar**

No `game_notifier.dart`, localizar `_saveGameRecord()` (chamado em `confirmGameOver` e ao fim da partida).

- [ ] **Step 2: Adicionar submissão de ranking**

Após salvar o `GameRecord` em `_saveGameRecord()`, submeter ao ranking:

```dart
// No final de _saveGameRecord(), antes do fechamento
final rankingRepo = ref.read(rankingRepositoryProvider);
final authProfile = ref.read(authControllerProvider);
final displayName = authProfile?.displayName;

// Submete tempo se venceu (nivel 11+)
if (state.hasWon && state.elapsedMs > 0) {
  unawaited(rankingRepo.submitScore(
    RankingType.globalTime,
    state.elapsedMs,
    displayName: displayName,
  ));
}

// Submete score/número sempre
if (state.maxTileValue > 0) {
  unawaited(rankingRepo.submitScore(
    RankingType.globalScore,
    state.maxTileValue,
    displayName: displayName,
  ));
}
```

Adicionar imports necessários:

```dart
import '../../core/providers/ranking_provider.dart';
import '../../domain/ranking/ranking_repository.dart';
```

- [ ] **Step 3: Suite de testes**

```bash
flutter test --reporter=compact
```

Esperado: todos passam (rankingRepo é FakeRankingService em testes).

- [ ] **Step 4: Commit**

```bash
git add lib/presentation/controllers/game_notifier.dart
git commit -m "feat(ranking): submit score to ranking repository on game over"
```

---

## Task 7: `WeeklyRewardModal` widget

**Files:**

- Create: `lib/presentation/widgets/weekly_reward_modal.dart`
- Create: `test/presentation/weekly_reward_modal_test.dart`

- [ ] **Step 1: Escrever o teste**

```dart
// test/presentation/weekly_reward_modal_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/ranking/weekly_reward_result.dart';
import 'package:capivara_2048/presentation/widgets/weekly_reward_modal.dart';

Widget _wrap(WeeklyRewardResult reward) => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => WeeklyRewardModal(reward: reward),
        ),
      ),
    );

void main() {
  testWidgets('exibe posição e itens para 1º lugar', (tester) async {
    final reward = WeeklyRewardResult.forPosition(1, weekId: '2025-W19');
    await tester.pumpWidget(_wrap(reward));
    expect(find.textContaining('1'), findsWidgets);
    expect(find.textContaining('5'), findsWidgets); // 5 vidas
  });

  testWidgets('exibe mensagem de parabéns', (tester) async {
    final reward = WeeklyRewardResult.forPosition(3, weekId: '2025-W19');
    await tester.pumpWidget(_wrap(reward));
    expect(find.textContaining('Parabéns'), findsOneWidget);
  });

  testWidgets('botão de continuar presente', (tester) async {
    final reward = WeeklyRewardResult.forPosition(2, weekId: '2025-W19');
    await tester.pumpWidget(_wrap(reward));
    expect(find.textContaining('Continuar'), findsOneWidget);
  });

  testWidgets('tap em Continuar fecha o modal sem crash', (tester) async {
    bool closed = false;
    final reward = WeeklyRewardResult.forPosition(5, weekId: '2025-W19');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (ctx) => WeeklyRewardModal(
          reward: reward,
          onDismiss: () => closed = true,
        )),
      ),
    ));
    await tester.tap(find.textContaining('Continuar'));
    await tester.pump();
    expect(closed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Rodar para confirmar falha**

```bash
flutter test test/presentation/weekly_reward_modal_test.dart
```

- [ ] **Step 3: Implementar**

```dart
// lib/presentation/widgets/weekly_reward_modal.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/ranking/weekly_reward_result.dart';

class WeeklyRewardModal extends StatelessWidget {
  const WeeklyRewardModal({
    super.key,
    required this.reward,
    this.onDismiss,
  });

  final WeeklyRewardResult reward;
  final VoidCallback? onDismiss;

  static Future<void> show(BuildContext context, WeeklyRewardResult reward) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WeeklyRewardModal(
        reward: reward,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
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
            Text(
              '🏆 Recompensa Semanal!',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Parabéns! Você ficou em ${reward.position}º lugar!',
              style: GoogleFonts.nunito(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _RewardItems(reward: reward),
            const SizedBox(height, 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Continuar',
                  style: GoogleFonts.fredoka(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardItems extends StatelessWidget {
  const _RewardItems({required this.reward});
  final WeeklyRewardResult reward;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (reward.lives > 0) {
      items.add(_Item(emoji: '❤️', label: '${reward.lives} Vida${reward.lives > 1 ? 's' : ''}'));
    }
    if (reward.bomb3 > 0) {
      items.add(_Item(emoji: '🧨', label: '${reward.bomb3}× Bomba 3'));
    }
    if (reward.bomb2 > 0) {
      items.add(_Item(emoji: '💣', label: '${reward.bomb2}× Bomba 2'));
    }
    if (reward.undo1 > 0) {
      items.add(_Item(emoji: '↩️', label: '${reward.undo1}× Desfazer'));
    }
    return Column(children: items);
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.emoji, required this.label});
  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

> **Nota:** corrigir o typo `const SizedBox(height, 24)` → `const SizedBox(height: 24)` na implementação final.

- [ ] **Step 4: Rodar testes**

```bash
flutter test test/presentation/weekly_reward_modal_test.dart
```

Esperado: todos passam.

- [ ] **Step 5: Suite completa**

```bash
flutter test --reporter=compact
```

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/widgets/weekly_reward_modal.dart test/presentation/weekly_reward_modal_test.dart
git commit -m "feat(ui): add WeeklyRewardModal for weekly ranking rewards"
```

---

## Task 8: `RankingController` + check de recompensa no startup

**Files:**

- Create: `lib/presentation/controllers/ranking_controller.dart`

- [ ] **Step 1: Implementar**

```dart
// lib/presentation/controllers/ranking_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ranking_provider.dart';
import '../../domain/ranking/ranking_repository.dart';
import '../../domain/ranking/week_id.dart';
import '../../domain/ranking/weekly_reward_result.dart';
import 'auth_controller.dart';

class RankingController extends StateNotifier<AsyncValue<WeeklyRewardResult?>> {
  RankingController(this._repository) : super(const AsyncValue.data(null));

  final RankingRepository _repository;

  /// Verifica recompensa da semana anterior ao abrir o app.
  Future<WeeklyRewardResult?> checkWeeklyReward() async {
    state = const AsyncValue.loading();
    try {
      final currentWeekId = WeekId.fromUtc(DateTime.now().toUtc());
      final reward = await _repository.checkAndClaimWeeklyReward(currentWeekId);
      state = AsyncValue.data(reward);
      return reward;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void clearReward() => state = const AsyncValue.data(null);
}

final rankingControllerProvider =
    StateNotifierProvider<RankingController, AsyncValue<WeeklyRewardResult?>>(
  (ref) {
    final repo = ref.watch(rankingRepositoryProvider);
    return RankingController(repo);
  },
);
```

- [ ] **Step 2: Verificar compilação**

```bash
flutter build apk --debug --dart-define=FLAVOR=dev 2>&1 | tail -5
```

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/controllers/ranking_controller.dart
git commit -m "feat(ranking): add RankingController for weekly reward check"
```

---

## Task 9: Usar displayName real no `_applyEvent` (legendReached)

**Files:**

- Modify: `lib/data/repositories/firebase_sync_engine.dart`

O `_applyEvent` para `legendReached` usa `'displayName': 'Jogador'` hardcoded.
Injetar o `displayName` real do `PlayerProfile` via construtor.

- [ ] **Step 1: Adicionar `displayName` ao construtor**

Em `FirebaseSyncEngine`, adicionar campo e construtor:

```dart
final String? displayName;

FirebaseSyncEngine({this.displayName});
```

- [ ] **Step 2: Usar `displayName` no `_applyEvent`**

Onde está `'displayName': 'Jogador'`, substituir por:

```dart
'displayName': displayName ?? 'Jogador',
```

- [ ] **Step 3: Atualizar provider do SyncEngine**

No `lib/domain/sync/sync_engine.dart` (ou onde o provider Firebase é criado — ver `app.dart` ou main), passar `displayName` do perfil.

- [ ] **Step 4: Suite de testes**

```bash
flutter test --reporter=compact
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/firebase_sync_engine.dart
git commit -m "fix(sync): use real displayName in legendReached Firestore entry"
```

---

## Task 10: Release + documentação

- [ ] **Step 1: Rodar suite completa**

```bash
flutter test --reporter=compact
```

Esperado: todos passam.

- [ ] **Step 2: Build APK de teste**

```bash
flutter build apk --debug --dart-define=FLAVOR=dev 2>&1 | tail -5
```

- [ ] **Step 3: Atualizar `CHANGELOG.md`**

Adicionar entrada v1.4.1 com:

- Sub-B: Ranking Global Semanal com Firestore (globalTime + globalScore)
- Sub-C: Ranking Lendas persistido com displayName real
- `WeekId` utilitário com cálculo ISO 8601 + reset sábado 21h UTC
- `WeeklyRewardResult` com tabela de recompensas
- `FirestoreRankingRepository` (prd) + `FakeRankingService` atualizado
- `WeeklyRewardModal` widget
- `RankingController` para verificação de recompensa no startup
- Score submetido automaticamente ao ranking no game over

- [ ] **Step 4: Atualizar `AGENTS.md`**

Atualizar fase atual: `Fase 4B concluída (v1.4.1) — próximo: Fase 4C (Convites)`.

Adicionar na tabela:

```
| 4B ✅ | Ranking Global Semanal (Firestore) + Ranking Lendas persistido |
```

- [ ] **Step 5: Commit de release**

```bash
git add CHANGELOG.md AGENTS.md docs/plans/2026-05-06-fase4b-ranking-global-lendas.md
git commit -m "chore: release v1.4.1 — Fase 4B Ranking Global + Lendas"
```

---

## Critérios de aceite

### Sub-B — Ranking Global Semanal

- [ ] `weekId` calculado identicamente em dois devices com mesmo horário
- [ ] Score submetido no game over aparece na `RankingScreen` (flavor prd)
- [ ] `WeeklyRewardModal` exibido ao abrir o app após reset semanal simulado
- [ ] `rewardsDistributed` (Hive box) impede segunda entrega ao reabrir
- [ ] Jogador sem entry na semana não recebe modal de recompensa
- [ ] Todos os testes unitários de `WeekId` e `WeeklyRewardResult` passam

### Sub-C — Ranking Lendas

- [ ] `legendsRankings/4096/entries/{userId}` atualizado com `displayName` real
- [ ] `legendsRankings/8192/entries/{userId}` idem
- [ ] `timesReached` incrementado corretamente via PendingEvent
- [ ] `firstReachedAt` preservado em reinstalação (restaurado via SyncEngine)
- [ ] Todos os testes da suite passam sem modificação
