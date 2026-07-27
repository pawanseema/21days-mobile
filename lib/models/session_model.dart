/// Live / upcoming session from `GET /api/live/sessions` (YouTube-backed).
class LiveSession {
  const LiveSession({
    required this.id,
    required this.title,
    required this.status,
    required this.youtubeLiveUrl,
    required this.zoomMeetingUrl,
    this.videoId = '',
    this.source = '',
    this.channelId = '',
    this.channelTitle = '',
    this.channelHandle = '',
    this.youtubeThumbnailUrl = '',
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String title;
  final LiveSessionStatus status;
  final String source;
  final String videoId;
  final String channelId;
  final String channelTitle;
  final String channelHandle;
  final String youtubeLiveUrl;
  final String youtubeThumbnailUrl;
  final String zoomMeetingUrl;
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool get isLiveNow => status == LiveSessionStatus.live;

  bool get isUpcoming => status == LiveSessionStatus.upcoming;

  bool get hasYouTube => youtubeLiveUrl.trim().isNotEmpty;

  bool get hasZoom => zoomMeetingUrl.trim().isNotEmpty;

  bool get hasThumbnail => youtubeThumbnailUrl.trim().isNotEmpty;

  bool get canRemind => isUpcoming && startsAt != null;

  String get channelLabel {
    if (channelTitle.trim().isNotEmpty) return channelTitle.trim();
    if (channelHandle.trim().isNotEmpty) return channelHandle.trim();
    return '';
  }

  Duration? get timeUntilStart {
    final start = startsAt;
    if (start == null) return null;
    return start.difference(DateTime.now());
  }

  /// Preferred deep-link payload for reminder notifications.
  String get primaryJoinUrl =>
      hasYouTube ? youtubeLiveUrl : zoomMeetingUrl;

  factory LiveSession.fromJson(Map<String, dynamic> json) {
    DateTime? parseTime(Object? raw) {
      if (raw is! String || raw.trim().isEmpty) return null;
      return DateTime.parse(raw).toLocal();
    }

    return LiveSession(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? 'Live Meditation') as String,
      status: LiveSessionStatus.fromApi(json['status'] as String?),
      source: (json['source'] ?? '') as String,
      videoId: (json['video_id'] ?? '') as String,
      channelId: (json['channel_id'] ?? '') as String,
      channelTitle: (json['channel_title'] ?? '') as String,
      channelHandle: (json['channel_handle'] ?? '') as String,
      youtubeLiveUrl: (json['youtube_live_url'] ?? '') as String,
      youtubeThumbnailUrl: (json['youtube_thumbnail_url'] ?? '') as String,
      zoomMeetingUrl: (json['zoom_meeting_url'] ?? '') as String,
      startsAt: parseTime(json['starts_at']),
      endsAt: parseTime(json['ends_at']),
    );
  }
}

enum LiveSessionStatus {
  upcoming,
  live,
  ended;

  static LiveSessionStatus fromApi(String? value) {
    switch (value) {
      case 'live':
        return LiveSessionStatus.live;
      case 'ended':
        return LiveSessionStatus.ended;
      case 'upcoming':
      default:
        return LiveSessionStatus.upcoming;
    }
  }
}
