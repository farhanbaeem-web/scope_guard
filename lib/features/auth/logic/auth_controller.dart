import 'package:flutter/material.dart';

import 'auth_service.dart';

/// AuthController handles UI-friendly auth logic:
/// - loading state
/// - error messages
/// - calling AuthService
///
/// This keeps widgets clean and testable.
class AuthController extends ChangeNotifier {
  final AuthService _service = AuthService.instance;

  bool _loading = false;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _setError(null);

    try {
      await _service.signInWithEmail(email: email, password: password);
      return true;
    } catch (e) {
      _setError(_mapError(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _service.signUpWithEmail(name: name, email: email, password: password);
      return true;
    } catch (e) {
      _setError(_mapError(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _service.signOut();
  }

  String _mapError(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('wrong-password') || s.contains('invalid-credential')) {
      return 'Incorrect email or password';
    }
    if (s.contains('user-not-found')) {
      return 'No account found for this email';
    }
    if (s.contains('email-already-in-use')) {
      return 'This email is already registered';
    }
    if (s.contains('weak-password')) {
      return 'Password is too weak';
    }
    if (s.contains('invalid-email')) {
      return 'Invalid email address';
    }
    return 'Authentication failed';
  }
}
