# Fireworks Milestone Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adicionar animação de confetes coloridos sobre o `MilestoneRankingDialog` toda vez que um milestone (2048, 4096, 8192) é atingido.

**Architecture:** Converter `MilestoneRankingDialog` de `StatelessWidget` para `StatefulWidget`. No `initState`, criar e disparar um `ConfettiController` de 4 segundos. O `build` retorna um `Stack` com o `Dialog` existente + `ConfettiWidget` alinhado no topo. Todo o restante da lógica (conteúdo, botões, `PostGameSummary`) permanece inalterado.

**Tech Stack:** Flutter, `confetti: ^0.7.0`, `dart:math` (pi)

---

## Arquivos

- Modify: `pubspec.yaml` — adicionar dependência `confetti`
- Modify: `lib/presentation/widgets/milestone_ranking_dialog.dart` — StatefulWidget + ConfettiController + Stack
- Modify: `test/presentation/widgets/milestone_ranking_dialog_test.dart` — atualizar helper + novo teste de presença

---

### Task 1: Adicionar dependência confetti

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Adicionar confetti ao pubspec.yaml**

No bloco `dependencies:`, adicionar logo após `flutter_animate` (ou qualquer dependência de animação existente):

```yaml
  confetti: ^0.7.0
```

- [ ] **Step 2: Instalar a dependência**

```bash
flutter pub get
```

