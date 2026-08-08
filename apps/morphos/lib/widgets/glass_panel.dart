import 'package:flutter/material.dart';

import '../core/morph_palette.dart';

/// Lightweight glass-style panel (no BackdropFilter — safer on emulator).
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.palette,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 20,
    this.blur = true, // kept for API compatibility; blur not used
  });

  final MorphPalette palette;
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: palette.panelBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.28 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
