// lib/presentation/screens/splash_screen.dart
// Animated splash screen — validates token offline-first, routes accordingly.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/device_provider.dart';
import '../../data/providers/locale_provider.dart';
import '../../data/services/auth_service.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _pulseFade;
  late Animation<double> _pulseScale;

  String _statusText = '';
  bool _isOffline    = false;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut);
    _logoFade  = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseFade  = Tween(begin: 0.3, end: 0.7).animate(_pulseCtrl);
    _pulseScale = Tween(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 800), _checkAuth);
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final s = context.read<LocaleProvider>().strings;

    if (!mounted) return;
    setState(() => _statusText = s.splashVerifying);

    final result = await AuthService().validateToken();

    if (!mounted) return;

    if (!result.isValid) {
      _navigateTo(const LoginScreen());
      return;
    }

    if (result.isOffline) {
      setState(() {
        _isOffline  = true;
        _statusText = s.splashOffline;
      });
    }

    if (result.user != null) {
      if (!mounted) return;
      context.read<AuthProvider>().setUserFromValidation(
        result.user!,
        offline: result.isOffline,
      );
    }

    if (!mounted) return;
    final dp = context.read<DeviceProvider>();
    try { await dp.initSocket(); } catch (_) {}
    try { await dp.loadDevices(); } catch (_) {}

    if (!mounted) return;
    _navigateTo(const HomeScreen());
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s      = context.watch<LocaleProvider>().strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0A1A),
                    Color(0xFF12082E),
                    Color(0xFF0A0A1A),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.bgLight,
                    Color(0xFFEAEAFF),
                    AppTheme.bgLight,
                  ],
                ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo with pulsing glow ───────────────────────────
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, child) => Transform.scale(
                        scale: _pulseScale.value,
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
                                color: AppTheme.primary
                                    .withValues(alpha: _pulseFade.value),
                                blurRadius: 36,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                            size: 54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── App name ─────────────────────────────────────────
                FadeTransition(
                  opacity: _logoFade,
                  child: Text(
                    s.appName,
                    style: TextStyle(
                      color: isDark ? AppTheme.textPrimary : AppTheme.textDark,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                FadeTransition(
                  opacity: _logoFade,
                  child: Text(
                    s.splashTagline,
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textMuted
                          : AppTheme.textDarkMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // ── Status text ──────────────────────────────────────
                if (_statusText.isNotEmpty) ...[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _statusText,
                      key: ValueKey(_statusText),
                      style: TextStyle(
                        color: _isOffline
                            ? AppTheme.warning
                            : (isDark
                                ? AppTheme.textMuted
                                : AppTheme.textDarkMuted),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 28, height: 28,
                    child: CircularProgressIndicator(
                      color: _isOffline ? AppTheme.warning : AppTheme.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                ],

                // ── Offline badge ────────────────────────────────────
                if (_isOffline) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.warning.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            color: AppTheme.warning, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          s.offlineMode,
                          style: const TextStyle(
                              color: AppTheme.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
