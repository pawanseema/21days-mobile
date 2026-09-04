import 'package:flutter/foundation.dart';

import '../models/handout_model.dart';
import '../models/recording_model.dart';
import '../models/ui_config_model.dart';
import '../services/search_service.dart';
import '../utils/api_messages.dart';

enum ResourceTab { videos, handouts }

class _SearchSnapshot {
  const _SearchSnapshot({required this.query, required this.results});

  final String query;
  final List<RecordingResult> results;
}

/// Per-mode Explore session (query + cards + video-only related state).
class _ModeSession {
  const _ModeSession({
    this.query = '',
    this.videoResults = const [],
    this.handoutResults = const [],
    this.error,
    this.engagedSeed,
    this.relatedViewActive = false,
    this.relatedSeed,
    this.searchSnapshot,
  });

  final String query;
  final List<RecordingResult> videoResults;
  final List<HandoutResult> handoutResults;
  final String? error;
  final RecordingResult? engagedSeed;
  final bool relatedViewActive;
  final RecordingResult? relatedSeed;
  final _SearchSnapshot? searchSnapshot;
}

/// Drives Explore: Videos / Handouts search + more-like-this for videos.
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
  String? _loadingHint;
  String? _error;
  UiConfig _uiConfig = const UiConfig();

  /// Clip the user last watched (button appears on this card after closing player).
  RecordingResult? _engagedSeed;

  /// True while showing related results from `/api/videos/related`.
  bool _relatedViewActive = false;
  RecordingResult? _relatedSeed;
  _SearchSnapshot? _searchSnapshot;

  /// Last session per mode so Videos ↔ Handouts can restore cards.
  _ModeSession _videosSession = const _ModeSession();
  _ModeSession _handoutsSession = const _ModeSession();

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
      ? 'Search meditation videos'
      : 'Search meditation handouts';

  String get emptyPrompt => _tab == ResourceTab.videos
      ? 'Try searching for a topic from your recent sessions.'
      : 'Search for affirmations, chakras, or practice guides.';

  /// Starter queries matching media-resources Explore chips.
  /// Ordered shortest-first so wrap uses less vertical space.
  List<String> get examplePrompts => _tab == ResourceTab.videos
      ? const [
          'Foot Soak with Mark',
          'Meditation with Flute',
          'Heart chakra meditation',
          'Meditation and Daily Life',
          "Founder's talk on Innocence",
          'Experience the silence within',
          'What is Sahaja Yoga Meditation?',
        ]
      : const [
          'Beginner meditation handout',
          'Chakra overview',
          'Daily meditation practice guide',
          'Affirmations for meditation',
          'How to raise Kundalini',
          'Online meditation classes',
        ];

  String get loadingMessage {
    if (_loadingHint != null) return _loadingHint!;
    if (_tab == ResourceTab.handouts) return 'Searching handouts…';
    if (_findingRelated) return 'Finding similar clips…';
    return 'Searching for relevant videos…';
  }

  void _markSlow() {
    if (_loadingHint == ApiMessages.retrying) return;
    _loadingHint = ApiMessages.takingLonger;
    notifyListeners();
  }

  void _markRetrying() {
    _loadingHint = ApiMessages.retrying;
    notifyListeners();
  }

  bool showFindSimilarOn(RecordingResult result) {
    if (!enableMoreLikeThis || _relatedViewActive) return false;
    if (_tab != ResourceTab.videos) return false;
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

  _ModeSession _captureSession() {
    if (_tab == ResourceTab.videos) {
      return _ModeSession(
        query: _query,
        videoResults: List<RecordingResult>.from(_videoResults),
        error: _error,
        engagedSeed: _engagedSeed,
        relatedViewActive: _relatedViewActive,
        relatedSeed: _relatedSeed,
        searchSnapshot: _searchSnapshot,
      );
    }
    return _ModeSession(
      query: _query,
      handoutResults: List<HandoutResult>.from(_handoutResults),
      error: _error,
    );
  }

  void _applySession(_ModeSession session) {
    _query = session.query;
    _error = session.error;
    _loading = false;
    _loadingHint = null;
    _findingRelated = false;
    if (_tab == ResourceTab.videos) {
      _videoResults = session.videoResults;
      _engagedSeed = session.engagedSeed;
      _relatedViewActive = session.relatedViewActive;
      _relatedSeed = session.relatedSeed;
      _searchSnapshot = session.searchSnapshot;
    } else {
      _handoutResults = session.handoutResults;
      _clearRelatedState();
    }
  }

  void setTab(ResourceTab tab) {
    if (_tab == tab) return;
    if (_tab == ResourceTab.videos) {
      _videosSession = _captureSession();
    } else {
      _handoutsSession = _captureSession();
    }
    _tab = tab;
    _applySession(
      tab == ResourceTab.videos ? _videosSession : _handoutsSession,
    );
    notifyListeners();
  }

  Future<void> search(String query) async {
    final requestedTab = _tab;
    _query = query;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _error = null;
      _loadingHint = null;
      if (requestedTab == ResourceTab.videos) {
        _videoResults = const [];
        _clearRelatedState();
        _videosSession = const _ModeSession();
      } else {
        _handoutResults = const [];
        _handoutsSession = const _ModeSession();
      }
      notifyListeners();
      return;
    }

    _loading = true;
    _loadingHint = null;
    _error = null;
    if (requestedTab == ResourceTab.videos) {
      _clearRelatedState();
    }
    notifyListeners();

    try {
      if (requestedTab == ResourceTab.videos) {
        final response = await _searchService.searchVideos(
          query: trimmed,
          onRetry: () {
            if (_tab == requestedTab) _markRetrying();
          },
          onSlow: () {
            if (_tab == requestedTab) _markSlow();
          },
        );
        final sorted = [...response.results]
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
        _videoResults = sorted;
        _videosSession = _ModeSession(query: trimmed, videoResults: sorted);
        if (_tab != requestedTab) return;
      } else {
        final response = await _searchService.searchHandouts(
          query: trimmed,
          onRetry: () {
            if (_tab == requestedTab) _markRetrying();
          },
          onSlow: () {
            if (_tab == requestedTab) _markSlow();
          },
        );
        final sorted = [...response.results]
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
        _handoutResults = sorted;
        _handoutsSession = _ModeSession(query: trimmed, handoutResults: sorted);
        if (_tab != requestedTab) return;
      }
    } catch (e) {
      debugPrint('SearchProvider search failed: $e');
      if (_tab != requestedTab) return;
      _error = ApiMessages.requestFailed;
      if (requestedTab == ResourceTab.videos) {
        _videoResults = const [];
        _videosSession = _ModeSession(query: trimmed);
      } else {
        _handoutResults = const [];
        _handoutsSession = _ModeSession(query: trimmed);
      }
    } finally {
      if (_tab == requestedTab) {
        _loading = false;
        _loadingHint = null;
        notifyListeners();
      }
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
      _error = "Couldn't find similar clips for this result.";
      notifyListeners();
      return;
    }

    final requestedTab = ResourceTab.videos;
    _searchSnapshot ??= _SearchSnapshot(
      query: _query,
      results: List<RecordingResult>.from(_videoResults),
    );
    final snapshot = _searchSnapshot;

    _loading = true;
    _findingRelated = true;
    _loadingHint = null;
    _error = null;
    notifyListeners();

    try {
      final response = await _searchService.fetchRelatedVideos(
        seed: seed,
        onRetry: () {
          if (_tab == requestedTab) _markRetrying();
        },
        onSlow: () {
          if (_tab == requestedTab) _markSlow();
        },
      );
      final relatedSeed = response.seed ?? seed;
      final sorted = [...response.results]
        ..sort((a, b) => b.confidence.compareTo(a.confidence));
      final sessionQuery = snapshot?.query ?? _query;
      _videosSession = _ModeSession(
        query: sessionQuery,
        videoResults: sorted,
        relatedViewActive: true,
        relatedSeed: relatedSeed,
        searchSnapshot: snapshot,
        error: sorted.isEmpty ? 'No similar segments found.' : null,
      );
      if (_tab != requestedTab) return;
      _searchSnapshot = snapshot;
      _videoResults = sorted;
      _relatedViewActive = true;
      _relatedSeed = relatedSeed;
      _engagedSeed = null;
      if (sorted.isEmpty) {
        _error = 'No similar segments found.';
      }
    } catch (e) {
      debugPrint('SearchProvider findSimilarClips failed: $e');
      if (_tab != requestedTab) return;
      _error = ApiMessages.requestFailed;
    } finally {
      if (_tab == requestedTab) {
        _loading = false;
        _findingRelated = false;
        _loadingHint = null;
        notifyListeners();
      }
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
    _videosSession = _ModeSession(
      query: snapshot.query,
      videoResults: snapshot.results,
    );
    notifyListeners();
  }

  void clear() {
    _query = '';
    _error = null;
    _loadingHint = null;
    if (_tab == ResourceTab.videos) {
      _videoResults = const [];
      _clearRelatedState();
      _videosSession = const _ModeSession();
    } else {
      _handoutResults = const [];
      _handoutsSession = const _ModeSession();
    }
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
