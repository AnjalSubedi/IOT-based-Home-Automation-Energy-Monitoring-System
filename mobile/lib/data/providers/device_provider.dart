// lib/data/providers/device_provider.dart
// Simplified for single-ESP32 / 4-relay household setup.
// The UI is NEVER blocked — 4 appliance slots are always visible.

import 'package:flutter/foundation.dart';
import '../models/device_model.dart';
import '../models/energy_reading_model.dart';
import '../models/relay_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';

enum ConnectionStatus { connecting, online, offline, error }

class DeviceProvider extends ChangeNotifier {
  final ApiService     _api    = ApiService();
  final SocketService  _socket = SocketService();
  final AuthService    _auth   = AuthService();

  // ── State ─────────────────────────────────────────────────────────────────
  DeviceModel?  _device;
  String?       _deviceId;             // Cached so toggle works even pre-load
  List<RelayModel> _relays  = RelayModel.defaultRelays();
  EnergyReading?   _liveReading;
  EnergySummary    _summary  = EnergySummary.empty();
  ConnectionStatus _status   = ConnectionStatus.connecting;
  bool             _isRefreshing  = false;
  bool             _isInitializing = false; // Prevents concurrent init() calls
  int              _unreadAlerts = 0;
  final Set<int>   _pendingToggles = {}; // relayIds currently being toggled

  // ── Getters ───────────────────────────────────────────────────────────────
  DeviceModel?          get device        => _device;
  List<RelayModel>      get relays        => _relays;
  EnergyReading?        get liveReading   => _liveReading;
  EnergySummary         get summary       => _summary;
  ConnectionStatus      get status        => _status;
  bool                  get isRefreshing  => _isRefreshing;
  int                   get unreadAlerts  => _unreadAlerts;
  bool                  get isOnline      => _status == ConnectionStatus.online;

  // ── Compatibility aliases (for screens not yet migrated) ──────────────────
  bool         get hasDevices     => _device != null;
  DeviceModel? get selectedDevice => _device;
  String?      get error          => _status == ConnectionStatus.error ? 'Cannot reach server' : null;
  List<DeviceModel> get devices   => _device != null ? [_device!] : [];

  // ── Initialize (called once on first load) ───────────────────────────────
  Future<void> init() async {
    if (_device != null) return;      // Already loaded
    if (_isInitializing) return;      // Already in progress
    _isInitializing = true;
    _status = ConnectionStatus.connecting;
    notifyListeners();

    await _connectSocket();
    await _loadDevice();
    _isInitializing = false;
  }

  // ── Pull-to-refresh ───────────────────────────────────────────────────────
  Future<void> refresh() async {
    if (_isRefreshing) return;   // Prevent concurrent refreshes
    _isRefreshing = true;
    notifyListeners();
    await _loadDevice();
    _isRefreshing = false;
    notifyListeners();
  }

  // ── Socket.IO — connect only, no device reload ────────────────────────────
  Future<void> _connectSocket() async {
    final token = await _auth.getToken();
    if (token == null) return;
    _socket.connect(token);

    // Live telemetry
    _socket.onLiveReading((data) {
      _liveReading = EnergyReading.fromLive(data);
      notifyListeners();
    });

    // Relay state from server / ESP32 confirmation
    // Skip events for relays that have an in-flight optimistic update to avoid
    // flicker where the server echo overwrites our locally toggled state.
    _socket.onRelayState((data) {
      final relayId = data['relayId'] as int;
      final state   = data['state'] as bool;
      if (_pendingToggles.contains(relayId)) return; // In-flight — ignore echo
      _relays = _relays.map((r) =>
          r.relayId == relayId ? r.copyWith(state: state, lastChangedBy: data['changedBy'] as String? ?? 'device') : r
      ).toList();
      notifyListeners();
    });

    // Device online / offline
    _socket.onDeviceStatus((data) {
      final isOnline = data['isOnline'] as bool;
      if (_device != null) {
        _device = _device!.copyWith(isOnline: isOnline);
        _status  = isOnline ? ConnectionStatus.online : ConnectionStatus.offline;
        notifyListeners();
      }
    });

    // Alert badge
    _socket.onNewAlert((_) {
      _unreadAlerts++;
      notifyListeners();
    });
  }

