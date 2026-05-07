// lib/presentation/controllers/auth_controller.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/player_profile.dart';
import '../../domain/auth/auth_service.dart';
import '../../domain/invites/invite_service.dart';
import '../../domain/sync/sync_engine.dart';
import '../../data/repositories/iap_startup_service.dart';

class AuthController extends Notifier<PlayerProfile?> {
  @override
  PlayerProfile? build() => ref.read(authServiceProvider).currentProfile;

  Future<void> signInWithGoogle() async {
    final profile = await ref.read(authServiceProvider).signInWithGoogle();
    state = profile;
    try {
      await ref
          .read(syncEngineProvider)
          .init(profile.userId, displayName: profile.displayName);
      await ref.read(syncEngineProvider).syncProfile();
      await ref.read(syncEngineProvider).drainPendingEvents();
      _initIAPStartup(profile.userId);
      unawaited(_registerPendingInvite(profile));
    } catch (_) {
      state = null;
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    final profile = await ref.read(authServiceProvider).signInWithApple();
    state = profile;
    try {
      await ref
          .read(syncEngineProvider)
          .init(profile.userId, displayName: profile.displayName);
      await ref.read(syncEngineProvider).syncProfile();
      await ref.read(syncEngineProvider).drainPendingEvents();
      _initIAPStartup(profile.userId);
      unawaited(_registerPendingInvite(profile));
    } catch (_) {
      state = null;
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    final profile = await ref
        .read(authServiceProvider)
        .signInWithEmail(email, password);
    state = profile;
    try {
      await ref
          .read(syncEngineProvider)
          .init(profile.userId, displayName: profile.displayName);
      await ref.read(syncEngineProvider).syncProfile();
      await ref.read(syncEngineProvider).drainPendingEvents();
      _initIAPStartup(profile.userId);
      unawaited(_registerPendingInvite(profile));
    } catch (_) {
      state = null;
      rethrow;
    }
  }

  Future<void> createAccountWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final profile = await ref
        .read(authServiceProvider)
        .createAccountWithEmail(email, password, displayName);
    state = profile;
    // New account: no remote data to sync yet — only init the engine.
    await ref
        .read(syncEngineProvider)
        .init(profile.userId, displayName: profile.displayName);
    _initIAPStartup(profile.userId);
    unawaited(_registerPendingInvite(profile));
  }

  /// Initializes IAPStartupService after successful login.
  /// No-op in dev (FakeIAPStartupService).
  void _initIAPStartup(String userId) {
    unawaited(ref.read(iapStartupServiceProvider).initialize(userId));
  }

  /// Called after every successful login.
  /// Reads pending invite ref from Hive and registers the invite in Firestore.
  /// Does NOT clear the ref — it is cleared by completeInviteReward after 1st game.
  Future<void> _registerPendingInvite(PlayerProfile profile) async {
    try {
      final box = await Hive.openBox<String>('invite_refs');
      final inviterId = box.get('pending_ref');
      if (inviterId == null || inviterId.isEmpty) return;
      final inviteService = ref.read(inviteServiceProvider);
      await inviteService.registerInvite(
        inviterId: inviterId,
        inviteeId: profile.userId,
        inviteeDisplayName: profile.displayName,
      );
    } catch (_) {
      // Never block login for invite failures
    }
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    unawaited(ref.read(iapStartupServiceProvider).dispose());
    await ref.read(syncEngineProvider).dispose();
    state = null;
  }

  Future<void> updateAvatar(String? avatarUrl) async {
    if (state == null) return;
    state = state!.copyWith(
      avatarUrl: avatarUrl,
    ); // optimistic: update local first
    try {
      await ref.read(syncEngineProvider).updateAvatar(avatarUrl);
    } catch (_) {
      // Remote update failed; local state still updated
    }
  }

  bool get isLoggedIn => state != null;
}

final authControllerProvider = NotifierProvider<AuthController, PlayerProfile?>(
  AuthController.new,
);
