import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/fake_ranking_service.dart';
import '../../domain/ranking/ranking_repository.dart';

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  if (kDebugMode) return FakeRankingService();
  throw UnimplementedError('Implementar FirebaseRankingService na Fase 3');
});
