// lib/presentation/screens/cost/cost_screen.dart
// Cost & Usage screen — calculates electricity bill using NEA tiered tariff.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/device_provider.dart';
import '../../../data/providers/locale_provider.dart';
import '../../../data/services/api_service.dart';

class CostScreen extends StatefulWidget {
  const CostScreen({super.key});

  @override
  State<CostScreen> createState() => _CostScreenState();
}

class _CostScreenState extends State<CostScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _api = ApiService();

  List<Map<String, dynamic>> _tariffSlabs = [];
  Map<String, dynamic> _usageData = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final tariffRes  = await _api.get('/tariff');
      final usageRes   = await _api.get('/analytics/summary');
      setState(() {
        _tariffSlabs = List<Map<String, dynamic>>.from(tariffRes['data']['slabs']);
        _usageData   = Map<String, dynamic>.from(usageRes['data'] ?? {});
        _loading     = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // NEA tiered bill calculation
  double _calcBill(double totalKWh) {
    if (_tariffSlabs.isEmpty) return 0;
    double bill = 0;
    double remaining = totalKWh;
    for (final slab in _tariffSlabs) {
      final from = (slab['fromKWh'] as num).toDouble();
      final to   = slab['toKWh'] != null
          ? (slab['toKWh'] as num).toDouble()
          : double.infinity;
      final rate = (slab['ratePerKWh'] as num).toDouble();
      if (remaining <= 0) break;
      final slabSize = to == double.infinity ? remaining : (to - from);
      final used     = remaining > slabSize ? slabSize : remaining;
      bill     += used * rate;
      remaining -= used;
    }
    return bill;
  }

  @override
  Widget build(BuildContext context) {
    final dp  = context.watch<DeviceProvider>();
    final s   = context.watch<LocaleProvider>().strings;
    final col = AppColors.of(context);

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        backgroundColor: col.bg,
        title: Text(s.costTitle,
            style: TextStyle(
                color: col.text, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: col.primary),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: col.textMuted,
          tabs: [
            Tab(text: s.today),
            Tab(text: s.thisMonth),
            Tab(text: s.thisYear),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: col.primary))
          : !dp.hasDevices
              ? _buildNoDevice(s, col)
              : RefreshIndicator(
                  color: col.primary,
                  backgroundColor: col.card,
                  onRefresh: _loadData,
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _buildTab(s, 'day', col),
                      _buildTab(s, 'month', col),
                      _buildTab(s, 'year', col),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTab(dynamic s, String period, AppColors col) {
    final kwh  = _getKwh(period);
    final bill = _calcBill(kwh);
    final avg  = _getAvg(period, kwh);
    final peak = _getPeak(period);
    final tip  = s.tipForUsage(kwh);
    final bars = _getBars(period);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Bill Hero Card ────────────────────────────────────────────
        _BillHeroCard(
          kwh: kwh,
          bill: bill,
          currency: s.currency,
          totalLabel: s.totalUsage,
          billLabel: s.estimatedBill,
        ),
        const SizedBox(height: 16),

        // ── Stat Row ──────────────────────────────────────────────────
        Row(
          children: [
            Expanded(child: _StatCard(
              label: s.dailyAvg,
              value: '${avg.toStringAsFixed(2)} kWh',
              icon: Icons.trending_flat,
              color: AppTheme.accent,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(
              label: s.peakUsage,
              value: '${peak.toStringAsFixed(1)} W',
              icon: Icons.bolt,
              color: AppTheme.warning,
            )),
          ],
        ),
        const SizedBox(height: 16),

        // ── Usage Chart ───────────────────────────────────────────────
        if (bars.isNotEmpty) ...[
          _SectionTitle(
              period == 'day'
                  ? 'Hourly Usage (kWh)'
                  : 'Daily Usage (kWh)',
              col),
          const SizedBox(height: 10),
          _UsageBarChart(bars: bars),
          const SizedBox(height: 16),
        ],

        // ── Bill Breakdown ─────────────────────────────────────────────
        if (_tariffSlabs.isNotEmpty) ...[
          _SectionTitle(s.billBreakdown, col),
          const SizedBox(height: 10),
          _BillBreakdown(
            kwh: kwh,
            slabs: _tariffSlabs,
            currency: s.currency,
          ),
          const SizedBox(height: 16),
        ],

        // ── Savings Tip ────────────────────────────────────────────────
        _TipCard(tip: tip, label: s.savingsTip),
        const SizedBox(height: 16),
      ],
    );
  }

  double _getKwh(String period) {
    if (_usageData.isEmpty) return 0;
    try {
      switch (period) {
        case 'day':   return (_usageData['todayKWh'] as num?)?.toDouble() ?? 0;
        case 'month': return (_usageData['monthKWh'] as num?)?.toDouble() ?? 0;
        case 'year':  return (_usageData['yearKWh']  as num?)?.toDouble() ?? 0;
        default:      return 0;
      }
    } catch (_) { return 0; }
  }

  double _getAvg(String period, double total) {
    if (total == 0) return 0;
    final now = DateTime.now();
    switch (period) {
      case 'day':   return total / 24;
      case 'month': return total / now.day;
      case 'year':  return total / now.month;
      default:      return 0;
    }
  }

  double _getPeak(String period) {
    try {
      return (_usageData['peakPowerW'] as num?)?.toDouble() ?? 0;
    } catch (_) { return 0; }
  }

  List<double> _getBars(String period) {
    try {
      final key = period == 'day' ? 'hourlyKWh' : 'dailyKWh';
      final raw = _usageData[key];
      if (raw == null) return [];
      return List<double>.from((raw as List).map((e) => (e as num).toDouble()));
    } catch (_) { return []; }
  }

  Widget _buildNoDevice(dynamic s, AppColors col) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              color: col.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(s.noCostData,
              style: TextStyle(
                  color: col.text, fontSize: 16)),
          const SizedBox(height: 8),
          Text(s.noDeviceHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: col.textSub, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BillHeroCard extends StatelessWidget {
  final double kwh;
  final double bill;
  final String currency;
  final String totalLabel;
  final String billLabel;

  const _BillHeroCard({
    required this.kwh,
    required this.bill,
    required this.currency,
    required this.totalLabel,
    required this.billLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1A1035), Color(0xFF0F2042)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.08),
                  AppTheme.accent.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.electric_bolt,
                    color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(totalLabel,
                      style: TextStyle(
                          color: AppColors.of(context).textMuted,
                          fontSize: 12)),
                  Text('${kwh.toStringAsFixed(2)} kWh',
                      style: TextStyle(
                          color: AppColors.of(context).text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: AppTheme.primary.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text(billLabel,
              style: TextStyle(
                  color: AppColors.of(context).textSub, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(currency,
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Text(bill.toStringAsFixed(2),
                  style: TextStyle(
                      color: AppColors.of(context).text,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      height: 1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: col.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: col.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final AppColors col;
  const _SectionTitle(this.title, this.col);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(
            color: col.text,
            fontSize: 15,
            fontWeight: FontWeight.w600));
  }
}

class _UsageBarChart extends StatelessWidget {
  final List<double> bars;
  const _UsageBarChart({required this.bars});

  @override
  Widget build(BuildContext context) {
    final col    = AppColors.of(context);
    final maxVal = bars.isEmpty ? 1.0 : bars.reduce((a, b) => a > b ? a : b);
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.border),
      ),
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (v, _) {
                  if (bars.length > 12 && v.toInt() % 4 != 0) {
                    return const SizedBox.shrink();
                  }
                  return Text('${v.toInt()}',
                      style: TextStyle(
                          color: col.textMuted, fontSize: 9));
                },
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: col.border,
              strokeWidth: 0.5,
            ),
          ),
          maxY: maxVal * 1.2,
          barGroups: List.generate(
            bars.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: bars[i],
                  color: AppTheme.primary.withValues(alpha: 0.85),
                  width: bars.length > 20 ? 5 : 10,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BillBreakdown extends StatelessWidget {
  final double kwh;
  final List<Map<String, dynamic>> slabs;
  final String currency;

  const _BillBreakdown({
    required this.kwh,
    required this.slabs,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final col = AppColors.of(context);
    double remaining = kwh;
    final List<Map<String, dynamic>> breakdown = [];

    for (final slab in slabs) {
      if (remaining <= 0) break;
      final from = (slab['fromKWh'] as num).toDouble();
      final to   = slab['toKWh'] != null
          ? (slab['toKWh'] as num).toDouble()
          : double.infinity;
      final rate = (slab['ratePerKWh'] as num).toDouble();
      final slabSize = to == double.infinity ? remaining : (to - from);
      final used     = remaining > slabSize ? slabSize : remaining;
      if (used > 0) {
        breakdown.add({
          'label': slab['label'] ?? 'Slab',
          'used': used,
          'rate': rate,
          'cost': used * rate,
        });
      }
      remaining -= used;
    }

    return Container(
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.border),
      ),
      child: Column(
        children: breakdown.asMap().entries.map((e) {
          final i     = e.key;
          final item  = e.value;
          final isLast = i == breakdown.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['label'],
                              style: TextStyle(
                                  color: col.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                              '${(item['used'] as double).toStringAsFixed(2)} kWh × $currency ${(item['rate'] as double).toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: col.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(
                      '$currency ${(item['cost'] as double).toStringAsFixed(2)}',
                      style: TextStyle(
                          color: col.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (!isLast) Divider(height: 1, color: col.border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String tip;
  final String label;

  const _TipCard({required this.tip, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lightbulb_outline,
                color: AppTheme.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(tip,
                    style: TextStyle(
                        color: AppColors.of(context).textSub,
                        fontSize: 13,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
