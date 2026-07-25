import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/session_model.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// Live tab — next session time + Join Now (YouTube / Zoom).
class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = context.watch<SessionProvider>();
    final session = sessionState.nextSession;
    final theme = Theme.of(context);

    if (session == null) {
      return const Center(child: Text('No upcoming session.'));
    }

    final dateLabel = DateFormat('EEEE, MMM d').format(session.startsAt);
    final timeLabel = DateFormat('h:mm a').format(session.startsAt);
    final until = session.timeUntilStart;
    final countdown = until.isNegative
        ? 'Happening now'
        : until.inHours >= 24
            ? 'In ${until.inDays} day${until.inDays == 1 ? '' : 's'}'
            : 'In ${until.inHours}h ${until.inMinutes.remainder(60)}m';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
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
                'Next live session',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
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
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.deepTeal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      await _open(session.joinUrl);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
                      }
                    }
                  },
                  icon: Icon(
                    session.platform == LivePlatform.zoom
                        ? Icons.videocam_outlined
                        : Icons.play_circle_outline,
                  ),
                  label: Text(
                    session.isLiveNow ? 'Join Now' : 'Join When Ready',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (session.description != null)
          Text(session.description!, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 20),
        Text('Also available', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _open(AppConstants.defaultYouTubeChannelUrl),
                icon: const Icon(Icons.ondemand_video_outlined),
                label: const Text('YouTube'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _open(AppConstants.defaultZoomUrl),
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Zoom'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Session reminders', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Get gentle alerts 30, 15, and 1 minute before the session starts.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: sessionState.enableReminders,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(
                    sessionState.remindersScheduled
                        ? 'Reminders enabled'
                        : 'Enable reminders',
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
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              ),
        ),
      ],
    );
  }
}
