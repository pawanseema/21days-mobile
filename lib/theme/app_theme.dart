import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Serene Sahaja-inspired palette: clean whites, soft orange & teal.
class AppColors {
  AppColors._();

  static const Color cream = Color(0xFFFFFBF7);
  static const Color softWhite = Color(0xFFFAF8F5);
  static const Color softOrange = Color(0xFFE8A87C);
  static const Color warmOrange = Color(0xFFD4845A);
  static const Color softTeal = Color(0xFF7BA7A0);
  static const Color deepTeal = Color(0xFF4A7C74);
  static const Color ink = Color(0xFF2C3332);
  static const Color mutedInk = Color(0xFF5C6664);
  static const Color mist = Color(0xFFE8EFED);
  static const Color apricotMist = Color(0xFFF7EDE4);
}

/// Elegant typography + light surfaces for a spiritual, calm feel.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final display = GoogleFonts.cormorantGaramondTextTheme();
    final body = GoogleFonts.sourceSans3TextTheme();

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.deepTeal,
        onPrimary: Colors.white,
        secondary: AppColors.warmOrange,
        onSecondary: Colors.white,
        surface: AppColors.softWhite,
        onSurface: AppColors.ink,
        tertiary: AppColors.softOrange,
      ),
      scaffoldBackgroundColor: AppColors.cream,
    );

    return base.copyWith(
      textTheme: body.copyWith(
        displayLarge: display.displayLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        displayMedium: display.displayMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: display.headlineLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: display.headlineMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: display.headlineSmall?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: display.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: body.titleMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: body.bodyLarge?.copyWith(color: AppColors.ink, height: 1.45),
        bodyMedium: body.bodyMedium?.copyWith(
          color: AppColors.mutedInk,
          height: 1.45,
        ),
        labelLarge: body.labelLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        titleTextStyle: display.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.softWhite,
        selectedItemColor: AppColors.deepTeal,
        unselectedItemColor: AppColors.mutedInk,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepTeal,
          side: const BorderSide(color: AppColors.softTeal, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.mist),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.mist),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.softTeal, width: 1.6),
        ),
        hintStyle: const TextStyle(color: AppColors.mutedInk),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.mist),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.mist, thickness: 1),
    );
  }
}
