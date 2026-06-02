// lib/presentation/controllers/game_notifier.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ranking_provider.dart';
import '../../data/models/game_record.dart';
import '../../data/models/game_state.dart';
import '../../data/models/item_type.dart';
import '../../data/models/tile.dart';
import '../../data/repositories/game_record_repository.dart';
import '../../domain/game_engine/bomb_mode.dart';
import '../../domain/game_engine/direction.dart';
import '../../domain/game_engine/game_engine.dart';
import '../../domain/inventory/inventory_notifier.dart';
import '../../domain/ranking/ranking_repository.dart';
import '../../data/models/pending_event.dart';
import '../../domain/invites/invite_service.dart';
import '../../domain/sync/sync_engine.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/haptic_utils.dart';
import '../../domain/audio/audio_service.dart';
import '../../presentation/controllers/settings_notifier.dart';
import '../controllers/auth_controller.dart';
import '../controllers/personal_records_notifier.dart';

class GameNotifier extends Notifier<GameState> {
  static const _savedGameKey = 'game.current_state';

  late GameEngine _engine;
  Timer? _timer;
  Timer? _firestoreSaveTimer;
  bool _timerStarted = false;
  List<(int, int)> _bombSelection = [];
  ItemType? _pendingBombItem;
  // Called on confirm to deduct the item; null-safe so tests don't need Hive.
  void Function(ItemType)? _consumeItem;
  final Set<int> _reachedMilestones = {};

  @override
  GameState build() {
    _engine = ref.read(gameEngineProvider);
    _consumeItem = (type) => ref.read(inventoryProvider.notifier).consume(type);
    ref.onDispose(() {
      _timer?.cancel();
      _firestoreSaveTimer?.cancel();
    });

    // Try to restore an in-progress game from SharedPreferences
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final saved = prefs.getString(_savedGameKey);
      if (saved != null) {
        final gs = GameState.fromJson(
          jsonDecode(saved) as Map<String, dynamic>,
        );
        if (gs.score > 0 && !gs.isGameOver && !gs.hasWon) {
          _populateMilestonesFromMaxLevel(gs.maxLevel);
          return gs;
        }
      }
    } catch (_) {
      // Fall through to fresh game on any parse error
    }

