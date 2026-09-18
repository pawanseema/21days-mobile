import 'package:intl/intl.dart';

import '../models/session_model.dart';

/// Relative start label for Upcoming, closer to YouTube-style scheduling copy.
///
/// Uses calendar days (tomorrow / weekday) instead of floored 24h blocks so
/// ~47h does not collapse to “In 1 day”.
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

  final startDay = DateTime(start.year, start.month, start.day);
  final today = DateTime(clock.year, clock.month, clock.day);
  final dayDiff = startDay.difference(today).inDays;
  final timeLabel = DateFormat('h:mm a').format(start);

  if (dayDiff <= 0) {
    final hours = until.inHours;
    final minutes = until.inMinutes.remainder(60);
    return 'In ${hours}h ${minutes}m';
  }
  if (dayDiff == 1) return 'Tomorrow · $timeLabel';
  if (dayDiff < 7) {
    final weekday = DateFormat('EEEE').format(start);
    return '$weekday · $timeLabel';
  }
  return 'In $dayDiff days';
}
