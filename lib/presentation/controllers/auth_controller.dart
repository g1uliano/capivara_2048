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
  PlayerProfile? build() {
    final profile = ref.read(authServiceProvider).currentProfile;
    if (profile != null) {
      // Sessão restaurada do cache local do Firebase Auth — busca dados
      // canônicos do Firestore em background (avatar tile + displayName).
      Future.microtask(() => _restoreSessionOnColdStart(profile));
    }
    return profile;
  }

  /// Espelha o que o fluxo de login faz, mas de forma assíncrona e
  /// não-bloqueante. Seguro chamar mesmo se o usuário fizer signOut
  /// antes de completar (state?.copyWith retornará null).
  Future<void> _restoreSessionOnColdStart(PlayerProfile profile) async {
    try {
      final syncEngine = ref.read(syncEngineProvider);
      await syncEngine.init(profile.userId, displayName: profile.displayName);
      await syncEngine.syncProfile();

      // Aplica avatar tile do Firestore (não existe no Firebase Auth photoURL)
      final remoteAvatar = syncEngine.remoteAvatarUrl;
      final remoteName = syncEngine.remoteDisplayName;

      PlayerProfile? updated = state;
      if (remoteAvatar != null && remoteAvatar.startsWith('tile:')) {
        updated = updated?.copyWith(avatarUrl: remoteAvatar);
      }
      // Corrige displayName vazio/nulo que o cache do Firebase Auth pode retornar
      if (remoteName != null &&
          remoteName.isNotEmpty &&
          (updated?.displayName.isEmpty ?? false)) {
        updated = updated?.copyWith(displayName: remoteName);
      }
      if (updated != null && updated != state) state = updated;

      await syncEngine.drainPendingEvents();
      _initIAPStartup(profile.userId);
    } catch (_) {
      // Não-fatal: sessão permanece ativa, só sem dados remotos
    }
  }

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
      // Restore tile avatar for email accounts (saved in Firestore)
      final tileAvatar = ref.read(syncEngineProvider).remoteAvatarUrl;
      if (tileAvatar != null && tileAvatar.startsWith('tile:')) {
        state = state!.copyWith(avatarUrl: tileAvatar);
      }
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

  Future<void> updateDisplayName(String name) async {
    if (state == null) return;
    state = state!.copyWith(displayName: name);
    try {
      await ref.read(authServiceProvider).updateDisplayName(name);
      await ref.read(syncEngineProvider).updateDisplayName(name);
    } catch (_) {
      // Local state already updated; remote failure is non-fatal
    }
  }

  Future<void> deleteAccount({String? senha}) async {
    // 1. Deletar dados no Firestore primeiro (pode falhar sem bloquear)
    try {
      await ref.read(syncEngineProvider).deleteUserData();
    } catch (_) {}

    // 2. Limpar todos os boxes Hive locais
    const boxNames = [
      'inventory',
      'lives',
      'personal_records',
      'pending_events',
      'daily_rewards',
      'invite_refs',
      'game_records',
      'ranking_rewards',
    ];
    for (final name in boxNames) {
      try {
        final box = await Hive.openBox(name);
        await box.clear();
        await box.close();
      } catch (_) {}
    }

    // 3. Deletar conta no Firebase Auth (inclui re-autenticação)
    await ref.read(authServiceProvider).deleteAccount(senha: senha);

    // 4. Dispose serviços
    unawaited(ref.read(iapStartupServiceProvider).dispose());
    try {
      await ref.read(syncEngineProvider).dispose();
    } catch (_) {}

    // 5. Limpar state
    state = null;
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

  void updateProfileTutorialFlag(bool completed) {
    if (state == null) return;
    state = state!.copyWith(tutorialCompleted: completed);
  }
}

final authControllerProvider = NotifierProvider<AuthController, PlayerProfile?>(
  AuthController.new,
);
