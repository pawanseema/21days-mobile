/// User-facing copy for API wait / failure states (no URLs or stack text).
class ApiMessages {
  ApiMessages._();

  /// Shown after [slowAfter] while the first (or later) attempt is still waiting.
  static const String takingLonger = 'Taking longer than usual.';

  /// Second line once a retry actually starts.
  static const String tryingAgain = 'Trying again…';

  /// Two-line hint used when a retry begins (centered in loading UIs).
  static const String retrying = '$takingLonger\n$tryingAgain';

  static const String requestFailed =
      "Couldn't complete the request. Check your connection and try again.";

  /// Wall-clock delay before [takingLonger] while an attempt is in flight.
  static const Duration slowAfter = Duration(seconds: 30);
}
