import 'dart:ui';

import 'package:flutter/material.dart';

/// Soft lift under the Shri Mataji portrait (photo + baked-in name).
///
/// Tune with [ChromePortrait.depth] — `0` flat, `1` medium (default), `2` strong.
enum PortraitDepth {
  flat(0),
  medium(1),
  strong(2);

  const PortraitDepth(this.level);
  final int level;

  static PortraitDepth fromLevel(int level) {
    return switch (level.clamp(0, 2)) {
      0 => PortraitDepth.flat,
      2 => PortraitDepth.strong,
      _ => PortraitDepth.medium,
    };
  }

  double get blurSigma => switch (this) {
        PortraitDepth.flat => 0,
        PortraitDepth.medium => 3.2,
        PortraitDepth.strong => 8.25,
      };

  double get offsetY => switch (this) {
        PortraitDepth.flat => 0,
        PortraitDepth.medium => 2.5,
        PortraitDepth.strong => 6.75,
      };

  double get shadowOpacity => switch (this) {
        PortraitDepth.flat => 0,
        PortraitDepth.medium => 0.28,
        PortraitDepth.strong => 0.6,
      };
}

/// Shri Mataji portrait for the yellow chrome bar (leading).
class ChromePortrait extends StatelessWidget {
  const ChromePortrait({
    super.key,
    this.height = 44,
    this.depth = depthDefault,
  });

  final double height;

  /// Soft-depth amount. Change [depthDefault] (or pass here) to compare looks.
  final PortraitDepth depth;

  /// Single knob for the whole app header: `flat` / `medium` / `strong`.
  static const PortraitDepth depthDefault = PortraitDepth.strong;

  static const assetPath =
      'assets/images/shri_mataji_round_blue_shadow_white_name.png';

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );

    if (depth == PortraitDepth.flat) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: image,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Alpha-following soft shadow (same silhouette as the PNG).
          Transform.translate(
            offset: Offset(0, depth.offsetY),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: depth.blurSigma,
                sigmaY: depth.blurSigma,
                tileMode: TileMode.decal,
              ),
              child: Opacity(
                opacity: depth.shadowOpacity,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    assetPath,
                    height: height,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ),
          ),
          image,
        ],
      ),
    );
  }
}
