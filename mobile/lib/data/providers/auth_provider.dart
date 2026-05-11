// lib/data/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  bool _isOffline = false;
  String? _error;

  UserModel? get user      => _user;
  bool get isLoggedIn      => _user != null;
  bool get isLoading       => _isLoading;
  bool get isOffline       => _isOffline;
  String? get error        => _error;

  // ── Set user directly from token validation result ─────────────────────
  void setUserFromValidation(UserModel user, {bool offline = false}) {
    _user = user;
    _isOffline = offline;
    _error = null;
    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _authService.login(email: email, password: password);
      _isOffline = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      _user = await _authService.register(name: name, email: email, password: password);
      _isOffline = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isOffline = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
