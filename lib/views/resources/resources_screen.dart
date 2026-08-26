import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/handout_model.dart';
import '../../models/recording_model.dart';
import '../../providers/search_provider.dart';
import '../../theme/app_theme.dart';
import 'handout_result_card.dart';
import 'handout_viewer_screen.dart';
import 'video_player_screen.dart';
import 'video_result_card.dart';

/// Explore tab — Videos (`/search`) and Handouts (`/api/resources/search`).
class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final _controller = TextEditingController();
  bool _draftEmpty = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onDraftChanged);
  }

  void _onDraftChanged() {
    final empty = _controller.text.trim().isEmpty;
    if (empty != _draftEmpty) {
      setState(() => _draftEmpty = empty);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onDraftChanged);
    _controller.dispose();
    super.dispose();
  }

  void _selectTab(ResourceTab tab) {
    final search = context.read<SearchProvider>();
    if (search.tab == tab) return;
    _controller.clear();
    search.setTab(tab);
    setState(() => _draftEmpty = true);
  }

  void _runSearch(String query) {
    context.read<SearchProvider>().search(query);
  }

  void _applyExample(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.collapsed(offset: text.length);
    _runSearch(text);
  }

  void _clearSearch() {
    _controller.clear();
    context.read<SearchProvider>().clear();
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

    // Desktop/web Explore stays external; Flutter web also opens externally.
    if (kIsWeb) {
      final uri = Uri.parse(item.downloadUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open that link.")),
        );
      }
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HandoutViewerScreen(handout: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ExploreModeToggle(
                tab: search.tab,
                onSelect: _selectTab,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: _runSearch,
                decoration: InputDecoration(
                  hintText: search.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: !_draftEmpty
                      ? IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                ),
              ),
              if (_draftEmpty &&
                  !search.hasQuery &&
                  !search.relatedViewActive) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final prompt in search.examplePrompts)
                      _ExampleChip(
                        label: prompt,
                        onTap: () => _applyExample(prompt),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
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

class _ExploreModeToggle extends StatelessWidget {
  const _ExploreModeToggle({
    required this.tab,
    required this.onSelect,
  });

  final ResourceTab tab;
  final ValueChanged<ResourceTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.mist),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Videos',
              selected: tab == ResourceTab.videos,
              onTap: () => onSelect(ResourceTab.videos),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'Handouts',
              selected: tab == ResourceTab.handouts,
              onTap: () => onSelect(ResourceTab.handouts),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? context.colors.softTeal : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: context.colors.ink,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: const Color(0xFFF4F7FA),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: context.colors.mist),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: context.colors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                search.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  if (search.relatedViewActive && search.relatedSeed != null) {
                    search.findSimilarClips(search.relatedSeed!);
                  } else {
                    search.search(search.query);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
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
      return const SizedBox.expand();
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
            showResultDebug: search.uiConfig.showResultDebug,
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
          showResultDebug: search.uiConfig.showResultDebug,
          onTap: () => onOpenHandout(item),
        );
      },
    );
  }
}
