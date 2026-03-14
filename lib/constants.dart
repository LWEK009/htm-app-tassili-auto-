import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Colors
  static const primary      = Color(0xFF0D47A1);
  static const primaryDark  = Color(0xFF072D66);
  static const primaryLight = Color(0xFF1976D2);
  static const orange       = Color(0xFFE85D04);
  static const orangeLight  = Color(0xFFFF9E00);
  
  // Backgrounds
  static const bg           = Color(0xFFF8FAFD);
  static const glassFixed   = Color(0x15FFFFFF);
  
  // Semantic
  static const success      = Color(0xFF00C853);
  static const error        = Color(0xFFFF1744);
  static const warning      = Color(0xFFFFD600);
  
  // Text
  static const textDark     = Color(0xFF0F172A);
  static const textGrey     = Color(0xFF64748B);
  static const textLight    = Color(0xFF94A3B8);
  static const divider      = Color(0xFFE2E8F0);
}

class AppShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get premium => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}

class AppTheme {
  static ThemeData get theme {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.orange,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );

    return baseTheme.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark),
        titleLarge: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark),
        bodyMedium: const TextStyle(color: AppColors.textGrey, height: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppColors.orange.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
    );
  }
}

