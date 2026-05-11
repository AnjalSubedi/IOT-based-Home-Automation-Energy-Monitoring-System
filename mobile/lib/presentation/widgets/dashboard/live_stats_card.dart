// lib/presentation/widgets/dashboard/live_stats_card.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/energy_reading_model.dart';

class LiveStatsCard extends StatelessWidget {
  final EnergyReading? reading;

  const LiveStatsCard({super.key, this.reading});

  @override
  Widget build(BuildContext context) {
    final col     = AppColors.of(context);
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final hasData = reading != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1835), Color(0xFF16162A)],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary.withValues(alpha: 0.06),
                  AppTheme.accent.withValues(alpha: 0.04),
                ],
              ),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: isDark ? 0.1 : 0.06),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status row ──────────────────────────────────────────────
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasData ? AppTheme.success : col.textMuted,
                  boxShadow: hasData
                      ? [BoxShadow(
                          color: AppTheme.success.withValues(alpha: 0.6),
                          blurRadius: 6)]
                      : [],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hasData ? 'Live Readings' : 'Waiting for data...',
                style: TextStyle(color: col.textSub, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Power — large display ────────────────────────────────────
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Text(
                        hasData
                            ? reading!.power.toStringAsFixed(1)
                            : '--',
                        key: ValueKey(hasData
                            ? reading!.power.toStringAsFixed(1)
                            : 'empty'),
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: col.text,
                          height: 1,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(' W',
                          style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 22,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Active Power',
                    style: TextStyle(color: col.textMuted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── V / A / Hz / PF row ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                icon: Icons.electric_bolt,
                label: 'Voltage',
                value: hasData
                    ? '${reading!.voltage.toStringAsFixed(1)} V'
                    : '--',
                color: AppTheme.warning,
              ),
              _StatChip(
                icon: Icons.electrical_services,
                label: 'Current',
                value: hasData
                    ? '${reading!.current.toStringAsFixed(2)} A'
                    : '--',
                color: AppTheme.accent,
              ),
              _StatChip(
                icon: Icons.waves,
                label: 'Frequency',
                value: hasData
                    ? '${reading!.frequency.toStringAsFixed(1)} Hz'
                    : '--',
                color: AppTheme.primary,
              ),
              _StatChip(
                icon: Icons.speed,
                label: 'PF',
                value: hasData
                    ? reading!.powerFactor.toStringAsFixed(2)
                    : '--',
                color: AppTheme.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final col = AppColors.of(context);
    return Column(
      children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: col.text,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: TextStyle(color: col.textMuted, fontSize: 10)),
      ],
    );
  }
}
