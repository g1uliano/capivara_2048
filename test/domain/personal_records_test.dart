import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/data/models/personal_records.dart';
import 'package:capivara_2048/data/models/personal_records_hive_adapter.dart';
import 'package:capivara_2048/presentation/controllers/personal_records_notifier.dart';
import 'package:hive/hive.dart';
// ignore: implementation_imports — Hive has no public API for creating concrete BinaryReader/Writer
// instances outside of a real box. These internals are stable across minor versions; pin Hive
// version in pubspec.yaml if this becomes a concern.
import 'package:hive/src/binary/binary_writer_impl.dart';
// ignore: implementation_imports
import 'package:hive/src/binary/binary_reader_impl.dart';
// ignore: implementation_imports
import 'package:hive/src/registry/type_registry_impl.dart';

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
      const original = PersonalRecords(
        bestTimeMs2048: 54321,
        timesReached2048: 3,
      );
      final writer = BinaryWriterImpl(TypeRegistryImpl.nullImpl);
      adapter.write(writer, original);
      final reader = BinaryReaderImpl(
        writer.toBytes(),
        TypeRegistryImpl.nullImpl,
      );
      final restored = adapter.read(reader);
      expect(restored.bestTimeMs2048, 54321);
      expect(restored.timesReached2048, 3);
    });

    test(
      'HiveAdapter — compatibilidade retroativa: bytes antigos retornam 0',
      () {
        final writer = BinaryWriterImpl(TypeRegistryImpl.nullImpl);
        writer.writeInt(2); // timesReached2048
        writer.writeInt(1); // timesReached4096
        writer.writeInt(0); // timesReached8192
        writer.writeBool(true);
        writer.writeInt(1700000000000); // firstReached2048At
        writer.writeBool(false); // firstReached4096At null
        writer.writeBool(false); // firstReached8192At null
        writer.writeBool(true); // rewardCollected4096
        writer.writeBool(false); // rewardCollected8192
        writer.writeInt(12); // highestLevelEver
        // Sem bestTimeMs2048

        final reader = BinaryReaderImpl(
          writer.toBytes(),
          TypeRegistryImpl.nullImpl,
        );
        final restored = PersonalRecordsHiveAdapter().read(reader);
        expect(restored.bestTimeMs2048, 0);
        expect(restored.timesReached2048, 2);
        expect(restored.highestLevelEver, 12);
      },
    );
  });

  group('PersonalRecordsNotifier.updateBestTime2048', () {
    late ProviderContainer container;

    setUp(() async {
      Hive.init('/tmp/capivara_pr_notifier_test_${DateTime.now().millisecondsSinceEpoch}');
      container = ProviderContainer();
      await container.read(personalRecordsProvider.notifier).load();
    });

    tearDown(() async {
      container.dispose();
      await Hive.close();
    });

    test('primeiro registro retorna true e salva', () async {
      final result = await container
          .read(personalRecordsProvider.notifier)
          .updateBestTime2048(5000);
      expect(result, true);
      expect(container.read(personalRecordsProvider).bestTimeMs2048, 5000);
    });

    test('tempo melhor retorna true e atualiza', () async {
      await container.read(personalRecordsProvider.notifier).updateBestTime2048(5000);
      final result = await container
          .read(personalRecordsProvider.notifier)
          .updateBestTime2048(3000);
      expect(result, true);
      expect(container.read(personalRecordsProvider).bestTimeMs2048, 3000);
    });

    test('tempo pior retorna false e não atualiza', () async {
      await container.read(personalRecordsProvider.notifier).updateBestTime2048(3000);
      final result = await container
          .read(personalRecordsProvider.notifier)
          .updateBestTime2048(5000);
      expect(result, false);
      expect(container.read(personalRecordsProvider).bestTimeMs2048, 3000);
    });

    test('tempo igual retorna false e não atualiza', () async {
      await container.read(personalRecordsProvider.notifier).updateBestTime2048(3000);
      final result = await container
          .read(personalRecordsProvider.notifier)
          .updateBestTime2048(3000);
      expect(result, false);
    });

    test('timeMs zero retorna false', () async {
      final result = await container
          .read(personalRecordsProvider.notifier)
          .updateBestTime2048(0);
      expect(result, false);
      expect(container.read(personalRecordsProvider).bestTimeMs2048, 0);
    });

    test('timeMs negativo retorna false', () async {
      final result = await container
          .read(personalRecordsProvider.notifier)
          .updateBestTime2048(-1);
      expect(result, false);
    });
  });
}
