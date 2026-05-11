// lib/data/services/api_service.dart
// Central HTTP client — adds JWT Authorization header to every request.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _auth = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path) => Uri.parse('${AppConstants.baseUrl}$path');

  // ── GET ───────────────────────────────────────────────────────────────────
  Future<dynamic> get(String path) async {
    final res = await http.get(_uri(path), headers: await _headers())
        .timeout(const Duration(seconds: AppConstants.receiveTimeoutSec));
    return _handle(res);
  }

  // ── POST ──────────────────────────────────────────────────────────────────
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: AppConstants.receiveTimeoutSec));
    return _handle(res);
  }

  // ── PUT ───────────────────────────────────────────────────────────────────
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: AppConstants.receiveTimeoutSec));
    return _handle(res);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<dynamic> delete(String path) async {
    final res = await http.delete(_uri(path), headers: await _headers())
        .timeout(const Duration(seconds: AppConstants.receiveTimeoutSec));
    return _handle(res);
  }

  // ── Response Handler ──────────────────────────────────────────────────────
  dynamic _handle(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    throw Exception(body['message'] ?? 'Request failed (${res.statusCode})');
  }
}
