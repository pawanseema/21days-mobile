import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/session_model.dart';
import '../utils/constants.dart';

/// Fetches the current / next live session from the media-resources API.
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
  Future<LiveSession?> fetchNextSession() async {
    final uri = Uri.parse('$baseUrl${AppConstants.liveSessionsPath}');
    late final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));
    } on Exception catch (e) {
      throw SessionException(
        'Cannot reach live session API at $uri. '
        'Is the backend running? ($e)',
      );
    }

    if (response.statusCode != 200) {
      throw SessionException(
        'Live session fetch failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw SessionException('Unexpected live session response shape.');
    }
    if (decoded.containsKey('error')) {
      throw SessionException(
        decoded['message']?.toString() ?? decoded['error'].toString(),
      );
    }

    final sessionJson = decoded['session'];
    if (sessionJson == null) return null;
    if (sessionJson is! Map<String, dynamic>) {
      throw SessionException('Unexpected session object in API response.');
    }
    return LiveSession.fromJson(sessionJson);
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

class SessionException implements Exception {
  SessionException(this.message);
  final String message;

  @override
  String toString() => 'SessionException: $message';
}