Expected: resolve sem conflitos, `confetti` aparece em `pubspec.lock`.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add confetti dependency"
```

---

### Task 2: Escrever os testes que vão falhar

**Files:**
- Modify: `test/presentation/widgets/milestone_ranking_dialog_test.dart`

- [ ] **Step 1: Atualizar o helper `openDialog`**

O helper atual usa `pumpAndSettle()`. Com a animação de confete de 4s, isso seria lento. Substituir por `pump()` + `pump(Duration)`:

```dart
Future<void> openDialog(WidgetTester tester, PostGameSummary summary) async {
  await tester.pumpWidget(
    wrap(
      Builder(
        builder: (ctx) {
          return ElevatedButton(
            onPressed: () => MilestoneRankingDialog.show(ctx, summary),
            child: const Text('Open'),
          );
        },
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pump();                              // inicia abertura do dialog
  await tester.pump(const Duration(milliseconds: 300)); // conclui animação de entrada
}
```

- [ ] **Step 2: Adicionar novos testes de presença do ConfettiWidget**

Acrescentar ao `group('MilestoneRankingDialog', ...)` existente, após o último teste:

```dart
    testWidgets('milestone 11: ConfettiWidget presente', (tester) async {
      const summary = PostGameSummary(
        milestone: 11,
        rankingPosition: 1,
        timeMs: 120000,
        earnedCombo: false,
      );
      await openDialog(tester, summary);
      expect(find.byType(ConfettiWidget), findsOneWidget);
    });

    testWidgets('milestone 12: ConfettiWidget presente', (tester) async {
      const summary = PostGameSummary(
        milestone: 12,
        timeMs: 300000,
        earnedCombo: false,
      );
      await openDialog(tester, summary);
      expect(find.byType(ConfettiWidget), findsOneWidget);
    });

    testWidgets('milestone 13: ConfettiWidget presente', (tester) async {
      const summary = PostGameSummary(
        milestone: 13,
        timeMs: 0,
        timesReached8192: 1,
        earnedCombo: false,
      );
      await openDialog(tester, summary);
      expect(find.byType(ConfettiWidget), findsOneWidget);
    });
```

Adicionar o import no topo do arquivo:

```dart
import 'package:confetti/confetti.dart';
```

- [ ] **Step 3: Rodar os novos testes — verificar que falham**

```bash
flutter test test/presentation/widgets/milestone_ranking_dialog_test.dart --name "ConfettiWidget"
```

Expected: FAIL — `Expected: exactly one matching widget; Actual: _WidgetTypeFinder: zero widgets with type "ConfettiWidget"`

- [ ] **Step 4: Rodar todos os testes do arquivo — verificar que os existentes continuam passando**

```bash
flutter test test/presentation/widgets/milestone_ranking_dialog_test.dart
```

Expected: os 5 testes existentes PASS, os 3 novos FAIL.

---

### Task 3: Implementar ConfettiWidget no dialog

**Files:**
- Modify: `lib/presentation/widgets/milestone_ranking_dialog.dart`

- [ ] **Step 1: Substituir o conteúdo completo do arquivo**

```dart
import 'dart:math' show pi;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../controllers/post_game_controller.dart';

class MilestoneRankingDialog extends StatefulWidget {
  const MilestoneRankingDialog({
    super.key,
    required this.summary,
    this.onViewRanking,
    this.onDismiss,
  });

  final PostGameSummary summary;
  final VoidCallback? onViewRanking;
  final VoidCallback? onDismiss;

  static Future<void> show(
    BuildContext context,
    PostGameSummary summary, {
    VoidCallback? onViewRanking,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MilestoneRankingDialog(
        summary: summary,
        onViewRanking: onViewRanking,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<MilestoneRankingDialog> createState() =>
      _MilestoneRankingDialogState();
}

class _MilestoneRankingDialogState extends State<MilestoneRankingDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  List<Color> _confettiColors() => switch (widget.summary.milestone) {
        11 => [AppColors.primary, const Color(0xFFFFD700), Colors.white],
        12 => [Colors.blue, Colors.cyan, Colors.lightBlue],
        13 => [Colors.orange, Colors.yellow, Colors.amber],
        _ => [AppColors.primary, Colors.yellow, Colors.white],
      };

  String _formatMs(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rem = s % 60;
    return '${m.toString().padLeft(2, '0')}:${rem.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitle(),
                const SizedBox(height: 8),
                _buildBody(),
                if (widget.summary.earnedCombo) ...[
                  const Divider(height: 24),
                  _buildComboReward(),
                ],
                const SizedBox(height: 20),
                _buildActions(context),
              ],
            ),
          ),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: pi / 2,
          maxBlastForce: 20,
          minBlastForce: 8,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          gravity: 0.05,
          colors: _confettiColors(),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    final (emoji, text) = switch (widget.summary.milestone) {
      11 => ('🏆', 'Ranking Global'),
      12 => ('🌊', 'Peixe-boi atingido!'),
      13 => ('🐊', 'Jacaré atingido!'),
      _ => ('🎯', 'Marco atingido!'),
    };
    return Text(
      '$emoji $text',
      style: GoogleFonts.fredoka(
        fontSize: 22,
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBody() {
    if (widget.summary.milestone == 11) {
      return Column(
        children: [
          if (widget.summary.rankingPosition != null)
            Text(
              'Você está em ${widget.summary.rankingPosition}º lugar!',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          Text(
            'Tempo: ${_formatMs(widget.summary.timeMs)}',
            style: GoogleFonts.nunito(fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (widget.summary.milestone == 12) {
      return Text(
        'Seu tempo: ${_formatMs(widget.summary.timeMs)}',
        style: GoogleFonts.nunito(fontSize: 15),
        textAlign: TextAlign.center,
      );
    } else {
      return Text(
        'Você chegou aqui ${widget.summary.timesReached8192} '
        '${widget.summary.timesReached8192 == 1 ? 'vez' : 'vezes'}!',
        style: GoogleFonts.nunito(fontSize: 15),
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _buildComboReward() {
    return Column(
      children: [
        Text(
          '🎁 Recorde pessoal!',
          style: GoogleFonts.fredoka(
            fontSize: 16,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '+1 vida  •  +1 bomba  •  +1 desfazer',
          style: GoogleFonts.nunito(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final dismiss = widget.onDismiss ?? () => Navigator.of(context).pop();
    if (widget.summary.milestone == 11) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onViewRanking?.call();
              },
              child: Text(
                'Ver Ranking',
                style: GoogleFonts.fredoka(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: dismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Continuar',
                style: GoogleFonts.fredoka(fontSize: 16),
              ),
            ),
          ),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: dismiss,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text('Continuar', style: GoogleFonts.fredoka(fontSize: 18)),
      ),
    );
  }
}
```

- [ ] **Step 2: Rodar os novos testes — verificar que agora passam**

```bash
flutter test test/presentation/widgets/milestone_ranking_dialog_test.dart --name "ConfettiWidget"
```

Expected: 3 testes PASS.

- [ ] **Step 3: Rodar todos os testes do arquivo**

```bash
flutter test test/presentation/widgets/milestone_ranking_dialog_test.dart
```

Expected: todos os 8 testes PASS.

- [ ] **Step 4: Rodar a suite completa para verificar regressões**

```bash
flutter test --exclude-tags golden
```

Expected: PASS sem regressões.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/widgets/milestone_ranking_dialog.dart \
        test/presentation/widgets/milestone_ranking_dialog_test.dart
git commit -m "feat: confetes animados no MilestoneRankingDialog"
```
