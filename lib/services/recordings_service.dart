import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/year_recordings.dart';
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
  Future<YearRecordings> fetchYearRecordings() async {
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
      throw RecordingsException(
        'Cannot reach recordings API at $uri. '
        'Is the backend running? ($e)',
      );
    }

    if (response.statusCode != 200) {
      throw RecordingsException(
        'Recordings API fetch failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw RecordingsException('Unexpected recordings API response shape.');
    }
    if (decoded.containsKey('error')) {
      throw RecordingsException(
        decoded['message']?.toString() ?? decoded['error'].toString(),
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

class RecordingsException implements Exception {
  RecordingsException(this.message);
  final String message;

  @override
  String toString() => 'RecordingsException: $message';
}
