/// Handout / resource hit from `POST /api/resources/search`.
class HandoutResult {
  const HandoutResult({
    required this.title,
    required this.downloadUrl,
    this.resourceId = '',
    this.description = '',
    this.topic = '',
    this.tags = const [],
    this.fileType = '',
    this.createdAt = '',
    this.confidence = 0,
  });

  final String resourceId;
  final String title;
  final String description;
  final String topic;
  final List<String> tags;
  final String downloadUrl;
  final String fileType;
  final String createdAt;
  final double confidence;

  String get topicLabel => topic.trim().isEmpty ? 'General' : topic.trim();

  String get truncatedDescription {
    final text = description.trim();
    if (text.length <= 150) return text;
    return '${text.substring(0, 147).trimRight()}...';
  }

  bool get hasDownloadUrl => downloadUrl.trim().isNotEmpty;

  factory HandoutResult.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final List<String> tags;
    if (rawTags is List) {
      tags = rawTags.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    } else if (rawTags is String && rawTags.trim().isNotEmpty) {
      tags = rawTags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } else {
      tags = const [];
    }

    return HandoutResult(
      resourceId: (json['resource_id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      topic: (json['topic'] ?? '') as String,
      tags: tags,
      downloadUrl: (json['download_url'] ?? '') as String,
      fileType: (json['file_type'] ?? '') as String,
      createdAt: (json['created_at'] ?? '') as String,
      confidence: (json['confidence'] is num)
          ? (json['confidence'] as num).toDouble()
          : 0,
    );
  }
}

/// Wrapper matching `{ query, results, count }` from resource search.
class HandoutSearchResponse {
  const HandoutSearchResponse({
    required this.query,
    required this.results,
    required this.count,
  });

  final String query;
  final List<HandoutResult> results;
  final int count;

  factory HandoutSearchResponse.fromJson(Map<String, dynamic> json) {
    final raw = (json['results'] as List<dynamic>? ?? const []);
    final results = raw
        .map((e) => HandoutResult.fromJson(e as Map<String, dynamic>))
        .toList();
    return HandoutSearchResponse(
      query: (json['query'] ?? '') as String,
      results: results,
      count: (json['count'] as int?) ?? results.length,
    );
  }
}
