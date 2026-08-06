import 'package:flutter/material.dart';

import '../../core/clock_engine/clock_format.dart';
import '../../core/clock_engine/clock_ticker.dart';
import '../../core/sound/sound_service.dart';
import '../../core/storage/settings_controller.dart';
import '../../core/theme_engine/neon_theme.dart';
import '../../widgets/glass_panel.dart';
import '../statistics/stats_controller.dart';
import 'focus_controller.dart';

class FocusStatsScreen extends StatelessWidget {
  const FocusStatsScreen({
    super.key,
    required this.ticker,
    required this.settings,
    required this.focus,
    required this.stats,
    required this.sound,
  });

  final ClockTicker ticker;
  final SettingsController settings;
  final FocusController focus;
  final StatsController stats;
  final SoundService sound;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ticker, settings, focus, stats]),
      builder: (context, _) {
        final s = settings.settings;
        final primary = s.accent.primary;
        final secondary = s.accent.secondary;
        final now = ticker.now;
        final active = focus.isActive;

        // Auto-complete pomodoro when remaining hits 0
        if (active && focus.remaining(now).inSeconds == 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            focus.stop(completed: true);
            sound.timerDone();
          });
        }

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Text(
                'FOCUS / TIME MAP',
                style: TextStyle(
                  color: primary,
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              GlassPanel(
                accent: active ? NeonColors.ok : primary,
                child: Column(
                  children: [
                    SectionLabel('Focus Session', color: secondary),
                    const SizedBox(height: 8),
                    Text(
                      active
                          ? ClockFormat.countdown(focus.remaining(now))
                          : ClockFormat.countdown(
                              Duration(minutes: focus.workMinutes),
                            ),
                      style: TextStyle(
                        color: active ? NeonColors.ok : primary,
                        fontSize: 48,
                        fontWeight: FontWeight.w200,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        shadows: neonGlow(primary, blur: 14),
                      ),
                    ),
                    Text(
                      active
                          ? 'TARGET: ${focus.active!.target.toUpperCase()}'
                          : 'TARGET: ${focus.target.toUpperCase()}',
                      style: TextStyle(
                        color: NeonColors.textSecondary,
                        letterSpacing: 1.5,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      active ? 'STATUS: ACTIVE' : 'STATUS: STANDBY',
                      style: TextStyle(
                        color: active ? NeonColors.ok : secondary,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: active ? focus.progress(now) : 0,
                      minHeight: 6,
                      backgroundColor: primary.withValues(alpha: 0.12),
                      color: active ? NeonColors.ok : primary,
                    ),
                    const SizedBox(height: 14),
                    if (!active) ...[
                      Wrap(
                        spacing: 8,
                        children: [15, 25, 45, 60].map((m) {
                          return ActionChip(
                            label: Text('${m}m'),
                            onPressed: () {
                              focus.setWorkMinutes(m);
                              sound.click();
                            },
                            labelStyle: TextStyle(color: primary),
                            backgroundColor: primary.withValues(alpha: 0.1),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              if (active) {
                                await focus.stop(completed: false);
                              } else {
                                await focus.start();
                              }
                              await sound.click();
                            },
                            child: Text(active ? 'STOP' : 'START POMODORO'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassPanel(
                accent: secondary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel('Your Time Map (manual)', color: secondary),
                    const SizedBox(height: 8),
                    ...stats.stats.bars.entries.map((e) {
                      final max = stats.stats.total <= 0 ? 1.0 : stats.stats.total;
                      final frac = (e.value / max).clamp(0.0, 1.0);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  e.key,
                                  style: const TextStyle(
                                    color: NeonColors.textPrimary,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${e.value.toStringAsFixed(0)}h',
                                  style: TextStyle(color: primary, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: frac,
                                minHeight: 8,
                                backgroundColor: primary.withValues(alpha: 0.1),
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    TextButton(
                      onPressed: () => _editStats(context, primary),
                      child: Text('EDIT HOURS', style: TextStyle(color: primary)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassPanel(
                accent: primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel('Focus History', color: secondary),
                    Text(
                      'Today: ${focus.totalFocusMinutesToday()} min',
                      style: TextStyle(color: primary, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    ...focus.history.take(6).map(
                          (h) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${h.target} · ${h.elapsed.inMinutes}m · '
                              '${h.completed ? "done" : "stop"}',
                              style: const TextStyle(
                                color: NeonColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
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

  Future<void> _editStats(BuildContext context, Color primary) async {
    final st = stats.stats;
    var sleep = st.sleep;
    var work = st.work;
    var focusH = st.focus;
    var free = st.free;
    var other = st.other;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return AlertDialog(
              backgroundColor: NeonColors.surface,
              title: Text('TIME MAP', style: TextStyle(color: primary, fontSize: 14)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _slider('Sleep', sleep, primary, (v) => setModal(() => sleep = v)),
                    _slider('Work', work, primary, (v) => setModal(() => work = v)),
                    _slider('Focus', focusH, primary, (v) => setModal(() => focusH = v)),
                    _slider('Free', free, primary, (v) => setModal(() => free = v)),
                    _slider('Other', other, primary, (v) => setModal(() => other = v)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    await stats.update(TimeStats(
                      sleep: sleep,
                      work: work,
                      focus: focusH,
                      free: free,
                      other: other,
                    ));
                    await sound.click();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _slider(
    String label,
    double value,
    Color primary,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label ${value.toStringAsFixed(0)}h',
            style: const TextStyle(color: NeonColors.textPrimary, fontSize: 12)),
        Slider(value: value, min: 0, max: 16, divisions: 16, onChanged: onChanged),
      ],
    );
  }
}
