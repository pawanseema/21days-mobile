import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/wisdom_topic.dart';
import '../../providers/wisdom_provider.dart';
import '../../theme/app_theme.dart';

/// Wisdom tab — topics from `GET /api/wisdom/topics`.
class WisdomScreen extends StatefulWidget {
  const WisdomScreen({super.key});

  @override
  State<WisdomScreen> createState() => _WisdomScreenState();
}

class _WisdomScreenState extends State<WisdomScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WisdomProvider>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WisdomProvider>();
    final theme = Theme.of(context);
    final topics = state.topics;

    if (state.isLoading || !state.hasAttemptedLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: state.refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: topics.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.heading, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  Text(
                    state.subtitle,
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
                    border: Border.all(color: context.colors.mist),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 4,
                        height: 56,
                        decoration: BoxDecoration(
                          color: index.isEven
                              ? context.colors.softTeal
                              : context.colors.softOrange,
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
                                  color: context.colors.warmOrange,
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
                      Icon(
                        Icons.chevron_right,
                        color: context.colors.mutedInk,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, WisdomTopic topic) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                      color: context.colors.mist,
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
