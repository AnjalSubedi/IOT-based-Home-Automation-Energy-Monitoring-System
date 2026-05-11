// lib/presentation/screens/dashboard/dashboard_screen.dart
// Simplified consumer dashboard — 4 appliances always visible, no blocking states.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/device_provider.dart';
import '../../../data/providers/locale_provider.dart';
import '../../widgets/dashboard/live_stats_card.dart';
import '../../widgets/dashboard/relay_grid.dart';
import '../../widgets/dashboard/energy_summary_card.dart';
import '../alerts/alerts_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double>   _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeIn   = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = context.read<DeviceProvider>();
      if (dp.device == null) dp.init();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String _greeting(dynamic s) {
    final h = DateTime.now().hour;
    if (h < 12) return s.greetingMorning;
    if (h < 17) return s.greetingAfternoon;
    return s.greetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dp   = context.watch<DeviceProvider>();
    final s    = context.watch<LocaleProvider>().strings;
    final col  = AppColors.of(context);

    return Scaffold(
      backgroundColor: col.bg,
      body: FadeTransition(
        opacity: _fadeIn,
        child: RefreshIndicator(
          color: col.primary,
          backgroundColor: col.card,
          onRefresh: () => dp.refresh(),
          child: CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 110,
                floating: true,
                snap: true,
                backgroundColor: col.bg,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${_greeting(s)},',
                                style: TextStyle(
                                    color: col.textSub, fontSize: 13)),
                            Text(auth.user?.name.split(' ').first ?? 'User',
                                style: TextStyle(
                                    color: col.text,
                                    fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Spacer(),
                        // Connection status chip
                        _ConnectionChip(status: dp.status),
                        const SizedBox(width: 8),
                        // Alert bell
                        Stack(
                          children: [
                            IconButton(
                              icon: Icon(Icons.notifications_outlined,
                                  color: col.textSub, size: 24),
                              onPressed: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const AlertsScreen())),
                            ),
                            if (dp.unreadAlerts > 0)
                              Positioned(
                                right: 8, top: 8,
                                child: Container(
                                  width: 14, height: 14,
                                  decoration: const BoxDecoration(
                                      color: AppTheme.danger, shape: BoxShape.circle),
                                  child: Center(
                                    child: Text('${dp.unreadAlerts}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Body ─────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // Offline warning
                    if (dp.status == ConnectionStatus.offline)
                      _Banner(
                        icon: Icons.wifi_off_rounded,
                        color: AppTheme.warning,
                        message: 'Monitor is offline — showing last known state',
                      ),

                    if (dp.status == ConnectionStatus.error)
                      _Banner(
                        icon: Icons.cloud_off_rounded,
                        color: AppTheme.danger,
                        message: 'Cannot reach server. Pull down to retry.',
                      ),

                    const SizedBox(height: 8),

                    // Live energy stats
                    LiveStatsCard(reading: dp.liveReading),
                    const SizedBox(height: 20),

                    // Appliance control
                    Row(
                      children: [
                        Text('My Appliances',
                            style: TextStyle(color: col.text,
                                fontSize: 17, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        if (dp.isRefreshing)
                          SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5, color: col.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RelayGrid(relays: dp.relays),
                    const SizedBox(height: 20),

                    // Energy summary
                    Text("Today's Energy",
                        style: TextStyle(color: col.text,
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    EnergySummaryCard(summary: dp.summary),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Connection status chip ───────────────────────────────────────────────────

class _ConnectionChip extends StatelessWidget {
  final ConnectionStatus status;
  const _ConnectionChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;

    switch (status) {
      case ConnectionStatus.online:
        color = AppTheme.success; label = 'Online';
        break;
      case ConnectionStatus.offline:
        color = AppTheme.warning; label = 'Offline';
        break;
      case ConnectionStatus.error:
        color = AppTheme.danger; label = 'No server';
        break;
      case ConnectionStatus.connecting:
        color = AppColors.of(context).textMuted; label = 'Connecting';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          status == ConnectionStatus.connecting
              ? SizedBox(
                  width: 8, height: 8,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: color))
              : Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
                  ),
                ),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color,
              fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Inline banner (non-blocking) ────────────────────────────────────────────

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   message;
  const _Banner({required this.icon, required this.color, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: TextStyle(color: color,
                  fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
