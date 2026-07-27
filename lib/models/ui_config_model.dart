/// Feature flags from `GET /api/ui-config`.
class UiConfig {
  const UiConfig({
    this.showResultDebug = true,
    this.enableMoreLikeThis = true,
    this.enableChromaWrites = true,
  });

  final bool showResultDebug;
  final bool enableMoreLikeThis;
  final bool enableChromaWrites;

  factory UiConfig.fromJson(Map<String, dynamic> json) {
    return UiConfig(
      showResultDebug: json['showResultDebug'] as bool? ?? true,
      enableMoreLikeThis: json['enableMoreLikeThis'] as bool? ?? true,
      enableChromaWrites: json['enableChromaWrites'] as bool? ?? true,
    );
  }
}
