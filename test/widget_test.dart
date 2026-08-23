import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twenty_one_days/main.dart';
import 'package:twenty_one_days/providers/theme_controller.dart';
import 'package:twenty_one_days/services/notification_service.dart';
import 'package:twenty_one_days/widgets/chrome_header.dart';

void main() {
  testWidgets('App opens on Explore with fixed chrome header', (tester) async {
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

    expect(find.text(ChromeHeader.headline), findsOneWidget);
    expect(find.text(ChromeHeader.subtitle), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Explore'), findsWidgets);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Recordings'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });
}
