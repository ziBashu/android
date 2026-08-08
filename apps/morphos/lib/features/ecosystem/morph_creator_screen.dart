import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/morph_background.dart';

/// Phase 5 — Morph Creator: save current look as a shareable mode without coding.
class MorphCreatorScreen extends StatefulWidget {
  const MorphCreatorScreen({super.key, required this.controller});

  final MorphController controller;

  @override
  State<MorphCreatorScreen> createState() => _MorphCreatorScreenState();
}

class _MorphCreatorScreenState extends State<MorphCreatorScreen> {
  MorphController get c => widget.controller;
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _tags;
  MorphProfileId _bind = MorphProfileId.phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bind = c.profileId;
    _name = TextEditingController(
      text: 'My ${c.profileId.label.replaceAll(' Morph', '')} Mode',
    );
    _desc = TextEditingController(
      text: '${c.themeId.label} · ${c.wallpaperId.label} · ${c.layoutId.label}',
    );
    _tags = TextEditingController(text: 'custom');
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _save({bool apply = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final tags = _tags.text
          .split(RegExp(r'[,;\s]+'))
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      final pack = await c.createPackFromCurrent(
        name: _name.text,
        description: _desc.text,
        tags: tags,
        bindProfile: _bind,
      );
      if (apply) {
        await c.applyPack(pack, reason: 'creator');
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            apply
                ? 'Created & applied ${pack.name}'
                : 'Saved ${pack.name} to My Modes',
          ),
        ),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = c.palette;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MorphBackground(
        wallpaperId: c.wallpaperId,
        palette: p,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Morph Creator'),
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
                      'Build a mode without coding',
                      style: TextStyle(
                        color: p.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Captures your current theme, wallpaper, layout, icons, '
                      'dock, and home set. Share as morphpack/v1 JSON.',
                      style: TextStyle(color: p.muted, height: 1.35, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassPanel(
                palette: p,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live snapshot',
                      style: TextStyle(
                        color: p.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _row(p, 'Theme', c.themeId.label),
                    _row(p, 'Wallpaper', c.wallpaperId.label),
                    _row(p, 'Layout', c.layoutId.label),
                    _row(p, 'Icons', c.iconStyle.name),
                    _row(p, 'Columns', '${c.gridColumns}'),
                    _row(p, 'Quiet', c.quietMode ? 'on' : 'off'),
                    _row(p, 'Large targets', c.largeTargets ? 'on' : 'off'),
                    _row(p, 'Dock apps', '${c.dockIds.length}'),
                    _row(p, 'Home apps', '${c.homeIds.length}'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassPanel(
                palette: p,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _name,
                      style: TextStyle(color: p.ink),
                      decoration: InputDecoration(
                        labelText: 'Mode name',
                        labelStyle: TextStyle(color: p.muted),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _desc,
                      style: TextStyle(color: p.ink),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: p.muted),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _tags,
                      style: TextStyle(color: p.ink),
                      decoration: InputDecoration(
                        labelText: 'Tags (comma separated)',
                        labelStyle: TextStyle(color: p.muted),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bind to morph profile',
                      style: TextStyle(color: p.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: MorphProfileId.values.map((profile) {
                        final sel = _bind == profile;
                        return ChoiceChip(
                          avatar: Icon(profile.icon, size: 16),
                          label: Text(
                            profile.label.replaceAll(' Morph', ''),
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: sel,
                          onSelected: (_) => setState(() => _bind = profile),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : () => _save(apply: true),
                icon: const Icon(Icons.flash_on),
                label: Text(_saving ? 'Saving…' : 'Save & apply mode'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _saving ? null : () => _save(apply: false),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save to My Modes only'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(dynamic p, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: TextStyle(color: p.muted, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                color: p.ink,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
