// lib/presentation/widgets/shop_package_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/shop_package.dart';

const _packImages = {
  'p1': 'assets/images/shop/shop_pack_01.webp',
  'p2': 'assets/images/shop/shop_pack_02.webp',
  'p3': 'assets/images/shop/shop_pack_03.webp',
  'p4': 'assets/images/shop/shop_pack_04.webp',
  'p5': 'assets/images/shop/shop_pack_05.webp',
  'p6': 'assets/images/shop/shop_pack_06.webp',
};

class ShopPackageCard extends StatelessWidget {
  const ShopPackageCard({
    super.key,
    required this.package,
    required this.onBuy,
    this.highlighted = false,
  });

  final ShopPackage package;
  final VoidCallback onBuy;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final imagePath = _packImages[package.id];
    if (imagePath != null) return _ImageCard(imagePath: imagePath, onBuy: onBuy, highlighted: highlighted);
    return _FallbackCard(package: package, onBuy: onBuy, highlighted: highlighted);
  }
}

class _ImageCard extends StatefulWidget {
  const _ImageCard({required this.imagePath, required this.onBuy, required this.highlighted});

  final String imagePath;
  final VoidCallback onBuy;
  final bool highlighted;

  @override
  State<_ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<_ImageCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(16));
    final innerRadius = widget.highlighted
        ? const BorderRadius.all(Radius.circular(13))
        : radius;

    return GestureDetector(
      onTap: widget.onBuy,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: widget.highlighted ? Border.all(color: const Color(0xFFFF8C42), width: 3) : null,
            boxShadow: [
              BoxShadow(
                color: _pressed ? Colors.black38 : Colors.black26,
                blurRadius: _pressed ? 2 : 6,
                offset: _pressed ? const Offset(0, 1) : const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: innerRadius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 100),
              child: Stack(
                children: [
                  Image.asset(widget.imagePath, fit: BoxFit.fitWidth, width: double.infinity),
                  if (_pressed)
                    Positioned.fill(
                      child: ColoredBox(color: Colors.black.withValues(alpha: 0.15)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackCard extends StatelessWidget {
  const _FallbackCard({required this.package, required this.onBuy, required this.highlighted});

  final ShopPackage package;
  final VoidCallback onBuy;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: highlighted
            ? const BorderSide(color: Color(0xFFFF8C42), width: 2)
            : BorderSide.none,
      ),
      elevation: 4,
      shadowColor: Colors.black26,
      color: Colors.white.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    package.name,
                    style: GoogleFonts.fredoka(fontSize: 18),
                  ),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFFF8C42),
                  child: Text(
                    '${package.discountPercent}%',
                    style: GoogleFonts.fredoka(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              package.description,
              style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(
                  child: Text(
                    'De R\$ ${package.originalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: const Color(0xFF9E9E9E),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Por R\$ ${package.currentPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Comprar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
