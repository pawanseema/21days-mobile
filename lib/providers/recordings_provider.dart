import 'package:flutter/foundation.dart';

import '../models/year_recordings.dart';
import '../services/recordings_service.dart';

/// Recordings tab state: latest year playlist sliced into sessions.
class RecordingsProvider extends ChangeNotifier {
  RecordingsProvider({RecordingsService? recordingsService})
      : _recordingsService = recordingsService ?? RecordingsService() {
    refresh();
  }

  final RecordingsService _recordingsService;

  YearRecordings? _year;
  bool _loading = true;
  String? _error;

  YearRecordings? get year => _year;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _year = await _recordingsService.fetchYearRecordings();
    } catch (e) {
      debugPrint('RecordingsProvider refresh failed: $e');
      _year = null;
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _recordingsService.dispose();
    super.dispose();
  }
}
