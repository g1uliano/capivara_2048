// lib/presentation/controllers/auth_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/player_profile.dart';
import '../../domain/auth/auth_service.dart';
import '../../domain/sync/sync_engine.dart';

class AuthController extends StateNotifier<PlayerProfile?> {
  AuthController(this._authService, this._syncEngine) : super(null) {
    state = _authService.currentProfile;
  }

  final AuthService _authService;
  final SyncEngine _syncEngine;

  Future<void> signInWithGoogle() async {
    final profile = await _authService.signInWithGoogle();
    state = profile;
    try {
      await _syncEngine.init(profile.userId);
      await _syncEngine.syncProfile();
      await _syncEngine.drainPendingEvents();
    } catch (_) {
      state = null;
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    final profile = await _authService.signInWithApple();
    state = profile;
    try {
      await _syncEngine.init(profile.userId);
      await _syncEngine.syncProfile();
      await _syncEngine.drainPendingEvents();
    } catch (_) {
      state = null;
      rethrow;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    final profile = await _authService.signInWithEmail(email, password);
    state = profile;
    try {
      await _syncEngine.init(profile.userId);
      await _syncEngine.syncProfile();
      await _syncEngine.drainPendingEvents();
    } catch (_) {
      state = null;
      rethrow;
    }
  }

  Future<void> createAccountWithEmail(String email, String password) async {
    final profile = await _authService.createAccountWithEmail(email, password);
    state = profile;
    // New account: no remote data to sync yet — only init the engine.
    await _syncEngine.init(profile.userId);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await _syncEngine.dispose();
    state = null;
  }

  bool get isLoggedIn => state != null;
}

final authControllerProvider =
    StateNotifierProvider<AuthController, PlayerProfile?>((ref) {
      final authService = ref.watch(authServiceProvider);
      final syncEngine = ref.watch(syncEngineProvider);
      return AuthController(authService, syncEngine);
    });
