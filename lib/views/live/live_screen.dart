import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/recent_recording.dart';
import '../../models/recording_model.dart';
import '../../models/session_model.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';
import '../resources/video_player_screen.dart';

/// Live tab — current/upcoming session + recent completed streams (≤72h).
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

  void _openRecording(BuildContext context, RecentRecording recording) {
    final result = RecordingResult(
      videoTitle: recording.title,
      sectionTitle: recording.channelLabel,
      videoId: recording.videoId,
      url: recording.youtubeWatchUrl,
      publishedAt: (recording.endsAt ?? recording.publishedAt)?.toIso8601String() ??
          '',
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerScreen(result: result),
      ),
    );
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

    if (sessionState.error != null && sessionState.session == null) {
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
    final recent = sessionState.recentRecordings;

    return RefreshIndicator(
      onRefresh: sessionState.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (session == null)
            _EmptyLiveCard(theme: theme)
          else ...[
            _LiveSessionCard(
              session: session,
              theme: theme,
              countdown: _countdown(session),
              onOpen: (url) => _open(context, url),
            ),
            if (session.isUpcoming) ...[
              const SizedBox(height: 16),
              _ReminderCard(session: session, sessionState: sessionState),
            ],
          ],
          const SizedBox(height: 28),
          Text(
            'Recent sessions',
            style: theme.textTheme.titleLarge?.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            'Latest recording from each channel (last 72 hours). Tap to watch.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedInk,
            ),
          ),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No recent recordings in the last 72 hours.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedInk,
                ),
              ),
            )
          else
            ...recent.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RecentRecordingCard(
                  recording: item,
                  onTap: () => _openRecording(context, item),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyLiveCard extends StatelessWidget {
  const _EmptyLiveCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(
            Icons.self_improvement_outlined,
            size: 48,
            color: AppColors.ink.withValues(alpha: 0.75),
          ),
          const SizedBox(height: 14),
          Text(
            'No live or upcoming session right now',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            'We look ahead 72 hours for the next stream. Pull to refresh.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveSessionCard extends StatelessWidget {
  const _LiveSessionCard({
    required this.session,
    required this.theme,
    required this.countdown,
    required this.onOpen,
  });

  final LiveSession session;
  final ThemeData theme;
  final String countdown;
  final void Function(String url) onOpen;

  @override
  Widget build(BuildContext context) {
    final start = session.startsAt;
    final dateLabel =
        start == null ? null : DateFormat('EEEE, MMM d').format(start);
    final timeLabel =
        start == null ? null : DateFormat('h:mm a').format(start);
    final eyebrow = session.isLiveNow ? 'Live now' : 'Upcoming live session';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            session.title.isEmpty ? 'Sahaja Yoga meditation' : session.title,
            style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.ink),
          ),
          if (session.channelLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            _MetaRow(icon: Icons.podcasts_outlined, label: session.channelLabel),
          ],
          if (dateLabel != null) ...[
            const SizedBox(height: 8),
            _MetaRow(icon: Icons.calendar_today_outlined, label: dateLabel),
          ],
          if (timeLabel != null) ...[
            const SizedBox(height: 8),
            _MetaRow(icon: Icons.schedule_outlined, label: timeLabel),
          ],
          const SizedBox(height: 8),
          _MetaRow(icon: Icons.timelapse_outlined, label: countdown),
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
                        ? () => onOpen(session.youtubeLiveUrl)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _JoinButton(
                    label: 'Join Zoom Meeting',
                    icon: Icons.videocam_outlined,
                    onPressed: session.hasZoom
                        ? () => onOpen(session.zoomMeetingUrl)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.session,
    required this.sessionState,
  });

  final LiveSession session;
  final SessionProvider sessionState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sessionState.remindersScheduled ? 'Reminder' : 'Enable Reminder',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              !session.canRemind
                  ? 'Start time is not available yet. Pull to refresh later.'
                  : sessionState.remindersScheduled
                      ? 'Reminder is on for 5 minutes before this session starts.'
                      : 'Get notified 5 minutes before this session starts.',
              style: theme.textTheme.bodyMedium,
            ),
            if (session.canRemind) ...[
              const SizedBox(height: 14),
              if (sessionState.remindersScheduled)
                OutlinedButton.icon(
                  onPressed: sessionState.disableReminders,
                  icon: const Icon(Icons.notifications_off_outlined),
                  label: const Text('Disable Reminder'),
                )
              else
                ElevatedButton.icon(
                  onPressed: sessionState.enableReminders,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Enable Reminder'),
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
    );
  }
}

class _RecentRecordingCard extends StatelessWidget {
  const _RecentRecordingCard({
    required this.recording,
    required this.onTap,
  });

  final RecentRecording recording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = recording.endsAt ?? recording.publishedAt;
    final whenLabel =
        when == null ? null : DateFormat('EEE, MMM d · h:mm a').format(when);
    final thumb = recording.thumbnailUrl;

    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.mist),
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
                    if (thumb != null)
                      Image.network(
                        thumb,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stackTrace) =>
                            const ColoredBox(color: AppColors.mist),
                      )
                    else
                      const ColoredBox(color: AppColors.mist),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recording.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (recording.channelLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        recording.channelLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedInk,
                        ),
                      ),
                    ],
                    if (whenLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        whenLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedInk,
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
