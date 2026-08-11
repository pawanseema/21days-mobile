import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Auth state exposed to the widget tree via Provider.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  UserModel? _user;
  bool _busy = false;
  bool _restoring = true;
  String? _error;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isBusy => _busy;
  bool get isRestoring => _restoring;
  String? get error => _error;
  AuthService get authService => _authService;

  /// Cold-start restore of guest / mock / Firebase session.
  Future<void> restoreSession() async {
    _restoring = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.restoreSession();
    } catch (e, st) {
      debugPrint('AuthProvider.restoreSession: $e\n$st');
      _user = null;
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  Future<bool> continueAsGuest() async {
    return _run(_authService.continueAsGuest);
  }

  Future<bool> signInWithEmail(String email, String password) async {
    return _run(() => _authService.signInWithEmail(
          email: email,
          password: password,
        ));
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return _run(() => _authService.signUpWithEmail(
          email: email,
          password: password,
          displayName: displayName,
        ));
  }

  Future<bool> signInWithGoogle() async {
    return _run(_authService.signInWithGoogle);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _error = null;
    notifyListeners();
  }

  /// Deletes the Firebase account or clears local guest/mock identity.
  Future<bool> deleteAccount() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _authService.deleteAccount();
      if (result.isSuccess) {
        _user = null;
        return true;
      }
      _error = result.message ?? 'Could not delete account.';
      return false;
    } catch (e, st) {
      debugPrint('AuthProvider.deleteAccount: $e\n$st');
      _error = e.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> _run(Future<AuthResult> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final result = await action();
      if (result.isSuccess) {
        _user = result.user;
        return true;
      }
      _error = result.message ?? 'Something went wrong.';
      return false;
    } catch (e, st) {
      debugPrint('AuthProvider error: $e\n$st');
      _error = e.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
