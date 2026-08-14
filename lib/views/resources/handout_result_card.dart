import 'package:flutter/material.dart';

import '../../models/handout_model.dart';
import '../../theme/app_theme.dart';

/// Handout search card aligned with media-resources handout results UI.
class HandoutResultCard extends StatelessWidget {
  const HandoutResultCard({
    super.key,
    required this.result,
    required this.onTap,
  });

  final HandoutResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
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
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: context.colors.mutedInk,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(label: result.topicLabel, accent: true),
                  if (result.fileType.trim().isNotEmpty)
                    _Chip(label: result.fileType.toUpperCase()),
                ],
              ),
              if (result.truncatedDescription.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  result.truncatedDescription,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (result.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: result.tags
                      .take(6)
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
