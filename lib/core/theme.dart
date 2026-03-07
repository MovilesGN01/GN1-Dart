import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Colour palette ──────────────────────────────────────────────────────────
abstract final class AppColors {
  static const primary = Color(0xFF1F5DFF);
  static const background = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF555555);
  static const muted = Color(0xFF94A3B8);
  static const cardSurface = Color(0xFFF8FAFC);
}

// ── Theme ────────────────────────────────────────────────────────────────────
final ThemeData uniRideTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.background,
  ),
  scaffoldBackgroundColor: AppColors.background,

  // Typography – Poppins for every text style
  textTheme: GoogleFonts.poppinsTextTheme().copyWith(
    bodyLarge: GoogleFonts.poppins(
      color: AppColors.textPrimary,
      fontSize: 16,
    ),
    bodyMedium: GoogleFonts.poppins(
      color: AppColors.textSecondary,
      fontSize: 14,
    ),
    bodySmall: GoogleFonts.poppins(
      color: AppColors.muted,
      fontSize: 12,
    ),
    titleLarge: GoogleFonts.poppins(
      color: AppColors.textPrimary,
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: GoogleFonts.poppins(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    labelLarge: GoogleFonts.poppins(
      color: AppColors.background,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),

  // AppBar
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.background,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.poppins(
      color: AppColors.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
  ),

  // ElevatedButton – full-width feel, primary colour, radius 12
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.background,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      elevation: 0,
    ),
  ),

  // InputDecoration – rounded 8 px, muted hint
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.cardSurface,
    hintStyle: GoogleFonts.poppins(
      color: AppColors.muted,
      fontSize: 14,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.muted, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.muted, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.red, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
  ),
);