import 'package:flutter/material.dart';

import '../../core/clock_engine/clock_format.dart';
import '../../core/theme_engine/neon_theme.dart';

/// Day as a landscape: sunrise → peak → sunset → night.
class TimeJourneyBar extends StatelessWidget {
  const TimeJourneyBar({
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
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final x = (p * w).clamp(10.0, w - 10);
            // Sky gradient strip
            return SizedBox(
              height: 48,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0A1630),
                          const Color(0xFFFF8A4C).withValues(alpha: 0.55),
                          const Color(0xFF4FC3F7).withValues(alpha: 0.7),
                          const Color(0xFFFFB74D).withValues(alpha: 0.6),
                          const Color(0xFF1A0A2E),
                        ],
                        stops: const [0, 0.22, 0.5, 0.78, 1],
                      ),
                    ),
                  ),
                  // Sun/moon marker
                  Positioned(
                    left: x - 8,
                    top: 14,
                    child: Icon(
                      p > 0.22 && p < 0.78
                          ? Icons.wb_sunny
                          : Icons.nightlight_round,
                      size: 18,
                      color: p > 0.22 && p < 0.78
                          ? NeonColors.warn
                          : secondary,
                      shadows: [
                        Shadow(
                          color: primary.withValues(alpha: 0.8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _mark('00', secondary),
            _mark('06', primary),
            _mark('12', primary),
            _mark('18', primary),
            _mark('24', secondary),
          ],
        ),
        Text(
          _phaseLabel(p),
          style: TextStyle(
            color: NeonColors.textSecondary,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _mark(String t, Color c) => Text(
        t,
        style: TextStyle(color: c.withValues(alpha: 0.75), fontSize: 10),
      );

  String _phaseLabel(double p) {
    if (p < 0.22) return 'NIGHT → SUNRISE';
    if (p < 0.5) return 'MORNING → PEAK';
    if (p < 0.78) return 'AFTERNOON → SUNSET';
    return 'EVENING → NIGHT';
  }
}

class TimeJourneyScreen extends StatelessWidget {
  const TimeJourneyScreen({
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
    final milestones = [
      (0.0, '00:00', 'Midnight'),
      (0.25, '06:00', 'Sunrise'),
      (0.5, '12:00', 'Peak'),
      (0.75, '18:00', 'Sunset'),
      (1.0, '24:00', 'Cycle end'),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Text(
            'TIME JOURNEY',
            style: TextStyle(
              color: primary,
              fontSize: 13,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
              shadows: neonGlow(primary, blur: 10, spread: 0),
            ),
          ),
          const SizedBox(height: 16),
          TimeJourneyBar(now: now, primary: primary, secondary: secondary),
          const SizedBox(height: 24),
          ...milestones.map((m) {
            final reached = p >= m.$1 - 0.001;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reached ? primary : NeonColors.textSecondary.withValues(alpha: 0.3),
                      boxShadow: reached
                          ? [BoxShadow(color: primary.withValues(alpha: 0.6), blurRadius: 8)]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    m.$2,
                    style: TextStyle(
                      color: primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '─ ${m.$3}',
                    style: TextStyle(
                      color: reached
                          ? NeonColors.textPrimary
                          : NeonColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Text(
            'Day ${(p * 100).round()}% complete · ${ClockFormat.timeHms(now, hour24: true)}',
            style: TextStyle(color: secondary, fontSize: 12, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}
