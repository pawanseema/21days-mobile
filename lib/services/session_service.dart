import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/recent_recording.dart';
import '../models/session_model.dart';
import '../utils/api_retry.dart';
import '../utils/constants.dart';

/// Fetches live / upcoming session and recent recordings from media-resources.
class SessionService {
  SessionService({
    http.Client? client,
    String? baseUrl,
  })  : baseUrl = _normalizeBaseUrl(baseUrl ?? AppConstants.apiBaseUrl),
        _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  /// GET `/api/live/sessions`.
  ///
  /// Returns `null` when the backend has no live or soon-upcoming broadcast
  /// (`session: null`).
  Future<LiveSession?> fetchNextSession({ApiOnRetry? onRetry}) async {
    final decoded = await _getJson(AppConstants.liveSessionsPath, onRetry: onRetry);
    final sessionJson = decoded['session'];
    if (sessionJson == null) return null;
    if (sessionJson is! Map<String, dynamic>) {
      throw ApiHttpException(
        'Unexpected session object in API response.',
        retryable: false,
      );
    }
    return LiveSession.fromJson(sessionJson);
  }

  /// GET `/api/live/recent` — at most one completed stream per channel (≤72h).
  Future<List<RecentRecording>> fetchRecentRecordings({ApiOnRetry? onRetry}) async {
    final decoded = await _getJson(AppConstants.liveRecentPath, onRetry: onRetry);
    final items = decoded['items'];
    if (items == null) return const [];
    if (items is! List) {
      throw ApiHttpException(
        'Unexpected recent recordings response shape.',
        retryable: false,
      );
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(RecentRecording.fromJson)
        .where((r) => r.videoId.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    ApiOnRetry? onRetry,
  }) {
    return runWithRetries(
      () => _getJsonOnce(path),
      onRetry: onRetry,
    );
  }

  Future<Map<String, dynamic>> _getJsonOnce(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    late final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 90));
    } on Exception catch (e) {
      throw ApiHttpException(
        'Cannot reach live API at $uri ($e)',
        retryable: true,
      );
    }

    if (response.statusCode != 200) {
      throw ApiHttpException(
        _apiErrorMessage(response),
        retryable: isRetryableStatusCode(response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiHttpException(
        'Unexpected live API response shape.',
        retryable: false,
      );
    }
    if (decoded.containsKey('error')) {
      throw ApiHttpException(
        decoded['message']?.toString() ?? decoded['error'].toString(),
        retryable: false,
      );
    }
    return decoded;
  }

  static String _apiErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString().trim() ?? '';
        final error = decoded['error']?.toString().trim() ?? '';
        if (message.isNotEmpty &&
            message.length < 180 &&
            !message.contains('Traceback')) {
          return message;
        }
        if (error.isNotEmpty) return error;
      }
    } catch (_) {}
    if (response.statusCode == 503) {
      return 'Service temporarily unavailable';
    }
    return 'Live API fetch failed (${response.statusCode})';
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
