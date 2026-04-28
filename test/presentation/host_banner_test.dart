import 'package:capivara_2048/core/constants/game_constants.dart';
import 'package:capivara_2048/presentation/widgets/host_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  group('HostBanner', () {
    testWidgets('renderiza sem erro', (tester) async {
      await tester.pumpWidget(_wrap(const HostBanner()));
      await tester.pump();
      expect(find.byType(HostBanner), findsOneWidget);
    });

    testWidgets('largura igual a twoCellWidth (152dp)', (tester) async {
      await tester.pumpWidget(_wrap(const HostBanner()));
      await tester.pump();
      final size = tester.getSize(find.byType(HostBanner));
      expect(size.width, GameConstants.twoCellWidth);
    });

    testWidgets('exibe Tanajura no estado inicial (maxLevel == 1)', (tester) async {
      await tester.pumpWidget(_wrap(const HostBanner()));
      await tester.pump();
      expect(find.text('Tanajura'), findsOneWidget);
      expect(find.text('Comece!'), findsNothing);
    });

    testWidgets('nome Mico-leão-dourado não causa overflow em 152dp', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: GameConstants.twoCellWidth,
            child: const HostBanner(),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
