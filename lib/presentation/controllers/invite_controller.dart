import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/invites/invite_service.dart';
import '../controllers/auth_controller.dart';

class InviteController extends StateNotifier<AsyncValue<String?>> {
  InviteController(this._service, this._ref)
      : super(const AsyncValue.data(null));

  final InviteService _service;
  final Ref _ref;

  /// Generates invite link for current user. Returns null if not logged in.
  Future<String?> generateLink() async {
    final profile = _ref.read(authControllerProvider);
    if (profile == null) return null;
    state = const AsyncValue.loading();
    try {
      final link = await _service.generateInviteLink(profile.userId);
      state = AsyncValue.data(link);
      return link;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final inviteControllerProvider =
    StateNotifierProvider<InviteController, AsyncValue<String?>>(
  (ref) => InviteController(ref.watch(inviteServiceProvider), ref),
);
