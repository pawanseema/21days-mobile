import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/recent_recording.dart';
import '../../models/recording_model.dart';
import '../../models/session_model.dart';
import '../../providers/search_provider.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';
import '../resources/video_player_screen.dart';

/// Live tab — current/upcoming session + recent completed streams (≤72h).
class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  Future<void> _openExternal(BuildContext context, String url) async {
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
          const SnackBar(content: Text("Couldn't open that link.")),
        );
      }
    }
  }

  void _openLiveYouTube(BuildContext context, LiveSession session) {
    if (session.videoId.trim().isEmpty && !session.hasYouTube) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('YouTube link is not available yet.')),
      );
      return;
    }
    if (session.videoId.trim().isEmpty) {
      _openExternal(context, session.youtubeLiveUrl);
      return;
    }
    final result = RecordingResult(
      videoTitle: session.title.isEmpty
          ? 'Sahaja Yoga meditation'
          : session.title,
      sectionTitle: session.channelLabel,
      videoId: session.videoId,
      url: session.youtubeLiveUrl,
    );
    final showResultDebug =
        context.read<SearchProvider>().uiConfig.showResultDebug;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerScreen(
          result: result,
          showResultDebug: showResultDebug,
        ),
      ),
    );
  }

  void _openRecording(BuildContext context, RecentRecording recording) {
    final result = RecordingResult(
      videoTitle: recording.title,
      sectionTitle: recording.channelLabel,
      videoId: recording.videoId,
      url: recording.youtubeWatchUrl,
      publishedAt: (recording.startsAt ?? recording.publishedAt)?.toIso8601String() ??
          '',
    );
    final showResultDebug =
        context.read<SearchProvider>().uiConfig.showResultDebug;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerScreen(
          result: result,
          showResultDebug: showResultDebug,
        ),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (sessionState.loadingHint != null) ...[
                const SizedBox(height: 16),
                Text(
                  sessionState.loadingHint!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      );
    }

    final session = sessionState.session;
    final recent = sessionState.recentRecordings;
    final loadError = sessionState.error;
    final recentError = sessionState.recentError;

    return RefreshIndicator(
      onRefresh: sessionState.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (loadError != null) ...[
            _LiveLoadErrorBanner(
              message: loadError,
              onRetry: sessionState.refresh,
            ),
            const SizedBox(height: 16),
          ],
          if (session == null && loadError == null)
            _EmptyLiveCard(theme: theme)
          else if (session != null) ...[
            _LiveSessionCard(
              session: session,
              theme: theme,
              countdown: _countdown(session),
              onWatchYouTube: () => _openLiveYouTube(context, session),
              onJoinZoom: () => _openExternal(context, session.zoomMeetingUrl),
            ),
            if (session.isUpcoming) ...[
              const SizedBox(height: 16),
              _ReminderCard(session: session, sessionState: sessionState),
            ],
          ],
          const SizedBox(height: 28),
          Text(
            'Recent',
            style: theme.textTheme.titleLarge?.copyWith(color: context.colors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap to watch',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.colors.mutedInk,
            ),
          ),
          const SizedBox(height: 14),
          if (recentError != null && recent.isEmpty)
            _LiveLoadErrorBanner(
              message: recentError,
              onRetry: sessionState.refresh,
            )
          else if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No recent recordings in the last 72 hours.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.colors.mutedInk,
                ),
              ),
            )
          else ...[
            if (recentError != null) ...[
              _LiveLoadErrorBanner(
                message: recentError,
                onRetry: sessionState.refresh,
              ),
              const SizedBox(height: 12),
            ],
            ...recent.map(
              (item) => _RecentRecordingCard(
                recording: item,
                onTap: () => _openRecording(context, item),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveLoadErrorBanner extends StatelessWidget {
  const _LiveLoadErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(color: context.colors.mist),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
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
            color: context.colors.ink.withValues(alpha: 0.75),
          ),
          const SizedBox(height: 14),
          Text(
            'No live or upcoming session right now',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(color: context.colors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            'We look ahead 72 hours for the next stream. Pull to refresh.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.colors.mutedInk,
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
    required this.onWatchYouTube,
    required this.onJoinZoom,
  });

  final LiveSession session;
  final ThemeData theme;
  final String countdown;
  final VoidCallback onWatchYouTube;
  final VoidCallback onJoinZoom;

  @override
  Widget build(BuildContext context) {
    final start = session.startsAt;
    final dateLabel =
        start == null ? null : DateFormat('EEEE, MMM d').format(start);
    final timeLabel =
        start == null ? null : DateFormat('h:mm a').format(start);
    // Compact density on phone: title ~62.5% of headline, body/meta ~75%.
    final titleSize = (theme.textTheme.headlineSmall?.fontSize ?? 24) * 0.625;
    final bodySize = (theme.textTheme.bodyLarge?.fontSize ?? 16) * 0.75;
    final labelSize = (theme.textTheme.labelLarge?.fontSize ?? 14) * 0.75;
    final sectionSize = (theme.textTheme.titleMedium?.fontSize ?? 16) * 0.75;
    final hintSize = (theme.textTheme.bodyMedium?.fontSize ?? 14) * 0.75;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.72),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: context.colors.ink.withValues(alpha: 0.08),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  fontSize: labelSize,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.bannerYellow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Upcoming',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: context.colors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: labelSize,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            session.title.isEmpty ? 'Sahaja Yoga meditation' : session.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: context.colors.ink,
              fontSize: titleSize,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (session.channelLabel.isNotEmpty) ...[
            const SizedBox(height: 6),
            _MetaRow(
              icon: Icons.podcasts_outlined,
              label: session.channelLabel,
              fontSize: bodySize,
              iconSize: 14,
            ),
          ],
          if (dateLabel != null) ...[
            const SizedBox(height: 6),
            _MetaRow(
              icon: Icons.calendar_today_outlined,
              label: dateLabel,
              fontSize: bodySize,
              iconSize: 14,
            ),
          ],
          if (timeLabel != null) ...[
            const SizedBox(height: 6),
            _MetaRow(
              icon: Icons.schedule_outlined,
              label: timeLabel,
              fontSize: bodySize,
              iconSize: 14,
            ),
          ],
          const SizedBox(height: 6),
          _MetaRow(
            icon: Icons.timelapse_outlined,
            label: countdown,
            fontSize: bodySize,
            iconSize: 14,
          ),
          if (session.isLiveNow) ...[
            const SizedBox(height: 14),
            Text(
              'Join',
              style: theme.textTheme.titleMedium?.copyWith(
                color: context.colors.ink,
                fontSize: sectionSize,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Watch in the app, or join Zoom for the interactive meeting.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.colors.mutedInk,
                fontSize: hintSize,
              ),
            ),
            const SizedBox(height: 10),
            _JoinButton(
              label: 'Watch on YouTube',
              subtitle: 'Plays in this app',
              icon: Icons.play_circle_outline,
              filled: true,
              onPressed: session.hasYouTube || session.videoId.trim().isNotEmpty
                  ? onWatchYouTube
                  : null,
            ),
            const SizedBox(height: 8),
            _JoinButton(
              label: 'Join Zoom Meeting',
              subtitle: 'Opens the Zoom app',
              icon: Icons.videocam_outlined,
              filled: false,
              onPressed: session.hasZoom ? onJoinZoom : null,
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
              'Reminder',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (!session.canRemind)
              Text(
                'Start time is not available yet. Pull to refresh later.',
                style: theme.textTheme.bodyMedium,
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Notify 5 minutes before the session starts',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch.adaptive(
                    value: sessionState.remindersScheduled,
                    activeColor: context.colors.softTeal,
                    onChanged: (enabled) {
                      if (enabled) {
                        sessionState.enableReminders();
                      } else {
                        sessionState.disableReminders();
                      }
                    },
                  ),
                ],
              ),
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
    final when = recording.startsAt ?? recording.publishedAt;
    final whenLabel =
        when == null ? null : DateFormat('EEE, MMM d · h:mm a').format(when);
    final thumb = recording.thumbnailUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 88,
                    height: 50,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (thumb != null)
                          Image.network(
                            thumb,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stackTrace) =>
                                ColoredBox(color: context.colors.mist),
                          )
                        else
                          ColoredBox(color: context.colors.mist),
                        Align(
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.play_circle_fill,
                            color: Colors.white.withValues(alpha: 0.92),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recording.title.isEmpty
                            ? 'Recent session'
                            : recording.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: context.colors.ink,
                          fontSize: 13.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (recording.channelLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          recording.channelLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.colors.mutedInk,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (whenLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          whenLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
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
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: filled
                        ? Colors.white.withValues(alpha: 0.85)
                        : colors.mutedInk,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            filled ? Icons.chevron_right : Icons.open_in_new,
            size: 20,
          ),
        ],
      ),
    );

    if (filled) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: colors.ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.mist,
          disabledForegroundColor: colors.mutedInk,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: content,
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.ink,
        disabledForegroundColor: colors.mutedInk,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        side: BorderSide(color: colors.ink, width: 1.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: onPressed,
      child: content,
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    this.fontSize,
    this.iconSize = 18,
  });

  final IconData icon;
  final String label;
  final double? fontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: iconSize, color: context.colors.mutedInk),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: context.colors.ink,
                  fontSize: fontSize,
                  height: 1.25,
                ),
          ),
        ),
      ],
    );
  }
}
