import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/reduce_effects_provider.dart';
import '../controllers/game_notifier.dart';
import 'outlined_text.dart';

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

    Widget content = Stack(
      children: [
        // Background
        Positioned.fill(
          child: Container(
            color: reduceEffects
                ? const Color(0xE6000000)
                : const Color(0x4DFFF8E7),
          ),
        ),
        // Black tint layer
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.25)),
        ),
        // Content
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '⏸',
                style: TextStyle(
                  fontSize: 64,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        color: Colors.black,
                        blurRadius: 2,
                        offset: const Offset(1.5, 1.5)),
                    Shadow(
                        color: Colors.black,
                        blurRadius: 2,
                        offset: const Offset(-1.5, -1.5)),
                    Shadow(
                        color: Colors.black,
                        blurRadius: 2,
                        offset: const Offset(1.5, -1.5)),
                    Shadow(
                        color: Colors.black,
                        blurRadius: 2,
                        offset: const Offset(-1.5, 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedText(
                text: 'Pausado',
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
                  OutlinedText(
                    text: 'Reduzir efeitos visuais',
                    style: const TextStyle(color: Colors.white),
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
                  child: OutlinedText(
                    text: 'Debug',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
      ],
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
        child: OutlinedText(
          text: label,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
