import 'package:flutter/material.dart';

import '../../core/sound/sound_service.dart';
import '../../core/storage/settings_controller.dart';
import '../../core/theme_engine/accent.dart';
import '../../core/theme_engine/neon_theme.dart';
import '../../widgets/glass_panel.dart';
import '../feed/feed_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.sound,
    required this.feed,
  });

  final SettingsController settings;
  final SoundService sound;
  final FeedController feed;

  Future<void> _addFeed(BuildContext context) async {
    final primary = settings.settings.accent.primary;
    var hour = 9;
    var minute = 0;
    final title = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: NeonColors.surface,
          title: Text('ADD FEED EVENT', style: TextStyle(color: primary, fontSize: 14)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                style: const TextStyle(color: NeonColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: NeonColors.textSecondary),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: NeonColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Hour'),
                      onChanged: (v) => hour = int.tryParse(v) ?? hour,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: NeonColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Min'),
                      onChanged: (v) => minute = int.tryParse(v) ?? minute,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (title.text.trim().isEmpty) return;
                await feed.add(FeedEvent(
                  hour: hour.clamp(0, 23),
                  minute: minute.clamp(0, 59),
                  title: title.text.trim(),
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
    title.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([settings, feed]),
      builder: (context, _) {
        final s = settings.settings;
        final primary = s.accent.primary;
        final secondary = s.accent.secondary;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Text(
                'NEON CHRONOS SETTINGS',
                style: TextStyle(
                  color: primary,
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  shadows: neonGlow(primary, blur: 10, spread: 0),
                ),
              ),
              const SizedBox(height: 16),
              GlassPanel(
                accent: primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel('Clock Mode', color: secondary),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ClockMode.values.map((m) {
                        final on = s.mode == m;
                        return ChoiceChip(
                          label: Text(m.shortLabel),
                          selected: on,
                          onSelected: (_) {
                            sound.click();
                            settings.setMode(m);
                          },
                          selectedColor: primary.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: on ? primary : NeonColors.textSecondary,
                          ),
                        );
                      }).toList(),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('24 Hour', style: TextStyle(color: NeonColors.textPrimary)),
                      value: s.hour24,
                      onChanged: (v) {
                        sound.click();
                        settings.setHour24(v);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Animation', style: TextStyle(color: NeonColors.textPrimary)),
                      value: s.animation,
                      onChanged: (v) {
                        sound.click();
                        settings.setAnimation(v);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sound', style: TextStyle(color: NeonColors.textPrimary)),
                      value: s.sound,
                      onChanged: (v) {
                        settings.setSound(v);
                        sound.syncFrom(settings.settings);
                        if (v) sound.click();
                      },
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
                    SectionLabel('Theme', color: secondary),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: NeonAccent.values.map((a) {
                        final on = s.accent == a;
                        return ChoiceChip(
                          label: Text(a.shortLabel),
                          selected: on,
                          onSelected: (_) {
                            sound.click();
                            settings.setAccent(a);
                          },
                          selectedColor: a.primary.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: on ? a.primary : NeonColors.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    SectionLabel('Background', color: secondary),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: BackgroundMode.values.map((b) {
                        final on = s.background == b;
                        return ChoiceChip(
                          label: Text(b.label),
                          selected: on,
                          onSelected: (_) {
                            sound.click();
                            settings.setBackground(b);
                          },
                          selectedColor: primary.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: on ? primary : NeonColors.textSecondary,
                          ),
                        );
                      }).toList(),
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
                    SectionLabel('Visual Effects', color: secondary),
                    Text('Glow ${(s.glow * 100).round()}%',
                        style: TextStyle(color: NeonColors.textSecondary, fontSize: 12)),
                    Slider(
                      value: s.glow,
                      onChanged: settings.setGlow,
                      onChangeEnd: (_) => sound.click(),
                    ),
                    Text('Particles ${(s.particleAmount * 100).round()}%',
                        style: TextStyle(color: NeonColors.textSecondary, fontSize: 12)),
                    Slider(
                      value: s.particleAmount,
                      onChanged: settings.setParticleAmount,
                      onChangeEnd: (_) => sound.click(),
                    ),
                    Text('Grid speed ${(s.gridSpeed * 100).round()}%',
                        style: TextStyle(color: NeonColors.textSecondary, fontSize: 12)),
                    Slider(
                      value: s.gridSpeed,
                      onChanged: settings.setGridSpeed,
                      onChangeEnd: (_) => sound.click(),
                    ),
                    Text('Animation level ${(s.animationLevel * 100).round()}%',
                        style: TextStyle(color: NeonColors.textSecondary, fontSize: 12)),
                    Slider(
                      value: s.animationLevel,
                      onChanged: settings.setAnimationLevel,
                      onChangeEnd: (_) => sound.click(),
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
                    Row(
                      children: [
                        SectionLabel('Chronos Feed (local)', color: secondary),
                        const Spacer(),
                        IconButton(
                          onPressed: () => _addFeed(context),
                          icon: Icon(Icons.add, color: primary, size: 20),
                        ),
                      ],
                    ),
                    ...feed.events.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${e.timeLabel}  ${e.title}',
                                style: const TextStyle(
                                  color: NeonColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 16,
                                color: NeonColors.danger,
                              ),
                              onPressed: () async {
                                await feed.remove(e.id);
                                await sound.click();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'v2.0  ·  SMART CHRONOS DEVICE  ·  from ziBashu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondary.withValues(alpha: 0.55),
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
