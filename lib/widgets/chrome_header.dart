import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import 'chrome_portrait.dart';

/// Fixed yellow-bar branding shared across all tabs.
class ChromeHeader extends StatelessWidget implements PreferredSizeWidget {
  const ChromeHeader({super.key});

  static const headline = 'Explore 21 Days';
  static const subtitle = 'Online Sahaja Yoga Meditation Course';
  static const aboutUrl = 'https://us.sahajayoga.org/21days/';

  @override
  Size get preferredSize => const Size.fromHeight(72);

  Future<void> _openAbout(BuildContext context) async {
    final uri = Uri.parse(aboutUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open About link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final display = theme.textTheme;
    final portraitHeight = MediaQuery.sizeOf(context).width < 768 ? 64.0 : 72.0;

    return Material(
      color: colors.chromeBackground,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 12, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ChromePortrait(height: portraitHeight),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        headline,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: display.titleLarge?.copyWith(
                          color: colors.chromeForeground,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: display.bodyMedium?.copyWith(
                          color: colors.mutedInk,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _openAbout(context),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.ink,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'About',
                    style: display.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
