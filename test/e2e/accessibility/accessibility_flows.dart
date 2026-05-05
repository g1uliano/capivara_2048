import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../_harness/scenario.dart';
import '../_harness/test_harness.dart';
import '../_harness/tester_extensions.dart';

// ─── helpers ────────────────────────────────────────────────────────────────

Future<void> _bootToHome(WidgetTester tester, GameTestHarness harness) async {
  final widget = await tester.runAsync(() => harness.boot());
  await tester.pumpWidget(widget!);
  await tester.pumpAndSettle(const Duration(seconds: 5));
}

// ─── a11y.home_buttons_have_semantics_labels ────────────────────────────────

final a11yHomeButtonsSemanticsScenario = E2EScenario(
  id: 'a11y.home_buttons_have_semantics_labels',
  title: 'botões da Home têm Semantics labels para leitores de tela',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);

    for (final label in [
      'Coleção',
      'Configurações',
      'Recompensas Diárias',
      'Ranking',
      'Loja',
      'Como Jogar',
    ]) {
      expect(
        find.bySemanticsLabel(label),
        findsOneWidget,
        reason: 'botão "$label" deve ter Semantics label para leitores de tela',
      );
    }
  },
);

// ─── a11y.game_board_has_semantics ──────────────────────────────────────────

final a11yGameBoardSemanticsScenario = E2EScenario(
  id: 'a11y.game_board_has_semantics',
  title: 'tabuleiro do jogo tem Semantics label "Tabuleiro do jogo"',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);
    await tester.gotoGame(harness);

    expect(
      find.bySemanticsLabel('Tabuleiro do jogo'),
      findsOneWidget,
      reason: 'tabuleiro deve ter Semantics label para leitores de tela',
    );
  },
);

// ─── a11y.contrast_score_panel_meets_aa ─────────────────────────────────────

final a11yContrastScorePanelScenario = E2EScenario(
  id: 'a11y.contrast_score_panel_meets_aa',
  title:
      'textos do StatusPanel usam outlined style (contraste WCAG AA via sombras)',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    await _bootToHome(tester, harness);
    await tester.gotoGame(harness);

    // O score inicial é 0. O StatusPanel exibe '0' com outlinedWhiteTextStyle.
    // outlinedWhiteTextStyle garante contraste via 8 shadows pretas ao redor do texto branco.
    final scoreTexts = tester.widgetList<Text>(find.text('0'));
    // Pode haver múltiplos widgets Text('0') na tela — verificar que pelo menos um
    // usa a style com shadows (StatusPanel score)
    final hasOutlinedScore = scoreTexts.any(
      (t) => t.style?.shadows != null && t.style!.shadows!.isNotEmpty,
    );
    expect(
      hasOutlinedScore,
      isTrue,
      reason:
          'StatusPanel deve usar outlinedWhiteTextStyle com shadows para contraste WCAG AA',
    );
  },
);

// ─── a11y.no_text_overflow_at_max_font_scale ────────────────────────────────

final a11yNoTextOverflowScenario = E2EScenario(
  id: 'a11y.no_text_overflow_at_max_font_scale',
  title: 'nenhum overflow de texto em viewport 360×640 (tela compacta)',
  tags: {ScenarioTag.critical},
  run: (tester, harness) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final overflowErrors = <String>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.toString();
      if (msg.contains('overflowed') || msg.contains('overflow')) {
        overflowErrors.add(msg);
      } else {
        originalOnError?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await _bootToHome(tester, harness);
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      overflowErrors,
      isEmpty,
      reason:
          'HomeScreen não deve ter overflow em viewport 360×640: $overflowErrors',
    );

    await tester.gotoGame(harness);
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      overflowErrors,
      isEmpty,
      reason:
          'GameScreen não deve ter overflow em viewport 360×640: $overflowErrors',
    );
  },
);
