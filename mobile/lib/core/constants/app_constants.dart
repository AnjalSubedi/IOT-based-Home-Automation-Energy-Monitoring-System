// lib/core/constants/app_constants.dart

class AppConstants {
  // ── Server URL ────────────────────────────────────────────────────────────
  // CLOUD (works from anywhere — update with your Railway URL after deployment):
  // static const String _cloudBase   = 'https://YOUR_APP.up.railway.app';
  //
  // LOCAL (same WiFi only — for development):
  static const String _localBase    = 'http://10.49.52.49:5000';

  // ← Toggle: set to true after Railway deployment to enable global access
  static const bool useCloud = false;

  static String get baseUrl   => useCloud
      ? 'https://YOUR_APP.up.railway.app/api'
      : '$_localBase/api';
  static String get socketUrl => useCloud
      ? 'https://YOUR_APP.up.railway.app'
      : _localBase;

  // ── Storage Keys ─────────────────────────────────────────────────────────
  static const String tokenKey    = 'auth_token';
  static const String userIdKey   = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey= 'user_email'; // For offline display

  // ── Timeouts ──────────────────────────────────────────────────────────────
  static const int connectTimeoutSec  = 10;
  static const int receiveTimeoutSec  = 30;   // Atlas free tier can be slow on first write
  static const int tokenValidateTimeout = 5; // Fast check on startup

  // ── Relay ─────────────────────────────────────────────────────────────────
  static const List<String> relayNames = [
    'Appliance 1',
    'Appliance 2',
    'Appliance 3',
    'Appliance 4',
  ];

  static const List<String> relayIcons = [
    'lightbulb',
    'fan',
    'electrical_services',
    'device_hub',
  ];
}
