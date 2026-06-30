import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../widgets/game_background.dart';
import 'tutorial_dots_indicator.dart';

class TutorialScaffold extends StatelessWidget {
  final Widget body;
  final int currentPage;
  final int totalPages;
  final bool canGoNext;
  final bool nextAnimated;
  final String nextLabel;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const TutorialScaffold({
    super.key,
    required this.body,
    required this.currentPage,
    required this.totalPages,
    required this.canGoNext,
    required this.nextAnimated,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Text(
            'Tutorial',
            style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: onSkip,
              child: Text(
                'Pular',
                style: GoogleFonts.fredoka(fontSize: 15, color: Colors.white70),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: body),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 120,
                      child: onBack == null
                          ? const SizedBox.shrink()
                          : TextButton(
                              onPressed: onBack,
                              child: Text(
                                '← Voltar',
                                style: outlinedWhiteTextStyle(
                                  GoogleFonts.fredoka(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    TutorialDotsIndicator(
                      total: totalPages,
                      current: currentPage,
                    ),
                    SizedBox(
                      width: 120,
                      child: TextButton(
                        onPressed: canGoNext ? onNext : null,
                        child: _NextLabel(
                          label: nextLabel,
                          animated: nextAnimated,
                          enabled: canGoNext,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Separate StatefulWidget so the animation controller lives independently
// from TutorialScaffold rebuilds and restarts cleanly when `animated` flips.
class _NextLabel extends StatelessWidget {
  final String label;
  final bool animated;
  final bool enabled;

  const _NextLabel({
    required this.label,
    required this.animated,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final color = animated
        ? Colors.yellow[400]!
        : (enabled ? Colors.white : Colors.white24);
    final text = Text(
      label,
      style: outlinedWhiteTextStyle(
        GoogleFonts.fredoka(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
    if (!animated) return text;
    return text
        .animate(
          key: const ValueKey('next-animated'),
          onPlay: (c) => c.repeat(reverse: true),
        )
        .scaleXY(begin: 1.0, end: 1.4, duration: 500.ms, curve: Curves.easeInOut);
  }
}
