// lib/data/repositories/firebase_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/models/player_profile.dart';
import '../../domain/auth/auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService() : _auth = fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  @override
  Stream<PlayerProfile?> get authStateChanges =>
      _auth.authStateChanges().map(_toProfile);

  @override
  PlayerProfile? get currentProfile => _toProfile(_auth.currentUser);

  @override
  Future<PlayerProfile> signInWithGoogle() async {
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    return _toProfile(result.user)!;
  }

  @override
  Future<PlayerProfile> signInWithApple() async {
    throw UnimplementedError('Apple Sign-In: implementar com sign_in_with_apple');
  }

  @override
  Future<PlayerProfile> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return _toProfile(result.user)!;
  }

  @override
  Future<PlayerProfile> createAccountWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await result.user?.updateDisplayName(displayName);
    return _toProfile(result.user)!;
  }

  @override
  Future<void> updateDisplayName(String name) async {
    // Full implementation in Task 4
    await _auth.currentUser?.updateDisplayName(name);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> deleteAccount({String? senha}) async {
    // Full implementation with re-auth in Task 4
    await _auth.currentUser?.delete();
  }

  @override
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  PlayerProfile? _toProfile(fb.User? user) {
    if (user == null) return null;
    final provider = _detectProvider(user);
    return PlayerProfile(
      userId: user.uid,
      displayName: user.displayName ?? 'Jogador',
      avatarUrl: user.photoURL,
      email: user.email,
      provider: provider,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      lastSeenAt: DateTime.now(),
    );
  }

  AuthProvider _detectProvider(fb.User user) {
    final providerId = user.providerData.isNotEmpty
        ? user.providerData.first.providerId
        : 'password';
    if (providerId.contains('google')) return AuthProvider.google;
    if (providerId.contains('apple')) return AuthProvider.apple;
    return AuthProvider.email;
  }
}
