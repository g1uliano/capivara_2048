// lib/presentation/widgets/shop_package_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/shop_package.dart';

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
