// lib/presentation/screens/alerts/alerts_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/device_provider.dart';
import '../../../data/services/api_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
    context.read<DeviceProvider>().clearUnreadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final res = await _api.get('/alerts?limit=30');
      setState(() {
        _alerts = List<Map<String, dynamic>>.from(res['data']);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _api.put('/alerts/read-all', {});
      _loadAlerts();
    } catch (_) {}
  }

  Color _alertColor(String type) {
    switch (type) {
      case 'HIGH_POWER':     return AppTheme.danger;
      case 'DEVICE_OFFLINE': return AppTheme.warning;
      default:               return AppTheme.primary;
    }
  }

  IconData _alertIcon(String type) {
    switch (type) {
      case 'HIGH_POWER':     return Icons.electric_bolt;
      case 'DEVICE_OFFLINE': return Icons.wifi_off;
      default:               return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final col = AppColors.of(context);

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        title: Text('Alerts', style: TextStyle(color: col.text)),
        backgroundColor: col.bg,
        iconTheme: IconThemeData(color: col.text),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text('Mark all read',
                style: TextStyle(
                    color: col.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: col.primary))
          : _alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          color: col.textMuted, size: 64),
                      const SizedBox(height: 12),
                      Text('No alerts yet',
                          style: TextStyle(
                              color: col.textSub, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text('You\'re all caught up!',
                          style: TextStyle(
                              color: col.textMuted, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: col.primary,
                  onRefresh: _loadAlerts,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final a      = _alerts[i];
                      final type   = a['type'] ?? 'CUSTOM';
                      final isRead = a['isRead'] ?? false;
                      final color  = _alertColor(type);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: col.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isRead
                                ? col.border
                                : color.withValues(alpha: 0.4),
                            width: isRead ? 1 : 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(_alertIcon(type),
                                  color: color, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a['message'] ?? '',
                                      style: TextStyle(
                                        color: isRead
                                            ? col.textSub
                                            : col.text,
                                        fontSize: 13,
                                        fontWeight: isRead
                                            ? FontWeight.normal
                                            : FontWeight.w600,
                                      )),
                                  const SizedBox(height: 4),
                                  Text(
                                    a['createdAt'] != null
                                        ? DateFormat.yMMMd().add_jm().format(
                                            DateTime.parse(a['createdAt']))
                                        : '',
                                    style: TextStyle(
                                        color: col.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8, height: 8,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
