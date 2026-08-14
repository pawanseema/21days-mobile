import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../models/recording_model.dart';
import '../../theme/app_theme.dart';
import 'youtube_embed.dart';

/// In-app YouTube player for a video search hit (starts at section timestamp).
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.result});

  final RecordingResult result;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;

    final videoId = widget.result.videoId.isNotEmpty
        ? widget.result.videoId
        : (YoutubePlayer.convertUrlToId(widget.result.url) ?? '');

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        startAt: widget.result.startSeconds,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openExternally() async {
    final url = widget.result.youtubeWatchUrl;
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final theme = Theme.of(context);
    final title = [
      if (result.videoTitle.isNotEmpty) result.videoTitle,
      if (result.sectionTitle.isNotEmpty) result.sectionTitle,
    ].join(' — ');

    final details = Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.sectionTitle.isNotEmpty)
            Text(result.sectionTitle, style: theme.textTheme.headlineSmall),
          if (result.videoTitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              result.videoTitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: context.colors.deepTeal,
              ),
            ),
          ],
          if (result.timestamp.isNotEmpty || result.durationLabel != null) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (result.timestamp.isNotEmpty) 'Starts ${result.timestamp}',
                if (result.durationLabel != null) result.durationLabel,
              ].join(' · '),
              style: theme.textTheme.labelLarge?.copyWith(
                color: context.colors.mutedInk,
              ),
            ),
          ],
          if (result.chakra.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Pill(label: result.chakra),
          ],
          if (result.summary.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(result.summary, style: theme.textTheme.bodyLarge),
          ],
          if (result.quote.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '"${result.quote}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: context.colors.mutedInk,
              ),
            ),
          ],
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: _openExternally,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open on YouTube'),
          ),
        ],
      ),
    );

    if (kIsWeb) {
      final embed = buildYoutubeEmbed(result);
      return Scaffold(
        backgroundColor: context.colors.pageBlue,
        appBar: AppBar(
          title: Text(
            title.isEmpty ? 'Video' : title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: ListView(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: embed ??
                  const ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: Text(
                        'Video unavailable',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
            ),
            details,
          ],
        ),
      );
    }

    final controller = _controller!;
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: context.colors.warmOrange,
        progressColors: ProgressBarColors(
          playedColor: context.colors.warmOrange,
          handleColor: context.colors.deepTeal,
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: context.colors.pageBlue,
          appBar: AppBar(
            title: Text(
              title.isEmpty ? 'Video' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: ListView(
            children: [player, details],
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.apricotMist,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.colors.warmOrange,
            ),
      ),
    );
  }
}
