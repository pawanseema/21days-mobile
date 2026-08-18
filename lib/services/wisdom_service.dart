import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/wisdom_topic.dart';
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
  Future<WisdomTopicsResponse> fetchTopics() async {
    final uri = Uri.parse('$baseUrl${AppConstants.wisdomTopicsPath}');
    late final http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
    } on Exception catch (e) {
      throw WisdomException(
        'Cannot reach wisdom API at $uri. '
        'Is the backend running? ($e)',
      );
    }

    if (response.statusCode != 200) {
      throw WisdomException(
        'Wisdom API fetch failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw WisdomException('Unexpected wisdom API response shape.');
    }
    if (decoded.containsKey('error')) {
      throw WisdomException(
        decoded['message']?.toString() ?? decoded['error'].toString(),
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

class WisdomException implements Exception {
  WisdomException(this.message);
  final String message;

  @override
  String toString() => 'WisdomException: $message';
}
