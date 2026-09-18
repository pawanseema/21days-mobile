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

  /// User preference: keep reminding for each next upcoming session.
  static const _prefRemindersEnabled = 'live_reminders_enabled';

  /// Session id that currently has an OS one-shot scheduled (if any).
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
  bool _remindersEnabled = false;
  String? _statusMessage;

  LiveSession? get session => _session;
  LiveSession? get nextSession => _session;
  List<RecentRecording> get recentRecordings => _recent;
  bool get isLoading => _loading;
  String? get loadingHint => _loadingHint;
  String? get error => _error;
  String? get recentError => _recentError;

  /// Switch value: lasting preference, not “OS notification still pending”.
  bool get remindersScheduled => _remindersEnabled;
  String? get statusMessage => _statusMessage;
  NotificationService get notifications => _notificationService;

  Future<SharedPreferences> _prefs() async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  void _markSlow() {
    // Don't downgrade the two-line retry copy if a retry already started.
    if (_loadingHint == ApiMessages.retrying) return;
    _loadingHint = ApiMessages.takingLonger;
    notifyListeners();
  }

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
      _session = await _sessionService.fetchNextSession(
        onRetry: _markRetrying,
        onSlow: _markSlow,
      );
    } catch (e) {
      debugPrint('SessionProvider session fetch failed: $e');
      _error = ApiMessages.requestFailed;
    }

    try {
      _recent = await _sessionService.fetchRecentRecordings(
        onRetry: _markRetrying,
        onSlow: _markSlow,
      );
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

  /// Deep link from a fired reminder: open Upcoming and refresh; keep preference on.
  Future<void> openFromReminder() async {
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

  Future<bool> _readRemindersEnabled(SharedPreferences prefs) async {
    if (prefs.containsKey(_prefRemindersEnabled)) {
      return prefs.getBool(_prefRemindersEnabled) ?? false;
    }
    // Migrate: older builds only stored a session id while the switch was on.
    final legacyId = prefs.getString(_prefReminderSessionId);
    if (legacyId != null && legacyId.isNotEmpty) {
      await prefs.setBool(_prefRemindersEnabled, true);
      return true;
    }
    return false;
  }

  Future<void> _clearScheduledNotification(SharedPreferences prefs) async {
    final storedId =
        prefs.getString(_prefReminderSessionId) ?? _session?.id;
    if (storedId != null && storedId.isNotEmpty) {
      await _notificationService.cancelSessionReminders(storedId);
    }
    await prefs.remove(_prefReminderSessionId);
  }

  /// Keep [live_reminders_enabled] sticky; schedule/cancel the OS one-shot as needed.
  Future<void> _syncReminderFlag() async {
    final prefs = await _prefs();
    final enabled = await _readRemindersEnabled(prefs);
    _remindersEnabled = enabled;

    if (!enabled) {
      await _clearScheduledNotification(prefs);
      _statusMessage = null;
      return;
    }

    final session = _session;
    if (session == null || !_reminderStillPending(session)) {
      await _clearScheduledNotification(prefs);
      _statusMessage =
          'Reminder is on — will notify 5 minutes before the next upcoming session.';
      return;
    }

    await _notificationService.initialize();
    final storedId = prefs.getString(_prefReminderSessionId);
    if (storedId != null &&
        storedId.isNotEmpty &&
        storedId != session.id) {
      await _notificationService.cancelSessionReminders(storedId);
    }

    try {
      final usedExact =
          await _notificationService.scheduleSessionReminders(session);
      await prefs.setString(_prefReminderSessionId, session.id);
      _statusMessage = usedExact
          ? 'Reminder is on — 5 minutes before start.'
          : 'Reminder is on — timing may vary slightly (exact alarms not allowed).';
    } catch (e) {
      debugPrint('SessionProvider auto-schedule failed: $e');
      await prefs.remove(_prefReminderSessionId);
      _statusMessage =
          'Reminder is on — could not schedule this session yet. Pull to refresh.';
    }
  }

  Future<void> disableReminders() async {
    final prefs = await _prefs();
    await prefs.setBool(_prefRemindersEnabled, false);
    await _clearScheduledNotification(prefs);
    _remindersEnabled = false;
    _statusMessage = 'Reminder turned off.';
    notifyListeners();
  }

  Future<void> enableReminders() async {
    final prefs = await _prefs();
    try {
      await _notificationService.initialize();
      final granted = await _notificationService.requestPermissions();
      if (!granted) {
        _statusMessage =
            'Notifications are off for 21Days. Enable them in Settings → 21Days → Notifications.';
        _remindersEnabled = false;
        await prefs.setBool(_prefRemindersEnabled, false);
        notifyListeners();
        return;
      }

      await prefs.setBool(_prefRemindersEnabled, true);
      _remindersEnabled = true;

      final session = _session;
      if (session == null || !_reminderStillPending(session)) {
        await _clearScheduledNotification(prefs);
        _statusMessage =
            'Reminder is on — will notify 5 minutes before the next upcoming session.';
        notifyListeners();
        return;
      }

      final usedExact =
          await _notificationService.scheduleSessionReminders(session);
      await prefs.setString(_prefReminderSessionId, session.id);
      _statusMessage = usedExact
          ? 'Reminder is on — 5 minutes before start.'
          : 'Reminder is on — timing may vary slightly (exact alarms not allowed).';
    } catch (e) {
      debugPrint('Failed to schedule reminders: $e');
      final detail = e.toString();
      final isAndroid =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      if (isAndroid && detail.contains('exact_alarms_not_permitted')) {
        _statusMessage =
            'Allow Alarms & reminders for 21Days in system Settings, then try again.';
      } else {
        _statusMessage = 'Could not schedule a reminder on this device.';
      }
      // Keep preference on so the next refresh can retry for a later session.
      await prefs.setBool(_prefRemindersEnabled, true);
      _remindersEnabled = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionService.dispose();
    super.dispose();
  }
}
