/// One Chroma timestamp chapter from `GET /api/videos/<id>/chapters`.
class VideoChapter {
  const VideoChapter({
    required this.timestamp,
    required this.sectionTitle,
    required this.startSeconds,
  });

  final String timestamp;
  final String sectionTitle;
  final int startSeconds;

  factory VideoChapter.fromJson(Map<String, dynamic> json) {
    final ts = (json['timestamp'] ?? '') as String;
    final start = json['start_seconds'];
    return VideoChapter(
      timestamp: ts,
      sectionTitle: (json['section_title'] ?? 'Section') as String,
      startSeconds: start is num
          ? start.toInt()
          : _timestampToSeconds(ts),
    );
  }

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
