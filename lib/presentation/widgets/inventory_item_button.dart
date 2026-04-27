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

  @override
  Widget build(BuildContext context) {
    final enabled = count > 0;

    return SizedBox(
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
            child: Material(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onPressed,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      pngPath != null
                          ? Image.asset(pngPath!, width: 32, height: 32,
                              errorBuilder: (_, __, ___) =>
                                  Icon(icon, color: Colors.white, size: 22))
                          : Icon(icon, color: Colors.white, size: 22),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                  '$count',
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
    );
  }
}
