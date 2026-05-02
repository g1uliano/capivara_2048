import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/text_styles.dart';

enum _BannerState { completo, bonus, restando, semVidas }

_BannerState _stateFor(int current) {
  if (current == 0) return _BannerState.semVidas;
  if (current < 5) return _BannerState.restando;
  if (current == 5) return _BannerState.completo;
  return _BannerState.bonus;
}

Color _colorFor(_BannerState s) => switch (s) {
      _BannerState.completo  => const Color(0xFF66BB6A),
      _BannerState.bonus     => const Color(0xFFFFD54F),
      _BannerState.restando  => const Color(0xFFFFA726),
      _BannerState.semVidas  => const Color(0xFFEF5350),
    };

class LivesStatusBanner extends StatefulWidget {
  final int current;
  final int previousCurrent;
  final DateTime lastRegenAt;

  const LivesStatusBanner({
    super.key,
    required this.current,
    required this.previousCurrent,
    required this.lastRegenAt,
  });

  /// Public static for unit testing without widget pump.
  static String timerTextFor(DateTime lastRegenAt, DateTime now) {
    final next = lastRegenAt.add(const Duration(minutes: 30));
    final remaining = next.difference(now);
    if (remaining.isNegative) return '00:00';
    final mm = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  State<LivesStatusBanner> createState() => _LivesStatusBannerState();
}

class _LivesStatusBannerState extends State<LivesStatusBanner>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 50),
    ]).animate(_scaleCtrl);
    _updateCountdownTimer();
  }

  @override
  void didUpdateWidget(LivesStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.current > oldWidget.current) {
      _scaleCtrl.forward(from: 0);
    }
    if (widget.current != oldWidget.current) {
      _updateCountdownTimer();
    }
  }

  void _updateCountdownTimer() {
    _countdownTimer?.cancel();
    if (_stateFor(widget.current) == _BannerState.restando) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scaleCtrl.dispose();
    super.dispose();
  }

  String _timerText() => LivesStatusBanner.timerTextFor(widget.lastRegenAt, DateTime.now());


  String _label(_BannerState s) => switch (s) {
        _BannerState.completo => 'Completo',
        _BannerState.bonus    => 'Bônus',
        _BannerState.restando => 'Restando ${_timerText()}',
        _BannerState.semVidas => 'Sem vidas',
      };

  @override
  Widget build(BuildContext context) {
    final s = _stateFor(widget.current);
    final color = _colorFor(s);
    final label = _label(s);

    return SizedBox(
      width: 120,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: ScaleTransition(
          key: ValueKey(s),
          scale: _scaleAnim,
          child: Container(
            key: ValueKey(s),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.30),
                ),
              ],
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: outlinedWhiteTextStyle(
                GoogleFonts.fredoka(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
