import 'package:flutter_test/flutter_test.dart';
import 'package:twenty_one_days/main.dart';
import 'package:twenty_one_days/services/notification_service.dart';
import 'package:twenty_one_days/utils/constants.dart';

void main() {
  testWidgets('Login screen shows 21Days brand', (tester) async {
    await tester.pumpWidget(
      TwentyOneDaysApp(notificationService: NotificationService()),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('Sign in with Email'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
