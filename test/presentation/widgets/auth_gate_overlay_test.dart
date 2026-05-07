import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/data/models/player_profile.dart';
import 'package:capivara_2048/presentation/controllers/auth_controller.dart';
import 'package:capivara_2048/presentation/widgets/auth_gate_overlay.dart';

class _FakeAuthController extends AuthController {
  _FakeAuthController(this._profile);
  final PlayerProfile? _profile;
  @override
  PlayerProfile? build() => _profile;
}

Widget _testApp({
  required PlayerProfile? profile,
  required Widget child,
  required VoidCallback onClose,
}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _FakeAuthController(profile)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: AuthGateOverlay(
          reason: 'Teste de motivo',
          onClose: onClose,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  final fakeProfile = PlayerProfile(
    userId: 'u1',
    displayName: 'Jogador',
    provider: AuthProvider.email,
    createdAt: DateTime(2025),
    lastSeenAt: DateTime(2025),
  );

  testWidgets('exibe child quando logado', (tester) async {
    await tester.pumpWidget(_testApp(
      profile: fakeProfile,
      child: const Text('conteúdo protegido'),
      onClose: () {},
    ));
    expect(find.text('conteúdo protegido'), findsOneWidget);
    expect(find.text('Fazer login'), findsNothing);
  });

  testWidgets('exibe gate quando não logado', (tester) async {
    await tester.pumpWidget(_testApp(
      profile: null,
      child: const Text('conteúdo protegido'),
      onClose: () {},
    ));
    expect(find.text('conteúdo protegido'), findsNothing);
    expect(find.text('Fazer login'), findsOneWidget);
    expect(find.text('Teste de motivo'), findsOneWidget);
  });

  testWidgets('botão Agora não chama onClose', (tester) async {
    bool called = false;
    await tester.pumpWidget(_testApp(
      profile: null,
      child: const Text('x'),
      onClose: () => called = true,
    ));
    await tester.tap(find.text('Agora não'));
    expect(called, isTrue);
  });
}
