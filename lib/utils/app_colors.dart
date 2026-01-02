import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Background (Cream/Beige)
  static const Color background = Color(0xFFFEF7E6);

  // Primary (Vibrant Orange)
  static const Color primary = Color(0xFFFF9800);

  // Text
  static const Color textPrimary = Color(0xFF1A237E);
  static const Color textPrimaryAlternative = Color(0xFF0D0D0D);

  // Secondary text (Grey)
  static const Color secondaryText = Color(0xFF757575);

  // Success and error
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);

  // Inputs / cards
  static const Color surface = Colors.white;
  static const Color inputBackground = Colors.white;

  // Subtle shadow
  static const Color shadow = Color(0x1F000000);
}

class AppTheme {
  static ThemeData get themeData {
    final base = ThemeData.light();

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
    ).copyWith(
      background: AppColors.background,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondaryText,
      surface: AppColors.surface,
      error: AppColors.error,
      onBackground: AppColors.textPrimary,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      useMaterial3: true,

      // Text using Google Fonts Poppins
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.secondaryText.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.secondaryText.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 4,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          textStyle: base.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
