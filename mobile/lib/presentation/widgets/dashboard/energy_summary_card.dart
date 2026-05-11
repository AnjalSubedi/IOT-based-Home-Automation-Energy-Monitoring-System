// lib/presentation/widgets/dashboard/energy_summary_card.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/energy_reading_model.dart';

class EnergySummaryCard extends StatelessWidget {
  final EnergySummary summary;

  const EnergySummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final col = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: col.card,
        border: Border.all(color: col.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: 'Energy Used',
                  value: summary.totalKWh.toStringAsFixed(3),
                  unit: 'kWh',
                  color: AppTheme.primary,
                  icon: Icons.bolt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricBox(
                  label: 'Est. Cost',
                  value: summary.estimatedCost.toStringAsFixed(2),
                  unit: summary.currency,
                  color: AppTheme.accent,
                  icon: Icons.monetization_on_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: 'Avg Power',
                  value: summary.avgPower.toStringAsFixed(1),
                  unit: 'W',
                  color: AppTheme.warning,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricBox(
                  label: 'Peak Power',
                  value: summary.peakPower.toStringAsFixed(1),
                  unit: 'W',
                  color: AppTheme.danger,
                  icon: Icons.speed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final col = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit,
                    style: TextStyle(
                        color: col.textMuted, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: col.textSub, fontSize: 12)),
        ],
      ),
    );
  }
}
