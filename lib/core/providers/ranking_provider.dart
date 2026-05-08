import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/fake_ranking_service.dart';
import '../../data/repositories/firestore_ranking_repository.dart';
import '../../domain/ranking/ranking_repository.dart';
import '../../presentation/controllers/auth_controller.dart';

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  if (flavor == 'tst') return FakeRankingService();

  final profile = ref.watch(authControllerProvider);
  if (profile == null) return FakeRankingService();

  return FirestoreRankingRepository(userId: profile.userId);
});
