import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';
import '../utils/layout_breakpoints.dart';

/// Share + Copy actions shown under in-app media (video / handout).
///
/// Open externally stays elsewhere (typically at the bottom of the screen).
class MediaActionBar extends StatelessWidget {
  const MediaActionBar({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  bool get _hasUrl => url.trim().isNotEmpty;

  Future<void> _copy(BuildContext context) async {
    if (!_hasUrl) return;
    await Clipboard.setData(ClipboardData(text: url.trim()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied')),
    );
  }

  Future<void> _share(BuildContext context) async {
    if (!_hasUrl) return;
    final label = title.trim().isEmpty ? '21Days' : title.trim();
    await SharePlus.instance.share(
      ShareParams(
        text: '$label\n${url.trim()}',
        subject: label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final iconSize = AppLayout.fontSize(context, 22);

    return Material(
      color: colors.surface,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.space(context, 12),
          vertical: AppLayout.space(context, 8),
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.mist),
          ),
        ),
        child: Row(
          children: [
            _Action(
              icon: Icons.ios_share,
              label: 'Share',
              iconSize: iconSize,
              enabled: _hasUrl,
              onTap: () => _share(context),
              theme: theme,
              colors: colors,
            ),
            SizedBox(width: AppLayout.space(context, 8)),
            _Action(
              icon: Icons.link,
              label: 'Copy link',
              iconSize: iconSize,
              enabled: _hasUrl,
              onTap: () => _copy(context),
              theme: theme,
              colors: colors,
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.iconSize,
    required this.enabled,
    required this.onTap,
    required this.theme,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final double iconSize;
  final bool enabled;
  final VoidCallback onTap;
  final ThemeData theme;
  final AppPalette colors;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: iconSize),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: colors.ink,
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.space(context, 10),
          vertical: AppLayout.space(context, 8),
        ),
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: AppLayout.fontSize(context, 14),
        ),
      ),
    );
  }
}