  Future<void> _loadDevice() async {
    try {
      final res = await _api.get('/devices');
      final list = res['data'] as List;
      if (list.isEmpty) {
        // No device configured yet — show offline, not error
        _status = ConnectionStatus.offline;
        notifyListeners();
        return;
      }

      _device   = DeviceModel.fromJson(list.first);
      _deviceId = _device!.deviceId; // Cache immediately for toggle use
      _status   = _device!.isOnline ? ConnectionStatus.online : ConnectionStatus.offline;

      // Subscribe to real-time updates for this device
      _socket.subscribeToDevice(_device!.deviceId);
      notifyListeners();

      // Load relays + energy in parallel (best-effort)
      await Future.wait([
        _loadRelays(_device!.deviceId),
        _loadSummary(_device!.deviceId),
        _loadLatestReading(_device!.deviceId),
      ]);
    } catch (_) {
      _status = ConnectionStatus.error;
    }
    notifyListeners();
  }

  Future<void> _loadRelays(String deviceId) async {
    try {
      final res  = await _api.get('/devices/$deviceId/relays');
      final list = res['data'] as List;
      if (list.isNotEmpty) {
        final fetched = list.map((r) => RelayModel.fromJson(r)).toList();
        _relays = List.generate(4, (i) {
          final match = fetched.where((r) => r.relayId == i + 1);
          return match.isNotEmpty ? match.first : RelayModel(relayId: i + 1, state: false);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadLatestReading(String deviceId) async {
    try {
      final res = await _api.get('/devices/$deviceId/latest');
      if (res['data'] != null) _liveReading = EnergyReading.fromJson(res['data']);
    } catch (_) {}
  }

  Future<void> _loadSummary(String deviceId, {String period = 'today'}) async {
    try {
      final res = await _api.get('/devices/$deviceId/summary?period=$period');
      _summary = EnergySummary.fromJson(res['data']);
    } catch (_) {}
    notifyListeners();
  }

  // ── Toggle Relay ──────────────────────────────────────────────────────────
  Future<void> toggleRelay(int relayId) async {
    final did = _deviceId ?? _device?.deviceId;
    if (did == null) return; // No device registered yet

    // Prevent double-tap while already toggling this relay
    if (_pendingToggles.contains(relayId)) return;

    final current  = _relays.firstWhere((r) => r.relayId == relayId).state;
    final newState = !current;

    // Optimistic update — UI responds instantly
    _pendingToggles.add(relayId);
    _relays = _relays.map((r) =>
        r.relayId == relayId ? r.copyWith(state: newState, lastChangedBy: 'user') : r
    ).toList();
    notifyListeners();

    try {
      await _api.post('/devices/$did/relays/$relayId/control', {'state': newState});
    } catch (_) {
      // Revert on failure
      _relays = _relays.map((r) =>
          r.relayId == relayId ? r.copyWith(state: current) : r
      ).toList();
      notifyListeners();
    } finally {
      _pendingToggles.remove(relayId);
      // Allow next socket echo to pass through (device confirmation)
    }
  }

  // ── Rename Appliance ──────────────────────────────────────────────────────
  Future<void> renameRelay(int relayId, String label) async {
    _relays = _relays.map((r) =>
        r.relayId == relayId ? r.copyWith(label: label) : r
    ).toList();
    notifyListeners();

    if (_device != null) {
      _api.put('/devices/${_device!.deviceId}/relays/$relayId', {'label': label})
          .catchError((_) {});
    }
  }

  void clearUnreadAlerts() {
    _unreadAlerts = 0;
    notifyListeners();
  }

  // ── Public reload (for Settings "Refresh") ───────────────────────────────
  Future<void> loadDevices() => refresh();

  /// Called from login/register/splash — only connects the socket.
  /// Device loading happens separately via init() from the dashboard.
  Future<void> initSocket() => _connectSocket();

  /// Stub — device is pre-configured, registration not needed from app
  Future<Map<String, dynamic>?> addDevice({
    required String deviceId,
    required String name,
    required String location,
  }) async => null;

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }
}
