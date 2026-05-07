import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/invites/invite_service.dart';
import '../controllers/auth_controller.dart';

class InviteController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<String?> generateLink() async {
    final profile = ref.read(authControllerProvider);
    if (profile == null) return null;
    state = const AsyncLoading();
    try {
      final link = await ref
          .read(inviteServiceProvider)
          .generateInviteLink(profile.userId);
      state = AsyncData(link);
      return link;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final inviteControllerProvider =
    AsyncNotifierProvider<InviteController, String?>(
  InviteController.new,
);
