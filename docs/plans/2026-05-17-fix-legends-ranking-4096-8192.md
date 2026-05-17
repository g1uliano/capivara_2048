# Fix: Ranking Lendas não registra 4096/8192 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enfileirar `PendingEvent.legendReached` ao atingir milestones 4096/8192 para que o ranking Lendas seja atualizado.

**Architecture:** A detecção de milestone já existe em `game_notifier.dart`. O `firebase_sync_engine.dart` já sabe processar `PendingEvent.legendReached`. O único elo faltante é a chamada a `enqueuePendingEvent` no momento da detecção.

**Tech Stack:** Flutter/Dart, Riverpod, Hive (PendingEvent), Firebase Firestore (via SyncEngine)

---

## Root Cause

`_submitToRanking()` em `game_notifier.dart` envia apenas para `globalScore` e `globalTime`.
O ranking Lendas usa `PendingEvent.legendReached` → `SyncEngine.enqueuePendingEvent` → `firebase_sync_engine._applyEvent` para atualizar `legendsRankings/{level}/entries` no Firestore.
**Esse evento nunca é enfileirado** quando milestone 12 (4096) ou 13 (8192) é detectado.

## Files Modified

- `lib/presentation/controllers/game_notifier.dart` — adicionar imports + enqueue do evento

---

## Tasks

### Task 1: Aplicar o fix em `game_notifier.dart`

- [ ] Abrir `lib/presentation/controllers/game_notifier.dart`
- [ ] Adicionar imports no topo (após os imports existentes de `sync_engine.dart`):
  ```dart
  import '../../data/models/pending_event.dart';
  import 'package:uuid/uuid.dart';
  ```
- [ ] No bloco de detecção de milestone (loop `for (final milestone in [11, 12, 13])`), após `_submitToRanking();`, adicionar:
  ```dart
  // Enfileirar evento para ranking Lendas (4096 / 8192)
  if (milestone == 12 || milestone == 13) {
    final tileValue = 1 << milestone; // 4096 ou 8192
    unawaited(
      ref.read(syncEngineProvider).enqueuePendingEvent(
        PendingEvent.legendReached(
          id: const Uuid().v4(),
          level: tileValue,
          occurredAt: DateTime.now(),
        ),
      ),
    );
  }
  ```
- [ ] Rodar `flutter analyze` e verificar que não há erros novos

### Task 2: Commit

- [ ] `git add lib/presentation/controllers/game_notifier.dart`
- [ ] `git commit -m "fix: enfileirar PendingEvent.legendReached ao atingir 4096/8192"`
