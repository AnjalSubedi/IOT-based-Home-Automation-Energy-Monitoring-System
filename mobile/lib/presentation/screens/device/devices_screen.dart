// lib/presentation/screens/device/devices_screen.dart
// Lists all registered Smart Monitors — consumer-friendly, fully localized.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/device_provider.dart';
import '../../../data/providers/locale_provider.dart';
import '../../../data/models/device_model.dart';
import 'add_device_screen.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceProvider>().loadDevices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DeviceProvider>();
    final s  = context.watch<LocaleProvider>().strings;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: Text(s.myMonitors,
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
            tooltip: s.addDevice,
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AddDeviceScreen())),
          ),
        ],
      ),
      body: dp.isRefreshing
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : !dp.hasDevices
              ? _buildEmpty(context, s)
              : RefreshIndicator(
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.bgCard,
                  onRefresh: () => dp.loadDevices(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: dp.devices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _DeviceCard(
                      device: dp.devices[i],
                      isSelected: dp.selectedDevice?.deviceId == dp.devices[i].deviceId,
                      onTap: () => dp.loadDevices(),
                      strings: s,
                    ),
                  ),
                ),
      floatingActionButton: dp.hasDevices
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AddDeviceScreen())),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(s.addDevice,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildEmpty(BuildContext context, dynamic s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.primary.withValues(alpha: 0.2), AppTheme.accent.withValues(alpha: 0.1)],
              ),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Icon(Icons.router_outlined, color: AppTheme.textMuted, size: 48),
          ),
          const SizedBox(height: 20),
          Text(s.noMonitors,
              style: const TextStyle(color: AppTheme.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(s.noMonitorsHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddDeviceScreen())),
            icon: const Icon(Icons.add_link),
            label: Text(s.pairMonitor),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final bool isSelected;
  final VoidCallback onTap;
  final dynamic strings;

  const _DeviceCard({
    required this.device,
    required this.isSelected,
    required this.onTap,
    required this.strings,
  });

  String _lastSeen(dynamic s) {
    if (device.lastSeenAt == null) return '';
    final diff = DateTime.now().difference(device.lastSeenAt!);
    if (diff.inMinutes < 1) return s.justNow;
    if (diff.inHours < 1) return '${diff.inMinutes} ${s.minutesAgo}';
    return '${diff.inHours} ${s.hoursAgo}';
  }

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.bgCard,
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.1),
                  blurRadius: 12, spreadRadius: 2)]
              : [],
        ),
        child: Row(
          children: [
            // Monitor icon with online indicator
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.15)
                        : AppTheme.bgCardLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.router,
                      color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                      size: 26),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: device.isOnline ? AppTheme.success : AppTheme.textMuted,
                      border: Border.all(color: AppTheme.bgDark, width: 2),
                      boxShadow: device.isOnline
                          ? [BoxShadow(color: AppTheme.success.withValues(alpha: 0.6),
                              blurRadius: 4)]
                          : [],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Device info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(device.name,
                            style: const TextStyle(color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(s.active,
                              style: const TextStyle(color: AppTheme.primary,
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(device.location,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: device.isOnline ? AppTheme.success : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        device.isOnline ? s.online : s.offline,
                        style: TextStyle(
                          color: device.isOnline ? AppTheme.success : AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!device.isOnline && device.lastSeenAt != null) ...[
                        const Text(' · ',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        Text(
                          '${s.lastSeen} ${_lastSeen(s)}',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
