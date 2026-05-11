// lib/presentation/screens/home_screen.dart
// Consumer-facing root screen — 4 tabs, no device management exposed.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/device_provider.dart';
import '../../data/providers/locale_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'alerts/alerts_screen.dart';
import 'settings/settings_screen.dart';
import 'cost/cost_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CostScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final dp  = context.watch<DeviceProvider>();
    final s   = context.watch<LocaleProvider>().strings;
    final col = AppColors.of(context);

    return Scaffold(
      backgroundColor: col.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: col.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: col.card,
          indicatorColor: AppTheme.primary.withValues(alpha: 0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard, color: AppTheme.primary),
              label: s.navDashboard,
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long, color: AppTheme.primary),
              label: s.navAnalytics,
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: dp.unreadAlerts > 0,
                label: Text('${dp.unreadAlerts}'),
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: const Icon(Icons.notifications, color: AppTheme.primary),
              label: s.navAlerts,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings, color: AppTheme.primary),
              label: s.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
