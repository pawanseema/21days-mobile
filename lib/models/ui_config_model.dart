/// Feature flags from `GET /api/ui-config`.
///
/// Defaults are production-safe (debug off). Local Flask returns
/// `showResultDebug: true` when `SHOW_RESULT_DEBUG` is unset.
class UiConfig {
  const UiConfig({
    this.showResultDebug = false,
    this.enableMoreLikeThis = true,
    this.enableChromaWrites = true,
  });

  final bool showResultDebug;
  final bool enableMoreLikeThis;
  final bool enableChromaWrites;

  factory UiConfig.fromJson(Map<String, dynamic> json) {
    return UiConfig(
      showResultDebug: json['showResultDebug'] as bool? ?? false,
      enableMoreLikeThis: json['enableMoreLikeThis'] as bool? ?? true,
      enableChromaWrites: json['enableChromaWrites'] as bool? ?? true,
    );
  }
}
