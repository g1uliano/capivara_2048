import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capivara_2048/domain/ranking/weekly_reward_result.dart';
import 'package:capivara_2048/presentation/widgets/weekly_reward_modal.dart';

Widget _wrap(WeeklyRewardResult reward, {VoidCallback? onDismiss}) =>
    MaterialApp(
      home: Scaffold(
        body: WeeklyRewardModal(reward: reward, onDismiss: onDismiss),
      ),
    );

void main() {
  testWidgets('exibe posição 1 e itens corretos', (tester) async {
    final reward = WeeklyRewardResult.forPosition(1, weekId: '2025-W19');
    await tester.pumpWidget(_wrap(reward));
    expect(find.textContaining('1º'), findsOneWidget);
    expect(find.textContaining('Parabéns'), findsOneWidget);
    expect(find.textContaining('5'), findsWidgets); // 5 vidas
    expect(find.textContaining('Continuar'), findsOneWidget);
  });

  testWidgets('botão Continuar chama onDismiss', (tester) async {
    bool called = false;
    final reward = WeeklyRewardResult.forPosition(2, weekId: '2025-W19');
    await tester.pumpWidget(_wrap(reward, onDismiss: () => called = true));
    await tester.tap(find.textContaining('Continuar'));
    await tester.pump();
    expect(called, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem itens exibe mensagem fallback', (tester) async {
    final reward = WeeklyRewardResult.forPosition(100, weekId: '2025-W19');
    await tester.pumpWidget(_wrap(reward));
    expect(find.textContaining('Nenhum item'), findsOneWidget);
  });
}
