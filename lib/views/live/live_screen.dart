import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/session_model.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';

/// Live tab — YouTube-backed live / upcoming session from `/api/live/sessions`.
class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join link is not configured yet.')),
      );
      return;
    }
    final uri = Uri.parse(trimmed);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $trimmed')),
        );
      }
    }
  }

  String _countdown(LiveSession session) {
    if (session.isLiveNow) return 'Happening now';
    final until = session.timeUntilStart;
    if (until == null) return 'Scheduled on YouTube';
    if (until.isNegative) return 'Starting soon';
    if (until.inHours >= 24) {
      final days = until.inDays;
      return 'In $days day${days == 1 ? '' : 's'}';
    }
    return 'In ${until.inHours}h ${until.inMinutes.remainder(60)}m';
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<SessionProvider>();
    final theme = Theme.of(context);

    if (sessionState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sessionState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Unable to load live sessions',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                sessionState.error!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: sessionState.refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final session = sessionState.session;
    if (session == null) {
      return RefreshIndicator(
        onRefresh: sessionState.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
          children: [
            Icon(
              Icons.self_improvement_outlined,
              size: 56,
              color: AppColors.ink.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 18),
            Text(
              'No live or upcoming session right now',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'We check the Sahaja Yoga YouTube channels for a stream that '
              'is live, or scheduled within the next 72 hours. Pull to refresh.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedInk,
              ),
            ),
          ],
        ),
      );
    }

    final start = session.startsAt;
    final dateLabel = start == null
        ? null
        : DateFormat('EEEE, MMM d').format(start);
    final timeLabel =
        start == null ? null : DateFormat('h:mm a').format(start);
    final eyebrow = session.isLiveNow ? 'Live now' : 'Upcoming live session';

    return RefreshIndicator(
      onRefresh: sessionState.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withValues(alpha: 0.72),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (session.isLiveNow) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'LIVE',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bannerYellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Upcoming',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  eyebrow,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.mutedInk,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  session.title.isEmpty
                      ? 'Sahaja Yoga meditation'
                      : session.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.ink,
                  ),
                ),
                if (session.channelLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _MetaRow(
                    icon: Icons.podcasts_outlined,
                    label: session.channelLabel,
                  ),
                ],
                if (dateLabel != null) ...[
                  const SizedBox(height: 8),
                  _MetaRow(
                    icon: Icons.calendar_today_outlined,
                    label: dateLabel,
                  ),
                ],
                if (timeLabel != null) ...[
                  const SizedBox(height: 8),
                  _MetaRow(
                    icon: Icons.schedule_outlined,
                    label: timeLabel,
                  ),
                ],
                const SizedBox(height: 8),
                _MetaRow(
                  icon: Icons.timelapse_outlined,
                  label: _countdown(session),
                ),
                if (session.isLiveNow) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Choose how you would like to join',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedInk,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _JoinButton(
                          label: 'Watch on YouTube',
                          icon: Icons.play_circle_outline,
                          onPressed: session.hasYouTube
                              ? () => _open(
                                    context,
                                    session.youtubeLiveUrl,
                                  )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _JoinButton(
                          label: 'Join Zoom Meeting',
                          icon: Icons.videocam_outlined,
                          onPressed: session.hasZoom
                              ? () => _open(
                                    context,
                                    session.zoomMeetingUrl,
                                  )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (session.isUpcoming) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable reminder',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      session.canRemind
                          ? 'Get gentle alerts 30, 15, and 1 minute before this '
                              'session starts. Join links appear when the stream '
                              'goes live.'
                          : 'This session is scheduled on YouTube, but a start '
                              'time is not available yet. Pull to refresh later.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (session.canRemind) ...[
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: sessionState.remindersScheduled
                            ? null
                            : sessionState.enableReminders,
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: Text(
                          sessionState.remindersScheduled
                              ? 'Reminders enabled'
                              : 'Enable reminder',
                        ),
                      ),
                    ],
                    if (sessionState.statusMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        sessionState.statusMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.deepTeal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.mist,
        disabledForegroundColor: AppColors.mutedInk,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.mutedInk),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.ink,
                ),
          ),
        ),
      ],
    );
  }
}
