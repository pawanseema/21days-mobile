import 'package:flutter/foundation.dart';

import '../models/year_recordings.dart';
import '../services/recordings_service.dart';
import '../utils/api_messages.dart';

/// Recordings tab state: latest year playlist sliced into sessions.
class RecordingsProvider extends ChangeNotifier {
  RecordingsProvider({RecordingsService? recordingsService})
      : _recordingsService = recordingsService ?? RecordingsService();

  final RecordingsService _recordingsService;

  YearRecordings? _year;
  bool _loading = false;
  bool _loadStarted = false;
  String? _loadingHint;
  String? _error;

  YearRecordings? get year => _year;
  bool get isLoading => _loading;
  bool get hasAttemptedLoad => _loadStarted;
  String? get loadingHint => _loadingHint;
  String? get error => _error;

  /// Fetch once when the Recordings tab is first shown (not at app start).
  ///
  /// Live/recent YouTube calls share the Flask process; kicking off a full
  /// playlist pagination at launch races them and times out.
  Future<void> ensureLoaded() {
    if (_loadStarted) return Future.value();
    return refresh();
  }

  Future<void> refresh() async {
    _loadStarted = true;
    _loading = true;
    _loadingHint = null;
    _error = null;
    notifyListeners();

    try {
      _year = await _recordingsService.fetchYearRecordings(
        onRetry: () {
          _loadingHint = ApiMessages.retrying;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('RecordingsProvider refresh failed: $e');
      _year = null;
      _error = ApiMessages.requestFailed;
    } finally {
      _loading = false;
      _loadingHint = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _recordingsService.dispose();
    super.dispose();
  }
}
