import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/year_recordings.dart';
import '../utils/api_retry.dart';
import '../utils/constants.dart';

/// Fetches year playlist recordings from media-resources.
class RecordingsService {
  RecordingsService({
    http.Client? client,
    String? baseUrl,
  })  : baseUrl = _normalizeBaseUrl(baseUrl ?? AppConstants.apiBaseUrl),
        _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  /// GET `/api/recordings` — latest year, sessions sliced oldest-first.
  Future<YearRecordings> fetchYearRecordings({
    ApiOnRetry? onRetry,
    ApiOnSlow? onSlow,
  }) {
    return runWithRetries(
      () => _fetchYearRecordingsOnce(),
      onRetry: onRetry,
      onSlow: onSlow,
    );
  }

  Future<YearRecordings> _fetchYearRecordingsOnce() async {
    final uri = Uri.parse('$baseUrl${AppConstants.recordingsPath}');
    late final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 60));
    } on Exception catch (e) {
      throw ApiHttpException(
        'Cannot reach recordings API at $uri ($e)',
        retryable: true,
      );
    }

    if (response.statusCode != 200) {
      throw ApiHttpException(
        'Recordings API fetch failed (${response.statusCode}): ${response.body}',
        retryable: isRetryableStatusCode(response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiHttpException(
        'Unexpected recordings API response shape.',
        retryable: false,
      );
    }
    if (decoded.containsKey('error')) {
      throw ApiHttpException(
        decoded['message']?.toString() ?? decoded['error'].toString(),
        retryable: false,
      );
    }
    return YearRecordings.fromJson(decoded);
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
