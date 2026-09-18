import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/daily_meditation_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/layout_breakpoints.dart';
import '../resources/video_player_screen.dart';
import '../resources/video_result_card.dart';

/// More tab — expandable Today's Meditation section.
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyMeditationProvider>().ensureLoaded();
    });
  }

  Future<void> _openPlayer(DailyMeditationProvider meditation) async {
    final result = meditation.activeResult;
    if (result == null) return;
    await meditation.markPlayed();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meditation = context.watch<DailyMeditationProvider>();
    final result = meditation.activeResult;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppLayout.space(context, 16),
        AppLayout.space(context, 12),
        AppLayout.space(context, 16),
        AppLayout.space(context, 24),
      ),
      children: [
        Material(
          color: context.colors.listPanel,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.colors.mist),
            ),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                onExpansionChanged: meditation.setExpanded,
                backgroundColor: context.colors.listPanel,
                collapsedBackgroundColor: context.colors.listPanel,
                tilePadding: EdgeInsets.symmetric(
                  horizontal: AppLayout.space(context, 16),
                  vertical: AppLayout.space(context, 4),
                ),
                childrenPadding: EdgeInsets.fromLTRB(
                  AppLayout.space(context, 12),
                  0,
                  AppLayout.space(context, 12),
                  AppLayout.space(context, 14),
                ),
                title: Text(
                  "Today's Meditation",
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: context.colors.ink,
                  ),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppLayout.space(context, 14),
                      vertical: AppLayout.space(context, 12),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFC6E4FD).withValues(alpha: 0.46),
                          context.colors.softTeal.withValues(alpha: 0.27),
                        ],
                      ),
                      border: Border.all(
                        color: context.colors.softTeal.withValues(alpha: 0.36),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.ink.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: context.colors.ink.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Find a quiet place. Sit comfortably and relaxed. '
                      'When you feel settled, click to play the meditation video below.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.colors.ink,
                        height: 1.45,
                      ),
                    ),
                  ),
                  SizedBox(height: AppLayout.space(context, 12)),
                  if (meditation.loading && result == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (meditation.error != null && result == null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppLayout.space(context, 12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            meditation.error!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          SizedBox(height: AppLayout.space(context, 10)),
                          TextButton(
                            onPressed: () => meditation.ensureLoaded(),
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    )
                  else if (result != null)
                    VideoResultCard(
                      result: result,
                      onTap: () => _openPlayer(meditation),
                      showSectionTitle: false,
                      showSummary: false,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
