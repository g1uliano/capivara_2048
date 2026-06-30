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
  // Non-null when a sub-step inside the current page is ready to advance.
  // Pressing "Próximo" calls this instead of doing normal page navigation.
  VoidCallback? _nextAction;

  static const _totalPages = 4;

  bool get _nextAnimated => _nextAction != null;

  bool get _canGoNext {
    if (_nextAction != null) return true;
    // Pages 1 and 2 stay blocked until their page signals readiness.
    if (_currentPage == 1 || _currentPage == 2) return false;
    return true;
  }

  String get _nextLabel =>
      _currentPage == _totalPages - 1 ? 'Começar 🌿' : 'Próximo →';

  // Pages call this to animate the Próximo button and register what it does.
  void _setNextState({required bool animated, VoidCallback? action}) {
    setState(() => _nextAction = animated ? action : null);
  }

  void _goNext() {
    if (_nextAction != null) {
      _nextAction!();
      return;
    }
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
    setState(() => _nextAction = null);
    _controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _complete() async {
    await ref.read(tutorialControllerProvider.notifier).markCompleted();
    if (mounted) Navigator.of(context).pop();
  }

  // Called by sandbox/items pages when their last step is done.
  // Navigates to the next page (the action already cleared _nextAction).
  void _onPage1Done() {
    setState(() => _nextAction = null);
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPage2Done() {
    setState(() => _nextAction = null);
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

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
      nextAnimated: _nextAnimated,
      nextLabel: _nextLabel,
      onBack: _currentPage == 0 ? null : _goBack,
      onNext: _goNext,
      onSkip: _complete,
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() {
          _currentPage = i;
          _nextAction = null; // clear stale action on any page change
        }),
        children: [
          const TutorialWelcomePage(),
          TutorialSandboxPage(
            onUserCompleted: _onPage1Done,
            setNextState: _setNextState,
          ),
          TutorialItemsPage(
            onUserCompleted: _onPage2Done,
            setNextState: _setNextState,
          ),
          const TutorialFinalePage(),
        ],
      ),
    );
  }
}
