// lib/presentation/widgets/dashboard/device_status_bar.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/device_model.dart';
import 'package:intl/intl.dart';

class DeviceStatusBar extends StatelessWidget {
  final DeviceModel? device;

  const DeviceStatusBar({super.key, this.device});

  @override
  Widget build(BuildContext context) {
    if (device == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          // Online indicator
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: device!.isOnline ? AppTheme.success : AppTheme.textMuted,
              boxShadow: device!.isOnline
                  ? [BoxShadow(color: AppTheme.success.withValues(alpha: 0.5), blurRadius: 6)]
                  : [],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device!.name,
                    style: const TextStyle(color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  device!.isOnline
                      ? device!.location
                      : 'Last seen: ${device!.lastSeenAt != null ? DateFormat.jm().format(device!.lastSeenAt!) : "never"}',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: device!.isOnline
                  ? AppTheme.success.withValues(alpha: 0.12)
                  : AppTheme.textMuted.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              device!.isOnline ? 'ONLINE' : 'OFFLINE',
              style: TextStyle(
                color: device!.isOnline ? AppTheme.success : AppTheme.textMuted,
                fontSize: 11, fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
