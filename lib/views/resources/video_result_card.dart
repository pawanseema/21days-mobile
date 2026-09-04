import 'package:flutter/material.dart';

import '../../models/recording_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/layout_breakpoints.dart';

/// Video search card aligned with media-resources `search.html` video results.
class VideoResultCard extends StatelessWidget {
  const VideoResultCard({
    super.key,
    required this.result,
    required this.onTap,
    this.showFindSimilar = false,
    this.onFindSimilar,
    this.showResultDebug = false,
  });

  final RecordingResult result;
  final VoidCallback onTap;
  final bool showFindSimilar;
  final VoidCallback? onFindSimilar;
  final bool showResultDebug;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.mist),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (result.thumbnailUrl != null)
                      Image.network(
                        result.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            ColoredBox(color: context.colors.mist),
                      )
                    else
                      ColoredBox(color: context.colors.mist),
                    Container(
                      color: Colors.black.withValues(alpha: 0.22),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: AppLayout.fontSize(context, 56),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppLayout.space(context, 14),
                  AppLayout.space(context, 12),
                  AppLayout.space(context, 14),
                  AppLayout.space(context, 14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.videoTitle.isEmpty
                          ? 'Meditation video'
                          : result.videoTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: AppLayout.fontSize(context, 15),
                      ),
                    ),
                    if (result.sectionTitle.isNotEmpty) ...[
                      SizedBox(height: AppLayout.space(context, 4)),
                      Text(
                        result.sectionTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.colors.deepTeal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (showFindSimilar && onFindSimilar != null) ...[
                      SizedBox(height: AppLayout.space(context, 10)),
                      OutlinedButton.icon(
                        onPressed: onFindSimilar,
                        icon: Icon(
                          Icons.auto_awesome,
                          size: AppLayout.fontSize(context, 18),
                        ),
                        label: const Text('Find similar clips'),
                      ),
                    ],
                    if (result.durationLabel != null) ...[
                      SizedBox(height: AppLayout.space(context, 8)),
                      Text(
                        result.durationLabel!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: context.colors.mutedInk,
                        ),
                      ),
                    ],
                    SizedBox(height: AppLayout.space(context, 8)),
                    Text(
                      result.summary.isEmpty
                          ? 'No summary available'
                          : result.summary,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (showResultDebug && result.chakra.isNotEmpty) ...[
                      SizedBox(height: AppLayout.space(context, 10)),
                      _Chip(label: result.chakra, accent: true),
                    ],
                    if (result.quote.isNotEmpty) ...[
                      SizedBox(height: AppLayout.space(context, 10)),
                      Text(
                        '"${result.quote}"',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: context.colors.mutedInk,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent ? context.colors.apricotMist : context.colors.mist,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: accent ? context.colors.warmOrange : context.colors.ink,
            ),
      ),
    );
  }
}
