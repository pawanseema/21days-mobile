import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/session_model.dart';

/// Schedules local reminders 30, 15, and 1 minute before a live session.
///
/// Scaffold only — call [initialize] once at app start, then
/// [scheduleSessionReminders] when a session is known.
class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'live_session_reminders',
    'Live session reminders',
    description: 'Alerts before Sahaja Yoga live meditations',
    importance: Importance.high,
  );

  bool get isInitialized => _initialized;

  /// Bootstrap timezone + notification plugin. Safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      // flutter_timezone 4.x returns the IANA name as a String.
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('NotificationService: timezone fallback to UTC ($e)');
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Deep-link into Live tab / join URL when navigation is available.
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

  /// Schedules three reminders: T-30, T-15, and T-1 minutes.
  ///
  /// Past offsets are skipped. Existing notifications for [session.id] are
  /// cancelled first so re-scheduling is idempotent.
  Future<void> scheduleSessionReminders(LiveSession session) async {
    if (!_initialized) {
      await initialize();
    }

    await cancelSessionReminders(session.id);

    const offsets = <Duration>[
      Duration(minutes: 30),
      Duration(minutes: 15),
      Duration(minutes: 1),
    ];

    for (final offset in offsets) {
      final when = session.startsAt.subtract(offset);
      if (when.isBefore(DateTime.now())) continue;

      final id = _notificationId(session.id, offset.inMinutes);
      final minutesLabel = offset.inMinutes == 1
          ? '1 minute'
          : '${offset.inMinutes} minutes';

      await _plugin.zonedSchedule(
        id,
        'Meditation begins soon',
        '${session.title} starts in $minutesLabel. Join when you are ready.',
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
        payload: session.primaryJoinUrl,
      );
    }
  }

  Future<void> cancelSessionReminders(String sessionId) async {
    for (final minutes in const [30, 15, 1]) {
      await _plugin.cancel(_notificationId(sessionId, minutes));
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Stable int id derived from session id + offset minutes.
  int _notificationId(String sessionId, int minutesBefore) {
    return Object.hash(sessionId, minutesBefore) & 0x7fffffff;
  }
}
