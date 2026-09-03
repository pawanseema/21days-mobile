import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/layout_breakpoints.dart';
import 'app_palette.dart';

export 'app_palette.dart';

/// Typography + surfaces built from an [AppPalette].
class AppTheme {
  AppTheme._();

  static ThemeData fromPalette(AppPalette colors) {
    final display = GoogleFonts.cormorantGaramondTextTheme();
    final body = GoogleFonts.sourceSans3TextTheme();

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: colors.ink,
        onPrimary: Colors.white,
        secondary: colors.chromeBackground,
        onSecondary: colors.chromeForeground,
        surface: colors.surface,
        onSurface: colors.ink,
        tertiary: colors.accent,
      ),
      scaffoldBackgroundColor: colors.pageBackground,
      extensions: <ThemeExtension<dynamic>>[colors],
    );

    return base.copyWith(
      textTheme: body.copyWith(
        displayLarge: display.displayLarge?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        displayMedium: display.displayMedium?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: display.headlineLarge?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: display.headlineMedium?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: display.headlineSmall?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: display.titleLarge?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: body.titleMedium?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: body.bodyLarge?.copyWith(color: colors.ink, height: 1.45),
        bodyMedium: body.bodyMedium?.copyWith(
          color: colors.mutedInk,
          height: 1.45,
        ),
        labelLarge: body.labelLarge?.copyWith(
          color: colors.ink,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: colors.chromeBackground,
        foregroundColor: colors.chromeForeground,
        titleTextStyle: display.titleLarge?.copyWith(
          color: colors.chromeForeground,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        iconTheme: IconThemeData(color: colors.chromeForeground),
        actionsIconTheme: IconThemeData(color: colors.chromeForeground),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.chromeBackground,
        selectedItemColor: colors.ink,
        unselectedItemColor: colors.mutedInk,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.ink,
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
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.ink, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.mist),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.mist),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.ink, width: 1.6),
        ),
        hintStyle: TextStyle(color: colors.mutedInk),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.mist),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.mist, thickness: 1),
    );
  }

  /// Larger type and control padding for wide layouts (iPad). Phone theme
  /// stays [fromPalette] — call only when [AppLayout.isComfortable].
  static ThemeData comfortableDensity(ThemeData base) {
    final fontScale = AppLayout.comfortableFontScale;
    final input = base.inputDecorationTheme;
    final padV = 14.0 * AppLayout.comfortableSpaceScale;
    final padH = 16.0 * AppLayout.comfortableSpaceScale;
    return base.copyWith(
      textTheme: base.textTheme.apply(fontSizeFactor: fontScale),
      primaryTextTheme: base.primaryTextTheme.apply(fontSizeFactor: fontScale),
      inputDecorationTheme: input.copyWith(
        contentPadding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12 * fontScale,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12 * fontScale),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: (base.elevatedButtonTheme.style ?? const ButtonStyle()).copyWith(
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: 28 * AppLayout.comfortableSpaceScale,
              vertical: 14 * AppLayout.comfortableSpaceScale,
            ),
          ),
        ),
      ),
    );
  }
}
