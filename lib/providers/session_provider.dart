import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recent_recording.dart';
import '../models/session_model.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../utils/api_messages.dart';

/// Live session dashboard state + reminder scheduling + recent recordings.
class SessionProvider extends ChangeNotifier {
  SessionProvider({
    SessionService? sessionService,
    NotificationService? notificationService,
    SharedPreferences? prefs,
  })  : _sessionService = sessionService ?? SessionService(),
        _notificationService = notificationService ?? NotificationService(),
        _prefsOverride = prefs {
    refresh();
  }

  static const _prefReminderSessionId = 'live_reminder_session_id';

  final SessionService _sessionService;
  final NotificationService _notificationService;
  final SharedPreferences? _prefsOverride;

  LiveSession? _session;
  List<RecentRecording> _recent = const [];
  bool _loading = true;
  String? _loadingHint;
  String? _error;
  String? _recentError;
  bool _remindersScheduled = false;
  String? _statusMessage;

  LiveSession? get session => _session;
  LiveSession? get nextSession => _session;
  List<RecentRecording> get recentRecordings => _recent;
  bool get isLoading => _loading;
  String? get loadingHint => _loadingHint;
  String? get error => _error;
  String? get recentError => _recentError;
  bool get remindersScheduled => _remindersScheduled;
  String? get statusMessage => _statusMessage;
  NotificationService get notifications => _notificationService;

  Future<SharedPreferences> _prefs() async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  void _markRetrying() {
    _loadingHint = ApiMessages.retrying;
    notifyListeners();
  }

  Future<void> refresh() async {
    _loading = true;
    _loadingHint = null;
    _error = null;
    _recentError = null;
    notifyListeners();

    // Live and recent are independent YouTube lookups. A 503 on one must not
    // skip or wipe the other — that left Recent empty after a Live retry.
    try {
      _session = await _sessionService.fetchNextSession(onRetry: _markRetrying);
    } catch (e) {
      debugPrint('SessionProvider session fetch failed: $e');
      _error = ApiMessages.requestFailed;
    }

    try {
      _recent =
          await _sessionService.fetchRecentRecordings(onRetry: _markRetrying);
    } catch (e) {
      debugPrint('SessionProvider recent fetch failed: $e');
      _recentError = ApiMessages.requestFailed;
    }

    try {
      await _syncReminderFlag();
    } catch (e) {
      debugPrint('SessionProvider reminder sync failed: $e');
    }

    _loading = false;
    _loadingHint = null;
    notifyListeners();
  }

  Future<void> openFromReminder() async {
    await clearReminderState(notify: false);
    await refresh();
  }

  bool _reminderStillPending(LiveSession session) {
    if (!session.canRemind) return false;
    final startsAt = session.startsAt;
    if (startsAt == null) return false;
    final fireAt = startsAt.subtract(
      const Duration(minutes: NotificationService.reminderMinutesBefore),
    );
    return fireAt.isAfter(DateTime.now());
  }

  Future<void> _syncReminderFlag() async {
    final prefs = await _prefs();
    final storedId = prefs.getString(_prefReminderSessionId);
    final session = _session;

    if (storedId == null) {
      _remindersScheduled = false;
      if (session?.canRemind == true) {
        _statusMessage = null;
      }
      return;
    }

    if (session == null || session.id != storedId) {
      await _notificationService.cancelSessionReminders(storedId);
      await prefs.remove(_prefReminderSessionId);
      _remindersScheduled = false;
      _statusMessage = null;
      return;
    }

    if (!_reminderStillPending(session)) {
      await clearReminderState(notify: false);
      return;
    }

    _remindersScheduled = true;
    _statusMessage = 'Reminder is on — 5 minutes before start.';
  }

  Future<void> clearReminderState({bool notify = true}) async {
    final session = _session;
    final prefs = await _prefs();
    final storedId = prefs.getString(_prefReminderSessionId) ?? session?.id;
    if (storedId != null) {
      await _notificationService.cancelSessionReminders(storedId);
    }
    await prefs.remove(_prefReminderSessionId);
    _remindersScheduled = false;
    _statusMessage = null;
    if (notify) notifyListeners();
  }

  Future<void> disableReminders() async {
    await clearReminderState(notify: false);
    _statusMessage = 'Reminder turned off.';
    notifyListeners();
  }

  Future<void> enableReminders() async {
    final session = _session;
    if (session == null || !session.canRemind) return;
    if (!_reminderStillPending(session)) {
      _statusMessage =
          'Too close to start time to set a 5-minute reminder.';
      notifyListeners();
      return;
    }

    try {
      await _notificationService.initialize();
      await _notificationService.requestPermissions();
      await _notificationService.scheduleSessionReminders(session);
      final prefs = await _prefs();
      await prefs.setString(_prefReminderSessionId, session.id);
      _remindersScheduled = true;
      _statusMessage = 'Reminder is on — 5 minutes before start.';
    } catch (e) {
      debugPrint('Failed to schedule reminders: $e');
      _statusMessage = 'Could not schedule a reminder on this device.';
      _remindersScheduled = false;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionService.dispose();
    super.dispose();
  }
}
