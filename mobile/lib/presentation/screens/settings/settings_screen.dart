// lib/presentation/screens/settings/settings_screen.dart
// Consumer-ready settings — theme switcher, language, NEA tariff, account info.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/device_provider.dart';
import '../../../data/providers/locale_provider.dart';
import '../../../data/providers/theme_provider.dart';
import '../../../data/services/api_service.dart';
import '../auth/login_screen.dart';
import '../admin/admin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _slabs = [];
  bool _loading = true;
  bool _saving  = false;

  // ── Secret admin unlock (5 taps on version tile) ──────────────────────────
  int _adminTaps = 0;
  DateTime? _lastTap;

  void _onVersionTap() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!).inSeconds > 3) {
      _adminTaps = 0;
    }
    _lastTap = now;
    _adminTaps++;

    if (_adminTaps >= 5) {
      _adminTaps = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            Icon(Icons.admin_panel_settings, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('🔧 Admin mode unlocked'),
          ]),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AdminScreen()));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTariff();
  }

  Future<void> _loadTariff() async {
    try {
      final res = await _api.get('/tariff');
      setState(() {
        _slabs   = List<Map<String, dynamic>>.from(res['data']['slabs']);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveTariff(dynamic s) async {
    setState(() => _saving = true);
    try {
      await _api.put('/tariff', {'slabs': _slabs});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.tariffSaved),
              backgroundColor: AppTheme.success),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.tariffFailed),
              backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _logout(dynamic s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.signOut,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        content: Text(s.signOutConfirmMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: Text(s.signOut),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final nav    = Navigator.of(context);
      final auth   = context.read<AuthProvider>();
      final device = context.read<DeviceProvider>();
      await auth.logout();
      device.dispose();
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth         = context.watch<AuthProvider>();
    final locale       = context.watch<LocaleProvider>();
    final themeP       = context.watch<ThemeProvider>();
    final s            = locale.strings;
    final col          = AppColors.of(context);

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        backgroundColor: col.bg,
        title: Text(s.settingsTitle,
            style: TextStyle(
                color: col.text, fontWeight: FontWeight.bold)),
        actions: [
          if (!_loading && _slabs.isNotEmpty)
            TextButton(
              onPressed: _saving ? null : () => _saveTariff(s),
              child: _saving
                  ? SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: col.primary, strokeWidth: 2))
                  : Text(s.save,
                      style: TextStyle(
                          color: col.primary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile Card ────────────────────────────────────────────────
          _SectionHeader(s.account),
          _ProfileCard(
            name: auth.user?.name ?? '',
            email: auth.user?.email ?? '',
          ),
          const SizedBox(height: 24),

          // ── Appearance ──────────────────────────────────────────────────
          _SectionHeader('Appearance'),
          _ThemeSelector(current: themeP.mode, onChanged: themeP.setMode),
          const SizedBox(height: 24),

          // ── Language ────────────────────────────────────────────────────
          _SectionHeader(s.language),
          Container(
            decoration: BoxDecoration(
              color: col.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: col.border),
            ),
            child: Column(
              children: [
                _LanguageTile(
                  label: s.langEnglish,
                  flag: '🇬🇧',
                  code: 'en',
                  selectedCode: locale.languageCode,
                  onTap: () => locale.setLanguage('en'),
                ),
                Divider(height: 1, color: col.border),
                _LanguageTile(
                  label: s.langNepali,
                  flag: '🇳🇵',
                  code: 'ne',
                  selectedCode: locale.languageCode,
                  onTap: () => locale.setLanguage('ne'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Tariff Settings ─────────────────────────────────────────────
          _SectionHeader(s.tariffSettings),
          const SizedBox(height: 4),
          Text(s.tariffHint,
              style: TextStyle(
                  color: col.textMuted, fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),

          _loading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: col.primary),
                  ))
              : _slabs.isEmpty
                  ? Text(s.tariffLoadFail,
                      style: TextStyle(color: col.textMuted))
                  : Column(
                      children: List.generate(
                        _slabs.length,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TariffSlabEditor(
                            slab: _slabs[i],
                            index: i,
                            onChanged: (updated) {
                              setState(() => _slabs[i] = updated);
                            },
                          ),
                        ),
                      ),
                    ),
          const SizedBox(height: 24),

          // ── About ──────────────────────────────────────────────────────
          _SectionHeader(s.aboutSection),
          GestureDetector(
            onTap: _onVersionTap,
            child: _SettingsTile(
              icon: Icons.info_outline,
              title: s.appVersion,
              trailing: '1.0.0',
            ),
          ),
          _SettingsTile(
            icon: Icons.support_agent_outlined,
            title: s.contactSupport,
            trailing: '',
          ),
          const SizedBox(height: 24),

          // ── Sign Out ────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _logout(s),
              icon: const Icon(Icons.logout, color: AppTheme.danger),
              label: Text(s.signOut,
                  style: const TextStyle(
                      color: AppTheme.danger, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.danger),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Profile card ─────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  const _ProfileCard({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    final col = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
              ),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: col.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                Text(email,
                    style: TextStyle(
                        color: col.textSub, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Theme Selector ───────────────────────────────────────────────────────────
class _ThemeSelector extends StatelessWidget {
  final ThemeMode current;
  final Future<void> Function(ThemeMode) onChanged;
  const _ThemeSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final col = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.border),
      ),
      child: Row(
        children: [
          _ThemeOption(
            label: 'System',
            icon: Icons.phone_android_rounded,
            mode: ThemeMode.system,
            current: current,
            onTap: () => onChanged(ThemeMode.system),
          ),
          _ThemeOption(
            label: 'Light',
            icon: Icons.light_mode_rounded,
            mode: ThemeMode.light,
            current: current,
            onTap: () => onChanged(ThemeMode.light),
          ),
          _ThemeOption(
            label: 'Dark',
            icon: Icons.dark_mode_rounded,
            mode: ThemeMode.dark,
            current: current,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final ThemeMode mode;
  final ThemeMode current;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.mode,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == current;
    final col = AppColors.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.4))
                : Border.all(color: Colors.transparent),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 22,
                  color: isSelected ? AppTheme.primary : col.textMuted),
              const SizedBox(height: 5),
              Text(label,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primary : col.textSub,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  final String label;
  final String flag;
  final String code;
  final String selectedCode;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.flag,
    required this.code,
    required this.selectedCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = code == selectedCode;
    final col = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: col.text, fontSize: 15)),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppTheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : col.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final col = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title.toUpperCase(),
          style: TextStyle(
            color: col.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          )),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final col = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: col.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      color: col.text, fontSize: 14))),
          if (trailing.isNotEmpty)
            Text(trailing,
                style: TextStyle(
                    color: col.textSub, fontSize: 13)),
        ],
      ),
    );
  }
}

class _TariffSlabEditor extends StatelessWidget {
  final Map<String, dynamic> slab;
  final int index;
  final Function(Map<String, dynamic>) onChanged;

  const _TariffSlabEditor({
    required this.slab,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final col  = AppColors.of(context);
    final ctrl = TextEditingController(
        text: (slab['ratePerKWh'] ?? 0).toStringAsFixed(2));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slab['label'] ?? 'Slab ${index + 1}',
                    style: TextStyle(
                        color: col.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  '${slab['fromKWh']} – ${slab['toKWh'] ?? '∞'} kWh',
                  style: TextStyle(
                      color: col.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 105,
            child: TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                  color: col.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                suffixText: ' NPR',
                suffixStyle: TextStyle(
                    color: col.textMuted, fontSize: 12),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: col.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: col.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.primary)),
                filled: true,
                fillColor: col.cardLight,
              ),
              onChanged: (v) {
                final rate = double.tryParse(v) ?? slab['ratePerKWh'];
                onChanged({...slab, 'ratePerKWh': rate});
              },
            ),
          ),
        ],
      ),
    );
  }
}
