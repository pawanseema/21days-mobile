/// Completed livestream from `GET /api/live/recent` (≤1 per channel, ≤72h).
class RecentRecording {
  const RecentRecording({
    required this.id,
    required this.videoId,
    required this.title,
    required this.youtubeWatchUrl,
    this.channelId = '',
    this.channelTitle = '',
    this.channelHandle = '',
    this.youtubeThumbnailUrl = '',
    this.startsAt,
    this.endsAt,
    this.publishedAt,
  });

  final String id;
  final String videoId;
  final String title;
  final String channelId;
  final String channelTitle;
  final String channelHandle;
  final String youtubeWatchUrl;
  final String youtubeThumbnailUrl;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? publishedAt;

  String get channelLabel {
    if (channelTitle.trim().isNotEmpty) return channelTitle.trim();
    if (channelHandle.trim().isNotEmpty) return channelHandle.trim();
    return '';
  }

  String? get thumbnailUrl {
    if (youtubeThumbnailUrl.trim().isNotEmpty) return youtubeThumbnailUrl;
    if (videoId.isEmpty) return null;
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  factory RecentRecording.fromJson(Map<String, dynamic> json) {
    DateTime? parseTime(Object? raw) {
      if (raw is! String || raw.trim().isEmpty) return null;
      return DateTime.parse(raw).toLocal();
    }

    return RecentRecording(
      id: (json['id'] ?? '') as String,
      videoId: (json['video_id'] ?? '') as String,
      title: (json['title'] ?? 'Recent meditation') as String,
      channelId: (json['channel_id'] ?? '') as String,
      channelTitle: (json['channel_title'] ?? '') as String,
      channelHandle: (json['channel_handle'] ?? '') as String,
      youtubeWatchUrl: (json['youtube_watch_url'] ?? '') as String,
      youtubeThumbnailUrl: (json['youtube_thumbnail_url'] ?? '') as String,
      startsAt: parseTime(json['starts_at']),
      endsAt: parseTime(json['ends_at']),
      publishedAt: parseTime(json['published_at']),
    );
  }
}
