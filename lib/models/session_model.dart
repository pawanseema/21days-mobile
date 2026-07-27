/// Live meditation session with YouTube + Zoom join links from the backend.
class LiveSession {
  const LiveSession({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.youtubeLiveUrl,
    required this.zoomMeetingUrl,
    this.description,
    this.timezone,
    this.earlyJoinMinutes = 5,
  });

  final String id;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final LiveSessionStatus status;
  final String youtubeLiveUrl;
  final String zoomMeetingUrl;
  final String? description;
  final String? timezone;
  final int earlyJoinMinutes;

  bool get isLiveNow => status == LiveSessionStatus.live;

  bool get isUpcoming => status == LiveSessionStatus.upcoming;

  bool get hasYouTube => youtubeLiveUrl.trim().isNotEmpty;

  bool get hasZoom => zoomMeetingUrl.trim().isNotEmpty;

  Duration get timeUntilStart => startsAt.difference(DateTime.now());

  /// Preferred deep-link payload for reminder notifications.
  String get primaryJoinUrl =>
      hasYouTube ? youtubeLiveUrl : zoomMeetingUrl;

  factory LiveSession.fromJson(Map<String, dynamic> json) {
    return LiveSession(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? 'Live Meditation') as String,
      startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
      status: LiveSessionStatus.fromApi(json['status'] as String?),
      youtubeLiveUrl: (json['youtube_live_url'] ?? '') as String,
      zoomMeetingUrl: (json['zoom_meeting_url'] ?? '') as String,
      description: json['description'] as String?,
      timezone: json['timezone'] as String?,
      earlyJoinMinutes: (json['early_join_minutes'] as int?) ?? 5,
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
