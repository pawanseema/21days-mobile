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
  String? _error;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isBusy => _busy;
  String? get error => _error;
  AuthService get authService => _authService;

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
