import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twenty_one_days/services/auth_service.dart';

/// Unit tests for [AuthService] validation, mock, guest, and persistence.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService validation', () {
    test('isValidEmail accepts well-formed addresses', () {
      expect(AuthService.isValidEmail('seeker@example.com'), isTrue);
      expect(AuthService.isValidEmail('  seeker@sahaja.org '), isTrue);
    });

    test('isValidEmail rejects malformed addresses', () {
      expect(AuthService.isValidEmail(''), isFalse);
      expect(AuthService.isValidEmail('not-an-email'), isFalse);
      expect(AuthService.isValidEmail('missing@domain'), isFalse);
      expect(AuthService.isValidEmail('@nodomain.com'), isFalse);
    });

    test('isValidPassword enforces minimum length', () {
      expect(AuthService.isValidPassword('12345'), isFalse);
      expect(AuthService.isValidPassword('123456'), isTrue);
    });
  });

  group('AuthService mock email flow', () {
    late AuthService auth;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      auth = AuthService(useMockBackend: true, prefs: prefs);
    });

    test('signInWithEmail succeeds with valid credentials', () async {
      final result = await auth.signInWithEmail(
        email: 'seeker@example.com',
        password: 'secret1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.user?.email, 'seeker@example.com');
      expect(auth.isSignedIn, isTrue);
    });

    test('signInWithEmail fails for invalid email', () async {
      final result = await auth.signInWithEmail(
        email: 'bad-email',
        password: 'secret1',
      );

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('valid email'));
      expect(auth.isSignedIn, isFalse);
    });

    test('signInWithEmail fails for short password', () async {
      final result = await auth.signInWithEmail(
        email: 'seeker@example.com',
        password: '123',
      );

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('6 characters'));
    });

    test('signUpWithEmail creates a user with display name', () async {
      final result = await auth.signUpWithEmail(
        email: 'new@example.com',
        password: 'secret1',
        displayName: 'Ananya',
      );

      expect(result.isSuccess, isTrue);
      expect(result.user?.displayName, 'Ananya');
    });

    test('signInWithGoogle mock placeholder returns a Google user', () async {
      final result = await auth.signInWithGoogle();

      expect(result.isSuccess, isTrue);
      expect(result.user?.authProvider.name, 'google');
    });

    test('signOut clears the current user', () async {
      await auth.signInWithEmail(
        email: 'seeker@example.com',
        password: 'secret1',
      );
      await auth.signOut();

      expect(auth.currentUser, isNull);
      expect(auth.isSignedIn, isFalse);
    });

    test('mock session restores after cold start', () async {
      await auth.signInWithEmail(
        email: 'seeker@example.com',
        password: 'secret1',
      );
      final prefs = await SharedPreferences.getInstance();
      final restored = AuthService(useMockBackend: true, prefs: prefs);
      final user = await restored.restoreSession();
      expect(user?.email, 'seeker@example.com');
    });
  });

  group('AuthService guest', () {
    late AuthService auth;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      auth = AuthService(useMockBackend: true, prefs: prefs);
    });

    test('continueAsGuest creates a local guest user', () async {
      final result = await auth.continueAsGuest();
      expect(result.isSuccess, isTrue);
      expect(result.user?.isGuest, isTrue);
      expect(result.user?.greetingName, 'Guest');
    });

    test('guest session restores after cold start', () async {
      await auth.continueAsGuest();
      final prefs = await SharedPreferences.getInstance();
      final restored = AuthService(useMockBackend: true, prefs: prefs);
      final user = await restored.restoreSession();
      expect(user?.isGuest, isTrue);
    });

    test('deleteAccount clears guest session', () async {
      await auth.continueAsGuest();
      final result = await auth.deleteAccount();
      expect(result.isSuccess, isTrue);
      expect(auth.currentUser, isNull);
      final prefs = await SharedPreferences.getInstance();
      final again = AuthService(useMockBackend: true, prefs: prefs);
      expect(await again.restoreSession(), isNull);
    });
  });

  group('AuthService Firebase stubs', () {
    test(
      'non-mock backend returns configuration failure (stub until Firebase)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final auth = AuthService(useMockBackend: false, prefs: prefs);
        final result = await auth.signInWithEmail(
          email: 'seeker@example.com',
          password: 'secret1',
        );

        expect(result.isSuccess, isFalse);
        expect(result.message, contains('Firebase'));
      },
    );
  });
}
