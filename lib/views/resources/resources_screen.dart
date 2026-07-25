import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/recording_model.dart';
import '../../providers/search_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/constants.dart';

/// Resources tab — live search against local Flask or Cloud Run `/search`.
class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open(RecordingResult item) async {
    final url = item.youtubeWatchUrl;
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search recorded meditations',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Live semantic search via ${AppConstants.apiBaseUrl}/search',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: search.search,
                decoration: InputDecoration(
                  hintText: 'e.g. chakras, forgiveness, left channel…',
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
                  child: const Text('Search'),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Builder(
            builder: (context) {
              if (search.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (search.error != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(search.error!, textAlign: TextAlign.center),
                  ),
                );
              }
              if (!search.hasQuery) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Try searching for a topic from your recent sessions.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.mutedInk,
                      ),
                    ),
                  ),
                );
              }
              if (search.results.isEmpty) {
                return const Center(child: Text('No recordings found.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                itemCount: search.results.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = search.results[index];
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _open(item),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.mist),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (item.chakra.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.apricotMist,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      item.chakra,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                        color: AppColors.warmOrange,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                if (item.timestamp.isNotEmpty)
                                  Text(
                                    item.timestamp,
                                    style: theme.textTheme.labelMedium,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.sectionTitle,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.videoTitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.deepTeal,
                              ),
                            ),
                            if (item.summary.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                item.summary,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
