import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/domain/auth/auth_service.dart';
import 'package:capivara_2048/domain/sync/sync_engine.dart';
import 'package:capivara_2048/presentation/screens/profile_screen.dart';
import 'package:capivara_2048/data/models/player_profile.dart';

Widget _wrap({PlayerProfile? profile}) {
  final fakeAuth = FakeAuthService(initialProfile: profile);
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(fakeAuth),
      syncEngineProvider.overrideWithValue(FakeSyncEngine()),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

void main() {
  testWidgets('exibe CTA de login quando não logado', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.textContaining('Entrar'), findsWidgets);
  });

  testWidgets('exibe nome do jogador quando logado', (tester) async {
    final profile = PlayerProfile(
      userId: 'u1',
      displayName: 'Capivarão',
      provider: AuthProvider.google,
      createdAt: DateTime(2025),
      lastSeenAt: DateTime(2025),
    );
    await tester.pumpWidget(_wrap(profile: profile));
    expect(find.textContaining('Capivarão'), findsOneWidget);
  });

  testWidgets('exibe botão Sair quando logado', (tester) async {
    final profile = PlayerProfile(
      userId: 'u1',
      displayName: 'Capivarão',
      provider: AuthProvider.google,
      createdAt: DateTime(2025),
      lastSeenAt: DateTime(2025),
    );
    await tester.pumpWidget(_wrap(profile: profile));
    expect(find.textContaining('Sair'), findsOneWidget);
  });
}
