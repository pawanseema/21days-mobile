import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/year_recordings.dart';
import '../../providers/recordings_provider.dart';
import '../../theme/app_theme.dart';
import '../resources/video_player_screen.dart';

/// Recordings tab — latest year playlist sliced into collapsible sessions.
class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RecordingsProvider>().ensureLoaded();
    });
  }

  void _openVideo(
    BuildContext context,
    RecordingSession session,
    SessionVideo video,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerScreen(
          result: video.toRecordingResult(sessionLabel: session.label),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecordingsProvider>();
    final theme = Theme.of(context);

    if (state.isLoading || !state.hasAttemptedLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.year == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Unable to load recordings',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                state.error!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: state.refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final year = state.year;
    final sessions = year?.sessions
            .where((session) => session.videos.isNotEmpty)
            .toList(growable: false) ??
        const <RecordingSession>[];
    if (year == null || sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            'No recordings are configured yet.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: state.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            year.title.isNotEmpty ? year.title : '${year.year} recordings',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Open a session to browse its recordings. Tap a row to play in the app.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...sessions.map(
            (session) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SessionTile(
                session: session,
                onVideoTap: (video) => _openVideo(context, session, video),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.onVideoTap,
  });

  final RecordingSession session;
  final ValueChanged<SessionVideo> onVideoTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = session.videos.length;
    final countLabel = count == 0
        ? 'No recordings yet'
        : '$count recording${count == 1 ? '' : 's'}';
    final dateFmt = DateFormat('MMM d, y');
    String? rangeLabel;
    final start = session.startsAt;
    final end = session.endsAt;
    if (start != null && end != null) {
      rangeLabel = start.year == end.year &&
              start.month == end.month &&
              start.day == end.day
          ? dateFmt.format(start)
          : '${dateFmt.format(start)} – ${dateFmt.format(end)}';
    } else if (start != null) {
      rangeLabel = 'Starts ${dateFmt.format(start)}';
    } else if (end != null) {
      rangeLabel = 'Ends ${dateFmt.format(end)}';
    }
    final subtitle = [
      if (rangeLabel != null) rangeLabel,
      countLabel,
    ].join(' · ');

    return Material(
      color: Colors.white,
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
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            title: Text(
              session.label,
              style: theme.textTheme.titleLarge?.copyWith(
                color: context.colors.ink,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: theme.textTheme.bodyMedium,
            ),
            children: [
              if (session.videos.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'This session has no recordings in the playlist yet.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                ...session.videos.map(
                  (video) => _SessionVideoRow(
                    video: video,
                    onTap: () => onVideoTap(video),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionVideoRow extends StatelessWidget {
  const _SessionVideoRow({
    required this.video,
    required this.onTap,
  });

  final SessionVideo video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumb = video.thumbnailUrl;
    final when = video.publishedAt;
    final whenLabel =
        when == null ? null : DateFormat('MMM d, y').format(when);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                        video.title.isEmpty ? 'Meditation' : video.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: context.colors.ink,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
