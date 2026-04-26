import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/reduce_effects_provider.dart';
import '../controllers/game_notifier.dart';

class PauseOverlay extends ConsumerStatefulWidget {
  const PauseOverlay({super.key});

  @override
  ConsumerState<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends ConsumerState<PauseOverlay> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceEffects = ref.watch(reduceEffectsProvider);
    final notifier = ref.read(gameProvider.notifier);

    Widget content = Container(
      color: reduceEffects
          ? const Color(0xE6000000)
          : const Color(0x4DFFF8E7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pause_circle_filled_rounded,
                size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Pausado',
              style: GoogleFonts.fredoka(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            _OverlayButton(
              label: 'Continuar',
              onPressed: notifier.resume,
            ),
            const SizedBox(height: 12),
            _OverlayButton(
              label: 'Reiniciar',
              onPressed: notifier.restart,
            ),
            const SizedBox(height: 12),
            _OverlayButton(
              label: 'Menu',
              onPressed: () {
                notifier.resume();
                Navigator.of(context).maybePop();
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Reduzir efeitos visuais',
                  style: TextStyle(color: Colors.white),
                ),
                Switch(
                  value: reduceEffects,
                  onChanged: (_) =>
                      ref.read(reduceEffectsProvider.notifier).toggle(),
                ),
              ],
            ),
            if (kDebugMode)
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Debug',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
    );

    if (!reduceEffects) {
      content = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: content,
      );
    }

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 250),
      child: content,
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _OverlayButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
