import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/lives/lives_notifier.dart';
import 'lives_status_banner.dart';

class LivesIndicator extends ConsumerStatefulWidget {
  const LivesIndicator({super.key});

  @override
  ConsumerState<LivesIndicator> createState() => _LivesIndicatorState();
}

class _LivesIndicatorState extends ConsumerState<LivesIndicator>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _elapsed = Duration.zero;
  int _prevLives = 0;

  @override
  void initState() {
    super.initState();
    _prevLives = ref.read(livesProvider).lives;
    _ticker = createTicker((elapsed) {
      setState(() => _elapsed = elapsed);
    });
    _syncTicker();
  }

  void _syncTicker() {
    final s = ref.read(livesProvider);
    if (s.lives < s.regenCap) {
      if (!_ticker.isActive) _ticker.start();
    } else {
      if (_ticker.isActive) _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  String _semanticsLabel(int lives, int regenCap, DateTime lastRegenAt) {
    if (lives == 0) return 'Sem vidas';
    if (lives == regenCap) return '$lives vidas, banco completo';
    if (lives > regenCap) return '$lives vidas, bônus';
    final next = lastRegenAt.add(const Duration(minutes: 30));
    final remaining = next.difference(DateTime.now());
    final mm = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$lives vidas, próxima em $mm:$ss';
  }

  void _onTap(int lives, int regenCap, DateTime lastRegenAt) {
    final next = lastRegenAt.add(const Duration(minutes: 30));
    final remaining = next.difference(DateTime.now());
    final mm = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Vidas',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 20),
          textAlign: TextAlign.center,
        ),
        content: Text(
          lives >= regenCap
              ? 'Vidas cheias!'
              : 'Próxima vida em $mm:$ss',
          style: GoogleFonts.nunito(fontSize: 15),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Ok', style: GoogleFonts.nunito(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final _ = _elapsed;
    final state = ref.watch(livesProvider);
    _syncTicker();

    // Capturar _prevLives antes do rebuild para passar ao banner
    final prevLives = _prevLives;
    // Atualizar após usar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prevLives = state.lives;
    });

    return Semantics(
      label: _semanticsLabel(state.lives, state.regenCap, state.lastRegenAt),
      child: GestureDetector(
        onTap: () => _onTap(state.lives, state.regenCap, state.lastRegenAt),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.favorite, color: Colors.redAccent, size: 40),
                  Text(
                    '${state.lives}',
                    style: GoogleFonts.fredoka(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            LivesStatusBanner(
              current: state.lives,
              previousCurrent: prevLives,
              lastRegenAt: state.lastRegenAt,
            ),
          ],
        ),
      ),
    );
  }
}
