import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/clock_engine/clock_ticker.dart';
import '../../core/engine/clock_face_config.dart';
import '../../core/sound/sound_service.dart';
import '../../core/storage/settings_controller.dart';
import '../../core/theme_engine/neon_theme.dart';
import '../../widgets/glass_panel.dart';
import 'advanced_faces.dart';
import 'face_config_controller.dart';

class ClockBuilderScreen extends StatefulWidget {
  const ClockBuilderScreen({
    super.key,
    required this.ticker,
    required this.settings,
    required this.faces,
    required this.sound,
  });

  final ClockTicker ticker;
  final SettingsController settings;
  final FaceConfigController faces;
  final SoundService sound;

  @override
  State<ClockBuilderScreen> createState() => _ClockBuilderScreenState();
}

class _ClockBuilderScreenState extends State<ClockBuilderScreen> {
  final _name = TextEditingController();
  final _import = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.text = widget.faces.config.name;
  }

  @override
  void dispose() {
    _name.dispose();
    _import.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.ticker,
        widget.settings,
        widget.faces,
      ]),
      builder: (context, _) {
        final s = widget.settings.settings;
        final f = widget.faces.config;
        final primary = s.accent.primary;
        final secondary = s.accent.secondary;

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Text(
                'CLOCK BUILDER',
                style: TextStyle(
                  color: primary,
                  fontSize: 13,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                  shadows: neonGlow(primary, blur: 10, spread: 0),
                ),
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 1,
                child: GlassPanel(
                  accent: primary,
                  padding: const EdgeInsets.all(8),
                  child: AdvancedClockFace(
                    now: widget.ticker.now,
                    settings: s,
                    face: f,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GlassPanel(
                accent: secondary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel('Face Type', color: secondary),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: FaceKind.values.map((k) {
                        final on = f.kind == k;
                        return ChoiceChip(
                          label: Text(k.label),
                          selected: on,
                          onSelected: (_) {
                            widget.sound.click();
                            widget.faces.update(f.copyWith(kind: k));
                          },
                          selectedColor: primary.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: on ? primary : NeonColors.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    SectionLabel('Shape', color: secondary),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: FaceShape.values.map((sh) {
                        final on = f.shape == sh;
                        return ChoiceChip(
                          label: Text(sh.label),
                          selected: on,
                          onSelected: (_) {
                            widget.sound.click();
                            widget.faces.update(f.copyWith(shape: sh));
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
                      title: const Text(
                        'Numbers',
                        style: TextStyle(color: NeonColors.textPrimary),
                      ),
                      value: f.showNumbers,
                      onChanged: (v) {
                        widget.sound.click();
                        widget.faces.update(f.copyWith(showNumbers: v));
                      },
                    ),
                    Text(
                      'Glow ${(f.glow * 100).round()}%',
                      style: const TextStyle(
                        color: NeonColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Slider(
                      value: f.glow,
                      onChanged: (v) =>
                          widget.faces.update(f.copyWith(glow: v)),
                    ),
                    Text(
                      'Particles ${(f.particles * 100).round()}%',
                      style: const TextStyle(
                        color: NeonColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Slider(
                      value: f.particles,
                      onChanged: (v) =>
                          widget.faces.update(f.copyWith(particles: v)),
                    ),
                    Text(
                      'Animation  Slow ←→ Fast',
                      style: const TextStyle(
                        color: NeonColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Slider(
                      value: f.animSpeed,
                      onChanged: (v) =>
                          widget.faces.update(f.copyWith(animSpeed: v)),
                    ),
                    TextField(
                      controller: _name,
                      style: const TextStyle(color: NeonColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Face name',
                        labelStyle:
                            const TextStyle(color: NeonColors.textSecondary),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: primary.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      onSubmitted: (v) {
                        widget.faces.update(f.copyWith(name: v.trim()));
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              await widget.faces.update(
                                f.copyWith(name: _name.text.trim().isEmpty
                                    ? f.name
                                    : _name.text.trim()),
                              );
                              await widget.faces.saveCurrent();
                              await widget.sound.click();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Face saved to library'),
                                  ),
                                );
                              }
                            },
                            child: const Text('SAVE FACE'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final code = widget.faces.config.exportCode();
                              await Clipboard.setData(ClipboardData(text: code));
                              await widget.sound.click();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Copied: $code')),
                                );
                              }
                            },
                            child: const Text('SHARE CODE'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _import,
                      style: const TextStyle(
                        color: NeonColors.textPrimary,
                        fontSize: 12,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Import NC3:… code',
                        labelStyle:
                            const TextStyle(color: NeonColors.textSecondary),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.download, color: primary),
                          onPressed: () async {
                            final ok = await widget.faces
                                .importShareCode(_import.text);
                            await widget.sound.click();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok ? 'Theme imported' : 'Invalid code',
                                  ),
                                ),
                              );
                            }
                            if (ok) _name.text = widget.faces.config.name;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.faces.saved.isNotEmpty) ...[
                const SizedBox(height: 12),
                SectionLabel('Saved library', color: secondary),
                const SizedBox(height: 8),
                ...widget.faces.saved.map(
                  (saved) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GlassPanel(
                      accent: primary,
                      onTap: () async {
                        await widget.faces.applySaved(saved);
                        _name.text = saved.name;
                        await widget.sound.click();
                      },
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        '${saved.name}  ·  ${saved.kind.label}',
                        style: TextStyle(color: primary, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
