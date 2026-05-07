// lib/domain/shop/share_codes_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/share_code.dart';
import '../../data/repositories/share_codes_repository.dart';

class ShareCodesNotifier extends Notifier<List<ShareCode>> {
  @override
  List<ShareCode> build() => [];

  Future<void> load() async {
    state = await ref.read(shareCodesRepositoryProvider).load();
  }

  Future<void> add(ShareCode code) async {
    state = [...state, code];
    await ref.read(shareCodesRepositoryProvider).save(state);
  }
}

final shareCodesRepositoryProvider = Provider<ShareCodesRepository>(
  (_) => ShareCodesRepository(),
);

final shareCodesProvider =
    NotifierProvider<ShareCodesNotifier, List<ShareCode>>(
      ShareCodesNotifier.new,
    );
