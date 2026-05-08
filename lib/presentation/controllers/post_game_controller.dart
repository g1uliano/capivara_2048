import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/item_type.dart';
import '../../domain/lives/lives_notifier.dart';
import '../../domain/inventory/inventory_notifier.dart';
import '../../domain/ranking/ranking_repository.dart';
import '../../core/providers/ranking_provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/personal_records_notifier.dart';

class PostGameSummary {
  final int milestone; // 11 = 2048, 12 = 4096, 13 = 8192
  final int? rankingPosition; // only for milestone 11; null if not logged in or error
  final int timeMs; // time to reach the milestone
  final int timesReached8192; // only for milestone 13
  final bool earnedCombo; // true if a personal record combo was granted

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

  /// Called by GameScreen when game_notifier emits pendingMilestone.
  /// [timesReached8192] must be read from PersonalRecordsNotifier AFTER
  /// recordMilestone() has been called.
  Future<void> onMilestone({
    required int milestone,
    required int timeMs,
    required int maxLevel,
    required int timesReached8192,
  }) async {
    final records = ref.read(personalRecordsProvider);
    final isLoggedIn = ref.read(authControllerProvider) != null;

    bool earnedCombo = false;

    if (milestone == 11) {
      // Criterion A: new personal best time to 2048
      final isNewTime = await ref
          .read(personalRecordsProvider.notifier)
          .updateBestTime2048(timeMs);
      if (isNewTime) earnedCombo = true;
    }

    // Criterion B: new highest tile ever (any milestone)
    if (maxLevel > records.highestLevelEver) {
      earnedCombo = true;
      // Note: highestLevelEver is updated by game_notifier via updateHighestLevel()
    }

    if (earnedCombo) {
      await _grantCombo();
    }

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
      await ref.read(livesProvider.notifier).addEarned(1);
      await ref.read(inventoryProvider.notifier).add(ItemType.bomb3, 1);
      await ref.read(inventoryProvider.notifier).add(ItemType.undo1, 1);
    } catch (_) {
      // Non-fatal — game must not be blocked by reward delivery failure
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
