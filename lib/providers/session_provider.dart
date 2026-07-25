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

  LiveSession? _nextSession;
  bool _remindersScheduled = false;
  String? _statusMessage;

  LiveSession? get nextSession => _nextSession;
  bool get remindersScheduled => _remindersScheduled;
  String? get statusMessage => _statusMessage;
  NotificationService get notifications => _notificationService;

  void refresh() {
    _nextSession = _sessionService.getNextSession();
    notifyListeners();
  }

  /// Initializes notifications and schedules 30/15/1 min alerts.
  Future<void> enableReminders() async {
    final session = _nextSession;
    if (session == null) return;

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
}
