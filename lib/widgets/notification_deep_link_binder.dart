import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/navigation_provider.dart';
import '../providers/session_provider.dart';
import '../services/notification_service.dart';

/// Listens for reminder notification taps (cold start + background) and opens
/// the Live tab with a fresh session fetch.
class NotificationDeepLinkBinder extends StatefulWidget {
  const NotificationDeepLinkBinder({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationDeepLinkBinder> createState() =>
      _NotificationDeepLinkBinderState();
}

class _NotificationDeepLinkBinderState
    extends State<NotificationDeepLinkBinder> {
  bool _pendingOpenLive = false;
  bool _bound = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bound) return;
    _bound = true;
    final notifications = context.read<SessionProvider>().notifications;
    notifications.onNotificationOpened = _onNotificationOpened;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumeLaunchPayload();
    });
  }

  Future<void> _consumeLaunchPayload() async {
    final notifications = context.read<SessionProvider>().notifications;
    final payload = await notifications.takeLaunchPayload();
    if (!mounted || payload == null) return;
    _onNotificationOpened(payload);
  }

  void _onNotificationOpened(String? payload) {
    if (!NotificationService.isLiveDeepLink(payload)) return;

    final nav = context.read<NavigationProvider>();
    if (!nav.inApp) {
      _pendingOpenLive = true;
      return;
    }
    _openLive();
  }

  void _openLive() {
    final nav = context.read<NavigationProvider>();
    final sessions = context.read<SessionProvider>();
    nav.openLiveTab();
    sessions.openFromReminder();
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    if (nav.inApp && _pendingOpenLive) {
      _pendingOpenLive = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openLive();
      });
    }
    return widget.child;
  }
}
