import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/text_styles.dart';

class PauseButtonTile extends StatefulWidget {
  final double tileSize;
  final VoidCallback onTap;

  const PauseButtonTile({
    super.key,
    required this.tileSize,
    required this.onTap,
  });

  @override
  State<PauseButtonTile> createState() => _PauseButtonTileState();
}

class _PauseButtonTileState extends State<PauseButtonTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Botão Pausar',
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse().then((_) {
            if (mounted) widget.onTap();
          });
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: SizedBox(
            width: widget.tileSize,
            height: widget.tileSize,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF8C42),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pause_circle_filled,
                      color: const Color(0xFFFF8C42),
                      size: widget.tileSize * 0.50,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pausar',
                      style: outlinedWhiteTextStyle(
                        GoogleFonts.fredoka(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
