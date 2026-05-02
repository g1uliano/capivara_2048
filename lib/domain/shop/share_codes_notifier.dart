// lib/domain/shop/share_codes_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/share_code.dart';
import '../../data/repositories/share_codes_repository.dart';

class ShareCodesNotifier extends StateNotifier<List<ShareCode>> {
  ShareCodesNotifier(this._repo) : super([]);

  final ShareCodesRepository _repo;

  Future<void> load() async {
    state = await _repo.load();
  }

  Future<void> add(ShareCode code) async {
    state = [...state, code];
    await _repo.save(state);
  }
}

final shareCodesRepositoryProvider = Provider<ShareCodesRepository>(
  (_) => ShareCodesRepository(),
);

final shareCodesProvider =
    StateNotifierProvider<ShareCodesNotifier, List<ShareCode>>(
  (ref) => ShareCodesNotifier(ref.read(shareCodesRepositoryProvider)),
);
