import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/mentor_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/search_provider.dart';
import 'providers/session_provider.dart';
import 'services/auth_service.dart';
import 'services/firebase_bootstrap.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';
import 'views/auth/login_screen.dart';
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

  runApp(
    TwentyOneDaysApp(
      notificationService: notifications,
      useMockAuth: !firebaseReady,
    ),
  );
}

/// 21Days — Sahaja Yoga Meditation hub.
class TwentyOneDaysApp extends StatelessWidget {
  const TwentyOneDaysApp({
    super.key,
    required this.notificationService,
    this.useMockAuth = true,
  });

  final NotificationService notificationService;
  final bool useMockAuth;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: AuthService(useMockBackend: useMockAuth),
          )..restoreSession(),
        ),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(
          create: (_) => SessionProvider(
            notificationService: notificationService,
          ),
        ),
        ChangeNotifierProvider(create: (_) => MentorProvider()),
      ],
      child: NotificationDeepLinkBinder(
        child: MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

/// Routes to [LoginScreen] or [HomeShell] based on auth state.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isRestoring) {
      return const Scaffold(
        key: ValueKey('restoring'),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: auth.isAuthenticated
          ? const HomeShell(key: ValueKey('home'))
          : const LoginScreen(key: ValueKey('login')),
    );
  }
}