    return _engine.newGame();
  }

  void _populateMilestonesFromMaxLevel(int maxLevel) {
    if (maxLevel >= 11) _reachedMilestones.add(11);
    if (maxLevel >= 12) _reachedMilestones.add(12);
    if (maxLevel >= 13) _reachedMilestones.add(13);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!state.isPaused && !state.isGameOver) {
        state = state.copyWith(elapsedMs: state.elapsedMs + 100);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void onSwipe(Direction dir) {
    if (state.isGameOver || state.isPaused) return;
    final before = state;
    final after = _engine.move(state, dir);
    // Detect if anything changed on the board (a valid move)
    final boardChanged =
        after.score != before.score ||
        after.isGameOver != before.isGameOver ||
        after.hasWon != before.hasWon ||
        _boardDiffers(before.board, after.board);
    // Set isAwaitingGameOverResolution only on first transition to game-over
    final justLost = !before.isGameOver && after.isGameOver && !after.hasWon;
    state = justLost
        ? after.copyWith(isAwaitingGameOverResolution: true)
        : after.isGameOver
        ? after
        : after.copyWith(isContinuingWithItem: false);

    // Haptic feedback graduado (respects settings toggle)
    if (after.score > before.score) {
      maybeHaptic(
        () => ref.read(settingsProvider).hapticEnabled,
        intensity: HapticIntensity.light,
      );
      ref.read(audioServiceProvider).playEffect(
        TilesMerged(_inferMergeLevel(after)),
      );
    }
    if (after.isGameOver && !before.isGameOver) {
      maybeHaptic(
        () => ref.read(settingsProvider).hapticEnabled,
        intensity: HapticIntensity.heavy,
      );
    }

    // Atualizar nível mais alto já alcançado (persistido para coleção)
    if (state.maxLevel > before.maxLevel) {
      maybeHaptic(
        () => ref.read(settingsProvider).hapticEnabled,
        intensity: HapticIntensity.heavy,
      );
      ref.read(audioServiceProvider).playEffect(
        AnimalReached(state.maxLevel),
      );
      unawaited(
        ref
            .read(personalRecordsProvider.notifier)
            .updateHighestLevel(state.maxLevel),
      );
    }

    // Detectar novos marcos
    for (final milestone in [11, 12, 13]) {
      if (!_reachedMilestones.contains(milestone) &&
          state.maxLevel >= milestone &&
          !state.hasWon &&
          state.pendingMilestone == null) {
        _handleMilestoneReached(milestone);
        break;
      }
    }

    if (boardChanged) {
      if (!_timerStarted) {
        _timerStarted = true;
        _startTimer();
      } else if (_timer == null && !state.isGameOver && !state.hasWon) {
        // Timer was stopped at game over; player continued with an item — restart.
        _startTimer();
      }
      if (state.isGameOver || state.hasWon || state.pendingMilestone != null) {
        _stopTimer();
      }
      if (!state.isGameOver && !state.hasWon) {
        _saveLocalGame();
        _scheduleFirestoreSave();
      }
    }
  }

  bool _boardDiffers(List<List<dynamic>> a, List<List<dynamic>> b) {
    for (int r = 0; r < a.length; r++) {
      for (int c = 0; c < a[r].length; c++) {
        if (a[r][c]?.level != b[r][c]?.level) return true;
      }
    }
    return false;
  }

  void pause() {
    if (state.isGameOver || state.hasWon || state.pendingMilestone != null) {
      return;
    }
    _stopTimer();
    _firestoreSaveTimer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    if (!state.isPaused) return;
    state = state.copyWith(isPaused: false);
    if (_timerStarted && !state.isGameOver && !state.hasWon) _startTimer();
  }

  bool undo(int steps) {
    final stack = state.undoStack;
    if (stack.length < steps) return false;
    final idx = steps - 1;
    final remainingStack = stack.skip(idx + 1).toList();
    state = stack[idx].copyWith(undoStack: remainingStack);
    ref.read(audioServiceProvider).playEffect(
      steps == 1 ? const Undo1Used() : const Undo3Used(),
    );
    return true;
  }

  void restart() {
    _clearSavedGame();
    _reachedMilestones.clear();
    _stopTimer();
    _timerStarted = false;
    final fresh = _engine.newGame();
    state = fresh.copyWith(elapsedMs: 0, isPaused: false);
  }

  /// Resets local game state for logout without touching Firestore currentGame.
  /// Firestore currentGame is preserved so the game can be restored on re-login.
  /// Unlike restart(), does NOT call _clearSavedGame() (which would set currentGame=null).
  void resetForLogout() {
    _firestoreSaveTimer?.cancel();
    _firestoreSaveTimer = null;
    _reachedMilestones.clear();
    _stopTimer();
    _timerStarted = false;
    final fresh = _engine.newGame();
    state = fresh.copyWith(elapsedMs: 0, isPaused: false);
  }

  // ignore: invalid_use_of_protected_member
  @visibleForTesting
  void debugSetState(GameState s) {
    _stopTimer();
    _firestoreSaveTimer?.cancel();
    state = s;
  }

  @visibleForTesting
  void debugJumpToLevel(int targetLevel) {
    if (!kDebugMode) return;

    final rng = Random();
    const uuid = Uuid();
    Tile makeTile(int level, int row, int col) =>
        Tile(id: uuid.v4(), level: level, row: row, col: col);
    int rowOf(int i) => i ~/ 4;
    int colOf(int i) => i % 4;

    // Shuffle all 16 positions so tile placement varies each call
    final positions = List.generate(16, (i) => i)..shuffle(rng);

    final board = List.generate(4, (_) => List<Tile?>.filled(4, null));

    // Two merge-ready tiles at targetLevel-1 (merging them reaches targetLevel)
    final mergeLevel = max(1, targetLevel - 1);
    for (int i = 0; i < 2; i++) {
      final r = rowOf(positions[i]);
      final c = colOf(positions[i]);
      board[r][c] = makeTile(mergeLevel, r, c);
    }

    // 3–5 filler tiles with randomised low levels for board/score variety
    final maxFillerLevel = max(1, targetLevel - 3);
    final fillerCount = 3 + rng.nextInt(3);
    for (int i = 2; i < 2 + fillerCount; i++) {
      final r = rowOf(positions[i]);
      final c = colOf(positions[i]);
      board[r][c] = makeTile(1 + rng.nextInt(maxFillerLevel), r, c);
    }

    final score = board
        .expand((row) => row)
        .whereType<Tile>()
        .fold(0, (sum, t) => sum + (1 << t.level));

    _stopTimer();
    _firestoreSaveTimer?.cancel();
    _timerStarted = true;
    _reachedMilestones.clear();
    _populateMilestonesFromMaxLevel(targetLevel - 1);
    state = GameState(
      board: board,
      score: score,
      highScore: max(state.highScore, score),
      maxLevel: targetLevel - 1,
      hasWon: false,
      isGameOver: false,
      isPaused: false,
      elapsedMs: state.elapsedMs,
    );
  }

  void setAwaitingResolution(bool value) {
    state = state.copyWith(isAwaitingGameOverResolution: value);
  }

  /// Confirma game over definitivo (quando jogador desiste/encerra) e salva o record.
  void confirmGameOver() {
    _clearSavedGame();
    unawaited(_saveGameRecord());
    setAwaitingResolution(false);
  }

  void startContinueWithItem() {
    state = state.copyWith(
      isAwaitingGameOverResolution: false,
      isContinuingWithItem: true,
    );
  }

  void cancelContinueWithItem() {
    state = state.copyWith(
      isContinuingWithItem: false,
      isAwaitingGameOverResolution: false,
    );
  }

  void enterBombMode(BombMode mode, ItemType itemType) {
    _bombSelection = [];
    _pendingBombItem = itemType;
    state = state.copyWith(bombMode: mode, selectedBombTiles: const []);
  }

  void selectBombTile(int row, int col) {
    final mode = state.bombMode;
    if (mode == null) return;
    final maxTiles = mode == BombMode.bomb2 ? 2 : 3;

    final pos = (row, col);
    if (_bombSelection.contains(pos)) {
      _bombSelection = _bombSelection.where((p) => p != pos).toList();
    } else if (_bombSelection.length < maxTiles) {
      _bombSelection = [..._bombSelection, pos];
      if (_bombSelection.length == maxTiles) {
        confirmBomb();
        return;
      }
    }
    // Emit updated selection so overlay rebuilds on intermediate selections
    state = state.copyWith(
      selectedBombTiles: List.unmodifiable(_bombSelection),
    );
  }

  void confirmBomb() {
    final mode = state.bombMode;
    if (mode == null || _bombSelection.isEmpty) {
      cancelBomb();
      return;
    }
    final newState = GameEngine.removeTiles(state, _bombSelection);
    _bombSelection = [];
    final item = _pendingBombItem;
    _pendingBombItem = null;
    if (item != null) _consumeItem?.call(item);
    if (mode == BombMode.bomb2) {
      ref.read(audioServiceProvider).playEffect(const Bomb2xUsed());
    } else {
      ref.read(audioServiceProvider).playEffect(const Bomb3xUsed());
    }
    state = newState.copyWith(
      bombMode: null,
      selectedBombTiles: const [],
      isContinuingWithItem: false,
      isAwaitingGameOverResolution: false,
    );
  }

  void cancelBomb() {
    final wasContinuing = state.isContinuingWithItem;
    _bombSelection = [];
    _pendingBombItem = null;
    if (wasContinuing) {
      // Return to the "use item?" overlay so the player can pick a different item.
      state = state.copyWith(
        bombMode: null,
        selectedBombTiles: const [],
        isContinuingWithItem: false,
        isAwaitingGameOverResolution: true,
      );
    } else {
      state = state.copyWith(bombMode: null, selectedBombTiles: const []);
    }
  }

  List<(int, int)> get bombSelection => List.unmodifiable(_bombSelection);

  /// Wired up by build(); can be overridden in tests via setConsumeCallback.
  void setConsumeCallback(void Function(ItemType) callback) {
    _consumeItem = callback;
  }

  void _handleMilestoneReached(int milestone) {
    _reachedMilestones.add(milestone);
    final captured = state.elapsedMs;
    GameState updated = state;
    if (milestone == 11) {
      updated = updated.copyWith(
        pendingMilestone: milestone,
        bestTimeMs2048: captured,
      );
    } else if (milestone == 12) {
      updated = updated.copyWith(
        pendingMilestone: milestone,
        bestTimeMs4096: captured,
      );
    } else {
      updated = updated.copyWith(pendingMilestone: milestone);
    }
    state = updated;
    maybeHaptic(
      () => ref.read(settingsProvider).hapticEnabled,
      intensity: HapticIntensity.medium,
    );
    if (milestone == 12 || milestone == 13) {
      final tileValue = 1 << milestone;
      unawaited(
        ref.read(syncEngineProvider).enqueuePendingEvent(
          PendingEvent.legendReached(
            id: const Uuid().v4(),
            level: tileValue,
            occurredAt: DateTime.now(),
            timeMs: milestone == 12 ? captured : null,
          ),
        ),
      );
    }
    unawaited(
      ref
          .read(personalRecordsProvider.notifier)
          .recordMilestone(milestone, DateTime.now()),
    );
  }

  void dismissMilestone() {
    state = state.copyWith(pendingMilestone: null);
    if (_timerStarted && !state.isGameOver && !state.hasWon) _startTimer();
  }

  Future<void> endGame() async {
    _clearSavedGame();
    _stopTimer();
    state = state.copyWith(hasWon: true, pendingMilestone: null);
    await _saveGameRecord();
  }

  Future<void> _saveGameRecord() async {
    try {
      final record = GameRecord(
        playedAt: DateTime.now(),
        elapsedMs: state.elapsedMs,
        score: state.score,
        maxLevel: state.maxLevel,
      );
      await ref.read(gameRecordRepositoryProvider).add(record);

      // Sync to Firestore if logged in
      final authProfileForSync = ref.read(authControllerProvider);
      if (authProfileForSync != null) {
        unawaited(ref.read(syncEngineProvider).syncGameRecord(record));
      }

      // Complete pending invite reward on first game
      try {
        final allRecords = ref.read(gameRecordRepositoryProvider).all;
        if (allRecords.length == 1) {
          final inviteService = ref.read(inviteServiceProvider);
          final authProfile = ref.read(authControllerProvider);
          if (authProfile != null) {
            unawaited(
              inviteService.completeInviteReward(
                inviteeId: authProfile.userId,
                inviteeDisplayName: authProfile.displayName,
              ),
            );
          }
        }
      } catch (_) {}
    } catch (_) {
      // Não bloquear o jogo se o save falhar
    }

    await _submitToRanking();
  }

  Future<void> _submitToRanking() async {
    try {
      final rankingRepo = ref.read(rankingRepositoryProvider);
      final authProfile = ref.read(authControllerProvider);
      final displayName = authProfile?.displayName;

      if (state.score > 0) {
        unawaited(
          rankingRepo.submitScore(
            RankingType.globalScore,
            state.score,
            displayName: displayName,
          ),
        );
      }

      // Submit time when player reached 2048 — covers both hasWon and milestone paths.
      // Awaited so that the local Firestore cache is updated before endGame() returns,
      // ensuring the ranking screen opens with fresh data (not stale T1 from first win).
      if ((state.hasWon || state.maxLevel >= 11) && state.elapsedMs > 0) {
        final maxTile = state.maxLevel > 0 ? (1 << state.maxLevel) : null;
        await rankingRepo.submitScore(
          RankingType.globalTime,
          state.elapsedMs,
          displayName: displayName,
          maxTile: maxTile,
        );
      }
    } catch (_) {
      // Never block the game for ranking errors
    }
  }

  /// Submits score/time and drains pending events (legend entries) so the
  /// ranking screen shows fresh Firestore data when opened. Does NOT end the
  /// game — the milestone dialog stays alive for Continuar/Encerrar.
  Future<void> submitForRanking() async {
    await _submitToRanking();
    try {
      await ref.read(syncEngineProvider).drainPendingEvents();
    } catch (_) {}
  }

  @visibleForTesting
  void setStateForTest(GameState s) => state = s;

  void _saveLocalGame() {
    if (state.isGameOver || state.hasWon) return;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setString(_savedGameKey, jsonEncode(state.toJson()));
    } catch (_) {
      // Non-fatal
    }
  }

  void _scheduleFirestoreSave() {
    _firestoreSaveTimer?.cancel();
    _firestoreSaveTimer = Timer(const Duration(seconds: 10), () {
      if (state.isGameOver || state.hasWon) return;
      final authProfile = ref.read(authControllerProvider);
      if (authProfile != null) {
        unawaited(ref.read(syncEngineProvider).syncCurrentGame(state));
      }
    });
  }

  void _clearSavedGame() {
    _firestoreSaveTimer?.cancel();
    _firestoreSaveTimer = null;
    try {
      ref.read(sharedPreferencesProvider).remove(_savedGameKey);
    } catch (_) {
      // Non-fatal
    }
    final authProfile = ref.read(authControllerProvider);
    if (authProfile != null) {
      unawaited(ref.read(syncEngineProvider).syncCurrentGame(null));
    }
  }

  Future<void> loadSavedGame() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final saved = prefs.getString(_savedGameKey);
      if (saved == null) return;
      final gs = GameState.fromJson(jsonDecode(saved) as Map<String, dynamic>);
      if (gs.isGameOver || gs.hasWon || gs.score <= 0) return;
      _populateMilestonesFromMaxLevel(gs.maxLevel);
      _timerStarted = false;
      _stopTimer();
      state = gs; // isPaused: true set by fromJson
    } catch (_) {
      // Non-fatal — leave current state unchanged
    }
  }

  int _inferMergeLevel(GameState s) {
    int maxLevel = 1;
    for (final row in s.board) {
      for (final tile in row) {
        if (tile != null && tile.level > maxLevel) maxLevel = tile.level;
      }
    }
    return maxLevel.clamp(1, 11);
  }
}

final gameEngineProvider = Provider<GameEngine>((ref) => GameEngine());

final gameProvider = NotifierProvider<GameNotifier, GameState>(
  GameNotifier.new,
);
