import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';

/// Live tab — upcoming (reminders) vs live-now (YouTube / Zoom join).
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
              const SizedBox(height: 8),
              Text(
                'If you are on Chrome/web and Flask logs show 200, the browser '
                'is likely blocking the response (CORS). Restart the local API '
                'after enabling CORS, then tap Retry.',
                style: theme.textTheme.bodySmall,
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
      return const Center(child: Text('No upcoming session.'));
    }

    final dateLabel = DateFormat('EEEE, MMM d').format(session.startsAt);
    final timeLabel = DateFormat('h:mm a').format(session.startsAt);
    final until = session.timeUntilStart;
    final countdown = session.isLiveNow
        ? 'Happening now'
        : until.inHours >= 24
            ? 'In ${until.inDays} day${until.inDays == 1 ? '' : 's'}'
            : until.isNegative
                ? 'Starting soon'
                : 'In ${until.inHours}h ${until.inMinutes.remainder(60)}m';

    final eyebrow = session.isLiveNow ? 'Live now' : 'Upcoming live session';

    return RefreshIndicator(
      onRefresh: sessionState.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: session.isLiveNow
                    ? const [
                        AppColors.warmOrange,
                        Color(0xFFD4A06A),
                        AppColors.deepTeal,
                      ]
                    : const [
                        AppColors.deepTeal,
                        Color(0xFF5F9A92),
                        AppColors.softOrange,
                      ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  session.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _MetaRow(icon: Icons.calendar_today_outlined, label: dateLabel),
                const SizedBox(height: 8),
                _MetaRow(icon: Icons.schedule_outlined, label: timeLabel),
                const SizedBox(height: 8),
                _MetaRow(icon: Icons.timelapse_outlined, label: countdown),
                if (session.isLiveNow) ...[
                  const SizedBox(height: 22),
                  Text(
                    'Choose how you would like to join',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
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
                              ? () => _open(context, session.youtubeLiveUrl)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _JoinButton(
                          label: 'Join Zoom Meeting',
                          icon: Icons.videocam_outlined,
                          onPressed: session.hasZoom
                              ? () => _open(context, session.zoomMeetingUrl)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (session.description != null &&
              session.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(session.description!, style: theme.textTheme.bodyLarge),
          ],
          if (session.isUpcoming) ...[
            const SizedBox(height: 24),
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
                      'Get gentle alerts 30, 15, and 1 minute before this '
                      'session starts. Join links appear when the session '
                      'goes live.',
                      style: theme.textTheme.bodyMedium,
                    ),
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
        backgroundColor: Colors.white,
        foregroundColor: AppColors.deepTeal,
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.55),
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
        Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
        ),
      ],
    );
  }
}
