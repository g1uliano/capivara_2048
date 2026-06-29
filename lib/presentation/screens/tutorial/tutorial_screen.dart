// lib/presentation/screens/tutorial/tutorial_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/tutorial_controller.dart';
import 'pages/tutorial_welcome_page.dart';
import 'pages/tutorial_sandbox_page.dart';
import 'pages/tutorial_items_page.dart';
import 'pages/tutorial_finale_page.dart';
import 'widgets/tutorial_scaffold.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  // Tracks completion of interactive pages (pages 1 and 2, 0-indexed)
  bool _page1Done = false;
  bool _page2Done = false;

  static const _totalPages = 4;

  bool get _canGoNext {
    if (_currentPage == 1) return _page1Done;
    if (_currentPage == 2) return _page2Done;
    return true;
  }

  String get _nextLabel =>
      _currentPage == _totalPages - 1 ? 'Começar 🌿' : 'Próximo →';

  void _goNext() {
    if (_currentPage == _totalPages - 1) {
      _complete();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _goBack() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _complete() async {
    await ref.read(tutorialControllerProvider.notifier).markCompleted();
    if (mounted) Navigator.of(context).pop();
  }

  void _onPage1Done() => setState(() => _page1Done = true);
  void _onPage2Done() => setState(() => _page2Done = true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TutorialScaffold(
      currentPage: _currentPage,
      totalPages: _totalPages,
      canGoNext: _canGoNext,
      nextLabel: _nextLabel,
      onBack: _currentPage == 0 ? null : _goBack,
      onNext: _goNext,
      onSkip: _complete,
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _currentPage = i),
        children: [
          const TutorialWelcomePage(),
          TutorialSandboxPage(onUserCompleted: _onPage1Done),
          TutorialItemsPage(onUserCompleted: _onPage2Done),
          const TutorialFinalePage(),
        ],
      ),
    );
  }
}
