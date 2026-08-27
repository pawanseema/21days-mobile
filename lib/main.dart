import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/mentor_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/recordings_provider.dart';
import 'providers/search_provider.dart';
import 'providers/session_provider.dart';
import 'providers/theme_controller.dart';
import 'providers/wisdom_provider.dart';
import 'services/auth_service.dart';
import 'services/firebase_bootstrap.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'views/home/home_shell.dart';
import 'widgets/notification_deep_link_binder.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Scaffold local notifications early so Live-tab reminders are ready.
  final notifications = NotificationService();
  try {
    await notifications.initialize();
  } catch (e) {
    debugPrint('Notification bootstrap skipped: $e');
  }

  final firebaseReady = await bootstrapFirebase();
  final themeController = ThemeController();
  await themeController.load();

  runApp(
    TwentyOneDaysApp(
      notificationService: notifications,
      themeController: themeController,
      useMockAuth: !firebaseReady,
    ),
  );
}

/// 21Days — Sahaja Yoga Meditation hub.
class TwentyOneDaysApp extends StatelessWidget {
  const TwentyOneDaysApp({
    super.key,
    required this.notificationService,
    required this.themeController,
    this.useMockAuth = true,
  });

  final NotificationService notificationService;
  final ThemeController themeController;
  final bool useMockAuth;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: AuthService(useMockBackend: useMockAuth),
          )..restoreSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => NavigationProvider(
            // Cold-start from a reminder: land on Upcoming on the first frame.
            initialIndex: notificationService.launchedFromNotification
                ? NavigationProvider.liveTabIndex
                : NavigationProvider.exploreTabIndex,
          ),
        ),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(
          create: (_) => SessionProvider(
            notificationService: notificationService,
          ),
        ),
        ChangeNotifierProvider(create: (_) => RecordingsProvider()),
        ChangeNotifierProvider(create: (_) => WisdomProvider()),
        ChangeNotifierProvider(create: (_) => MentorProvider()),
      ],
      child: NotificationDeepLinkBinder(
        child: Consumer<ThemeController>(
          builder: (context, themes, _) {
            return MaterialApp(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.fromPalette(themes.palette),
              home: const HomeShell(),
            );
          },
        ),
      ),
    );
  }
}
