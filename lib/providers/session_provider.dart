import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_model.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';

/// Live session dashboard state + reminder scheduling.
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
  bool _loading = true;
  String? _error;
  bool _remindersScheduled = false;
  String? _statusMessage;

  LiveSession? get session => _session;
  LiveSession? get nextSession => _session; // back-compat for older call sites
  bool get isLoading => _loading;
  String? get error => _error;
  bool get remindersScheduled => _remindersScheduled;
  String? get statusMessage => _statusMessage;
  NotificationService get notifications => _notificationService;

  Future<SharedPreferences> _prefs() async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _session = await _sessionService.fetchNextSession();
      await _syncReminderFlag();
    } catch (e) {
      debugPrint('SessionProvider refresh failed: $e');
      _session = null;
      _error = e.toString();
      _remindersScheduled = false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Opens from a reminder tap: clear enabled state (already fired), then refresh.
  Future<void> openFromReminder() async {
    await clearReminderState(notify: false);
    await refresh();
  }

  /// True when the T-5 fire time is still in the future for [session].
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

    // New / missing session — drop the old reminder booking.
    if (session == null || session.id != storedId) {
      await _notificationService.cancelSessionReminders(storedId);
      await prefs.remove(_prefReminderSessionId);
      _remindersScheduled = false;
      _statusMessage = null;
      return;
    }

    // Same session: turn off once fired, live, or no longer remindable.
    if (!_reminderStillPending(session)) {
      await clearReminderState(notify: false);
      return;
    }

    _remindersScheduled = true;
    _statusMessage = 'Reminder is on — 5 minutes before start.';
  }

  /// Cancels the scheduled notification and clears local “enabled” state.
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

  /// User turns off a pending reminder.
  Future<void> disableReminders() async {
    await clearReminderState(notify: false);
    _statusMessage = 'Reminder turned off.';
    notifyListeners();
  }

  /// Initializes notifications and schedules a single T-5 minute alert.
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
