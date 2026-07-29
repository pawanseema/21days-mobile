import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette aligned with media-resources `ui/search.html`
/// (mobile: blue ~25% lighter; yellow further lightened for banners).
class AppColors {
  AppColors._();

  /// Page background — ~25% lighter than search.html `#67b7f8`.
  static const Color pageBlue = Color(0xFF8DC9FA);

  /// Title / nav banner yellow — lighter pastel than search.html `#ffcf32`.
  static const Color bannerYellow = Color(0xFFFFE58A);

  /// Primary ink used for buttons and text on yellow banners.
  static const Color ink = Color(0xFF133B5B);

  static const Color mutedInk = Color(0xFF3D5A73);
  static const Color softWhite = Color(0xFFFFFFF8);
  static const Color mist = Color(0xFFD6EAF8);
  static const Color softYellow = Color(0xFFFFF8E0);

  // Legacy aliases — mapped onto the new brand so existing screens pick it up.
  static const Color cream = pageBlue;
  static const Color softOrange = Color(0xFFFFE08A);
  static const Color warmOrange = Color(0xFFE8B020);
  static const Color softTeal = Color(0xFF4A8FBF);
  static const Color deepTeal = ink;
  static const Color apricotMist = softYellow;
}

/// Typography + surfaces for the blue / yellow brand.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final display = GoogleFonts.cormorantGaramondTextTheme();
    final body = GoogleFonts.sourceSans3TextTheme();

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.ink,
        onPrimary: Colors.white,
        secondary: AppColors.bannerYellow,
        onSecondary: AppColors.ink,
        surface: AppColors.softWhite,
        onSurface: AppColors.ink,
        tertiary: AppColors.warmOrange,
      ),
      scaffoldBackgroundColor: AppColors.pageBlue,
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
        backgroundColor: AppColors.bannerYellow,
        foregroundColor: AppColors.ink,
        titleTextStyle: display.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
        actionsIconTheme: const IconThemeData(color: AppColors.ink),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bannerYellow,
        selectedItemColor: AppColors.ink,
        unselectedItemColor: AppColors.mutedInk,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
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
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 1.2),
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
          borderSide: const BorderSide(color: AppColors.ink, width: 1.6),
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
