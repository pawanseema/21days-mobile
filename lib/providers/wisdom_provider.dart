import 'package:flutter/foundation.dart';

import '../models/wisdom_topic.dart';
import '../services/wisdom_service.dart';

/// Wisdom tab state: topics from `GET /api/wisdom/topics`.
class WisdomProvider extends ChangeNotifier {
  WisdomProvider({WisdomService? wisdomService})
      : _wisdomService = wisdomService ?? WisdomService();

  final WisdomService _wisdomService;

  WisdomTopicsResponse? _payload;
  bool _loading = false;
  bool _loadStarted = false;
  String? _error;

  String get heading =>
      _payload?.heading ?? 'Meditation wisdom';
  String get subtitle =>
      _payload?.subtitle ??
      'Foundational Sahaja Yoga topics to deepen your attention.';
  List<WisdomTopic> get topics =>
      _payload?.topics ?? WisdomCatalog.topics;
  bool get isLoading => _loading;
  bool get hasAttemptedLoad => _loadStarted;
  String? get error => _error;
  bool get usedFallback =>
      _error != null && (_payload == null || _payload!.topics.isEmpty);

  Future<void> ensureLoaded() {
    if (_loadStarted) return Future.value();
    return refresh();
  }

  Future<void> refresh() async {
    _loadStarted = true;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _wisdomService.fetchTopics();
      _payload = fetched.topics.isEmpty
          ? WisdomTopicsResponse(
              heading: fetched.heading,
              subtitle: fetched.subtitle,
              topics: WisdomCatalog.topics,
            )
          : fetched;
    } catch (e) {
      debugPrint('WisdomProvider refresh failed: $e');
      _error = e.toString();
      _payload ??= WisdomTopicsResponse(
        heading: 'Meditation wisdom',
        subtitle:
            'Foundational Sahaja Yoga topics to deepen your attention.',
        topics: WisdomCatalog.topics,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _wisdomService.dispose();
    super.dispose();
  }
}
