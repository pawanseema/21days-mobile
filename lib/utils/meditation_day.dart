/// Local meditation-day helpers (day boundary at 06:00 device local time).
class MeditationDay {
  MeditationDay._();

  static const int boundaryHour = 6;

  /// Start of the meditation day containing [now] (local).
  static DateTime startOf(DateTime now) {
    final local = now.toLocal();
    final sixAm = DateTime(local.year, local.month, local.day, boundaryHour);
    if (local.isBefore(sixAm)) {
      return sixAm.subtract(const Duration(days: 1));
    }
    return sixAm;
  }

  /// Stable id for storage / comparisons (ISO local day-start).
  static String idFor(DateTime now) => startOf(now).toIso8601String();

  /// True when [playedDayId] is a strictly earlier meditation day than [now].
  static bool isLaterDayThan(String? playedDayId, DateTime now) {
    if (playedDayId == null || playedDayId.isEmpty) return false;
    final played = DateTime.tryParse(playedDayId);
    if (played == null) return false;
    return startOf(now).isAfter(played);
  }
}
