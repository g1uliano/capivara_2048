import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/domain/auth/auth_service.dart';
import 'package:capivara_2048/domain/sync/sync_engine.dart';
import 'package:capivara_2048/presentation/widgets/auth_banner.dart';
import 'package:capivara_2048/data/models/player_profile.dart';

Widget _wrap(Widget child, {PlayerProfile? profile}) {
  final fakeAuth = FakeAuthService(initialProfile: profile);
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(fakeAuth),
      syncEngineProvider.overrideWithValue(FakeSyncEngine()),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  testWidgets('AuthBanner visível quando não logado', (tester) async {
    await tester.pumpWidget(_wrap(const AuthBanner()));
    expect(find.byType(AuthBanner), findsOneWidget);
    expect(find.textContaining('Faça login'), findsOneWidget);
  });

  testWidgets('AuthBanner oculto (SizedBox.shrink) quando logado', (tester) async {
    final profile = PlayerProfile(
      userId: 'u1',
      displayName: 'Teste',
      provider: AuthProvider.google,
      createdAt: DateTime(2025),
      lastSeenAt: DateTime(2025),
    );
    await tester.pumpWidget(_wrap(const AuthBanner(), profile: profile));
    expect(find.textContaining('Faça login'), findsNothing);
  });
}
