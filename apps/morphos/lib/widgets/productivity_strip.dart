import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/morph_palette.dart';
import '../core/productivity.dart';
import 'glass_panel.dart';

/// Home productivity chrome: battery · quick rotation · quick app search.
class ProductivityStrip extends StatelessWidget {
  const ProductivityStrip({
    super.key,
    required this.palette,
    required this.battery,
    required this.rotation,
    required this.onSearch,
    required this.onCycleRotation,
    this.onBatteryTap,
  });

  final MorphPalette palette;
  final BatterySnapshot battery;
  final RotationAction rotation;
  final VoidCallback onSearch;
  final VoidCallback onCycleRotation;
  final VoidCallback? onBatteryTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: GlassPanel(
        palette: p,
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: _Chip(
                palette: p,
                icon: _batteryIcon(battery),
                label: battery.label,
                accent: battery.isLow,
                onTap: onBatteryTap,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _Chip(
                palette: p,
                icon: Icons.screen_rotation,
                label: rotation.shortLabel,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onCycleRotation();
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: _Chip(
                palette: p,
                icon: Icons.search_rounded,
                label: 'Search apps',
                onTap: onSearch,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _batteryIcon(BatterySnapshot b) {
    switch (b.iconKey) {
      case 'charging':
        return Icons.battery_charging_full;
      case 'alert':
        return Icons.battery_alert;
      case 'low':
        return Icons.battery_3_bar;
      case 'mid':
        return Icons.battery_5_bar;
      case 'full':
        return Icons.battery_full;
      default:
        return Icons.battery_unknown;
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.palette,
    required this.icon,
    required this.label,
    this.onTap,
    this.accent = false,
  });

  final MorphPalette palette;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final fg = accent ? const Color(0xFFFF8A80) : p.ink;
    return Material(
      color: p.scaffoldTint.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
