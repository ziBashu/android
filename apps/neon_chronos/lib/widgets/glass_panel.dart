import 'package:flutter/material.dart';

import '../core/theme_engine/neon_theme.dart';

/// Frosted glass HUD panel with press scale and soft neon edge.
class GlassPanel extends StatefulWidget {
  const GlassPanel({
    super.key,
    required this.child,
    required this.accent,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.borderRadius = 14,
  });

  final Widget child;
  final Color accent;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  State<GlassPanel> createState() => _GlassPanelState();
}

class _GlassPanelState extends State<GlassPanel> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    final panel = AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: widget.padding,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NeonColors.surface.withValues(alpha: 0.72),
              NeonColors.surface.withValues(alpha: 0.42),
              widget.accent.withValues(alpha: 0.06),
            ],
            stops: const [0, 0.55, 1],
          ),
          border: Border.all(
            color: widget.accent.withValues(alpha: _pressed ? 0.55 : 0.32),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.accent.withValues(alpha: _pressed ? 0.18 : 0.1),
              blurRadius: _pressed ? 20 : 14,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap == null) return panel;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap!();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: panel,
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color.withValues(alpha: 0.88),
        fontSize: 10,
        letterSpacing: 2.2,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    );
  }
}

/// Soft page fade + slight slide for tab / route changes.
class FadeSlidePage extends StatelessWidget {
  const FadeSlidePage({
    super.key,
    required this.child,
    this.offset = const Offset(0, 0.02),
  });

  final Widget child;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(offset.dx * 24 * (1 - t), offset.dy * 24 * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Animated neon bottom rail item.
class NeonNavItem extends StatelessWidget {
  const NeonNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.dimColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final Color dimColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = selected ? color : dimColor;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withValues(alpha: 0.12),
        highlightColor: color.withValues(alpha: 0.06),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected ? color.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(icon, size: 20, color: c),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: c,
                  fontSize: 9,
                  letterSpacing: 0.7,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(label),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(top: 3),
                height: 2,
                width: selected ? 16 : 0,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.7),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
