// lib/presentation/screens/admin/admin_screen.dart
// Hidden admin panel — accessible only via 5-tap secret on Settings version tile.
// Shows all ESP32 devices, technical details, and allows registering new modules.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/device_provider.dart';
import '../../../data/services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _api = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _rawDevices = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRawDevices();
  }

  Future<void> _loadRawDevices() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get('/devices');
      setState(() {
        _rawDevices = List<Map<String, dynamic>>.from(res['data']);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _deleteDevice(String deviceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Device',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('Remove "$deviceId" from the system?',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _api.delete('/devices/$deviceId');
        await _loadRawDevices();
        if (mounted) context.read<DeviceProvider>().loadDevices();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: ${e.toString()}'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    }
  }

  void _showRegisterDialog() {
    final idCtrl    = TextEditingController();
    final nameCtrl  = TextEditingController();
    final formKey   = GlobalKey<FormState>();
    bool saving     = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Register ESP32 Device',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('This is admin-only. Consumers never see this.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 20),

                // Device ID
                const Text('Device ID (ESP32 ID)',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: idCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontFamily: 'monospace',
                      letterSpacing: 1.5),
                  decoration: const InputDecoration(
                    hintText: 'e.g. esp32-001',
                    prefixIcon: Icon(Icons.memory, color: AppTheme.textMuted),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Friendly name
                const Text('Friendly Name',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Living Room Monitor',
                    prefixIcon: Icon(Icons.label_outline, color: AppTheme.textMuted),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setS(() => saving = true);
                            try {
                              await context.read<DeviceProvider>().addDevice(
                                    deviceId: idCtrl.text.trim().toLowerCase(),
                                    name: nameCtrl.text.trim(),
                                    location: 'Home',
                                  );
                              if (ctx.mounted) Navigator.pop(ctx);
                              await _loadRawDevices();
                            } catch (e) {
                              setS(() => saving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString()),
                                    backgroundColor: AppTheme.danger,
                                  ),
                                );
                              }
                            }
                          },
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.add_circle_outline),
                    label: Text(saving ? 'Registering…' : 'Register Device',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final col = AppColors.of(context);
    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        backgroundColor: col.bg,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
              ),
              child: const Text('ADMIN',
                  style: TextStyle(
                      color: AppTheme.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
            const SizedBox(width: 10),
            Text('Device Management',
                style: TextStyle(
                    color: col.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: col.text),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: col.textMuted),
            onPressed: _loadRawDevices,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _buildError()
              : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRegisterDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Register ESP32',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildError() {
    final col = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
          const SizedBox(height: 12),
          Text(_error!,
              style: TextStyle(color: col.textSub),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadRawDevices,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final col = AppColors.of(context);
    if (_rawDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.memory, color: col.textMuted, size: 56),
            const SizedBox(height: 16),
            Text('No devices registered',
                style: TextStyle(
                    color: col.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Tap the button below to register your ESP32.',
                style: TextStyle(color: col.textSub)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _rawDevices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _AdminDeviceCard(
        data: _rawDevices[i],
        onDelete: () => _deleteDevice(
          (_rawDevices[i]['deviceId'] ?? _rawDevices[i]['_id']) as String,
        ),
      ),
    );
  }
}

// ─── Device card with full technical details ─────────────────────────────────

class _AdminDeviceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;

  const _AdminDeviceCard({required this.data, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final deviceId  = (data['deviceId'] ?? data['_id'] ?? '—') as String;
    final name      = (data['name'] ?? 'Unnamed') as String;
    final location  = (data['location'] ?? '') as String;
    final isOnline  = (data['isOnline'] ?? false) as bool;
    final secret    = (data['deviceSecret'] ?? '') as String;
    final col       = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline
              ? AppTheme.success.withValues(alpha: 0.4)
              : col.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppTheme.success.withValues(alpha: 0.1)
                      : AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.memory,
                    color: isOnline ? AppTheme.success : AppTheme.textMuted,
                    size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            color: col.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    if (location.isNotEmpty)
                      Text(location,
                          style: TextStyle(
                              color: col.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              // Online status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOnline
                      ? AppTheme.success.withValues(alpha: 0.15)
                      : AppTheme.textMuted.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? AppTheme.success : AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                            color: isOnline ? AppTheme.success : AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: col.border),
          const SizedBox(height: 12),

          // Technical details
          _TechRow(label: 'Device ID', value: deviceId, monospace: true, copyable: true),
          if (secret.isNotEmpty)
            _TechRow(label: 'Secret', value: secret, monospace: true, copyable: true, obscure: true),

          const SizedBox(height: 12),

          // Delete button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 16),
              label: const Text('Remove Device',
                  style: TextStyle(color: AppTheme.danger, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TechRow extends StatefulWidget {
  final String label;
  final String value;
  final bool monospace;
  final bool copyable;
  final bool obscure;

  const _TechRow({
    required this.label,
    required this.value,
    this.monospace = false,
    this.copyable  = false,
    this.obscure   = false,
  });

  @override
  State<_TechRow> createState() => _TechRowState();
}

class _TechRowState extends State<_TechRow> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final displayVal = widget.obscure && !_revealed
        ? '••••••••••••'
        : widget.value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(widget.label,
                style: TextStyle(
                    color: AppColors.of(context).textMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(displayVal,
                style: TextStyle(
                    color: AppColors.of(context).text,
                    fontSize: 13,
                    fontFamily: widget.monospace ? 'monospace' : null,
                    letterSpacing: widget.monospace ? 0.5 : 0)),
          ),
          if (widget.obscure)
            GestureDetector(
              onTap: () => setState(() => _revealed = !_revealed),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                    _revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.textMuted,
                    size: 16),
              ),
            ),
          if (widget.copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.label} copied'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.copy_outlined,
                    color: AppTheme.textMuted, size: 15),
              ),
            ),
        ],
      ),
    );
  }
}
