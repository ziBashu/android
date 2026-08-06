import 'package:flutter/material.dart';

import '../../core/clock_engine/clock_format.dart';
import '../../core/clock_engine/clock_ticker.dart';
import '../../core/sound/sound_service.dart';
import '../../core/storage/settings_controller.dart';
import '../../core/theme_engine/neon_theme.dart';
import '../../widgets/glass_panel.dart';
import 'timer_controllers.dart';

class TimerSuiteScreen extends StatefulWidget {
  const TimerSuiteScreen({
    super.key,
    required this.ticker,
    required this.settings,
    required this.sound,
    required this.countdown,
    required this.stopwatch,
  });

  final ClockTicker ticker;
  final SettingsController settings;
  final SoundService sound;
  final CountdownController countdown;
  final ChronosStopwatch stopwatch;

  @override
  State<TimerSuiteScreen> createState() => _TimerSuiteScreenState();
}

class _TimerSuiteScreenState extends State<TimerSuiteScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      final onTools = _tabs.index == 1 || widget.countdown.running || widget.stopwatch.running;
      widget.ticker.enableHiRes(
        widget.countdown.running || widget.stopwatch.running || _tabs.index == 1,
      );
      // keep hi-res if either tool running
      if (widget.countdown.running || widget.stopwatch.running) {
        widget.ticker.enableHiRes(true);
      }
      if (!onTools && !widget.countdown.running && !widget.stopwatch.running) {
        widget.ticker.enableHiRes(false);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.settings.settings.accent.primary;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'TIME TOOLS',
                style: TextStyle(
                  color: primary,
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          TabBar(
            controller: _tabs,
            labelColor: primary,
            unselectedLabelColor: NeonColors.textSecondary,
            indicatorColor: primary,
            tabs: const [
              Tab(text: 'TIMER'),
              Tab(text: 'STOPWATCH'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _TimerTab(
                  ticker: widget.ticker,
                  settings: widget.settings,
                  countdown: widget.countdown,
                ),
                _StopwatchTab(
                  ticker: widget.ticker,
                  settings: widget.settings,
                  stopwatch: widget.stopwatch,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerTab extends StatelessWidget {
  const _TimerTab({
    required this.ticker,
    required this.settings,
    required this.countdown,
  });

  final ClockTicker ticker;
  final SettingsController settings;
  final CountdownController countdown;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ticker, settings, countdown]),
      builder: (context, _) {
        // drive countdown off ticker
        countdown.tick(ticker.now);
        if (countdown.running) ticker.enableHiRes(true);

        final primary = settings.settings.accent.primary;
        final secondary = settings.settings.accent.secondary;
        final rem = countdown.remaining;
        final blocks = 10;
        final filled = (countdown.progress * blocks).round().clamp(0, blocks);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            GlassPanel(
              accent: countdown.finished ? NeonColors.ok : primary,
              child: Column(
                children: [
                  SectionLabel('Countdown', color: secondary),
                  const SizedBox(height: 8),
                  Text(
                    ClockFormat.countdown(rem),
                    style: TextStyle(
                      color: countdown.finished ? NeonColors.ok : primary,
                      fontSize: 56,
                      fontWeight: FontWeight.w200,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      shadows: neonGlow(primary, blur: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(blocks, (i) {
                      final on = i < filled;
                      return Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: on
                              ? primary
                              : primary.withValues(alpha: 0.15),
                          boxShadow: on
                              ? [
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  if (countdown.finished)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'TIMER COMPLETE',
                        style: TextStyle(
                          color: NeonColors.ok,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionLabel('Presets', color: secondary),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [1, 3, 5, 10, 15, 25, 45, 60].map((m) {
                return ActionChip(
                  label: Text('${m}m'),
                  onPressed: () {
                    countdown.setMinutes(m);
                    ticker.enableHiRes(false);
                  },
                  backgroundColor: primary.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: primary),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: countdown.running
                        ? countdown.pause
                        : () {
                            ticker.enableHiRes(true);
                            countdown.start();
                          },
                    child: Text(countdown.running ? 'PAUSE' : 'START'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      countdown.reset();
                      if (!countdown.running) ticker.enableHiRes(false);
                    },
                    child: const Text('RESET'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StopwatchTab extends StatelessWidget {
  const _StopwatchTab({
    required this.ticker,
    required this.settings,
    required this.stopwatch,
  });

  final ClockTicker ticker;
  final SettingsController settings;
  final ChronosStopwatch stopwatch;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ticker, settings, stopwatch]),
      builder: (context, _) {
        if (stopwatch.running) ticker.enableHiRes(true);
        final primary = settings.settings.accent.primary;
        final secondary = settings.settings.accent.secondary;
        final e = stopwatch.elapsed(ticker.now);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            GlassPanel(
              accent: primary,
              child: Column(
                children: [
                  SectionLabel('Stopwatch', color: secondary),
                  const SizedBox(height: 8),
                  Text(
                    ClockFormat.timeHmsMs(ticker.now, e),
                    style: TextStyle(
                      color: primary,
                      fontSize: 42,
                      fontWeight: FontWeight.w200,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      shadows: neonGlow(primary, blur: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (stopwatch.running) {
                        stopwatch.stop(ticker.now);
                      } else {
                        ticker.enableHiRes(true);
                        stopwatch.start(ticker.now);
                      }
                    },
                    child: Text(stopwatch.running ? 'STOP' : 'START'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: stopwatch.running
                        ? () => stopwatch.lap(ticker.now)
                        : null,
                    child: const Text('LAP'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      stopwatch.reset();
                      ticker.enableHiRes(false);
                    },
                    child: const Text('RESET'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...stopwatch.laps.asMap().entries.map((e) {
              final i = stopwatch.laps.length - e.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GlassPanel(
                  accent: secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Text(
                        'LAP $i',
                        style: TextStyle(color: secondary, fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        ClockFormat.timeHmsMs(ticker.now, e.value),
                        style: TextStyle(
                          color: primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
