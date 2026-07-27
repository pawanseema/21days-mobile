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

  /// Related / more-like-this video sections.
  static const String relatedVideosPath = '/api/videos/related';

  /// Feature flags for the HTML UI (more-like-this, debug fields, etc.).
  static const String uiConfigPath = '/api/ui-config';

  /// Current / next live meditation session (YouTube + Zoom links).
  static const String liveSessionsPath = '/api/live/sessions';
}
