import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/wisdom_topic.dart';
import '../utils/api_retry.dart';
import '../utils/constants.dart';

/// Fetches shared Wisdom topics from media-resources.
class WisdomService {
  WisdomService({
    http.Client? client,
    String? baseUrl,
  })  : baseUrl = _normalizeBaseUrl(baseUrl ?? AppConstants.apiBaseUrl),
        _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  /// GET `/api/wisdom/topics`.
  Future<WisdomTopicsResponse> fetchTopics({
    ApiOnRetry? onRetry,
    ApiOnSlow? onSlow,
  }) {
    return runWithRetries(
      () => _fetchTopicsOnce(),
      onRetry: onRetry,
      onSlow: onSlow,
    );
  }

  Future<WisdomTopicsResponse> _fetchTopicsOnce() async {
    final uri = Uri.parse('$baseUrl${AppConstants.wisdomTopicsPath}');
    late final http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
    } on Exception catch (e) {
      throw ApiHttpException(
        'Cannot reach wisdom API at $uri ($e)',
        retryable: true,
      );
    }

    if (response.statusCode != 200) {
      throw ApiHttpException(
        'Wisdom API fetch failed (${response.statusCode}): ${response.body}',
        retryable: isRetryableStatusCode(response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiHttpException(
        'Unexpected wisdom API response shape.',
        retryable: false,
      );
    }
    if (decoded.containsKey('error')) {
      throw ApiHttpException(
        decoded['message']?.toString() ?? decoded['error'].toString(),
        retryable: false,
      );
    }
    return WisdomTopicsResponse.fromJson(decoded);
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
