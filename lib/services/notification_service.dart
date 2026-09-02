import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/session_model.dart';

/// Local reminder 5 minutes before a live session, with tap → Live tab deep link.
class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Payload that opens the Live tab and refreshes session info.
  static const String liveDeepLinkPayload = 'navigate:live';

  /// Minutes before [LiveSession.startsAt] to fire the reminder.
  static const int reminderMinutesBefore = 5;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  /// Cold-start launch from a notification (consumed by [takeLaunchPayload]).
  bool _launchedFromNotification = false;
  String? _launchPayload;

  /// Tap arrived before the UI binder registered [onNotificationOpened].
  bool _hasPendingOpen = false;
  String? _pendingOpenPayload;

  void Function(String? payload)? _onNotificationOpened;

  /// Invoked when the user taps a notification (app in foreground/background).
  ///
  /// Setting this flushes any tap that arrived during early plugin init.
  set onNotificationOpened(void Function(String? payload)? callback) {
    _onNotificationOpened = callback;
    if (callback != null && _hasPendingOpen) {
      _hasPendingOpen = false;
      final payload = _pendingOpenPayload;
      _pendingOpenPayload = null;
      callback(payload);
    }
  }

  void Function(String? payload)? get onNotificationOpened =>
      _onNotificationOpened;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'live_session_reminders',
    'Live session reminders',
    description: 'Alerts before Sahaja Yoga live meditations',
    importance: Importance.high,
  );

  bool get isInitialized => _initialized;

  /// True once when the process was started by tapping a reminder notification.
  bool get launchedFromNotification => _launchedFromNotification;

  /// Bootstrap timezone + notification plugin. Safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('NotificationService: timezone fallback to UTC ($e)');
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      // Request when the user turns on a reminder (not at cold start).
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Capture cold-start launch details before the UI mounts. On some iOS
    // versions payload may be null even when the tap launched the app.
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      _launchedFromNotification = true;
      final raw = details?.notificationResponse?.payload;
      _launchPayload = (raw == null || raw.isEmpty) ? liveDeepLinkPayload : raw;
    }

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    final payload = (response.payload == null || response.payload!.isEmpty)
        ? liveDeepLinkPayload
        : response.payload;
    final callback = _onNotificationOpened;
    if (callback != null) {
      callback(payload);
      return;
    }
    // Plugin may deliver the tap during initialize() before the binder exists.
    _hasPendingOpen = true;
    _pendingOpenPayload = payload;
  }

  /// If the app was launched from a notification tap (killed → opened), return
  /// that payload once. Call after UI is ready to navigate.
  ///
  /// Always returns a non-null payload when [didNotificationLaunchApp] was true,
  /// even if the OS omitted the payload string (defaults to [liveDeepLinkPayload]).
  Future<String?> takeLaunchPayload() async {
    if (!_initialized) {
      await initialize();
    }
    if (!_launchedFromNotification) {
      // Re-check in case initialize ran before the OS attached launch details.
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp != true) return null;
      _launchedFromNotification = true;
      final raw = details?.notificationResponse?.payload;
      _launchPayload =
          (raw == null || raw.isEmpty) ? liveDeepLinkPayload : raw;
    }

    _launchedFromNotification = false;
    final payload = _launchPayload ?? liveDeepLinkPayload;
    _launchPayload = null;
    return payload;
  }

  /// Whether [payload] should open the Live / Upcoming tab.
  static bool isLiveDeepLink(String? payload) {
    if (payload == null || payload.isEmpty) return true;
    return payload == liveDeepLinkPayload || payload.startsWith('navigate:live');
  }

  /// Request runtime permission (iOS + Android 13+).
  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    final androidGranted =
        await android?.requestNotificationsPermission() ?? true;
    final iosGranted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;
    return androidGranted && iosGranted;
  }

  /// Schedules one reminder at T-5 minutes. Skips if that time is already past.
  Future<void> scheduleSessionReminders(LiveSession session) async {
    if (!_initialized) {
      await initialize();
    }

    final startsAt = session.startsAt;
    if (startsAt == null) {
      throw StateError('Cannot schedule reminders without starts_at');
    }

    await cancelSessionReminders(session.id);

    final when = startsAt.subtract(
      const Duration(minutes: reminderMinutesBefore),
    );
    if (when.isBefore(DateTime.now())) {
      throw StateError(
        'Reminder time is already past (need at least '
        '$reminderMinutesBefore minutes before start).',
      );
    }

    final id = _notificationId(session.id, reminderMinutesBefore);
    final title = session.title.trim().isEmpty
        ? 'Live meditation'
        : session.title.trim();

    await _plugin.zonedSchedule(
      id,
      'Live session starting soon',
      '$title begins in $reminderMinutesBefore minutes. Tap to open Upcoming.',
      tz.TZDateTime.from(when, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: liveDeepLinkPayload,
    );
  }

  Future<void> cancelSessionReminders(String sessionId) async {
    // Cancel current 5-min id and legacy 30/15/1 offsets from older builds.
    for (final minutes in const [5, 30, 15, 1]) {
      await _plugin.cancel(_notificationId(sessionId, minutes));
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Stable int id derived from session id + offset minutes.
  int _notificationId(String sessionId, int minutesBefore) {
    return Object.hash(sessionId, minutesBefore) & 0x7fffffff;
  }
}
