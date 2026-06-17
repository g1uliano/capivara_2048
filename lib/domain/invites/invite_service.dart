import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_invite_repository.dart';
import '../../presentation/controllers/auth_controller.dart';

abstract class InviteService {
  /// Generates (or retrieves) an invite link for the given userId.
  /// Returns the HTTPS URL: "https://olhaobichim.com.br/invite?ref={userId}"
  Future<String> generateInviteLink(String userId);

  /// Registers that inviteeId was referred by inviterId.
  /// No-op if inviteeId is already linked to an inviter.
  Future<void> registerInvite({
    required String inviterId,
    required String inviteeId,
    required String inviteeDisplayName,
  });

  /// Completes the invite reward: delivers rewards to inviter and invitee.
  /// Called when invitee completes their 1st game.
  /// Returns true if invite was completed, false if no pending invite.
  Future<bool> completeInviteReward({
    required String inviteeId,
    required String inviteeDisplayName,
  });
}

/// In-memory fake for tests and dev flavor.
class FakeInviteService implements InviteService {
  final Map<String, String> _inviterByInvitee = {};
  bool lastCompleteResult = false;

  @override
  Future<String> generateInviteLink(String userId) async =>
      'https://olhaobichim.com.br/invite?ref=$userId';

  @override
  Future<void> registerInvite({
    required String inviterId,
    required String inviteeId,
    required String inviteeDisplayName,
  }) async {
    if (!_inviterByInvitee.containsKey(inviteeId)) {
      _inviterByInvitee[inviteeId] = inviterId;
    }
  }

  @override
  Future<bool> completeInviteReward({
    required String inviteeId,
    required String inviteeDisplayName,
  }) async {
    if (_inviterByInvitee.containsKey(inviteeId)) {
      lastCompleteResult = true;
      _inviterByInvitee.remove(inviteeId);
      return true;
    }
    return false;
  }
}

final inviteServiceProvider = Provider<InviteService>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  if (flavor == 'tst') return FakeInviteService();

  final profile = ref.watch(authControllerProvider);
  if (profile == null) {
    throw StateError(
      'inviteServiceProvider acessado sem usuário logado. '
      'A UI deve checar authControllerProvider antes de usar convites.',
    );
  }
  return FirestoreInviteRepository(
    userId: profile.userId,
    displayName: profile.displayName,
  );
});
