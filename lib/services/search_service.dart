import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/handout_model.dart';
import '../models/recording_model.dart';
import '../models/ui_config_model.dart';
import '../models/video_chapter.dart';
import '../utils/constants.dart';

/// Client for the 21days-media-resources semantic search APIs.
///
/// - Videos: `POST /search`
/// - Handouts: `POST /api/resources/search`
/// - Related: `POST /api/videos/related`
/// - Chapters: `GET /api/videos/<id>/chapters`
class SearchService {
  SearchService({
    http.Client? client,
    String? baseUrl,
  })  : baseUrl = _normalizeBaseUrl(baseUrl ?? AppConstants.apiBaseUrl),
        _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  /// GET `/api/ui-config` — feature flags for more-like-this / debug UI.
  Future<UiConfig> fetchUiConfig() async {
    final uri = Uri.parse('$baseUrl${AppConstants.uiConfigPath}');
    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return const UiConfig();
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return UiConfig.fromJson(decoded);
      }
    } catch (_) {
      // Defaults match local Flask when config is unreachable.
    }
    return const UiConfig();
  }

  /// POST `/search` — video timestamp sections.
  Future<SearchResponse> searchVideos({
    required String query,
    int topK = 8,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const SearchResponse(query: '', results: [], count: 0);
    }

    final body = await _postJson(
      path: AppConstants.searchPath,
      payload: {'query': trimmed, 'top_k': topK},
      label: 'video search',
    );
    return SearchResponse.fromJson(body);
  }

  /// Back-compat alias used by older call sites.
  Future<SearchResponse> searchRecordings({
    required String query,
    int topK = 8,
  }) =>
      searchVideos(query: query, topK: topK);

  /// POST `/api/resources/search` — handout / document search.
  Future<HandoutSearchResponse> searchHandouts({
    required String query,
    int topK = 8,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const HandoutSearchResponse(query: '', results: [], count: 0);
    }

    final body = await _postJson(
      path: AppConstants.resourceSearchPath,
      payload: {'query': trimmed, 'top_k': topK},
      label: 'handout search',
    );
    return HandoutSearchResponse.fromJson(body);
  }

  /// POST `/api/videos/related` — more-like-this for a seed clip.
  Future<RelatedVideosResponse> fetchRelatedVideos({
    required RecordingResult seed,
    int topK = 5,
  }) async {
    if (!seed.canRequestRelated) {
      throw SearchException(
        'Cannot find related clips for this result '
        '(missing chroma id or video id/timestamp).',
      );
    }

    final Map<String, dynamic> payload;
    final chromaId = seed.chromaId?.trim();
    if (chromaId != null && chromaId.isNotEmpty) {
      payload = {'id': chromaId, 'top_k': topK};
    } else {
      payload = {
        'video_id': seed.videoId,
        'timestamp': seed.timestamp,
        'top_k': topK,
      };
    }

    final body = await _postJson(
      path: AppConstants.relatedVideosPath,
      payload: payload,
      label: 'related videos',
    );
    return RelatedVideosResponse.fromJson(body, fallbackSeed: seed);
  }

  /// GET `/api/videos/<id>/chapters` — Chroma timestamp sections (may be empty).
  Future<List<VideoChapter>> fetchVideoChapters(String videoId) async {
    final trimmed = videoId.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.parse(
      '$baseUrl${AppConstants.videoChaptersPath(trimmed)}',
    );
    late final http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 30));
    } on Exception {
      return const [];
    }

    if (response.statusCode != 200) return const [];

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return const [];
    if (decoded.containsKey('error')) return const [];

    final raw = decoded['chapters'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(VideoChapter.fromJson)
        .where((c) => c.timestamp.isNotEmpty)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _postJson({
    required String path,
    required Map<String, dynamic> payload,
    required String label,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));
    } on Exception catch (e) {
      throw SearchException(
        'Cannot reach $label API at $uri. '
        'Is Flask running, or is API_BASE_URL set? ($e)',
      );
    }

    if (response.statusCode != 200) {
      throw SearchException(
        '$label failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw SearchException('Unexpected $label response shape.');
    }
    if (decoded.containsKey('error')) {
      throw SearchException(
        decoded['message']?.toString() ?? decoded['error'].toString(),
      );
    }
    return decoded;
  }

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  void dispose() => _client.close();
}

/// Response from `POST /api/videos/related`.
class RelatedVideosResponse {
  const RelatedVideosResponse({
    required this.results,
    required this.count,
    this.seed,
  });

  final RecordingResult? seed;
  final List<RecordingResult> results;
  final int count;

  factory RelatedVideosResponse.fromJson(
    Map<String, dynamic> json, {
    RecordingResult? fallbackSeed,
  }) {
    final raw = (json['results'] as List<dynamic>? ?? const []);
    final results = raw
        .map((e) => RecordingResult.fromJson(e as Map<String, dynamic>))
        .toList();
    RecordingResult? seed;
    final seedJson = json['seed'];
    if (seedJson is Map<String, dynamic>) {
      seed = RecordingResult.fromJson(seedJson);
    }
    return RelatedVideosResponse(
      seed: seed ?? fallbackSeed,
      results: results,
      count: (json['count'] as int?) ?? results.length,
    );
  }
}

class SearchException implements Exception {
  SearchException(this.message);
  final String message;

  @override
  String toString() => 'SearchException: $message';
}
