import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DreamLoop Design System
/// A dark, magical, dreamy aesthetic with pixel-game vibes.

class DreamColors {
  // Primary palette
  static const primary = Color(0xFF6C5CE7);
  static const primaryLight = Color(0xFF8B7FE8);
  static const accent = Color(0xFF00CEC9);
  static const accentLight = Color(0xFF55E6C1);

  // Backgrounds
  static const backgroundDark = Color(0xFF0A0E21);
  static const backgroundCard = Color(0xFF1A1A2E);
  static const backgroundSurface = Color(0xFF16213E);

  // Tones
  static const cute = Color(0xFFFD79A8);
  static const adventure = Color(0xFFFDCB6E);
  static const mystery = Color(0xFFA29BFE);
  static const horror = Color(0xFFE17055);
  static const bonding = Color(0xFF55E6C1);

  // Text
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFB0B0C3);
  static const textMuted = Color(0xFF6C6C80);

  // Utility
  static const success = Color(0xFF00B894);
  static const warning = Color(0xFFFDCB6E);
  static const error = Color(0xFFE17055);
  static const divider = Color(0xFF2D2D44);
}

class DreamTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: DreamColors.backgroundDark,
      primaryColor: DreamColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: DreamColors.primary,
        secondary: DreamColors.accent,
        surface: DreamColors.backgroundCard,
        error: DreamColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: DreamColors.textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: DreamColors.textPrimary,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: DreamColors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: DreamColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DreamColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: DreamColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: DreamColors.textPrimary,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: DreamColors.textSecondary,
            height: 1.5,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DreamColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: DreamColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: DreamColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: DreamColors.backgroundCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DreamColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DreamColors.textPrimary,
          side: const BorderSide(color: DreamColors.divider, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DreamColors.backgroundSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DreamColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: DreamColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      dividerColor: DreamColors.divider,
    );
  }
}
