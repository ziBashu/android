import 'package:flutter/material.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../core/morph_palette.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/morph_background.dart';

/// Product philosophy — the twelve questions MorphOS must answer.
class VisionScreen extends StatelessWidget {
  const VisionScreen({super.key, required this.controller});

  final MorphController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final p = c.palette;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MorphBackground(
        wallpaperId: c.wallpaperId,
        palette: p,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('What MorphOS is'),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: FromZiBashuBadge(compact: true, openWebsite: false),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              GlassPanel(
                palette: p,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal adaptive environment',
                      style: TextStyle(
                        color: p.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'MorphOS sits between you and the phone. '
                      'It does not compete by replacing Android immediately — '
                      'it changes how you experience Android.',
                      style: TextStyle(color: p.muted, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Android gives users apps.\nMorphOS gives users environments.',
                      style: TextStyle(
                        color: p.accentSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _q(
                p,
                '1 · Identity',
                'Launcher, OS, or personal environment?',
                'A personal adaptive environment layer — not a skin race, not a full ROM yet.',
              ),
              _q(
                p,
                '2 · Personalization',
                'What proves “this is my phone”?',
                'Wallpaper · icon styles · rename apps · home redesign · themes · morph packs. '
                'Sounds & custom animation engines are next.',
              ),
              _q(
                p,
                '3 · Shape',
                'Is a phone always a phone?',
                'No. Pocket, gaming console, mini computer, book reader, dashboard, '
                'plus Work / Relax / Study / Travel spaces.',
              ),
              _shapeChips(c, p),
              _q(
                p,
                '4 · Orientation',
                'Why did the user rotate?',
                'Morph Engine maps profile → orientation (and system-wide with Accessibility). '
                'Ask mode can propose: “Switch to desktop?”',
              ),
              _q(
                p,
                '5 · Environments',
                'Does one home fit every moment?',
                'Each morph is a full environment: layout, dock, apps, quiet mode, wallpaper.',
              ),
              _q(
                p,
                '6 · Intelligence',
                'Should users configure everything?',
                'Beginner auto · Ask first · Advanced IF/THEN rules.',
              ),
              _intelligencePicker(c, p),
              _q(
                p,
                '7 · Interaction',
                'Besides tapping icons?',
                'Control Center, Morph Hub, QS tile, gestures (cycle morph). '
                'Voice / edge / motion are roadmap.',
              ),
              _q(
                p,
                '8 · Visual world',
                'Android clone or something new?',
                'Grid + spatial + cards + desktop shell today. '
                'Object-based activities (“Play music”) are next.',
              ),
              _q(
                p,
                '9 · Creation',
                'Customization or creation?',
                'Morph Creator + Store + morphpack share — build My Night / Car / Gaming modes.',
              ),
              _q(
                p,
                '10 · Hardware',
                'Software only?',
                'Orientation, chrome immersion, keep-awake desktop, boot restore. '
                'Refresh rate / audio profile / foldables later.',
              ),
              _q(
                p,
                '11 · Social',
                'Why share a Morph?',
                'A Morph is not a theme — it changes how the phone behaves '
                '(layout, apps, rules, orientation).',
              ),
              _q(
                p,
                '12 · Ultimate',
                'If Android disappeared, what remains?',
                '“MorphOS knows how I use my device and transforms itself into the tool I need.”',
              ),
              const SizedBox(height: 8),
              GlassPanel(
                palette: p,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Five fundamentals',
                      style: TextStyle(
                        color: p.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _fund(p, 'How does my phone look?', 'Customization'),
                    _fund(p, 'How does my phone behave?', 'Modes / Morphs'),
                    _fund(p, 'How does it change shape?', 'Orientation engine'),
                    _fund(p, 'How does it adapt?', 'Context system'),
                    _fund(p, 'How do I create my own?', 'Morph Creator'),
                    const SizedBox(height: 12),
                    Text(
                      'Active now: ${c.profileId.label} · ${c.profileId.shape.label}',
                      style: TextStyle(color: p.accentSecondary, fontSize: 13),
                    ),
                    Text(
                      'Intelligence: ${c.intelligenceMode.label}',
                      style: TextStyle(color: p.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _intelligencePicker(MorphController c, MorphPalette p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        palette: p,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Intelligence mode',
              style: TextStyle(color: p.ink, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IntelligenceMode.values.map((m) {
                final sel = c.intelligenceMode == m;
                return ChoiceChip(
                  label: Text(m.label),
                  selected: sel,
                  onSelected: (_) => c.setIntelligenceMode(m),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Text(
              c.intelligenceMode.blurb,
              style: TextStyle(color: p.muted, fontSize: 12, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shapeChips(MorphController c, MorphPalette p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: MorphProfileId.values.map((profile) {
          final sel = c.profileId == profile;
          return ActionChip(
            avatar: Icon(profile.icon, size: 16),
            label: Text(profile.shape.label),
            backgroundColor:
                sel ? p.accent.withValues(alpha: 0.35) : p.panel,
            onPressed: () => c.applyProfile(profile, reason: 'vision:shape'),
          );
        }).toList(),
      ),
    );
  }

  Widget _q(MorphPalette p, String title, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        palette: p,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: p.accentSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              question,
              style: TextStyle(
                color: p.ink,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              answer,
              style: TextStyle(color: p.muted, height: 1.4, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fund(MorphPalette p, String q, String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(q, style: TextStyle(color: p.muted, fontSize: 13)),
          ),
          Text(
            feature,
            style: TextStyle(
              color: p.ink,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
