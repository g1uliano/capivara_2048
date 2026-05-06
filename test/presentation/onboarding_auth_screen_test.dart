import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capivara_2048/domain/auth/auth_service.dart';
import 'package:capivara_2048/domain/sync/sync_engine.dart';
import 'package:capivara_2048/presentation/screens/onboarding_auth_screen.dart';

Widget _wrap() => ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(FakeAuthService()),
        syncEngineProvider.overrideWithValue(FakeSyncEngine()),
      ],
      child: const MaterialApp(home: OnboardingAuthScreen()),
    );

void main() {
  testWidgets('exibe botão Entrar com Google', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.textContaining('Google'), findsOneWidget);
  });

  testWidgets('exibe botão Entrar com Email', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.textContaining('Email'), findsOneWidget);
  });

  testWidgets('exibe botão Jogar sem conta', (tester) async {
    await tester.pumpWidget(_wrap());
    expect(find.textContaining('sem conta'), findsOneWidget);
  });

  testWidgets('toque em Jogar sem conta não lança exceção', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.tap(find.textContaining('sem conta'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
