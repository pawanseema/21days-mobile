import '../models/user_model.dart';

/// Result of an auth attempt — success carries [user], failure carries [message].
class AuthResult {
  const AuthResult._({this.user, this.message});

  final UserModel? user;
  final String? message;

  bool get isSuccess => user != null;

  factory AuthResult.success(UserModel user) => AuthResult._(user: user);

  factory AuthResult.failure(String message) => AuthResult._(message: message);
}

/// Authentication facade.
///
/// Production will call Firebase Auth + Google Sign-In. Until Firebase is
/// configured for this app, [useMockBackend] keeps the UI fully usable and
/// makes the service easy to unit-test.
class AuthService {
  AuthService({this.useMockBackend = true});

  /// When true, email/Google flows are simulated locally (no Firebase network).
  final bool useMockBackend;

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  bool get isSignedIn => _currentUser != null;

  /// Basic email validation used by the login / sign-up forms and unit tests.
  static bool isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(trimmed);
  }

  /// Password policy stub — at least 6 characters.
  static bool isValidPassword(String password) => password.length >= 6;

  /// Sign in with email & password.
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (!isValidEmail(normalized)) {
      return AuthResult.failure('Please enter a valid email address.');
    }
    if (!isValidPassword(password)) {
      return AuthResult.failure('Password must be at least 6 characters.');
    }

    if (useMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      _currentUser = UserModel(
        id: 'mock_${normalized.hashCode}',
        email: normalized,
        displayName: normalized.split('@').first,
        authProvider: AuthProviderType.email,
      );
      return AuthResult.success(_currentUser!);
    }

    // TODO: Wire FirebaseAuth.instance.signInWithEmailAndPassword
    return AuthResult.failure(
      'Firebase Auth is not configured yet. Enable useMockBackend or add '
      'google-services / GoogleService-Info.',
    );
  }

  /// Create an account with email & password.
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (!isValidEmail(normalized)) {
      return AuthResult.failure('Please enter a valid email address.');
    }
    if (!isValidPassword(password)) {
      return AuthResult.failure('Password must be at least 6 characters.');
    }

    if (useMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      _currentUser = UserModel(
        id: 'mock_${normalized.hashCode}',
        email: normalized,
        displayName: displayName?.trim().isNotEmpty == true
            ? displayName!.trim()
            : normalized.split('@').first,
        authProvider: AuthProviderType.email,
      );
      return AuthResult.success(_currentUser!);
    }

    // TODO: Wire FirebaseAuth.instance.createUserWithEmailAndPassword
    return AuthResult.failure(
      'Firebase Auth is not configured yet. Enable useMockBackend or add '
      'google-services / GoogleService-Info.',
    );
  }

  /// Google Sign-In placeholder — mock success until Firebase + OAuth are wired.
  Future<AuthResult> signInWithGoogle() async {
    if (useMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _currentUser = const UserModel(
        id: 'mock_google_user',
        email: 'seeker@example.com',
        displayName: 'Seeker',
        authProvider: AuthProviderType.google,
      );
      return AuthResult.success(_currentUser!);
    }

    // TODO: GoogleSignIn + FirebaseAuth.instance.signInWithCredential
    return AuthResult.failure(
      'Google Sign-In is not configured yet.',
    );
  }

  Future<void> signOut() async {
    if (!useMockBackend) {
      // TODO: await FirebaseAuth.instance.signOut();
    }
    _currentUser = null;
  }
}
