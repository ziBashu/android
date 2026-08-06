import 'package:flutter/material.dart';

import '../../core/clock_engine/clock_format.dart';
import '../../core/theme_engine/neon_theme.dart';

class DayProgressRing extends StatelessWidget {
  const DayProgressRing({
    super.key,
    required this.now,
    required this.primary,
    required this.secondary,
  });

  final DateTime now;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final p = ClockFormat.dayProgress(now);
    final pct = (p * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DAY COMPLETION',
          style: TextStyle(
            color: secondary.withValues(alpha: 0.85),
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: p,
            minHeight: 8,
            backgroundColor: primary.withValues(alpha: 0.12),
            color: primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$pct%',
          style: TextStyle(
            color: primary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
            shadows: neonGlow(primary, blur: 8, spread: 0),
          ),
        ),
      ],
    );
  }
}

class SolarCycleBar extends StatelessWidget {
  const SolarCycleBar({
    super.key,
    required this.now,
    required this.primary,
    required this.secondary,
  });

  final DateTime now;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final p = ClockFormat.dayProgress(now);
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.wb_sunny_outlined, size: 14, color: NeonColors.warn),
            const Spacer(),
            Text(
              'SOLAR CYCLE',
              style: TextStyle(
                color: NeonColors.textSecondary,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Icon(Icons.nightlight_outlined, size: 14, color: secondary),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, c) {
            final x = (p * c.maxWidth).clamp(8.0, c.maxWidth - 8);
            return SizedBox(
              height: 20,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 2,
                    width: c.maxWidth,
                    color: primary.withValues(alpha: 0.2),
                  ),
                  Positioned(
                    left: x - 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.7),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          p < 0.25
              ? 'NIGHT → DAWN'
              : p < 0.5
                  ? 'MORNING'
                  : p < 0.75
                      ? 'AFTERNOON'
                      : 'EVENING → NIGHT',
          style: TextStyle(
            color: NeonColors.textSecondary,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
