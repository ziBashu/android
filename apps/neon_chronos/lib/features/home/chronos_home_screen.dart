import 'package:flutter/material.dart';

import '../../core/clock_engine/clock_format.dart';
import '../../core/clock_engine/clock_ticker.dart';
import '../../core/sound/sound_service.dart';
import '../../core/storage/settings_controller.dart';
import '../../core/theme_engine/neon_theme.dart';
import '../../widgets/glass_panel.dart';
import '../alarm/alarm_controller.dart';
import '../feed/feed_controller.dart';
import '../focus/focus_controller.dart';
import '../statistics/stats_controller.dart';
import '../viz/day_viz.dart';
import '../viz/time_journey.dart';
import 'home_layout_controller.dart';
import 'home_module.dart';

/// Customizable Temporal OS command center.
class ChronosHomeScreen extends StatelessWidget {
  const ChronosHomeScreen({
    super.key,
    required this.ticker,
    required this.settings,
    required this.alarms,
    required this.feed,
    required this.focus,
    required this.stats,
    required this.layout,
    required this.sound,
    required this.onOpenTab,
  });

  final ClockTicker ticker;
  final SettingsController settings;
  final AlarmController alarms;
  final FeedController feed;
  final FocusController focus;
  final StatsController stats;
  final HomeLayoutController layout;
  final SoundService sound;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ticker,
        settings,
        alarms,
        feed,
        focus,
        stats,
        layout,
      ]),
      builder: (context, _) {
        final s = settings.settings;
        final primary = s.accent.primary;
        final secondary = s.accent.secondary;
        final now = ticker.now;

        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 6),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEON CHRONOS',
                          style: TextStyle(
                            color: primary,
                            fontSize: 15,
                            letterSpacing: 3.2,
                            fontWeight: FontWeight.w800,
                            shadows: neonGlow(primary, blur: 14, spread: 0),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'TEMPORAL OS  ·  COMMAND CENTER',
                          style: TextStyle(
                            color: secondary.withValues(alpha: 0.75),
                            fontSize: 9,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Material(
                      color: primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      child: IconButton(
                        tooltip: 'Arrange modules',
                        onPressed: () => _editLayout(context, primary),
                        icon: Icon(
                          Icons.dashboard_customize_outlined,
                          color: primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 108),
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        final t = Curves.easeOut.transform(animation.value);
                        return Transform.scale(
                          scale: 1 + 0.03 * t,
                          child: Material(
                            color: Colors.transparent,
                            elevation: 8 * t,
                            shadowColor: primary.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(14),
                            child: child,
                          ),
                        );
                      },
                      child: child,
                    );
                  },
                  itemCount: layout.modules.length,
                  onReorder: (a, b) async {
                    await layout.reorder(a, b);
                    await sound.click();
                  },
                  itemBuilder: (context, i) {
                    final m = layout.modules[i];
                    return Padding(
                      key: ValueKey(m.name),
                      padding: const EdgeInsets.only(bottom: 11),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 280 + i * 40),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, child) {
                          return Opacity(
                            opacity: t,
                            child: Transform.translate(
                              offset: Offset(0, 12 * (1 - t)),
                              child: child,
                            ),
                          );
                        },
                        child: _moduleCard(
                          m,
                          now: now,
                          primary: primary,
                          secondary: secondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _moduleCard(
    HomeModule m, {
    required DateTime now,
    required Color primary,
    required Color secondary,
  }) {
    switch (m) {
      case HomeModule.timeCore:
        return GlassPanel(
          accent: primary,
          onTap: () => onOpenTab(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel('Time Core', color: secondary),
              Text(
                ClockFormat.timeHms(now, hour24: settings.settings.hour24),
                style: TextStyle(
                  color: primary,
                  fontSize: 40,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  shadows: neonGlow(primary, blur: 16),
                ),
              ),
              Text(
                '${ClockFormat.weekday(now).toUpperCase()}  ·  ${ClockFormat.dateLine(now)}',
                style: const TextStyle(
                  color: NeonColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      case HomeModule.energy:
        return GlassPanel(
          accent: NeonColors.ok,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel('Energy', color: NeonColors.ok),
                    const Text(
                      'NORMAL',
                      style: TextStyle(
                        color: NeonColors.ok,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'DAY ${(ClockFormat.dayProgress(now) * 100).round()}% COMPLETE',
                style: TextStyle(
                  color: primary,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      case HomeModule.dayProgress:
        return GlassPanel(
          accent: primary,
          child: DayProgressRing(
            now: now,
            primary: primary,
            secondary: secondary,
          ),
        );
      case HomeModule.nextAlarm:
        final next = alarms.nextFireTime(now);
        final label = alarms.nextAlarm?.label ?? 'None armed';
        return GlassPanel(
          accent: secondary,
          onTap: () => onOpenTab(3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel('Next Alarm', color: secondary),
              Text(
                next == null
                    ? '--:--'
                    : ClockFormat.timeHm(next, hour24: settings.settings.hour24),
                style: TextStyle(
                  color: secondary,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Text(label,
                  style: const TextStyle(
                      color: NeonColors.textSecondary, fontSize: 12)),
            ],
          ),
        );
      case HomeModule.focusStatus:
        final active = focus.isActive;
        return GlassPanel(
          accent: active ? NeonColors.ok : primary,
          onTap: () => onOpenTab(5), // MORE hub → Focus
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel('Focus', color: secondary),
              Text(
                active ? 'ACTIVE' : 'IDLE',
                style: TextStyle(
                  color: active ? NeonColors.ok : primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              Text(
                active
                    ? '${focus.active!.target} · ${ClockFormat.countdown(focus.remaining(now))}'
                    : 'Tap to start session',
                style: const TextStyle(
                    color: NeonColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        );
      case HomeModule.chronosFeed:
        return GlassPanel(
          accent: primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel('Events', color: secondary),
              ...feed.events.take(3).map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${e.timeLabel}  ${e.title}',
                        style: const TextStyle(
                          color: NeonColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      case HomeModule.worldPeek:
        return GlassPanel(
          accent: secondary,
          onTap: () => onOpenTab(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel('World', color: secondary),
              Text(
                'Open world network →',
                style: TextStyle(color: primary, fontSize: 14),
              ),
            ],
          ),
        );
      case HomeModule.timeJourney:
        return GlassPanel(
          accent: primary,
          onTap: () => onOpenTab(5), // MORE hub → Journey
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel('Journey', color: secondary),
              const SizedBox(height: 6),
              TimeJourneyBar(now: now, primary: primary, secondary: secondary),
            ],
          ),
        );
      case HomeModule.statsPeek:
        final st = stats.stats;
        return GlassPanel(
          accent: secondary,
          onTap: () => onOpenTab(5), // MORE hub → Focus/stats
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel('Time Map', color: secondary),
              Text(
                'Work ${st.work.toStringAsFixed(0)}h · Focus ${st.focus.toStringAsFixed(0)}h · Sleep ${st.sleep.toStringAsFixed(0)}h',
                style: TextStyle(color: primary, fontSize: 13),
              ),
            ],
          ),
        );
    }
  }

  Future<void> _editLayout(BuildContext context, Color primary) async {
    await sound.click();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: NeonColors.surface,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: layout,
          builder: (ctx, _) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.paddingOf(ctx).bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HOME MODULES',
                    style: TextStyle(
                      color: primary,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...HomeModule.values.map((m) {
                    final on = layout.modules.contains(m);
                    return SwitchListTile(
                      title: Text(
                        m.title,
                        style: const TextStyle(color: NeonColors.textPrimary),
                      ),
                      value: on,
                      onChanged: (_) => layout.toggle(m),
                    );
                  }),
                  TextButton(
                    onPressed: () => layout.reset(),
                    child: const Text('Reset layout'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
