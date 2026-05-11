// lib/data/services/auth_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Result of a token validation attempt.
class TokenValidationResult {
  final bool isValid;    // Token is valid (local OR server confirmed)
  final bool isOffline;  // Network/server unreachable — using cached state
  final UserModel? user; // User data if available

  const TokenValidationResult({
    required this.isValid,
    required this.isOffline,
    this.user,
  });
}

class AuthService {
  final _storage = const FlutterSecureStorage();

  // ── Register ──────────────────────────────────────────────────────────────
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    ).timeout(const Duration(seconds: AppConstants.connectTimeoutSec));

    final body = jsonDecode(res.body);
    if (res.statusCode == 201 && body['success'] == true) {
      final user = UserModel.fromJson(body['user'], body['token']);
      await _saveUser(user);
      return user;
    }
    throw Exception(body['message'] ?? 'Registration failed');
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: AppConstants.connectTimeoutSec));

    final body = jsonDecode(res.body);
    if (res.statusCode == 200 && body['success'] == true) {
      final user = UserModel.fromJson(body['user'], body['token']);
      await _saveUser(user);
      return user;
    }
    throw Exception(body['message'] ?? 'Login failed');
  }

  // ── Validate Token (Offline-First) ────────────────────────────────────────
  /// Checks the stored token against the server.
  /// - Online + valid  → returns {isValid: true, isOffline: false, user: serverUser}
  /// - Online + 401    → clears token → returns {isValid: false}
  /// - Network error   → falls back to cached user → returns {isValid: true, isOffline: true}
  Future<TokenValidationResult> validateToken() async {
    final token = await getToken();

    // No token stored — must log in
    if (token == null || token.isEmpty) {
      return const TokenValidationResult(isValid: false, isOffline: false);
    }

    try {
      final res = await http.get(
        Uri.parse('${AppConstants.baseUrl}/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: AppConstants.tokenValidateTimeout));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final userData = body['user'] as Map<String, dynamic>;
        // Refresh cached user data from server
        final user = UserModel.fromJson(userData, token);
        await _saveUser(user);
        return TokenValidationResult(isValid: true, isOffline: false, user: user);
      }

      if (res.statusCode == 401) {
        // Token expired or revoked — force re-login
        await logout();
        return const TokenValidationResult(isValid: false, isOffline: false);
      }

      // Other server error (5xx etc.) — trust the cached token
      final cachedUser = await _loadCachedUser(token);
      return TokenValidationResult(isValid: true, isOffline: true, user: cachedUser);

    } on SocketException {
      // No network — use cached user data
      final cachedUser = await _loadCachedUser(token);
      return TokenValidationResult(isValid: true, isOffline: true, user: cachedUser);
    } on Exception {
      // Timeout or other error — treat as offline
      final cachedUser = await _loadCachedUser(token);
      return TokenValidationResult(isValid: true, isOffline: true, user: cachedUser);
    }
  }

  // ── Token / User Management ───────────────────────────────────────────────
  Future<void> _saveUser(UserModel user) async {
    await _storage.write(key: AppConstants.tokenKey,    value: user.token);
    await _storage.write(key: AppConstants.userIdKey,   value: user.id);
    await _storage.write(key: AppConstants.userNameKey, value: user.name);
    await _storage.write(key: AppConstants.userEmailKey,value: user.email);
  }

  Future<UserModel?> _loadCachedUser(String token) async {
    final name  = await _storage.read(key: AppConstants.userNameKey);
    final id    = await _storage.read(key: AppConstants.userIdKey);
    final email = await _storage.read(key: AppConstants.userEmailKey);
    if (name != null && id != null) {
      return UserModel(id: id, name: name, email: email ?? '', token: token);
    }
    return null;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: AppConstants.userIdKey);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: AppConstants.userNameKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
