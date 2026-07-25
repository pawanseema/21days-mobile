import 'package:flutter/material.dart';

import '../../models/wisdom_topic.dart';
import '../../theme/app_theme.dart';

/// Wisdom tab — scrollable static meditation topics.
class WisdomScreen extends StatelessWidget {
  const WisdomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topics = WisdomCatalog.topics;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      itemCount: topics.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meditation wisdom', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Foundational Sahaja Yoga topics to deepen your attention.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final topic = topics[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openDetail(context, topic),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.mist),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 56,
                      decoration: BoxDecoration(
                        color: index.isEven
                            ? AppColors.softTeal
                            : AppColors.softOrange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (topic.accentLabel != null)
                            Text(
                              topic.accentLabel!.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.warmOrange,
                                letterSpacing: 1.1,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(topic.title, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(topic.subtitle, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.mutedInk,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openDetail(BuildContext context, WisdomTopic topic) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.mist,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(topic.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(topic.subtitle, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                Text(topic.body, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        );
      },
    );
  }
}
