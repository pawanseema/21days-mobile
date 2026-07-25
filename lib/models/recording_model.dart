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

  String get youtubeWatchUrl {
    if (url.isNotEmpty) return url;
    if (videoId.isEmpty) return '';
    final base = 'https://www.youtube.com/watch?v=$videoId';
    if (timestamp.isEmpty) return base;
    return '$base&t=${_timestampToSeconds(timestamp)}s';
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
