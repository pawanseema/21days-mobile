import 'package:flutter/material.dart';

/// Shri Mataji portrait for the yellow chrome bar (leading).
class ChromePortrait extends StatelessWidget {
  const ChromePortrait({super.key, this.height = 44});

  final double height;

  static const assetPath = 'assets/images/shri_mataji_portrait.png';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Image.asset(
        assetPath,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
