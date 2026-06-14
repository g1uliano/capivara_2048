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
  Future<PlayerProfile> createAccountWithEmail(
    String email,
    String password,
    String displayName,
  );
  Future<void> updateDisplayName(String name);
  Future<void> sendPasswordReset(String email);
  // senha: obrigatório para AuthProvider.email; ignorado para Google
  Future<void> deleteAccount({String? senha});
  Future<void> signOut();
  Future<DateTime?> getBirthDate();
  Future<void> saveBirthDate(DateTime dob);
}

class FakeAuthService implements AuthService {
  PlayerProfile? _profile;
  DateTime? _birthDate;
  final _controller = StreamController<PlayerProfile?>.broadcast();

  FakeAuthService({PlayerProfile? initialProfile, DateTime? initialBirthDate})
      : _profile = initialProfile,
        _birthDate = initialBirthDate;

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
    String displayName,
  ) async {
    _profile = _fakeProfile(
      AuthProvider.email,
      email: email,
      name: displayName,
    );
    _controller.add(_profile);
    return _profile!;
  }

  @override
  Future<void> updateDisplayName(String name) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(displayName: name);
    _controller.add(_profile);
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> deleteAccount({String? senha}) async {
    _profile = null;
    _controller.add(null);
  }

  @override
  Future<void> signOut() async {
    _profile = null;
    _controller.add(null);
  }

  @override
  Future<DateTime?> getBirthDate() async => _birthDate;

  @override
  Future<void> saveBirthDate(DateTime dob) async {
    _birthDate = dob;
  }

  void dispose() => _controller.close();

  PlayerProfile _fakeProfile(
    AuthProvider provider, {
    String? email,
    String? name,
  }) => PlayerProfile(
    userId: 'fake-user-id',
    displayName: name ?? 'Jogador Teste',
    email: email,
    provider: provider,
    createdAt: DateTime(2025, 1, 1),
    lastSeenAt: DateTime.now(),
  );
}

final authServiceProvider = Provider<AuthService>((ref) {
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  if (flavor == 'prd' || flavor == 'dev') {
    return FirebaseAuthService();
  }
  return FakeAuthService(
    initialBirthDate: DateTime(1990, 1, 1),
    initialProfile: PlayerProfile(
      userId: 'fake-user-id',
      displayName: 'Jogador Teste',
      provider: AuthProvider.google,
      createdAt: DateTime(2025, 1, 1),
      lastSeenAt: DateTime(2025, 1, 1),
      tutorialCompleted: true,
    ),
  );
});
