import 'package:flutter/material.dart';

class InventoryItemButton extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback? onPressed;
  final IconData icon;
  final String? pngPath;

  const InventoryItemButton({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    this.onPressed,
    this.pngPath,
  });

  Widget _fallbackButton() {
    return Material(
      color: const Color(0xFF4CAF50),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Center(child: Icon(icon, color: Colors.white, size: 28)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = count > 0;
    final badgeText = count > 99 ? '99+' : '$count';

    return Tooltip(
      message: '$count $label',
      triggerMode: TooltipTriggerMode.longPress,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ColorFiltered(
              colorFilter: enabled
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                  : const ColorFilter.matrix([
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0,      0,      0,      1, 0,
                    ]),
              child: pngPath != null
                  ? GestureDetector(
                      onTap: onPressed,
                      child: Image.asset(
                        pngPath!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _fallbackButton(),
                      ),
                    )
                  : _fallbackButton(),
            ),
            if (count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
