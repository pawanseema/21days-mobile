import 'package:flutter/material.dart';

/// Semantic brand colors. Add a new [AppPalette] preset here, then pick it
/// at runtime from Account → Appearance — no screen-by-screen edits.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.id,
    required this.label,
    required this.pageBackground,
    required this.chromeBackground,
    required this.chromeForeground,
    required this.ink,
    required this.mutedInk,
    required this.surface,
    required this.mist,
    required this.accent,
    required this.accentSoft,
    required this.softTeal,
  });

  /// Stable id stored in preferences.
  final String id;

  /// Short name shown in the appearance picker.
  final String label;

  /// Scaffold / page fill.
  final Color pageBackground;

  /// App bar, bottom nav, login title bar.
  final Color chromeBackground;

  /// Text and icons on [chromeBackground].
  final Color chromeForeground;

  /// Primary text and filled buttons.
  final Color ink;

  /// Secondary body text.
  final Color mutedInk;

  /// Cards and input fills.
  final Color surface;

  /// Borders and dividers.
  final Color mist;

  /// Warm accent (chips, progress, highlights).
  final Color accent;

  /// Soft wash behind chips / quotes.
  final Color accentSoft;

  /// Cool secondary accent (Wisdom dots, etc.).
  final Color softTeal;

  // Back-compat aliases used across existing screens.
  Color get pageBlue => pageBackground;
  Color get bannerYellow => chromeBackground;
  Color get cream => pageBackground;
  Color get deepTeal => ink;
  Color get warmOrange => accent;
  Color get softOrange => accent;
  Color get apricotMist => accentSoft;
  Color get softWhite => surface;

  static const String skyYellowId = 'skyYellow';
  static const String slateStoneId = 'slateStone';

  /// Current default — search.html sky blue + yellow chrome.
  static const AppPalette skyYellow = AppPalette(
    id: skyYellowId,
    label: 'Sky & yellow',
    pageBackground: Color(0xFF8DC9FA),
    chromeBackground: Color(0xFFFFE58A),
    chromeForeground: Color(0xFF133B5B),
    ink: Color(0xFF133B5B),
    mutedInk: Color(0xFF3D5A73),
    surface: Color(0xFFFFFFF8),
    mist: Color(0xFFD6EAF8),
    accent: Color(0xFFE8B020),
    accentSoft: Color(0xFFFFF8E0),
    softTeal: Color(0xFF4A8FBF),
  );

  /// Muted ice page, taupe chrome, charcoal-blue ink.
  static const AppPalette slateStone = AppPalette(
    id: slateStoneId,
    label: 'Slate & stone',
    pageBackground: Color(0xFFEAF0F6),
    chromeBackground: Color(0xFFEFECE6),
    chromeForeground: Color(0xFF2C3E50),
    ink: Color(0xFF2C3E50),
    mutedInk: Color(0xFF5A6B7D),
    surface: Color(0xFFFFFFF8),
    mist: Color(0xFFD5DDE6),
    accent: Color(0xFF8B7355),
    accentSoft: Color(0xFFF4F1EB),
    softTeal: Color(0xFF6B8499),
  );

  /// Palettes shown in the appearance picker. Append new schemes here.
  static const List<AppPalette> presets = [
    skyYellow,
    slateStone,
  ];

  static AppPalette byId(String? id) {
    for (final palette in presets) {
      if (palette.id == id) return palette;
    }
    return skyYellow;
  }

  @override
  AppPalette copyWith({
    String? id,
    String? label,
    Color? pageBackground,
    Color? chromeBackground,
    Color? chromeForeground,
    Color? ink,
    Color? mutedInk,
    Color? surface,
    Color? mist,
    Color? accent,
    Color? accentSoft,
    Color? softTeal,
  }) {
    return AppPalette(
      id: id ?? this.id,
      label: label ?? this.label,
      pageBackground: pageBackground ?? this.pageBackground,
      chromeBackground: chromeBackground ?? this.chromeBackground,
      chromeForeground: chromeForeground ?? this.chromeForeground,
      ink: ink ?? this.ink,
      mutedInk: mutedInk ?? this.mutedInk,
      surface: surface ?? this.surface,
      mist: mist ?? this.mist,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      softTeal: softTeal ?? this.softTeal,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    if (t < 0.5) return this;
    return other;
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.skyYellow;
}
