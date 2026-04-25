import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFF3FA968),
      cardColor: const Color(0xFFE8D5B7),
      primaryColor: const Color(0xFFFF8C42),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFF8C42),
        primary: const Color(0xFFFF8C42),
        surface: const Color(0xFFE8D5B7),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.fredoka(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF3E2723),
        ),
        displayMedium: GoogleFonts.fredoka(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF3E2723),
        ),
        displaySmall: GoogleFonts.fredoka(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF3E2723),
        ),
        headlineMedium: GoogleFonts.fredoka(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF3E2723),
        ),
        titleLarge: GoogleFonts.fredoka(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3E2723),
        ),
        bodyLarge: GoogleFonts.nunito(color: const Color(0xFF3E2723)),
        bodyMedium: GoogleFonts.nunito(color: const Color(0xFF3E2723)),
        labelLarge: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8C42),
          foregroundColor: const Color(0xFFE8D5B7),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
