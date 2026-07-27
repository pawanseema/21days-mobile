import 'package:flutter/foundation.dart';

import '../models/handout_model.dart';
import '../models/recording_model.dart';
import '../models/ui_config_model.dart';
import '../services/search_service.dart';

enum ResourceTab { videos, handouts }

class _SearchSnapshot {
  const _SearchSnapshot({required this.query, required this.results});

  final String query;
  final List<RecordingResult> results;
}

/// Drives Resources: Videos / Handouts search + more-like-this for videos.
class SearchProvider extends ChangeNotifier {
  SearchProvider({SearchService? searchService})
      : _searchService = searchService ?? SearchService() {
    _loadUiConfig();
  }

  final SearchService _searchService;

  ResourceTab _tab = ResourceTab.videos;
  String _query = '';
  List<RecordingResult> _videoResults = const [];
  List<HandoutResult> _handoutResults = const [];
  bool _loading = false;
  bool _findingRelated = false;
  String? _error;
  UiConfig _uiConfig = const UiConfig();

  /// Clip the user last watched (button appears on this card after closing player).
  RecordingResult? _engagedSeed;

  /// True while showing related results from `/api/videos/related`.
  bool _relatedViewActive = false;
  RecordingResult? _relatedSeed;
  _SearchSnapshot? _searchSnapshot;

  ResourceTab get tab => _tab;
  String get query => _query;
  List<RecordingResult> get videoResults => _videoResults;
  List<HandoutResult> get handoutResults => _handoutResults;
  List<RecordingResult> get results => _videoResults;
  bool get isLoading => _loading;
  bool get isFindingRelated => _findingRelated;
  String? get error => _error;
  bool get hasQuery => _query.trim().isNotEmpty;
  UiConfig get uiConfig => _uiConfig;
  bool get enableMoreLikeThis => _uiConfig.enableMoreLikeThis;
  bool get relatedViewActive => _relatedViewActive;
  RecordingResult? get relatedSeed => _relatedSeed;
  RecordingResult? get engagedSeed => _engagedSeed;

  String get searchHint => _tab == ResourceTab.videos
      ? 'Type your query to search meditation videos…'
      : 'Search meditation handouts…';

  String get emptyPrompt => _tab == ResourceTab.videos
      ? 'Try searching for a topic from your recent sessions.'
      : 'Search for affirmations, chakras, or practice guides.';

  String get loadingMessage {
    if (_tab == ResourceTab.handouts) return 'Searching resources…';
    if (_findingRelated) return 'Finding similar clips…';
    return 'Searching for relevant videos…';
  }

  bool showFindSimilarOn(RecordingResult result) {
    if (!enableMoreLikeThis || _relatedViewActive) return false;
    final engaged = _engagedSeed;
    if (engaged == null) return false;
    return engaged.seedKey == result.seedKey && result.canRequestRelated;
  }

  Future<void> _loadUiConfig() async {
    try {
      _uiConfig = await _searchService.fetchUiConfig();
      notifyListeners();
    } catch (e) {
      debugPrint('UiConfig load failed: $e');
    }
  }

  void setTab(ResourceTab tab) {
    if (_tab == tab) return;
    _tab = tab;
    _query = '';
    _videoResults = const [];
    _handoutResults = const [];
    _error = null;
    _loading = false;
    _clearRelatedState();
    notifyListeners();
  }

  Future<void> search(String query) async {
    _query = query;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _videoResults = const [];
      _handoutResults = const [];
      _error = null;
      _clearRelatedState();
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    _clearRelatedState();
    notifyListeners();

    try {
      if (_tab == ResourceTab.videos) {
        final response = await _searchService.searchVideos(query: trimmed);
        final sorted = [...response.results]
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
        _videoResults = sorted;
        _handoutResults = const [];
      } else {
        final response = await _searchService.searchHandouts(query: trimmed);
        final sorted = [...response.results]
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
        _handoutResults = sorted;
        _videoResults = const [];
      }
    } catch (e) {
      _error = e.toString();
      _videoResults = const [];
      _handoutResults = const [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Called after the user closes the video player (matches HTML `closeModal`).
  void markEngaged(RecordingResult result) {
    if (!enableMoreLikeThis || _tab != ResourceTab.videos) return;
    _engagedSeed = result;
    notifyListeners();
  }

  /// `POST /api/videos/related` for the engaged / given seed clip.
  Future<void> findSimilarClips(RecordingResult seed) async {
    if (!enableMoreLikeThis) return;
    if (!seed.canRequestRelated) {
      _error =
          'Cannot find related clips for this result (missing video id or timestamp).';
      notifyListeners();
      return;
    }

    _searchSnapshot ??= _SearchSnapshot(
      query: _query,
      results: List<RecordingResult>.from(_videoResults),
    );

    _loading = true;
    _findingRelated = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _searchService.fetchRelatedVideos(seed: seed);
      _relatedViewActive = true;
      _relatedSeed = response.seed ?? seed;
      _engagedSeed = null;
      final sorted = [...response.results]
        ..sort((a, b) => b.confidence.compareTo(a.confidence));
      _videoResults = sorted;
      if (sorted.isEmpty) {
        _error = 'No similar segments found.';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      _findingRelated = false;
      notifyListeners();
    }
  }

  /// Restore the original search results (HTML `backToSearch`).
  void backToSearchResults() {
    final snapshot = _searchSnapshot;
    if (snapshot == null) {
      _clearRelatedState();
      notifyListeners();
      return;
    }
    _query = snapshot.query;
    _videoResults = snapshot.results;
    _error = null;
    _clearRelatedState();
    notifyListeners();
  }

  void clear() {
    _query = '';
    _videoResults = const [];
    _handoutResults = const [];
    _error = null;
    _clearRelatedState();
    notifyListeners();
  }

  void _clearRelatedState() {
    _engagedSeed = null;
    _relatedViewActive = false;
    _relatedSeed = null;
    _searchSnapshot = null;
    _findingRelated = false;
  }

  @override
  void dispose() {
    _searchService.dispose();
    super.dispose();
  }
}
