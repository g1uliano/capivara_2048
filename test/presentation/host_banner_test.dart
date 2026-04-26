import 'package:capivara_2048/presentation/widgets/host_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HostBanner placeholder has no DecoratedBox', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: HostBanner()),
        ),
      ),
    );

    expect(find.byType(DecoratedBox), findsNothing);
  });

  testWidgets('HostBanner placeholder shows "Comece a jogar!" text', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: HostBanner()),
        ),
      ),
    );

    expect(find.text('Comece a jogar!'), findsOneWidget);
  });
}
