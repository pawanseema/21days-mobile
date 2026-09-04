import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../models/recording_model.dart';
import '../../models/video_chapter.dart';
import '../../providers/search_provider.dart';
import '../../services/search_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/layout_breakpoints.dart';
import '../../widgets/app_content_width.dart';
import '../../widgets/media_action_bar.dart';
import 'youtube_embed.dart';

/// In-app YouTube player for a video search hit (starts at section timestamp).
///
/// Loads Chroma chapters when available; hides the list if none are ingested.
/// Start offset uses the same `startAt` mechanism as Resources search cards.
///
/// Debug-only metadata (section start timestamp, chakra) follows
/// [SearchProvider.uiConfig.showResultDebug], same as Explore result cards.
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    required this.result,
    this.showResultDebug,
  });

  final RecordingResult result;

  /// When null, uses [SearchProvider] ui-config (defaults to false).
  final bool? showResultDebug;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  YoutubePlayerController? _controller;
  final SearchService _searchService = SearchService();
  List<VideoChapter> _chapters = const [];
  bool _chaptersLoading = true;
  bool _playerReady = false;
  late int _startSeconds;

  String get _videoId {
    if (widget.result.videoId.isNotEmpty) return widget.result.videoId;
    return YoutubePlayer.convertUrlToId(widget.result.url) ?? '';
  }

  RecordingResult get _playbackResult {
    if (_startSeconds == widget.result.startSeconds) {
      return widget.result;
    }
    final r = widget.result;
    return RecordingResult(
      videoTitle: r.videoTitle,
      sectionTitle: r.sectionTitle,
      videoId: r.videoId,
      timestamp: _secondsToTimestamp(_startSeconds),
      summary: r.summary,
      url: r.url,
      chakra: r.chakra,
      quote: r.quote,
      hashtags: r.hashtags,
      publishedAt: r.publishedAt,
      confidence: r.confidence,
      sectionDurationSeconds: r.sectionDurationSeconds,
      chromaId: r.chromaId,
    );
  }

  static String _secondsToTimestamp(int total) {
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _startSeconds = widget.result.startSeconds;
    // Resources cards already carry a section timestamp — start immediately.
    // Recordings (start at 0) wait for chapters so startAt skips the bumper.
    if (_startSeconds > 0) {
      _initPlayer(_startSeconds);
    }
    _loadChaptersAndMaybeStart();
  }

  void _initPlayer(int startAt) {
    if (kIsWeb || _controller != null) return;
    _controller = YoutubePlayerController(
      initialVideoId: _videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        startAt: startAt,
      ),
    );
    _playerReady = true;
  }

  Future<void> _loadChaptersAndMaybeStart() async {
    final id = _videoId;
    if (id.isEmpty) {
      if (mounted) {
        setState(() {
          _chaptersLoading = false;
          _initPlayer(_startSeconds);
          _playerReady = true;
        });
      }
      return;
    }

    try {
      final chapters = await _searchService.fetchVideoChapters(id);
      if (!mounted) return;

      var start = widget.result.startSeconds;
      if (chapters.isNotEmpty) {
        final firstMeaningful = chapters.first.startSeconds;
        // Same idea as Resources: open at the intended section. If we would
        // land in the bumper (or at 0), use the first listed chapter instead.
        if (start < firstMeaningful) {
          start = firstMeaningful;
        }
      }

      setState(() {
        _chapters = chapters;
        _chaptersLoading = false;
        _startSeconds = start;
        _initPlayer(start);
        _playerReady = true;
      });
    } catch (e) {
      debugPrint('VideoPlayerScreen chapters failed: $e');
      if (!mounted) return;
      setState(() {
        _chapters = const [];
        _chaptersLoading = false;
        _initPlayer(_startSeconds);
        _playerReady = true;
      });
    }
  }

  Future<void> _seekToChapter(VideoChapter chapter) async {
    if (kIsWeb) {
      final base = widget.result.videoId.isNotEmpty
          ? 'https://www.youtube.com/watch?v=${widget.result.videoId}'
          : widget.result.youtubeWatchUrl;
      if (base.isEmpty) return;
      final url = chapter.startSeconds > 0
          ? '$base&t=${chapter.startSeconds}s'
          : base;
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return;
    }
    final controller = _controller;
    if (controller == null) return;
    final at = Duration(seconds: chapter.startSeconds);
    // Ensure the player is active before seeking (paused WebViews ignore seeks).
    if (!controller.value.isPlaying) {
      controller.play();
    }
    controller.seekTo(at);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _searchService.dispose();
    super.dispose();
  }

  Future<void> _openExternally() async {
    final url = widget.result.youtubeWatchUrl;
    if (url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  bool get _showResultDebug {
    if (widget.showResultDebug != null) return widget.showResultDebug!;
    return context.watch<SearchProvider>().uiConfig.showResultDebug;
  }

  Widget _buildDetails(ThemeData theme) {
    final result = widget.result;
    final showDebug = _showResultDebug;
    final showStart = showDebug && result.timestamp.isNotEmpty;
    final durationLabel = result.durationLabel;
    return AppContentWidth(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppLayout.space(context, 20),
          AppLayout.space(context, 18),
          AppLayout.space(context, 20),
          AppLayout.space(context, 28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.sectionTitle.isNotEmpty)
              Text(result.sectionTitle, style: theme.textTheme.headlineSmall),
            if (result.videoTitle.isNotEmpty) ...[
              SizedBox(height: AppLayout.space(context, 6)),
              Text(
                result.videoTitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: context.colors.deepTeal,
                ),
              ),
            ],
            if (showStart || durationLabel != null) ...[
              SizedBox(height: AppLayout.space(context, 10)),
              Text(
                [
                  if (showStart) 'Starts ${result.timestamp}',
                  ?durationLabel,
                ].join(' · '),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: context.colors.mutedInk,
                ),
              ),
            ],
            if (showDebug && result.chakra.isNotEmpty) ...[
              SizedBox(height: AppLayout.space(context, 12)),
              _Pill(label: result.chakra),
            ],
            if (result.summary.isNotEmpty) ...[
              SizedBox(height: AppLayout.space(context, 16)),
              Text(result.summary, style: theme.textTheme.bodyLarge),
            ],
            if (result.quote.isNotEmpty) ...[
              SizedBox(height: AppLayout.space(context, 16)),
              Text(
                '"${result.quote}"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: context.colors.mutedInk,
                ),
              ),
            ],
            if (_chaptersLoading) ...[
              SizedBox(height: AppLayout.space(context, 20)),
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ] else if (_chapters.isNotEmpty) ...[
              SizedBox(height: AppLayout.space(context, 22)),
              Text(
                'Jump directly to a section',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: context.colors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppLayout.space(context, 4)),
              ..._chapters.map(
                (chapter) => _ChapterRow(
                  chapter: chapter,
                  onTap: () => _seekToChapter(chapter),
                ),
              ),
            ],
            SizedBox(height: AppLayout.space(context, 18)),
            TextButton.icon(
              onPressed: _openExternally,
              icon: Icon(
                Icons.open_in_new,
                size: AppLayout.fontSize(context, 20),
              ),
              label: const Text('Open on YouTube'),
            ),
          ],
        ),
      ),
    );
  }

  /// Player is a pushed route — outside [HomeShell]'s Theme — so re-apply
  /// comfortable density here for iPad (Explore / Recordings / Upcoming Recent).
  Widget _wrapComfortable(BuildContext context, Widget child) {
    if (!AppLayout.isComfortable(context)) return child;
    return Theme(
      data: AppTheme.comfortableDensity(Theme.of(context)),
      child: child,
    );
  }

  Widget _playerScaffold({
    required String title,
    required Widget playerSlot,
    required bool scrollPlayerWithDetails,
  }) {
    return Builder(
      builder: (context) {
        final details = _buildDetails(Theme.of(context));
        final shareUrl = widget.result.youtubeWatchUrl;
        final shareTitle = [
          if (widget.result.videoTitle.isNotEmpty) widget.result.videoTitle,
          if (widget.result.sectionTitle.isNotEmpty) widget.result.sectionTitle,
        ].join(' — ');
        final actions = MediaActionBar(
          url: shareUrl,
          title: shareTitle.isEmpty ? 'Meditation video' : shareTitle,
        );

        if (scrollPlayerWithDetails) {
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
                playerSlot,
                actions,
                details,
              ],
            ),
          );
        }
        return Scaffold(
          backgroundColor: context.colors.pageBlue,
          appBar: AppBar(
            title: Text(
              title.isEmpty ? 'Video' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: Column(
            children: [
              playerSlot,
              actions,
              Expanded(
                child: ListView(
                  children: [details],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final title = [
      if (result.videoTitle.isNotEmpty) result.videoTitle,
      if (result.sectionTitle.isNotEmpty) result.sectionTitle,
    ].join(' — ');

    if (kIsWeb) {
      return _wrapComfortable(
        context,
        _playerScaffold(
          title: title,
          scrollPlayerWithDetails: false,
          playerSlot: AspectRatio(
            aspectRatio: 16 / 9,
            child: !_playerReady && _startSeconds == 0
                ? const ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                : (buildYoutubeEmbed(_playbackResult) ??
                    const ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: Text(
                          'Video unavailable',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )),
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return _wrapComfortable(
        context,
        _playerScaffold(
          title: title,
          scrollPlayerWithDetails: true,
          playerSlot: const AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
        ),
      );
    }

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
        // Keep the player pinned so scrolling chapters/details does not
        // detach the WebView (which pauses playback and breaks seekTo).
        return _wrapComfortable(
          context,
          _playerScaffold(
            title: title,
            scrollPlayerWithDetails: false,
            playerSlot: player,
          ),
        );
      },
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.chapter,
    required this.onTap,
  });

  final VideoChapter chapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppLayout.space(context, 5),
            horizontal: AppLayout.space(context, 4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: AppLayout.space(context, 72),
                child: Text(
                  chapter.timestamp,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: context.colors.deepTeal,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              SizedBox(width: AppLayout.space(context, 8)),
              Expanded(
                child: Text(
                  chapter.sectionTitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: context.colors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.space(context, 10),
        vertical: AppLayout.space(context, 4),
      ),
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
