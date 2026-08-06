import 'package:flutter/material.dart';

import '../../core/sound/sound_service.dart';
import '../../core/storage/settings_controller.dart';
import '../../core/theme_engine/neon_theme.dart';
import '../../widgets/glass_panel.dart';
import 'alarm_controller.dart';
import 'alarm_models.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({
    super.key,
    required this.settings,
    required this.alarms,
    required this.sound,
  });

  final SettingsController settings;
  final AlarmController alarms;
  final SoundService sound;

  Future<void> _edit(BuildContext context, [ChronosAlarm? existing]) async {
    await sound.click();
    var hour = existing?.hour ?? 7;
    var minute = existing?.minute ?? 0;
    var label = existing?.label ?? 'Wake Event';
    var mode = existing?.mode ?? AlarmMode.cyberPulse;
    var intensity = existing?.intensity ?? 0.7;
    var vibrate = existing?.vibrate ?? true;
    var weekdays = List<int>.of(existing?.weekdays ?? [1, 2, 3, 4, 5]);
    final labelCtrl = TextEditingController(text: label);
    final primary = settings.settings.accent.primary;

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NeonColors.surface,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom +
                    MediaQuery.paddingOf(ctx).bottom +
                    16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      existing == null ? 'NEW WAKE EVENT' : 'EDIT WAKE EVENT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primary,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _NumCol(
                          value: hour,
                          max: 23,
                          onChanged: (v) => setModal(() => hour = v),
                          color: primary,
                        ),
                        Text(
                          ':',
                          style: TextStyle(color: primary, fontSize: 36),
                        ),
                        _NumCol(
                          value: minute,
                          max: 59,
                          onChanged: (v) => setModal(() => minute = v),
                          color: primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: labelCtrl,
                      style: const TextStyle(color: NeonColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Label',
                        labelStyle: TextStyle(color: NeonColors.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: primary.withValues(alpha: 0.35),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SectionLabel('Mode', color: primary),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: AlarmMode.values.map((m) {
                        final on = mode == m;
                        return ChoiceChip(
                          label: Text(m.label),
                          selected: on,
                          onSelected: (_) => setModal(() => mode = m),
                          selectedColor: primary.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: on ? primary : NeonColors.textSecondary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    SectionLabel('Intensity', color: primary),
                    Slider(
                      value: intensity,
                      onChanged: (v) => setModal(() => intensity = v),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Vibration',
                        style: TextStyle(color: NeonColors.textPrimary),
                      ),
                      value: vibrate,
                      onChanged: (v) => setModal(() => vibrate = v),
                    ),
                    SectionLabel('Repeat', color: primary),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: List.generate(7, (i) {
                        final day = i + 1;
                        const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final on = weekdays.contains(day);
                        return FilterChip(
                          label: Text(labels[i]),
                          selected: on,
                          onSelected: (v) {
                            setModal(() {
                              if (v) {
                                weekdays = [...weekdays, day]..sort();
                              } else {
                                weekdays = weekdays.where((d) => d != day).toList();
                              }
                            });
                          },
                          selectedColor: primary.withValues(alpha: 0.3),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        final alarm = (existing ?? ChronosAlarm(hour: hour, minute: minute))
                            .copyWith(
                          hour: hour,
                          minute: minute,
                          label: labelCtrl.text.trim().isEmpty
                              ? 'Wake Event'
                              : labelCtrl.text.trim(),
                          mode: mode,
                          intensity: intensity,
                          vibrate: vibrate,
                          weekdays: weekdays.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : weekdays,
                        );
                        if (existing == null) {
                          await alarms.add(alarm);
                        } else {
                          await alarms.update(alarm);
                        }
                        await sound.click();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('SAVE'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    labelCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([settings, alarms]),
      builder: (context, _) {
        final primary = settings.settings.accent.primary;
        final secondary = settings.settings.accent.secondary;
        final list = alarms.alarms;
        final next = alarms.nextAlarm;

        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'WAKE EVENTS',
                      style: TextStyle(
                        color: primary,
                        fontSize: 13,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _edit(context),
                      icon: Icon(Icons.add_alarm, color: primary),
                    ),
                  ],
                ),
              ),
              if (next != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassPanel(
                    accent: secondary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionLabel('Next Wake Event', color: secondary),
                        Text(
                          next.timeLabel,
                          style: TextStyle(
                            color: secondary,
                            fontSize: 36,
                            fontWeight: FontWeight.w300,
                            shadows: neonGlow(secondary, blur: 12),
                          ),
                        ),
                        Text(
                          'MODE: ${next.mode.label.toUpperCase()}',
                          style: TextStyle(color: NeonColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        _IntensityBar(value: next.intensity, color: secondary),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final a = list[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassPanel(
                        accent: a.enabled ? primary : NeonColors.textSecondary,
                        onTap: () => _edit(context, a),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.timeLabel,
                                    style: TextStyle(
                                      color: a.enabled
                                          ? primary
                                          : NeonColors.textSecondary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w300,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                  Text(
                                    a.label,
                                    style: const TextStyle(
                                      color: NeonColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    a.mode.label,
                                    style: TextStyle(
                                      color: secondary.withValues(alpha: 0.8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: a.enabled,
                              onChanged: (_) async {
                                await alarms.toggle(a.id);
                                await sound.click();
                              },
                            ),
                            IconButton(
                              onPressed: () async {
                                await alarms.remove(a.id);
                                await sound.click();
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: NeonColors.danger,
                                size: 20,
                              ),
                            ),
                          ],
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
}

class _NumCol extends StatelessWidget {
  const _NumCol({
    required this.value,
    required this.max,
    required this.onChanged,
    required this.color,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: () => onChanged((value + 1) % (max + 1)),
          icon: Icon(Icons.keyboard_arrow_up, color: color),
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            color: color,
            fontSize: 36,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        IconButton(
          onPressed: () => onChanged((value - 1) < 0 ? max : value - 1),
          icon: Icon(Icons.keyboard_arrow_down, color: color),
        ),
      ],
    );
  }
}

class _IntensityBar extends StatelessWidget {
  const _IntensityBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const n = 8;
    final filled = (value * n).round().clamp(0, n);
    return Row(
      children: List.generate(n, (i) {
        final on = i < filled;
        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: i == n - 1 ? 0 : 3),
            decoration: BoxDecoration(
              color: on ? color.withValues(alpha: 0.4 + i / n * 0.6) : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
