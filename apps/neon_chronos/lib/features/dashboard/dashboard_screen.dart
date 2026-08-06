import 'package:flutter/material.dart';

import '../../core/clock_engine/clock_format.dart';
import '../../core/clock_engine/clock_ticker.dart';
import '../../core/storage/settings_controller.dart';
import '../../core/theme_engine/neon_theme.dart';
import '../../widgets/glass_panel.dart';
import '../alarm/alarm_controller.dart';
import '../feed/feed_controller.dart';
import '../viz/day_viz.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.ticker,
    required this.settings,
    required this.alarms,
    required this.feed,
    required this.onOpenTab,
  });

  final ClockTicker ticker;
  final SettingsController settings;
  final AlarmController alarms;
  final FeedController feed;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ticker, settings, alarms, feed]),
      builder: (context, _) {
        final s = settings.settings;
        final primary = s.accent.primary;
        final secondary = s.accent.secondary;
        final now = ticker.now;
        final next = alarms.nextFireTime(now);
        final nextAlarm = alarms.nextAlarm;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Row(
                children: [
                  Text(
                    'CHRONOS CONSOLE',
                    style: TextStyle(
                      color: primary,
                      fontSize: 13,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w700,
                      shadows: neonGlow(primary, blur: 10, spread: 0),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'SYSTEM NORMAL',
                    style: TextStyle(
                      color: NeonColors.ok,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GlassPanel(
                accent: primary,
                onTap: () => onOpenTab(1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel('Time Core', color: secondary),
                    const SizedBox(height: 6),
                    Text(
                      ClockFormat.timeHm(now, hour24: s.hour24),
                      style: TextStyle(
                        color: primary,
                        fontSize: 42,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 3,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        shadows: neonGlow(primary, blur: 16),
                      ),
                    ),
                    Text(
                      '${ClockFormat.weekday(now).toUpperCase()}  ·  ${ClockFormat.dateLine(now)}',
                      style: TextStyle(
                        color: NeonColors.textSecondary,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GlassPanel(
                      accent: secondary,
                      onTap: () => onOpenTab(3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionLabel('Next Alarm', color: secondary),
                          const SizedBox(height: 6),
                          Text(
                            next != null
                                ? ClockFormat.timeHm(next, hour24: s.hour24)
                                : '--:--',
                            style: TextStyle(
                              color: secondary,
                              fontSize: 26,
                              fontWeight: FontWeight.w300,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            nextAlarm?.label ?? 'None armed',
                            style: TextStyle(
                              color: NeonColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassPanel(
                      accent: NeonColors.ok,
                      onTap: () => onOpenTab(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionLabel('Tools', color: NeonColors.ok),
                          const SizedBox(height: 6),
                          Text(
                            'TIMER',
                            style: TextStyle(
                              color: NeonColors.ok,
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 2,
                            ),
                          ),
                          const Text(
                            'Stopwatch suite',
                            style: TextStyle(
                              color: NeonColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GlassPanel(
                accent: primary,
                child: DayProgressRing(
                  now: now,
                  primary: primary,
                  secondary: secondary,
                ),
              ),
              const SizedBox(height: 10),
              GlassPanel(
                accent: secondary,
                child: SolarCycleBar(
                  now: now,
                  primary: primary,
                  secondary: secondary,
                ),
              ),
              const SizedBox(height: 10),
              GlassPanel(
                accent: primary,
                onTap: () => onOpenTab(2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel('World Network', color: secondary),
                    const SizedBox(height: 4),
                    Text(
                      'Open world clocks →',
                      style: TextStyle(color: primary, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GlassPanel(
                accent: secondary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel('Chronos Feed', color: secondary),
                    const SizedBox(height: 8),
                    ...feed.events.take(5).map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Text(
                                  e.timeLabel,
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 13,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    e.title,
                                    style: const TextStyle(
                                      color: NeonColors.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (feed.events.isEmpty)
                      const Text(
                        'No local events',
                        style: TextStyle(color: NeonColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
