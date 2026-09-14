import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../utils/layout_breakpoints.dart';
import 'chrome_portrait.dart';

/// Fixed yellow-bar branding shared across all tabs.
///
/// Wrap with [PreferredSize] using [preferredHeightFor] so the status-bar
/// inset is included (required on notched iPhones).
class ChromeHeader extends StatelessWidget {
  const ChromeHeader({super.key});

  static const headline = 'Explore 21 Days';
  static const subtitle = 'Online Sahaja Yoga Meditation Course';
  static const aboutUrl = 'https://us.sahajayoga.org/21days/';

  /// Yellow bar content height below the status bar.
  static const double contentHeight = 76;

  /// Status bar styling so Android (Pixel) matches the yellow chrome from cold start.
  /// Custom [PreferredSize] app bars do not apply [AppBarTheme.systemOverlayStyle].
  static SystemUiOverlayStyle systemOverlayFor(Color chromeBackground) {
    return SystemUiOverlayStyle(
      statusBarColor: chromeBackground,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.dark,
    );
  }

  /// Full AppBar height including status-bar / notch inset.
  static double preferredHeightFor(BuildContext context) =>
      MediaQuery.paddingOf(context).top + contentHeight;

  static PreferredSize preferredSizeFor(BuildContext context) => PreferredSize(
        preferredSize: Size.fromHeight(preferredHeightFor(context)),
        child: const ChromeHeader(),
      );

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
    final comfortable = AppLayout.isComfortable(context);
    final narrow = MediaQuery.sizeOf(context).width < 768;
    // Phone baselines; [AppLayout.fontSize] is 1.0 on iPhone, 1.3 on Android
    // phone, 1.75 on tablet.
    final portraitHeight = comfortable
        ? AppLayout.space(context, 52)
        : (narrow ? 52.0 : 64.0);
    final headlineSize = AppLayout.fontSize(context, narrow ? 17 : 20);
    final subtitleSize = AppLayout.fontSize(context, narrow ? 11.5 : 13);
    final aboutSize = AppLayout.fontSize(context, 13);
    final overlay = systemOverlayFor(colors.chromeBackground);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Material(
        color: colors.chromeBackground,
        elevation: 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.chromeBackground,
            border: Border(
              bottom: BorderSide(
                color: colors.ink.withValues(alpha: 0.154),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.ink.withValues(alpha: 0.11),
                blurRadius: 9,
                offset: const Offset(0, 3.5),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: contentHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ChromePortrait(height: portraitHeight),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width - 140,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                headline,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: display.titleLarge?.copyWith(
                                  color: colors.chromeForeground,
                                  fontWeight: FontWeight.w700,
                                  fontSize: headlineSize,
                                  height: 1.15,
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
                                  fontSize: subtitleSize,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openAbout(context),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.ink,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'About',
                        style: display.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: aboutSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
