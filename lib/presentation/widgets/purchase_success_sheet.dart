import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';

class PurchaseSuccessSheet extends StatelessWidget {
  const PurchaseSuccessSheet({
    super.key,
    required this.shareCode,
    this.onDismiss,
  });

  final String shareCode;
  final VoidCallback? onDismiss;

  static Future<void> show(BuildContext context, String shareCode) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PurchaseSuccessSheet(
        shareCode: shareCode,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('✅', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(
              'Compra realizada!',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Seus itens foram adicionados.',
              style: GoogleFonts.nunito(fontSize: 14, color: Colors.grey[700]),
            ),
            const Divider(height: 32),
            Text(
              '🎁 Presente para um amigo:',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                shareCode,
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  letterSpacing: 2,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: shareCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado!')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text('Copiar', style: GoogleFonts.nunito()),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text: 'Use este código em Olha o Bichim!: $shareCode',
                      subject: 'Presente no Olha o Bichim!',
                    ),
                  ),
                  icon: const Icon(Icons.share, size: 18),
                  label: Text('Compartilhar', style: GoogleFonts.nunito()),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Válido por 30 dias · 1 uso',
              style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continuar jogando',
                  style: GoogleFonts.fredoka(fontSize: 17),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
