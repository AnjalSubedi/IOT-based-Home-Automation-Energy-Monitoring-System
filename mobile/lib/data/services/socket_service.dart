// lib/data/services/socket_service.dart
// Socket.IO client for real-time updates from the backend.

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/constants/app_constants.dart';

class SocketService {
  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // ── Connect with JWT ───────────────────────────────────────────────────────
  void connect(String token) {
    if (_socket != null && _isConnected) return;

    _socket = io.io(
      AppConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('[Socket] Connected');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('[Socket] Disconnected');
    });

    _socket!.onConnectError((err) {
      debugPrint('[Socket] Connection error: $err');
    });
  }

  // ── Subscribe to device-specific room ────────────────────────────────────
  void subscribeToDevice(String deviceId) {
    _socket?.emit('subscribe_device', deviceId);
  }

  void unsubscribeFromDevice(String deviceId) {
    _socket?.emit('unsubscribe_device', deviceId);
  }

  // ── Event Listeners ───────────────────────────────────────────────────────
  // NOTE: Always remove the old listener before registering a new one to
  // prevent duplicate handlers from stacking up on reconnect.
  void onLiveReading(Function(Map<String, dynamic>) callback) {
    _socket?.off('live_reading');
    _socket?.on('live_reading', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onRelayState(Function(Map<String, dynamic>) callback) {
    _socket?.off('relay_state');
    _socket?.on('relay_state', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onNewAlert(Function(Map<String, dynamic>) callback) {
    _socket?.off('new_alert');
    _socket?.on('new_alert', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onDeviceStatus(Function(Map<String, dynamic>) callback) {
    _socket?.off('device_status');
    _socket?.on('device_status', (data) => callback(Map<String, dynamic>.from(data)));
  }

  // ── Remove Listeners ──────────────────────────────────────────────────────
  void off(String event) {
    _socket?.off(event);
  }

  // ── Disconnect ────────────────────────────────────────────────────────────
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
