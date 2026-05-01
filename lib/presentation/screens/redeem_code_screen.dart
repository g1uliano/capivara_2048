import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/game_background.dart';

class RedeemCodeScreen extends StatelessWidget {
  const RedeemCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Resgatar Código', style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Text('Em breve', style: GoogleFonts.fredoka(fontSize: 28, color: AppColors.primary)),
        ),
      ),
    );
  }
}
