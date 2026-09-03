import 'package:flutter/material.dart';

import '../../models/handout_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/layout_breakpoints.dart';

/// Handout search card — title + description in release; optional debug pills.
class HandoutResultCard extends StatelessWidget {
  const HandoutResultCard({
    super.key,
    required this.result,
    required this.onTap,
    this.showResultDebug = false,
  });

  final HandoutResult result;
  final VoidCallback onTap;
  final bool showResultDebug;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showFileType =
        showResultDebug && result.fileType.trim().isNotEmpty;
    final debugTags =
        showResultDebug ? result.tags.take(6).toList(growable: false) : const <String>[];

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(AppLayout.space(context, 16)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.mist),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      result.title.isEmpty ? 'Handout' : result.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: AppLayout.fontSize(context, 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.open_in_new,
                    size: AppLayout.fontSize(context, 18),
                    color: context.colors.mutedInk,
                  ),
                ],
              ),
              if (showFileType) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(label: result.fileType.toUpperCase()),
                  ],
                ),
              ],
              if (result.truncatedDescription.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  result.truncatedDescription,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (debugTags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: debugTags
                      .map((tag) => _Chip(label: tag))
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Tap to open →',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: context.colors.deepTeal,
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
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.mist,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.colors.ink,
            ),
      ),
    );
  }
}
