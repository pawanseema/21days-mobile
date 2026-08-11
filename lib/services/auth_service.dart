import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Authentication facade: email / Google (Firebase or mock) + local guest.
class AuthService {
  AuthService({
    this.useMockBackend = true,
    SharedPreferences? prefs,
    GoogleSignIn? googleSignIn,
    fb.FirebaseAuth? this._firebaseAuth,
  })  : _prefsOverride = prefs,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);

  static const _prefGuest = 'auth_guest';
  static const _prefMockUser = 'auth_mock_user_json';

  /// When true, email/Google flows are simulated locally (no Firebase network).
  final bool useMockBackend;

  final SharedPreferences? _prefsOverride;
  final GoogleSignIn _googleSignIn;
  final fb.FirebaseAuth? _firebaseAuth;

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  bool get isSignedIn => _currentUser != null;

  fb.FirebaseAuth get _fb => _firebaseAuth ?? fb.FirebaseAuth.instance;

  Future<SharedPreferences> _prefs() async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  /// Basic email validation used by the login / sign-up forms and unit tests.
  static bool isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(trimmed);
  }

  /// Password policy stub — at least 6 characters.
  static bool isValidPassword(String password) => password.length >= 6;

  /// Restore guest, mock, or Firebase session after a cold start.
  Future<UserModel?> restoreSession() async {
    if (!useMockBackend) {
      try {
        final fbUser = _fb.currentUser;
        if (fbUser != null) {
          _currentUser = _fromFirebaseUser(fbUser);
          await _clearLocalIdentityPrefs();
          return _currentUser;
        }
      } catch (e, st) {
        debugPrint('Firebase restore skipped: $e\n$st');
      }
    }

    final prefs = await _prefs();
    if (prefs.getBool(_prefGuest) == true) {
      _currentUser = UserModel.guest;
      return _currentUser;
    }

    if (useMockBackend) {
      final raw = prefs.getString(_prefMockUser);
      if (raw != null && raw.isNotEmpty) {
        try {
          _currentUser =
              UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          return _currentUser;
        } catch (e) {
          debugPrint('Corrupt mock user prefs: $e');
          await prefs.remove(_prefMockUser);
        }
      }
    }

    _currentUser = null;
    return null;
  }

  /// Local-only guest — no Firebase user is created.
  Future<AuthResult> continueAsGuest() async {
    final prefs = await _prefs();
    await prefs.setBool(_prefGuest, true);
    await prefs.remove(_prefMockUser);
    _currentUser = UserModel.guest;
    return AuthResult.success(_currentUser!);
  }

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
      await _persistMockUser(_currentUser!);
      return AuthResult.success(_currentUser!);
    }

    try {
      final cred = await _fb.signInWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        return AuthResult.failure('Sign-in failed. Please try again.');
      }
      _currentUser = _fromFirebaseUser(user);
      await _clearLocalIdentityPrefs();
      return AuthResult.success(_currentUser!);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure(
        'Firebase Auth is not configured yet. Enable useMockBackend or add '
        'google-services / GoogleService-Info. ($e)',
      );
    }
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

    final name = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : normalized.split('@').first;

    if (useMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      _currentUser = UserModel(
        id: 'mock_${normalized.hashCode}',
        email: normalized,
        displayName: name,
        authProvider: AuthProviderType.email,
      );
      await _persistMockUser(_currentUser!);
      return AuthResult.success(_currentUser!);
    }

    try {
      final cred = await _fb.createUserWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        return AuthResult.failure('Could not create account. Please try again.');
      }
      if (name.isNotEmpty) {
        await user.updateDisplayName(name);
        await user.reload();
      }
      _currentUser = _fromFirebaseUser(_fb.currentUser ?? user);
      await _clearLocalIdentityPrefs();
      return AuthResult.success(_currentUser!);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure(
        'Firebase Auth is not configured yet. Enable useMockBackend or add '
        'google-services / GoogleService-Info. ($e)',
      );
    }
  }

  /// Google Sign-In via Firebase, or mock when [useMockBackend] is true.
  Future<AuthResult> signInWithGoogle() async {
    if (useMockBackend) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _currentUser = const UserModel(
        id: 'mock_google_user',
        email: 'seeker@example.com',
        displayName: 'Seeker',
        authProvider: AuthProviderType.google,
      );
      await _persistMockUser(_currentUser!);
      return AuthResult.success(_currentUser!);
    }

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.failure('Google sign-in was cancelled.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _fb.signInWithCredential(credential);
      final user = cred.user;
      if (user == null) {
        return AuthResult.failure('Google sign-in failed. Please try again.');
      }
      _currentUser = _fromFirebaseUser(user);
      await _clearLocalIdentityPrefs();
      return AuthResult.success(_currentUser!);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure(
        'Google Sign-In is not configured yet. ($e)',
      );
    }
  }

  Future<void> signOut() async {
    if (!useMockBackend) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      try {
        await _fb.signOut();
      } catch (e) {
        debugPrint('Firebase signOut: $e');
      }
    }
    await _clearLocalIdentityPrefs();
    _currentUser = null;
  }

  /// App Store account deletion — removes Firebase user or local guest/mock.
  Future<AuthResult> deleteAccount() async {
    final user = _currentUser;
    if (user == null) {
      return AuthResult.failure('No account is signed in.');
    }

    if (user.isGuest || useMockBackend) {
      await _clearLocalIdentityPrefs();
      _currentUser = null;
      return AuthResult.success(UserModel.guest); // signals success; caller clears UI
    }

    try {
      final fbUser = _fb.currentUser;
      if (fbUser == null) {
        await signOut();
        return AuthResult.failure('Session expired. Sign in again to delete.');
      }
      await fbUser.delete();
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      await _clearLocalIdentityPrefs();
      _currentUser = null;
      return AuthResult.success(UserModel.guest);
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return AuthResult.failure(
          'For security, sign out, sign back in, then delete your account.',
        );
      }
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      return AuthResult.failure('Could not delete account: $e');
    }
  }

  Future<void> _persistMockUser(UserModel user) async {
    final prefs = await _prefs();
    await prefs.setBool(_prefGuest, false);
    await prefs.setString(_prefMockUser, jsonEncode(user.toJson()));
  }

  Future<void> _clearLocalIdentityPrefs() async {
    final prefs = await _prefs();
    await prefs.remove(_prefGuest);
    await prefs.remove(_prefMockUser);
  }

  UserModel _fromFirebaseUser(fb.User user) {
    final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      authProvider:
          isGoogle ? AuthProviderType.google : AuthProviderType.email,
    );
  }

  String _mapFirebaseError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Authentication failed (${e.code}).';
    }
  }
}
