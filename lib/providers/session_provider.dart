import 'package:flutter/foundation.dart';

import '../models/session_model.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';

/// Live session dashboard state + reminder scheduling.
class SessionProvider extends ChangeNotifier {
  SessionProvider({
    SessionService? sessionService,
    NotificationService? notificationService,
  })  : _sessionService = sessionService ?? SessionService(),
        _notificationService = notificationService ?? NotificationService() {
    refresh();
  }

  final SessionService _sessionService;
  final NotificationService _notificationService;

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

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _session = await _sessionService.fetchNextSession();
      _remindersScheduled = false;
      _statusMessage = null;
    } catch (e) {
      debugPrint('SessionProvider refresh failed: $e');
      _session = null;
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Initializes notifications and schedules 30/15/1 min alerts (upcoming only).
  Future<void> enableReminders() async {
    final session = _session;
    if (session == null || !session.canRemind) return;

    try {
      await _notificationService.initialize();
      await _notificationService.requestPermissions();
      await _notificationService.scheduleSessionReminders(session);
      _remindersScheduled = true;
      _statusMessage = 'Reminders set for 30, 15, and 1 minute before.';
    } catch (e) {
      debugPrint('Failed to schedule reminders: $e');
      _statusMessage = 'Could not schedule reminders on this device.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionService.dispose();
    super.dispose();
  }
}
