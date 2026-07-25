import 'package:flutter/foundation.dart';

import '../models/recording_model.dart';
import '../services/search_service.dart';

/// Drives the Resources tab search field + result list.
class SearchProvider extends ChangeNotifier {
  SearchProvider({SearchService? searchService})
      : _searchService = searchService ?? SearchService();

  final SearchService _searchService;

  String _query = '';
  List<RecordingResult> _results = const [];
  bool _loading = false;
  String? _error;

  String get query => _query;
  List<RecordingResult> get results => _results;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get hasQuery => _query.trim().isNotEmpty;

  Future<void> search(String query) async {
    _query = query;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _results = const [];
      _error = null;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _searchService.searchRecordings(query: trimmed);
      _results = response.results;
    } catch (e) {
      _error = e.toString();
      _results = const [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _query = '';
    _results = const [];
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchService.dispose();
    super.dispose();
  }
}
