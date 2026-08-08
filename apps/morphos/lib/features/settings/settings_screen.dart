import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/morph_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

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
          title: const Text('MorphOS Settings'),
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
            _section(c, 'Theme engine', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MorphThemeId.values.map((t) {
                  final sel = c.themeId == t;
                  return ChoiceChip(
                    label: Text(t.label),
                    selected: sel,
                    onSelected: (_) => c.setTheme(t),
                  );
                }).toList(),
              ),
            ]),
            _section(c, 'Wallpaper engine', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WallpaperId.values.map((w) {
                  final sel = c.wallpaperId == w;
                  return ChoiceChip(
                    label: Text(w.label),
                    selected: sel,
                    onSelected: (_) => c.setWallpaper(w),
                  );
                }).toList(),
              ),
            ]),
            _section(c, 'Home layout (portrait default)', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MorphLayoutId.values.map((l) {
                  final sel = c.layoutId == l;
                  return ChoiceChip(
                    avatar: Icon(l.icon, size: 16),
                    label: Text(l.label),
                    selected: sel,
                    onSelected: (_) => c.setLayout(l),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'Landscape uses each morph pack’s landscape layout (Phase 2).',
                style: TextStyle(color: p.muted, fontSize: 12),
              ),
            ]),
            _section(c, 'Icons', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: IconStyleId.values.map((s) {
                  final sel = c.iconStyle == s;
                  return ChoiceChip(
                    label: Text(s.name),
                    selected: sel,
                    onSelected: (_) => c.setIconStyle(s),
                  );
                }).toList(),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Show labels', style: TextStyle(color: p.ink)),
                value: c.showLabels,
                onChanged: c.setShowLabels,
              ),
              Text('Icon size', style: TextStyle(color: p.muted, fontSize: 12)),
              Slider(
                value: c.iconScale,
                min: 0.75,
                max: 1.4,
                divisions: 13,
                label: c.iconScale.toStringAsFixed(2),
                onChanged: c.setIconScale,
              ),
              Text(
                'Grid columns: ${c.gridColumns}',
                style: TextStyle(color: p.muted, fontSize: 12),
              ),
              Slider(
                value: c.gridColumns.toDouble(),
                min: 3,
                max: 6,
                divisions: 3,
                label: '${c.gridColumns}',
                onChanged: (v) => c.setGridColumns(v.round()),
              ),
            ]),
            _section(c, 'Morph Engine · Phase 3 Adaptive', [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title:
                    Text('Per-app morph rules', style: TextStyle(color: p.ink)),
                value: c.perAppMorphEnabled,
                onChanged: c.setPerAppMorphEnabled,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Time-based morph', style: TextStyle(color: p.ink)),
                value: c.timeBasedMorph,
                onChanged: c.setTimeBasedMorph,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Charge → Desktop Morph',
                    style: TextStyle(color: p.ink)),
                subtitle: Text(
                  c.isCharging ? 'Currently charging' : 'Off when unplugged',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                value: c.chargeMorphEnabled,
                onChanged: c.setChargeMorphEnabled,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Category adaptive morph',
                    style: TextStyle(color: p.ink)),
                value: c.categoryMorphEnabled,
                onChanged: c.setCategoryMorphEnabled,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.save_outlined, color: p.accentSecondary),
                title: Text(
                  'Save look into ${c.profileId.label}',
                  style: TextStyle(color: p.ink),
                ),
                onTap: () async {
                  await c.saveCurrentIntoActiveEnvironment();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Morph pack updated')),
                    );
                  }
                },
              ),
            ]),
            _section(c, 'Data system', [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.upload_outlined, color: p.accentSecondary),
                title:
                    Text('Export backup JSON', style: TextStyle(color: p.ink)),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: c.exportJson()));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Backup copied to clipboard'),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    Icon(Icons.download_outlined, color: p.accentSecondary),
                title: Text(
                  'Import backup from clipboard',
                  style: TextStyle(color: p.ink),
                ),
                onTap: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  final ok = await c.importJson(data?.text ?? '');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(ok ? 'Restore OK' : 'Invalid backup JSON'),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.restart_alt, color: p.accentSecondary),
                title: Text('Reset MorphOS', style: TextStyle(color: p.ink)),
                onTap: () async {
                  await c.resetAll();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                },
              ),
            ]),
            _section(c, 'About', [
              Text(
                'MorphOS 0.3.0 — Phase 3 Adaptive Environment.\n'
                'Device apps + launch · time/charge/category morphs.\n'
                'Reference: Launcher OS + Rotation (system orientation later).\n'
                'from ziBashu · gestures: ↓ control · ←→ morph · ↑ apps.',
                style: TextStyle(color: p.muted, height: 1.4, fontSize: 13),
              ),
            ]),
          ],
        ),
      ),
      ),
    );
  }

  Widget _section(
    MorphController c,
    String title,
    List<Widget> children,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassPanel(
        palette: c.palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: c.palette.ink,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}
