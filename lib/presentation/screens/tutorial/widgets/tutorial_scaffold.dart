import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../widgets/game_background.dart';
import 'tutorial_dots_indicator.dart';

class TutorialScaffold extends StatelessWidget {
  final Widget body;
  final int currentPage;
  final int totalPages;
  final bool canGoNext;
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
          backgroundColor: Colors.transparent,
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
                style: outlinedWhiteTextStyle(
                  GoogleFonts.fredoka(fontSize: 15, color: Colors.white70),
                ),
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
                      width: 100,
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
                      width: 100,
                      child: TextButton(
                        onPressed: canGoNext ? onNext : null,
                        child: Text(
                          nextLabel,
                          style: outlinedWhiteTextStyle(
                            GoogleFonts.fredoka(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: canGoNext
                                  ? Colors.white
                                  : Colors.white24,
                            ),
                          ),
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
