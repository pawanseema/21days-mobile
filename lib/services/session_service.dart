import '../models/session_model.dart';
import '../utils/constants.dart';

/// Provides the next live meditation (mock calendar for now).
class SessionService {
  /// Returns the upcoming session — prefers a near-future slot for demos.
  LiveSession getNextSession({DateTime? now}) {
    final current = now ?? DateTime.now();
    // Next session: today at 7:00 PM local, or tomorrow if already past.
    var start = DateTime(current.year, current.month, current.day, 19);
    if (!start.isAfter(current.add(const Duration(minutes: 2)))) {
      start = start.add(const Duration(days: 1));
    }

    return LiveSession(
      id: 'session_${start.toIso8601String()}',
      title: 'Evening Collective Meditation',
      startsAt: start,
      joinUrl: AppConstants.defaultYouTubeLiveUrl,
      platform: LivePlatform.youtube,
      description:
          'Join the live Sahaja Yoga meditation on YouTube. Arrive a few '
          'minutes early to settle your attention.',
    );
  }
}
