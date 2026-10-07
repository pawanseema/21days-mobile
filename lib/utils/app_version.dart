/// Dot-separated store version (`1.0.4`). Build metadata after `+` is ignored.
class AppVersion {
  const AppVersion(this.parts);

  final List<int> parts;

  /// Returns null when [raw] is empty or not a simple numeric version.
  static AppVersion? tryParse(String? raw) {
    if (raw == null) return null;
    final head = raw.split('+').first.trim();
    if (head.isEmpty) return null;
    final parts = <int>[];
    for (final segment in head.split('.')) {
      if (segment.isEmpty) return null;
      final value = int.tryParse(segment);
      if (value == null || value < 0) return null;
      parts.add(value);
    }
    if (parts.isEmpty) return null;
    return AppVersion(parts);
  }

  /// True when this install is older than [latest].
  bool isBehind(AppVersion latest) {
    final count = parts.length > latest.parts.length
        ? parts.length
        : latest.parts.length;
    for (var i = 0; i < count; i++) {
      final installed = i < parts.length ? parts[i] : 0;
      final published = i < latest.parts.length ? latest.parts[i] : 0;
      if (installed < published) return true;
      if (installed > published) return false;
    }
    return false;
  }
}
