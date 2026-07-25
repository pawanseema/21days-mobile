/// Upcoming live meditation session (Zoom or YouTube).
class LiveSession {
  const LiveSession({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.joinUrl,
    this.platform = LivePlatform.youtube,
    this.description,
  });

  final String id;
  final String title;
  final DateTime startsAt;
  final String joinUrl;
  final LivePlatform platform;
  final String? description;

  bool get isLiveNow {
    final now = DateTime.now();
    return now.isAfter(startsAt.subtract(const Duration(minutes: 5))) &&
        now.isBefore(startsAt.add(const Duration(hours: 2)));
  }

  Duration get timeUntilStart => startsAt.difference(DateTime.now());
}

enum LivePlatform { youtube, zoom }
