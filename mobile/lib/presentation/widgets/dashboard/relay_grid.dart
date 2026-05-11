// lib/presentation/widgets/dashboard/relay_grid.dart
// Appliance control grid — localized labels, rename support, haptic feedback.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/relay_model.dart';
import '../../../data/providers/device_provider.dart';
import '../../../data/providers/locale_provider.dart';

class RelayGrid extends StatelessWidget {
  final List<RelayModel> relays;

  const RelayGrid({super.key, required this.relays});

  static const _icons = [
    Icons.lightbulb_outline,
    Icons.air,
    Icons.electrical_services,
    Icons.toggle_on_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleProvider>().strings;
    final defaultLabels = [s.defaultRelay1, s.defaultRelay2, s.defaultRelay3, s.defaultRelay4];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: List.generate(4, (i) {
        final relay = i < relays.length
            ? relays[i]
            : RelayModel(relayId: i + 1, state: false);
        return _RelayCard(
          key: ValueKey(relay.relayId),
          relay: relay,
          icon: _icons[i],
          defaultLabel: defaultLabels[i],
          strings: s,
        );
      }),
    );
  }
}

class _RelayCard extends StatefulWidget {
  final RelayModel relay;
  final IconData icon;
  final String defaultLabel;
  final dynamic strings;

  const _RelayCard({
    super.key,
    required this.relay,
    required this.icon,
    required this.defaultLabel,
    required this.strings,
  });

  @override
  State<_RelayCard> createState() => _RelayCardState();
}

class _RelayCardState extends State<_RelayCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    context.read<DeviceProvider>().toggleRelay(widget.relay.relayId);
    _pulse.reverse().then((_) { if (mounted) _pulse.forward(); });
  }

  void _showRename() {
    final s    = widget.strings;
    final ctrl = TextEditingController(
        text: widget.relay.label ?? widget.defaultLabel);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.renameAppliance,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: s.applianceName,
            prefixIcon: const Icon(Icons.edit_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final newLabel = ctrl.text.trim();
              if (newLabel.isNotEmpty) {
                context.read<DeviceProvider>().renameRelay(
                    widget.relay.relayId, newLabel);
              }
              Navigator.pop(ctx);
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOn  = widget.relay.state;
    final label = widget.relay.label ?? widget.defaultLabel;
    final s     = widget.strings;
    final col   = AppColors.of(context);

    return ScaleTransition(
      scale: _pulse,
      child: GestureDetector(
        onTap: _toggle,
        onLongPress: _showRename,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isOn
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.18),
                      AppTheme.primary.withValues(alpha: 0.12),
                    ],
                  )
                : null,
            color: isOn ? null : col.card,
            border: Border.all(
              color: isOn
                  ? AppTheme.accent.withValues(alpha: 0.55)
                  : col.border,
              width: isOn ? 1.5 : 1,
            ),
            boxShadow: isOn
                ? [BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.18),
                    blurRadius: 14,
                    spreadRadius: 2)]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ── Icon + Toggle ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Appliance icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isOn
                          ? AppTheme.accent.withValues(alpha: 0.18)
                          : col.cardLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon,
                        color: isOn ? AppTheme.accent : col.textMuted,
                        size: 22),
                  ),
                  // Custom toggle switch
                  _ToggleSwitch(isOn: isOn),
                ],
              ),

              // ── Label + Status ───────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        color: isOn ? col.text : col.textSub,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOn ? AppTheme.accent : col.textMuted,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(isOn ? s.relayOn : s.relayOff,
                          style: TextStyle(
                            color: isOn ? AppTheme.accent : col.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Animated custom toggle switch ───────────────────────────────────────────
class _ToggleSwitch extends StatelessWidget {
  final bool isOn;
  const _ToggleSwitch({required this.isOn});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 40,
      height: 22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        color: isOn
            ? AppTheme.accent.withValues(alpha: 0.85)
            : AppColors.of(context).border,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
