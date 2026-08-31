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
  final Set<String> _openIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WisdomProvider>().ensureLoaded();
    });
  }

  void _toggle(String id) {
    setState(() {
      if (!_openIds.remove(id)) {
        _openIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WisdomProvider>();
    final theme = Theme.of(context);
    final topics = state.topics;

    if (state.isLoading || !state.hasAttemptedLoad) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (state.loadingHint != null) ...[
                const SizedBox(height: 16),
                Text(
                  state.loadingHint!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      );
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
            child: _WisdomTopicCard(
              topic: topic,
              accentTeal: index.isEven,
              expanded: _openIds.contains(topic.id),
              onToggle: () => _toggle(topic.id),
            ),
          );
        },
      ),
    );
  }
}

class _WisdomTopicCard extends StatelessWidget {
  const _WisdomTopicCard({
    required this.topic,
    required this.accentTeal,
    required this.expanded,
    required this.onToggle,
  });

  final WisdomTopic topic;
  final bool accentTeal;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.colors.mist),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accentTeal
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
                              color: context.colors.accentStrong,
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
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.expand_more,
                        color: context.colors.mutedInk,
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: expanded
                    ? Padding(
                        padding: const EdgeInsets.only(left: 18, top: 14),
                        child: Text(
                          topic.body,
                          style: theme.textTheme.bodyLarge,
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
