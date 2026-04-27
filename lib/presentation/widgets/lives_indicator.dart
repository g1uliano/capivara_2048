import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/lives/lives_notifier.dart';

class LivesIndicator extends ConsumerStatefulWidget {
  const LivesIndicator({super.key});

  @override
  ConsumerState<LivesIndicator> createState() => _LivesIndicatorState();
}

class _LivesIndicatorState extends ConsumerState<LivesIndicator>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _elapsed = elapsed);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  String _nextRegenText(DateTime lastRegenAt) {
    final next = lastRegenAt.add(const Duration(minutes: 30));
    final remaining = next.difference(DateTime.now());
    if (remaining.isNegative) return '00:00';
    final mm = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void _onTap() {
    final state = ref.read(livesProvider);
    final timerText = _nextRegenText(state.lastRegenAt);
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
          state.lives >= state.regenCap
              ? 'Vidas cheias!'
              : 'Próxima vida em $timerText',
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
    final isBonusLives = state.lives > state.regenCap;

    return GestureDetector(
      onTap: _onTap,
      child: Stack(
        clipBehavior: Clip.none,
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
          if (isBonusLives)
            Positioned(
              top: -10,
              left: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD600),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  'Bônus ⭐',
                  style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
