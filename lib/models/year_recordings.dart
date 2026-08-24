import 'recording_model.dart';

/// One playlist video from `GET /api/recordings` session slices.
class SessionVideo {
  const SessionVideo({
    required this.videoId,
    required this.title,
    required this.youtubeWatchUrl,
    this.publishedAt,
    this.youtubeThumbnailUrl = '',
  });

  final String videoId;
  final String title;
  final String youtubeWatchUrl;
  final String youtubeThumbnailUrl;
  final DateTime? publishedAt;

  String? get thumbnailUrl {
    if (youtubeThumbnailUrl.trim().isNotEmpty) return youtubeThumbnailUrl;
    if (videoId.isEmpty) return null;
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  RecordingResult toRecordingResult({String sessionLabel = ''}) {
    return RecordingResult(
      videoTitle: title.isEmpty ? 'Meditation' : title,
      sectionTitle: sessionLabel,
      videoId: videoId,
      url: youtubeWatchUrl,
      publishedAt: publishedAt?.toIso8601String() ?? '',
    );
  }

  factory SessionVideo.fromJson(Map<String, dynamic> json) {
    DateTime? parseTime(Object? raw) {
      if (raw is! String || raw.trim().isEmpty) return null;
      return DateTime.parse(raw).toLocal();
    }

    return SessionVideo(
      videoId: (json['video_id'] ?? '') as String,
      title: (json['title'] ?? 'Meditation') as String,
      youtubeWatchUrl: (json['youtube_watch_url'] ?? '') as String,
      youtubeThumbnailUrl: (json['youtube_thumbnail_url'] ?? '') as String,
      publishedAt: parseTime(json['published_at']),
    );
  }
}

/// Config session with its slice of playlist videos.
class RecordingSession {
  const RecordingSession({
    required this.id,
    required this.label,
    required this.videoCount,
    required this.videos,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String label;
  final int videoCount;
  final List<SessionVideo> videos;
  final DateTime? startsAt;
  final DateTime? endsAt;

  factory RecordingSession.fromJson(Map<String, dynamic> json) {
    /// Config calendar dates (`YYYY-MM-DD`) must stay on that civil day —
    /// [DateTime.parse] treats date-only as UTC and [toLocal] shifts them back a day.
    DateTime? parseCalendarDate(Object? raw) {
      if (raw is! String || raw.trim().isEmpty) return null;
      final text = raw.trim();
      final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
      if (match != null) {
        return DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      }
      return DateTime.parse(text).toLocal();
    }

    final raw = json['videos'];
    final videos = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(SessionVideo.fromJson)
            .where((v) => v.videoId.trim().isNotEmpty)
            .toList(growable: false)
        : const <SessionVideo>[];
    return RecordingSession(
      id: (json['id'] ?? '') as String,
      label: (json['label'] ?? 'Session') as String,
      videoCount: (json['video_count'] is num)
          ? (json['video_count'] as num).toInt()
          : videos.length,
      videos: videos,
      startsAt: parseCalendarDate(json['starts_at']),
      endsAt: parseCalendarDate(json['ends_at']),
    );
  }
}

/// Latest year playlist from `GET /api/recordings`.
class YearRecordings {
  const YearRecordings({
    required this.year,
    required this.title,
    required this.playlistId,
    required this.sessions,
  });

  final int year;
  final String title;
  final String playlistId;
  final List<RecordingSession> sessions;

  factory YearRecordings.fromJson(Map<String, dynamic> json) {
    final raw = json['sessions'];
    final sessions = raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(RecordingSession.fromJson)
            .toList(growable: false)
        : const <RecordingSession>[];
    return YearRecordings(
      year: (json['year'] is num) ? (json['year'] as num).toInt() : 0,
      title: (json['title'] ?? '') as String,
      playlistId: (json['playlist_id'] ?? '') as String,
      sessions: sessions,
    );
  }
}
