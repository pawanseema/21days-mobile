import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twenty_one_days/main.dart';
import 'package:twenty_one_days/providers/theme_controller.dart';
import 'package:twenty_one_days/services/notification_service.dart';

void main() {
  testWidgets('Welcome screen shows 21Days brand and Continue', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final themes = ThemeController();
    await themes.load();

    await tester.pumpWidget(
      TwentyOneDaysApp(
        notificationService: NotificationService(),
        themeController: themes,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('21 Days'), findsWidgets);
    expect(find.text('Start your meditation journey'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsNothing);
    expect(find.text('Sign in with Email'), findsNothing);
  });
}
