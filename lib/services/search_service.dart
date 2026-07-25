import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/recording_model.dart';
import '../utils/constants.dart';

/// Client for the 21days-media-resources semantic search APIs.
///
/// Always calls the live backend:
/// - Local: `http://127.0.0.1:5005` (default)
/// - Cloud Run: pass `--dart-define=API_BASE_URL=https://…run.app`
class SearchService {
  SearchService({
    http.Client? client,
    String? baseUrl,
  })  : baseUrl = _normalizeBaseUrl(baseUrl ?? AppConstants.apiBaseUrl),
        _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  /// POST `/search` — video timestamp sections (Resources tab).
  Future<SearchResponse> searchRecordings({
    required String query,
    int topK = 8,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const SearchResponse(query: '', results: [], count: 0);
    }

    final uri = Uri.parse('$baseUrl${AppConstants.searchPath}');
    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'query': trimmed, 'top_k': topK}),
          )
          .timeout(const Duration(seconds: 60));
    } on Exception catch (e) {
      throw SearchException(
        'Cannot reach search API at $uri. '
        'Start local Flask on :5005, or set API_BASE_URL to your Cloud Run URL. ($e)',
      );
    }

    if (response.statusCode != 200) {
      throw SearchException(
        'Search failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw SearchException('Unexpected search response shape.');
    }
    if (decoded.containsKey('error')) {
      throw SearchException(
        decoded['message']?.toString() ?? decoded['error'].toString(),
      );
    }
    return SearchResponse.fromJson(decoded);
  }

  /// POST `/api/resources/search` — handout / document search.
  Future<SearchResponse> searchHandouts({
    required String query,
    int topK = 5,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const SearchResponse(query: '', results: [], count: 0);
    }

    final uri = Uri.parse('$baseUrl${AppConstants.resourceSearchPath}');
    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'query': trimmed, 'top_k': topK}),
          )
          .timeout(const Duration(seconds: 60));
    } on Exception catch (e) {
      throw SearchException(
        'Cannot reach resource search API at $uri. ($e)',
      );
    }

    if (response.statusCode != 200) {
      throw SearchException(
        'Resource search failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw SearchException('Unexpected resource search response shape.');
    }
    if (decoded.containsKey('error')) {
      throw SearchException(
        decoded['message']?.toString() ?? decoded['error'].toString(),
      );
    }
    return SearchResponse.fromJson(decoded);
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

class SearchException implements Exception {
  SearchException(this.message);
  final String message;

  @override
  String toString() => 'SearchException: $message';
}
