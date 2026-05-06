// lib/domain/auth/auth_service.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/player_profile.dart';
import '../../data/repositories/firebase_auth_service.dart';

abstract class AuthService {
  Stream<PlayerProfile?> get authStateChanges;
  PlayerProfile? get currentProfile;
  Future<PlayerProfile> signInWithGoogle();
  Future<PlayerProfile> signInWithApple();
  Future<PlayerProfile> signInWithEmail(String email, String password);
  Future<PlayerProfile> createAccountWithEmail(String email, String password);
  Future<void> signOut();
}

class FakeAuthService implements AuthService {
  PlayerProfile? _profile;
  final _controller = StreamController<PlayerProfile?>.broadcast();

  FakeAuthService({PlayerProfile? initialProfile}) : _profile = initialProfile;

  @override
  Stream<PlayerProfile?> get authStateChanges => _controller.stream;

  @override
  PlayerProfile? get currentProfile => _profile;

  @override
  Future<PlayerProfile> signInWithGoogle() async {
    _profile = _fakeProfile(AuthProvider.google);
    _controller.add(_profile);
    return _profile!;
  }

  @override
  Future<PlayerProfile> signInWithApple() async {
    _profile = _fakeProfile(AuthProvider.apple);
    _controller.add(_profile);
    return _profile!;
  }

  @override
  Future<PlayerProfile> signInWithEmail(String email, String password) async {
    _profile = _fakeProfile(AuthProvider.email, email: email);
    _controller.add(_profile);
    return _profile!;
  }

  @override
  Future<PlayerProfile> createAccountWithEmail(
    String email,
    String password,
  ) async {
    _profile = _fakeProfile(AuthProvider.email, email: email);
    _controller.add(_profile);
    return _profile!;
  }

  @override
  Future<void> signOut() async {
    _profile = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();

  PlayerProfile _fakeProfile(AuthProvider provider, {String? email}) =>
      PlayerProfile(
        userId: 'fake-user-id',
        displayName: 'Jogador Teste',
        email: email,
        provider: provider,
        createdAt: DateTime(2025, 1, 1),
        lastSeenAt: DateTime.now(),
      );
}

// TODO(fase4b): Replace FakeAuthService with FirebaseAuthService for prd flavor.
// See docs/plans/2026-05-05-fase4a-firebase-auth-sync.md Task 13.
final authServiceProvider = Provider<AuthService>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  if (flavor == 'prd') return FirebaseAuthService();
  return FakeAuthService();
});
