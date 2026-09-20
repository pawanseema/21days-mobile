import '../models/session_model.dart';

/// Relative start label for Upcoming.
///
/// Absolute schedule (weekday / clock time) is shown separately on the card,
/// so this label stays duration-based: minutes, then hours while under 48h,
/// then whole days.
String liveCountdownLabel(LiveSession session, {DateTime? now}) {
  if (session.isLiveNow) return 'Happening now';
  final start = session.startsAt;
  if (start == null) return 'Scheduled on YouTube';

  final clock = now ?? DateTime.now();
  final until = start.difference(clock);
  if (until.isNegative || until.inSeconds < 60) return 'Starting soon';

  if (until.inHours < 1) {
    final minutes = until.inMinutes.clamp(1, 59);
    return 'In $minutes min';
  }

  if (until.inHours < 48) {
    final hours = until.inHours;
    final minutes = until.inMinutes.remainder(60);
    return 'In ${hours}h ${minutes}m';
  }

  final days = until.inDays.clamp(2, 999);
  return 'In $days days';
}
