import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/handout_model.dart';
import '../../models/recording_model.dart';
import '../../providers/search_provider.dart';
import '../../theme/app_theme.dart';
import 'handout_result_card.dart';
import 'video_player_screen.dart';
import 'video_result_card.dart';

/// Resources tab — Videos (`/search`) and Handouts (`/api/resources/search`).
class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    final next =
        _tabs.index == 0 ? ResourceTab.videos : ResourceTab.handouts;
    final search = context.read<SearchProvider>();
    if (search.tab != next) {
      _controller.clear();
      search.setTab(next);
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openVideo(RecordingResult item) async {
    final hasId = item.videoId.isNotEmpty ||
        item.youtubeWatchUrl.contains('youtube.com') ||
        item.youtubeWatchUrl.contains('youtu.be');
    if (!hasId && item.youtubeWatchUrl.isEmpty) return;

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerScreen(result: item),
      ),
    );
    // Match HTML: engage seed after the player is closed.
    if (!mounted) return;
    context.read<SearchProvider>().markEngaged(item);
  }

  Future<void> _openHandout(HandoutResult item) async {
    if (!item.hasDownloadUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No download link for this handout.')),
      );
      return;
    }
    final uri = Uri.parse(item.downloadUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${item.downloadUrl}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resources', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                search.tab == ResourceTab.videos
                    ? 'Semantic search over meditation video sections'
                    : 'Semantic search over practice handouts',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabs,
                labelColor: context.colors.deepTeal,
                unselectedLabelColor: context.colors.mutedInk,
                indicatorColor: context.colors.deepTeal,
                tabs: const [
                  Tab(text: 'Videos'),
                  Tab(text: 'Handouts'),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: search.search,
                decoration: InputDecoration(
                  hintText: search.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: search.hasQuery
                      ? IconButton(
                          onPressed: () {
                            _controller.clear();
                            search.clear();
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: search.isLoading
                      ? null
                      : () => search.search(_controller.text),
                  child: Text(
                    search.isLoading ? 'Searching…' : 'Search',
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (search.relatedViewActive)
          _RelatedBanner(
            search: search,
            onBack: () {
              search.backToSearchResults();
              _controller.text = search.query;
              _controller.selection =
                  TextSelection.collapsed(offset: search.query.length);
            },
          ),
        const Divider(height: 1),
        Expanded(
          child: _ResultsPane(
            onOpenVideo: _openVideo,
            onOpenHandout: _openHandout,
          ),
        ),
      ],
    );
  }
}

class _RelatedBanner extends StatelessWidget {
  const _RelatedBanner({required this.search, required this.onBack});

  final SearchProvider search;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = search.relatedSeed?.sectionTitle.trim().isNotEmpty == true
        ? search.relatedSeed!.sectionTitle
        : 'this clip';

    return Material(
      color: context.colors.apricotMist,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Showing more like: ',
                  style: theme.textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.deepTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed: onBack,
              child: const Text('← Back to Search Result'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsPane extends StatelessWidget {
  const _ResultsPane({
    required this.onOpenVideo,
    required this.onOpenHandout,
  });

  final Future<void> Function(RecordingResult item) onOpenVideo;
  final Future<void> Function(HandoutResult item) onOpenHandout;

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final theme = Theme.of(context);

    if (search.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(search.loadingMessage, style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    if (search.error != null &&
        !(search.relatedViewActive &&
            search.error == 'No similar segments found.')) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(search.error!, textAlign: TextAlign.center),
        ),
      );
    }

    if (search.relatedViewActive && search.videoResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            search.error ?? 'No similar segments found.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    if (!search.hasQuery && !search.relatedViewActive) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            search.emptyPrompt,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: context.colors.mutedInk,
            ),
          ),
        ),
      );
    }

    if (search.tab == ResourceTab.videos) {
      if (search.videoResults.isEmpty) {
        return const Center(
          child: Text('No results found. Try a different search query.'),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        itemCount: search.videoResults.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = search.videoResults[index];
          return VideoResultCard(
            result: item,
            showFindSimilar: search.showFindSimilarOn(item),
            onFindSimilar: () => search.findSimilarClips(item),
            onTap: () => onOpenVideo(item),
          );
        },
      );
    }

    if (search.handoutResults.isEmpty) {
      return const Center(
        child: Text('No results found. Try a different search query.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: search.handoutResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = search.handoutResults[index];
        return HandoutResultCard(
          result: item,
          onTap: () => onOpenHandout(item),
        );
      },
    );
  }
}
