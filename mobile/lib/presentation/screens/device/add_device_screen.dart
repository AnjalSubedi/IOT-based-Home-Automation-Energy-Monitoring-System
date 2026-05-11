// lib/presentation/screens/device/add_device_screen.dart
// Consumer-facing "Pair Monitor" screen — proper error handling, help tooltip.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/device_provider.dart';
import '../../../data/providers/locale_provider.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _codeCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  String? _selectedRoom;
  bool _loading    = false;
  bool _success    = false;

  late AnimationController _animCtrl;
  late Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    setState(() => _loading = true);

    final s = context.read<LocaleProvider>().strings;

    try {
      final res = await context.read<DeviceProvider>().addDevice(
        deviceId: _codeCtrl.text.trim().toUpperCase(),
        name:     _nameCtrl.text.trim(),
        location: _selectedRoom ?? 'Home',
      );

      if (!mounted) return;

      if (res != null) {
        setState(() { _loading = false; _success = true; });
        _animCtrl.forward();
      } else {
        // Device provider returned null — check the provider's error
        final errMsg = context.read<DeviceProvider>().error ?? s.pairFailed;
        _showError(_resolveError(errMsg, s));
        setState(() => _loading = false);
      }
    } on SocketException {
      if (!mounted) return;
      _showError(s.pairNetworkErr);
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      _showError(_resolveError(msg, s));
      setState(() => _loading = false);
    }
  }

  /// Map backend error messages to user-friendly strings.
  String _resolveError(String raw, dynamic s) {
    final lower = raw.toLowerCase();
    if (lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('socket') ||
        lower.contains('timeout') ||
        lower.contains('reach')) {
      return s.pairNetworkErr;
    }
    if (lower.contains('not found') || lower.contains('invalid')) {
      return s.pairCodeNotFound;
    }
    if (lower.contains('already') || lower.contains('exists')) {
      return s.pairAlreadyPaired;
    }
    return s.pairFailed;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: context.read<LocaleProvider>().strings.retry,
          textColor: Colors.white,
          onPressed: _submit,
        ),
      ),
    );
  }

  void _showPairHelp(dynamic s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.help_outline,
                      color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.pairHelpTitle,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Visual label example
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgCardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ESP32-001',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '← Device ID label',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.pairHelpBody,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().strings;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(s.pairTitle,
            style: const TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          // Help button
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppTheme.textMuted),
            tooltip: s.pairHelpTitle,
            onPressed: () => _showPairHelp(s),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _success ? _buildSuccess(s) : _buildForm(s),
      ),
    );
  }

  Widget _buildForm(dynamic s) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.add_link, color: Colors.white, size: 46),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(s.pairTitle,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(s.pairSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    height: 1.4)),
          ),
          const SizedBox(height: 32),

          // ── Pairing Code ────────────────────────────────────────────
          Row(
            children: [
              _label(s.pairingCode),
              const Spacer(),
              GestureDetector(
                onTap: () => _showPairHelp(s),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.help_outline,
                        color: AppTheme.primary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      s.pairHelpTitle,
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          TextFormField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontFamily: 'monospace',
                fontSize: 16,
                letterSpacing: 2),
            decoration: InputDecoration(
              hintText: s.pairingCodeHint,
              prefixIcon: const Icon(Icons.qr_code, color: AppTheme.textMuted),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? s.pairingCodeEmpty : null,
          ),
          const SizedBox(height: 16),

          // ── Monitor Name ─────────────────────────────────────────────
          _label(s.monitorName),
          TextFormField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: s.monitorNameHint,
              prefixIcon:
                  const Icon(Icons.home_outlined, color: AppTheme.textMuted),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? s.monitorNameEmpty : null,
          ),
          const SizedBox(height: 16),

          // ── Room / Location ──────────────────────────────────────────
          _label(s.room),
          DropdownButtonFormField<String>(
            value: _selectedRoom, // ignore: deprecated_member_use
            dropdownColor: AppTheme.bgCard,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: s.roomHint,
              prefixIcon: const Icon(Icons.location_on_outlined,
                  color: AppTheme.textMuted),
            ),
            items: (s.rooms as List<String>).map((r) {
              return DropdownMenuItem<String>(value: r, child: Text(r));
            }).toList(),
            onChanged: (v) => setState(() => _selectedRoom = v),
          ),
          const SizedBox(height: 32),

          // ── Submit Button ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.link),
              label: Text(s.pairBtn,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                backgroundColor: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSuccess(dynamic s) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.success.withValues(alpha: 0.15),
              border: Border.all(color: AppTheme.success, width: 2),
            ),
            child: const Icon(Icons.check_rounded,
                color: AppTheme.success, size: 60),
          ),
          const SizedBox(height: 24),
          Text(s.pairSuccess,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(s.pairSuccessMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.5)),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.dashboard_outlined),
              label: Text(s.goToDashboard,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                backgroundColor: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500)),
    );
  }
}
