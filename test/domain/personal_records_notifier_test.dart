import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:capivara_2048/presentation/controllers/personal_records_notifier.dart';
import 'package:capivara_2048/data/models/personal_records.dart';
import 'package:capivara_2048/data/models/personal_records_hive_adapter.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(PersonalRecords.hiveTypeId)) {
      Hive.registerAdapter(PersonalRecordsHiveAdapter());
    }
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('personal_records');
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('PersonalRecordsNotifier', () {
    test('inicia com todos os contadores zerados', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(personalRecordsProvider.notifier).load();
      final state = container.read(personalRecordsProvider);
      expect(state.timesReached2048, 0);
      expect(state.timesReached4096, 0);
      expect(state.timesReached8192, 0);
    });

    test('recordMilestone(11) incrementa timesReached2048', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(personalRecordsProvider.notifier).load();
      await container.read(personalRecordsProvider.notifier)
          .recordMilestone(11, DateTime.now());
      expect(container.read(personalRecordsProvider).timesReached2048, 1);
    });

    test('recordMilestone(12) incrementa timesReached4096', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(personalRecordsProvider.notifier).load();
      await container.read(personalRecordsProvider.notifier)
          .recordMilestone(12, DateTime.now());
      expect(container.read(personalRecordsProvider).timesReached4096, 1);
    });

    test('recordMilestone(13) incrementa timesReached8192', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(personalRecordsProvider.notifier).load();
      await container.read(personalRecordsProvider.notifier)
          .recordMilestone(13, DateTime.now());
      expect(container.read(personalRecordsProvider).timesReached8192, 1);
    });

    test('firstReached4096At só é setado na primeira chamada', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(personalRecordsProvider.notifier).load();
      final notifier = container.read(personalRecordsProvider.notifier);
      final first = DateTime(2026, 5, 3, 10);
      final second = DateTime(2026, 5, 3, 11);
      await notifier.recordMilestone(12, first);
      await notifier.recordMilestone(12, second);
      expect(container.read(personalRecordsProvider).firstReached4096At, first);
    });

    test('isFirstTime(12) retorna true antes de recordMilestone', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(personalRecordsProvider.notifier).load();
      expect(container.read(personalRecordsProvider.notifier).isFirstTime(12), true);
    });

    test('isFirstTime(12) retorna false após recordMilestone', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(personalRecordsProvider.notifier).load();
      final notifier = container.read(personalRecordsProvider.notifier);
      await notifier.recordMilestone(12, DateTime.now());
      expect(notifier.isFirstTime(12), false);
    });

    test('markRewardCollected(12) seta flag rewardCollected4096', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(personalRecordsProvider.notifier).load();
      await container.read(personalRecordsProvider.notifier).markRewardCollected(12);
      expect(container.read(personalRecordsProvider).rewardCollected4096, true);
    });

    test('markRewardCollected(13) seta flag rewardCollected8192', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(personalRecordsProvider.notifier).load();
      await container.read(personalRecordsProvider.notifier).markRewardCollected(13);
      expect(container.read(personalRecordsProvider).rewardCollected8192, true);
    });
  });
}
