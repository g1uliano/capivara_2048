import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/lives/lives_notifier.dart';
import 'info_dialog.dart';
import 'lives_status_banner.dart';

class LivesIndicator extends ConsumerStatefulWidget {
  final double iconSize;
  const LivesIndicator({super.key, this.iconSize = 44.0});

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
    final String title;
    final String message;

    if (lives > regenCap) {
      title = 'Vidas extras! 🎁';
      message =
          'Você tem mais vidas do que o limite normal — são bônus ganhos em recompensas! '
          'Novas vidas não são geradas enquanto você tiver vidas extras. '
          'Elas não expiram, é só jogar!';
    } else if (lives == regenCap) {
      title = 'Banco cheio! ❤️';
      message =
          'Você tem o máximo de vidas ($regenCap). '
          'A regeneração recomeça assim que você usar uma delas no jogo.';
    } else {
      final next = lastRegenAt.add(const Duration(minutes: 30));
      final remaining = next.difference(DateTime.now());
      final mm = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
      final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
      title = 'Regenerando... ⏳';
      message =
          'Próxima vida em $mm:$ss. '
          'Uma nova vida aparece a cada 30 minutos, até o limite de $regenCap.';
    }

    showInfoDialog(
      context: context,
      title: title,
      message: message,
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
              width: widget.iconSize,
              height: widget.iconSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.favorite, color: Colors.redAccent, size: widget.iconSize * 0.9),
                  Text(
                    '${state.lives}',
                    style: GoogleFonts.fredoka(
                      fontSize: widget.iconSize * 0.36,
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
