import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Width breakpoints for tablet / wide-layout adaptation on Flutter.
///
/// Independent of the desktop web shell (separate repo). Phone layouts stay
/// phone-scaled even in landscape; tablets use comfortable density via
/// [shortestSide], not landscape width alone.
class AppLayout {
  AppLayout._();

  /// Centered content column on tablets / wide windows.
  /// 860 leaves ~16% blank on a 13" iPad portrait (~1024pt).
  static const double contentMaxWidth = 860;

  /// Explore results use two columns at or above this width.
  static const double exploreTwoColumnMinWidth = 760;

  /// Gap between Explore result cards in a row.
  static const double exploreGridGap = 12;

  /// Legacy width gate (kept for call sites / docs). Prefer [isComfortable].
  static const double comfortableMinWidth = 700;

  /// Tablet-class devices (iPad, large Android tablets). Phone landscape is
  /// often wider than [comfortableMinWidth] but still phone-height — those
  /// must not get 1.75× type or the yellow chrome overflows.
  static const double comfortableMinShortestSide = 600;

  /// Type / control scale when [isComfortable] is true.
  static const double comfortableFontScale = 1.75;

  /// Android phone-only type scale (iPhone stays 1.0). Not applied on tablet.
  static const double androidPhoneFontScale = 1.25;

  /// Android phone-only scale for yellow-chrome headline/subtitle.
  /// Independent of [androidPhoneFontScale]; iPhone stays on [fontScaleOf].
  static const double androidChromeFontScale = 1.4;

  /// Padding / vertical density scale when comfortable.
  static const double comfortableSpaceScale = 1.4;

  /// How many Explore result columns fit in [contentWidth].
  static int exploreColumnsFor(double contentWidth) =>
      contentWidth >= exploreTwoColumnMinWidth ? 2 : 1;

  /// Logical window size, correcting a known Android first-frame glitch where
  /// [MediaQuery] briefly reports physical pixels as logical size (which would
  /// wrongly trip tablet density, then snap back — a visible font flash).
  static Size sizeOf(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final view = View.maybeOf(context);
    if (view == null) return mq;
    final dpr = view.devicePixelRatio;
    if (dpr <= 0) return mq;
    final viewSize = view.physicalSize / dpr;
    if (mq.shortestSide > viewSize.shortestSide * 1.15 &&
        viewSize.shortestSide >= 300) {
      return viewSize;
    }
    return mq;
  }

  /// Whether the current window should use tablet-comfortable density.
  ///
  /// Uses [shortestSide] so phone landscape (wide but short) stays phone scale.
  static bool isComfortableSize(Size size) =>
      size.shortestSide >= comfortableMinShortestSide;

  static bool isComfortableWidth(double width) => width >= comfortableMinWidth;

  static bool isComfortable(BuildContext context) =>
      isComfortableSize(sizeOf(context));

  /// Android phone (not tablet / not iOS).
  static bool isAndroidPhone(BuildContext context) =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      !isComfortable(context);

  static double fontScaleOf(BuildContext context) {
    // Android phone before tablet: avoids a 1.75→1.25 flash if size flickers.
    if (isAndroidPhone(context)) return androidPhoneFontScale;
    if (isComfortable(context)) return comfortableFontScale;
    return 1.0;
  }

  /// Scale for yellow-chrome headline/subtitle (Android phone may differ).
  static double chromeFontScaleOf(BuildContext context) {
    if (isAndroidPhone(context)) return androidChromeFontScale;
    if (isComfortable(context)) return comfortableFontScale;
    return 1.0;
  }

  /// Phone [phoneSize] scaled for tablet / Android phone; unchanged on iPhone.
  static double fontSize(BuildContext context, double phoneSize) =>
      phoneSize * fontScaleOf(context);

  /// Chrome headline/subtitle size; Android phone uses [androidChromeFontScale].
  static double chromeFontSize(BuildContext context, double phoneSize) =>
      phoneSize * chromeFontScaleOf(context);

  /// Phone padding/spacing scaled up on tablet.
  static double space(BuildContext context, double phoneSize) =>
      phoneSize *
      (isComfortable(context) ? comfortableSpaceScale : 1.0);
}
