/// Shared app-wide constants for 21Days.
class AppConstants {
  AppConstants._();

  static const String appName = '21Days';
  static const String appTagline = 'Sahaja Yoga Meditation';

  /// Base URL for the 21days-media-resources search API.
  ///
  /// Defaults to local Flask (`http://127.0.0.1:5005`).
  /// Point at Cloud Run with:
  /// `--dart-define=API_BASE_URL=https://na21days-media-api-….run.app`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5005',
  );

  /// Semantic video-section search (POST JSON `{ "query", "top_k" }`).
  static const String searchPath = '/search';

  /// Handout / resource search.
  static const String resourceSearchPath = '/api/resources/search';

  /// Placeholder live-session destinations (replace with real calendar links).
  static const String defaultZoomUrl = 'https://zoom.us/j/placeholder';
  static const String defaultYouTubeLiveUrl =
      'https://www.youtube.com/@SahajaYogaMeditation/live';
  static const String defaultYouTubeChannelUrl =
      'https://www.youtube.com/@SahajaYogaMeditation';
}
