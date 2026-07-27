/// Search hit shaped like the 21days-media-resources `/search` card payload.
class RecordingResult {
  const RecordingResult({
    required this.videoTitle,
    required this.sectionTitle,
    required this.videoId,
    this.timestamp = '',
    this.summary = '',
    this.url = '',
    this.chakra = '',
    this.quote = '',
    this.hashtags = '',
    this.publishedAt = '',
    this.confidence = 0,
    this.sectionDurationSeconds,
    this.chromaId,
  });

  final String videoTitle;
  final String sectionTitle;
  final String videoId;
  final String timestamp;
  final String summary;
  final String url;
  final String chakra;
  final String quote;
  final String hashtags;
  final String publishedAt;
  final double confidence;
  final int? sectionDurationSeconds;
  final String? chromaId;

  /// Identity key matching media-resources `seedKey()` (`videoId|timestamp`).
  String get seedKey {
    final vid = videoId.isNotEmpty ? videoId : '';
    return '$vid|$timestamp';
  }

  bool get canRequestRelated =>
      (chromaId != null && chromaId!.trim().isNotEmpty) ||
      (videoId.trim().isNotEmpty && timestamp.trim().isNotEmpty);

  /// Start offset in seconds from `timestamp` (e.g. `4:12` → 252).
  int get startSeconds => _timestampToSeconds(timestamp);

  String get youtubeWatchUrl {
    if (videoId.isNotEmpty) {
      final base = 'https://www.youtube.com/watch?v=$videoId';
      if (startSeconds <= 0) return base;
      return '$base&t=${startSeconds}s';
    }
    if (url.isNotEmpty) return url;
    return '';
  }

  String? get thumbnailUrl {
    if (videoId.isEmpty) return null;
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  String? get durationLabel {
    final seconds = sectionDurationSeconds;
    if (seconds == null || seconds <= 0) return null;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return 'Length $h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return 'Length $m:${s.toString().padLeft(2, '0')}';
  }

  factory RecordingResult.fromJson(Map<String, dynamic> json) {
    return RecordingResult(
      videoTitle: (json['video_title'] ?? '') as String,
      sectionTitle: (json['section_title'] ?? '') as String,
      videoId: (json['video_id'] ?? '') as String,
      timestamp: (json['timestamp'] ?? '') as String,
      summary: (json['summary'] ?? '') as String,
      url: (json['url'] ?? '') as String,
      chakra: (json['chakra'] ?? '') as String,
      quote: (json['quote'] ?? '') as String,
      hashtags: (json['hashtags'] ?? '') as String,
      publishedAt: (json['published_at'] ?? '') as String,
      confidence: (json['confidence'] is num)
          ? (json['confidence'] as num).toDouble()
          : 0,
      sectionDurationSeconds: json['section_duration_seconds'] as int?,
      chromaId: json['chroma_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'video_title': videoTitle,
        'section_title': sectionTitle,
        'video_id': videoId,
        'timestamp': timestamp,
        'summary': summary,
        'url': url,
        'chakra': chakra,
        'quote': quote,
        'hashtags': hashtags,
        'published_at': publishedAt,
        'confidence': confidence,
        if (sectionDurationSeconds != null)
          'section_duration_seconds': sectionDurationSeconds,
        if (chromaId != null) 'chroma_id': chromaId,
      };

  static int _timestampToSeconds(String ts) {
    final parts = ts.split(':').map(int.tryParse).toList();
    if (parts.any((p) => p == null)) return 0;
    if (parts.length == 3) {
      return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
    }
    if (parts.length == 2) {
      return parts[0]! * 60 + parts[1]!;
    }
    return parts.first ?? 0;
  }
}

/// Wrapper matching `{ query, results, count }` from the Flask search API.
class SearchResponse {
  const SearchResponse({
    required this.query,
    required this.results,
    required this.count,
  });

  final String query;
  final List<RecordingResult> results;
  final int count;

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    final raw = (json['results'] as List<dynamic>? ?? const []);
    final results = raw
        .map((e) => RecordingResult.fromJson(e as Map<String, dynamic>))
        .toList();
    return SearchResponse(
      query: (json['query'] ?? '') as String,
      results: results,
      count: (json['count'] as int?) ?? results.length,
    );
  }
}
