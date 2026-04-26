import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/lives/lives_notifier.dart';

class LivesIndicator extends ConsumerStatefulWidget {
  const LivesIndicator({super.key});

  @override
  ConsumerState<LivesIndicator> createState() => _LivesIndicatorState();
}

class _LivesIndicatorState extends ConsumerState<LivesIndicator> {
  OverlayEntry? _overlay;

  void _showTimerOverlay(BuildContext context, DateTime lastRegenAt) {
    _overlay?.remove();
    final next = lastRegenAt.add(const Duration(minutes: 30));
    final remaining = next.difference(DateTime.now());
    if (remaining.isNegative) return;
    final mm = remaining.inMinutes.toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlay = OverlayEntry(
      builder: (_) => Positioned(
        top: offset.dy + renderBox.size.height + 4,
        left: offset.dx,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Próxima vida em $mm:$ss',
              style: GoogleFonts.nunito(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
    Future.delayed(const Duration(seconds: 3), () {
      _overlay?.remove();
      _overlay = null;
    });
  }

  @override
  void dispose() {
    _overlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(livesProvider);
    final displayHearts = state.lives.clamp(0, 5);
    final showCount = state.lives > 5;

    return GestureDetector(
      onTap: () => _showTimerOverlay(context, state.lastRegenAt),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 5; i++)
            Icon(
              i < displayHearts ? Icons.favorite : Icons.favorite_border,
              color: Colors.redAccent,
              size: 22,
            ),
          if (showCount) ...[
            const SizedBox(width: 4),
            Text(
              '×${state.lives}',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
