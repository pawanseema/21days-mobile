import 'package:flutter/foundation.dart';

import '../models/recording_model.dart';
import '../services/daily_meditation_store.dart';
import '../services/search_service.dart';
import '../utils/meditation_day.dart';

/// Loads and refreshes Today's Meditation using local sticky/6AM rules.
class DailyMeditationProvider extends ChangeNotifier {
  DailyMeditationProvider({
    SearchService? searchService,
    DailyMeditationStore? store,
  })  : _search = searchService ?? SearchService(),
        _store = store ?? DailyMeditationStore();

  final SearchService _search;
  final DailyMeditationStore _store;

  DailyMeditationState? _state;
  bool _loading = false;
  String? _error;
  bool _expanded = true;

  DailyMeditationState? get state => _state;
  RecordingResult? get activeResult => _state?.active?.result;
  bool get loading => _loading;
  String? get error => _error;
  bool get expanded => _expanded;
  bool get wasPlayed => _state?.active?.wasPlayed ?? false;

  String get collapsedSubtitle {
    final result = activeResult;
    if (result == null) {
      return loading ? 'Loading…' : 'Tap to see today’s practice';
    }
    if (wasPlayed) {
      return 'Played · ${result.sectionTitle}';
    }
    if (result.sectionTitle.isNotEmpty) return result.sectionTitle;
    return 'Ready to practice';
  }

  void setExpanded(bool value) {
    if (_expanded == value) return;
    _expanded = value;
    notifyListeners();
  }

  Future<void> ensureLoaded() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      var state = await _store.load();
      _state = state;

      if (!state.needsFetch(now)) {
        _loading = false;
        notifyListeners();
        return;
      }

      final exclude = state.excludePayload(includeActive: true);
      final result = await _search.fetchDailyMeditation(
        deviceId: state.deviceId,
        exclude: exclude,
      );

      if (result == null) {
        _error = 'No meditation recommendation is available right now.';
        return;
      }

      final history = [...state.history];
      final previous = state.active;
      if (previous != null) {
        history.insert(
          0,
          DailyMeditationHistoryItem(
            videoId: previous.result.videoId,
            timestamp: previous.result.timestamp,
            playedAt: previous.playedAt,
          ),
        );
        while (history.length > DailyMeditationStore.historyLimit) {
          history.removeLast();
        }
      }

      final dayId = MeditationDay.idFor(now);
      state = state.copyWith(
        active: DailyMeditationActive(
          result: result,
          assignedAt: now,
          assignedMeditationDayId: dayId,
        ),
        history: history,
      );
      await _store.save(state);
      _state = state;
      _error = null;
    } catch (e) {
      _error = 'Could not load today’s meditation.';
      debugPrint('DailyMeditationProvider: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markPlayed() async {
    final state = _state;
    final active = state?.active;
    if (state == null || active == null || active.wasPlayed) return;

    final now = DateTime.now();
    final updated = state.copyWith(
      active: active.copyWith(
        playedAt: now,
        playedMeditationDayId: MeditationDay.idFor(now),
      ),
    );
    await _store.save(updated);
    _state = updated;
    notifyListeners();
  }
}
