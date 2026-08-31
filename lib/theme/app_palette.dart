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
    required this.listPanel,
    required this.mist,
    required this.accent,
    required this.accentSoft,
    required this.softTeal,
    required this.accentStrong,
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

  /// Hero cards + content panels (same cool light blue as Explore chips).
  final Color surface;

  /// Grouped list panels — same fill as [surface] for a single panel system.
  final Color listPanel;

  /// Borders and dividers.
  final Color mist;

  /// Warm accent (chips, progress, highlights).
  final Color accent;

  /// Soft wash behind chips / quotes.
  final Color accentSoft;

  /// Cool secondary accent (Wisdom dots, etc.).
  final Color softTeal;

  /// Dark gold for small labels (Wisdom topic kicker).
  final Color accentStrong;

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
    pageBackground: Color(0xFFC6E4FD),
    chromeBackground: Color(0xFFFFF0BF),
    chromeForeground: Color(0xFF133B5B),
    ink: Color(0xFF133B5B),
    mutedInk: Color(0xFF3D5A73),
    // Same cool light blue as Explore chips / original Upcoming frost look.
    surface: Color(0xFFF4F7FA),
    listPanel: Color(0xFFF4F7FA),
    mist: Color(0xFFDAE9ED),
    accent: Color(0xFFF3D485),
    accentSoft: Color(0xFFFFFBEE),
    softTeal: Color(0xFFA5C7DF),
    accentStrong: Color(0xFF6B4E12),
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
    surface: Color(0xFFF4F7FA),
    listPanel: Color(0xFFF4F7FA),
    mist: Color(0xFFD5DDE6),
    accent: Color(0xFF8B7355),
    accentSoft: Color(0xFFF4F1EB),
    softTeal: Color(0xFF6B8499),
    accentStrong: Color(0xFF5C4A38),
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
    Color? listPanel,
    Color? mist,
    Color? accent,
    Color? accentSoft,
    Color? softTeal,
    Color? accentStrong,
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
      listPanel: listPanel ?? this.listPanel,
      mist: mist ?? this.mist,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      softTeal: softTeal ?? this.softTeal,
      accentStrong: accentStrong ?? this.accentStrong,
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
