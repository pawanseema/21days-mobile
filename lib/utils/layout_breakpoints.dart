import 'package:flutter/widgets.dart';

/// Width breakpoints for tablet / wide-layout adaptation on Flutter.
///
/// Independent of the desktop web shell (separate repo). Phone widths stay
/// under the comfortable / content thresholds, so iPhone layout is unchanged.
class AppLayout {
  AppLayout._();

  /// Centered content column on tablets / wide windows.
  /// 860 leaves ~16% blank on a 13" iPad portrait (~1024pt).
  static const double contentMaxWidth = 860;

  /// Explore results use two columns at or above this width.
  static const double exploreTwoColumnMinWidth = 760;

  /// Gap between Explore result cards in a row.
  static const double exploreGridGap = 12;

  /// At or above this screen width, use larger type and control padding.
  /// iPhones stay below this; iPads (and wide windows) go above.
  static const double comfortableMinWidth = 700;

  /// Type / control scale when [isComfortable] is true.
  /// iPhone never applies this (width stays under [comfortableMinWidth]).
  static const double comfortableFontScale = 1.75;

  /// Padding / vertical density scale when comfortable.
  static const double comfortableSpaceScale = 1.4;

  /// How many Explore result columns fit in [contentWidth].
  static int exploreColumnsFor(double contentWidth) =>
      contentWidth >= exploreTwoColumnMinWidth ? 2 : 1;

  /// Whether the current window should use tablet-comfortable density.
  static bool isComfortableWidth(double width) => width >= comfortableMinWidth;

  static bool isComfortable(BuildContext context) =>
      isComfortableWidth(MediaQuery.sizeOf(context).width);

  static double fontScaleOf(BuildContext context) =>
      isComfortable(context) ? comfortableFontScale : 1.0;

  /// Phone [phoneSize] scaled up on tablet; unchanged on phone.
  static double fontSize(BuildContext context, double phoneSize) =>
      phoneSize * fontScaleOf(context);

  /// Phone padding/spacing scaled up on tablet.
  static double space(BuildContext context, double phoneSize) =>
      phoneSize *
      (isComfortable(context) ? comfortableSpaceScale : 1.0);
}
