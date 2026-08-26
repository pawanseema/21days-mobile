/// User-facing copy for API wait / failure states (no URLs or stack text).
class ApiMessages {
  ApiMessages._();

  static const String retrying = 'Taking longer than usual. Trying again…';

  static const String requestFailed =
      "Couldn't complete the request. Check your connection and try again.";
}
