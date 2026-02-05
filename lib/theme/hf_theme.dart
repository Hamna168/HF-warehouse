import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HFBrandColors {
  // Primary Colors - Bold and Professional
  static const Color primaryBlack = Color(0xFF1A1A1A);
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color accentWhite = Color(0xFFFAFAFA);

  // Secondary Colors
  static const Color darkGray = Color(0xFF2D2D2D);
  static const Color mediumGray = Color(0xFF757575);
  static const Color lightGray = Color(0xFFEEEEEE);

  // Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFE63946);
  static const Color infoBlue = Color(0xFF2196F3);

  // Additional Palette
  static const Color softBlack = Color(0xFF424242);
  static const Color borderColor = Color(0xFFCECECE);
}

class HFTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: HFBrandColors.primaryBlack,
      scaffoldBackgroundColor: HFBrandColors.accentWhite,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: HFBrandColors.primaryBlack,
        secondary: HFBrandColors.primaryGold,
        tertiary: HFBrandColors.darkGray,
        surface: HFBrandColors.accentWhite,
        error: HFBrandColors.errorRed,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: HFBrandColors.primaryBlack,
        foregroundColor: HFBrandColors.accentWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: HFBrandColors.accentWhite,
        ),
      ),

      // Text Themes
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: HFBrandColors.primaryBlack,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: HFBrandColors.primaryBlack,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: HFBrandColors.primaryBlack,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: HFBrandColors.primaryBlack,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: HFBrandColors.softBlack,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: HFBrandColors.mediumGray,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: HFBrandColors.mediumGray,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: HFBrandColors.primaryBlack,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HFBrandColors.primaryBlack,
          foregroundColor: HFBrandColors.accentWhite,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: HFBrandColors.primaryBlack, width: 1.5),
          foregroundColor: HFBrandColors.primaryBlack,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HFBrandColors.lightGray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: HFBrandColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: HFBrandColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: HFBrandColors.primaryBlack,
            width: 2,
          ),
        ),
        labelStyle: GoogleFonts.poppins(
          color: HFBrandColors.mediumGray,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: HFBrandColors.accentWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: HFBrandColors.lightGray),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: HFBrandColors.borderColor,
        thickness: 1,
      ),
    );
  }
}
