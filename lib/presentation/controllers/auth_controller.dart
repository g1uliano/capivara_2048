// lib/presentation/controllers/auth_controller.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/player_profile.dart';
import '../../domain/auth/auth_service.dart';
import '../../domain/invites/invite_service.dart';
import '../../domain/sync/sync_engine.dart';
import '../../data/repositories/iap_startup_service.dart';

class AuthController extends StateNotifier<PlayerProfile?> {
  AuthController(this._authService, this._syncEngine, this._ref) : super(null) {
    state = _authService.currentProfile;
  }

  final AuthService _authService;
  final SyncEngine _syncEngine;
  final Ref _ref;

  Future<void> signInWithGoogle() async {
    final profile = await _authService.signInWithGoogle();
    state = profile;
    try {
      await _syncEngine.init(profile.userId, displayName: profile.displayName);
      await _syncEngine.syncProfile();
      await _syncEngine.drainPendingEvents();
      _initIAPStartup(profile.userId);
      unawaited(_registerPendingInvite(profile));
    } catch (_) {
      state = null;
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    final profile = await _authService.signInWithApple();
    state = profile;
    try {
      await _syncEngine.init(profile.userId, displayName: profile.displayName);
      await _syncEngine.syncProfile();
      await _syncEngine.drainPendingEvents();
      _initIAPStartup(profile.userId);
      unawaited(_registerPendingInvite(profile));
    } catch (_) {
      state = null;
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    final profile = await _authService.signInWithEmail(email, password);
    state = profile;
    try {
      await _syncEngine.init(profile.userId, displayName: profile.displayName);
      await _syncEngine.syncProfile();
      await _syncEngine.drainPendingEvents();
      _initIAPStartup(profile.userId);
      unawaited(_registerPendingInvite(profile));
    } catch (_) {
      state = null;
      rethrow;
    }
  }

  Future<void> createAccountWithEmail(String email, String password) async {
    final profile = await _authService.createAccountWithEmail(email, password);
    state = profile;
    // New account: no remote data to sync yet — only init the engine.
    await _syncEngine.init(profile.userId, displayName: profile.displayName);
    _initIAPStartup(profile.userId);
    unawaited(_registerPendingInvite(profile));
  }

  /// Initializes IAPStartupService after successful login.
  /// No-op in dev (FakeIAPStartupService).
  void _initIAPStartup(String userId) {
    unawaited(_ref.read(iapStartupServiceProvider).initialize(userId));
  }

  /// Called after every successful login.
  /// Reads pending invite ref from Hive and registers the invite in Firestore.
  /// Does NOT clear the ref — it is cleared by completeInviteReward after 1st game.
  Future<void> _registerPendingInvite(PlayerProfile profile) async {
    try {
      final box = await Hive.openBox<String>('invite_refs');
      final inviterId = box.get('pending_ref');
      if (inviterId == null || inviterId.isEmpty) return;
      final inviteService = _ref.read(inviteServiceProvider);
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
    await _authService.signOut();
    unawaited(_ref.read(iapStartupServiceProvider).dispose());
    await _syncEngine.dispose();
    state = null;
  }

  bool get isLoggedIn => state != null;
}

final authControllerProvider =
    StateNotifierProvider<AuthController, PlayerProfile?>((ref) {
      final authService = ref.watch(authServiceProvider);
      final syncEngine = ref.watch(syncEngineProvider);
      return AuthController(authService, syncEngine, ref);
    });
