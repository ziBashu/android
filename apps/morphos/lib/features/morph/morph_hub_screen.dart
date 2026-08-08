import 'package:flutter/material.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/morph_background.dart';

/// Phase 2 Morph Engine — profiles, per-app rules, environment packs.
class MorphHubScreen extends StatelessWidget {
  const MorphHubScreen({super.key, required this.controller});

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
          title: const Text('Morph Engine'),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: FromZiBashuBadge(compact: true, openWebsite: false),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            GlassPanel(
              palette: p,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active: ${c.profileId.label}',
                    style: TextStyle(
                      color: p.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.profileId.blurb,
                    style: TextStyle(color: p.muted, height: 1.35),
                  ),
                  if (c.lastMorphReason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last morph: ${c.lastMorphReason}',
                      style: TextStyle(color: p.accentSecondary, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'Phase 2: full environment packs + per-app rules + gestures. '
                    'System-wide rotation (Rotation APK / Accessibility) remains Phase 2+ native.',
                    style: TextStyle(color: p.muted, fontSize: 12, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Morph profiles',
              style: TextStyle(
                color: p.ink,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            ...MorphProfileId.values.map((profile) {
              final selected = c.profileId == profile;
              final env = c.environments[profile]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: selected
                      ? p.accent.withValues(alpha: 0.25)
                      : p.panel,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => c.applyProfile(profile, reason: 'morph hub'),
                    onLongPress: () => _editEnvironment(context, c, env),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected ? p.accent : p.panelBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: p.accent.withValues(alpha: 0.2),
                            child: Icon(profile.icon, color: p.accentSecondary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.label,
                                  style: TextStyle(
                                    color: p.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${env.themeId.label} · ${env.wallpaperId.label} · '
                                  'P:${env.layoutPortrait.label}/L:${env.layoutLandscape.label}',
                                  style: TextStyle(
                                    color: p.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            Icon(Icons.check_circle, color: p.accentSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              'Per-app morph rules',
              style: TextStyle(
                color: p.ink,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Long-press a rule to remove. Tap app on home to fire.',
              style: TextStyle(color: p.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            GlassPanel(
              palette: p,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Enable per-app morph',
                        style: TextStyle(color: p.ink)),
                    value: c.perAppMorphEnabled,
                    onChanged: c.setPerAppMorphEnabled,
                  ),
                  SwitchListTile(
                    title: Text('Time-based morph',
                        style: TextStyle(color: p.ink)),
                    subtitle: Text(
                      'Morning work · Day phone · Evening relax · Night reading',
                      style: TextStyle(color: p.muted, fontSize: 11),
                    ),
                    value: c.timeBasedMorph,
                    onChanged: c.setTimeBasedMorph,
                  ),
                  const Divider(height: 1),
                  ...c.appRules.map((rule) {
                    final app = c.appById(rule.appId);
                    final name = app != null ? c.labelFor(app) : rule.appId;
                    return ListTile(
                      leading: Icon(
                        app?.icon ?? Icons.apps,
                        color: p.accentSecondary,
                      ),
                      title: Text(name, style: TextStyle(color: p.ink)),
                      subtitle: Text(
                        '→ ${rule.profileId.label}${rule.enabled ? '' : ' (off)'}',
                        style: TextStyle(color: p.muted, fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          rule.enabled
                              ? Icons.toggle_on
                              : Icons.toggle_off_outlined,
                          color: p.accentSecondary,
                          size: 32,
                        ),
                        onPressed: () => c.setAppRule(
                          AppMorphRule(
                            appId: rule.appId,
                            profileId: rule.profileId,
                            enabled: !rule.enabled,
                          ),
                        ),
                      ),
                      onLongPress: () => c.removeAppRule(rule.appId),
                      onTap: () => _pickRuleProfile(context, c, rule),
                    );
                  }),
                  ListTile(
                    leading: Icon(Icons.add, color: p.accentSecondary),
                    title: Text('Add rule', style: TextStyle(color: p.ink)),
                    onTap: () => _addRule(context, c),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: () async {
                await c.saveCurrentIntoActiveEnvironment();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Saved look into ${c.profileId.label} pack',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save current look into active morph pack'),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _pickRuleProfile(
    BuildContext context,
    MorphController c,
    AppMorphRule rule,
  ) async {
    final p = c.palette;
    final next = await showModalBottomSheet<MorphProfileId>(
      context: context,
      backgroundColor: p.panel,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: MorphProfileId.values
            .map(
              (id) => ListTile(
                leading: Icon(id.icon, color: p.accentSecondary),
                title: Text(id.label, style: TextStyle(color: p.ink)),
                onTap: () => Navigator.pop(ctx, id),
              ),
            )
            .toList(),
      ),
    );
    if (next != null) {
      await c.setAppRule(
        AppMorphRule(appId: rule.appId, profileId: next, enabled: rule.enabled),
      );
    }
  }

  Future<void> _addRule(BuildContext context, MorphController c) async {
    final p = c.palette;
    final used = c.appRules.map((r) => r.appId).toSet();
    final candidates =
        kDemoApps.where((a) => !used.contains(a.id)).toList(growable: false);
    if (candidates.isEmpty) return;
    final app = await showModalBottomSheet<MorphAppItem>(
      context: context,
      backgroundColor: p.panel,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: candidates
            .map(
              (a) => ListTile(
                leading: Icon(a.icon, color: p.accentSecondary),
                title: Text(c.labelFor(a), style: TextStyle(color: p.ink)),
                onTap: () => Navigator.pop(ctx, a),
              ),
            )
            .toList(),
      ),
    );
    if (app == null) return;
    if (!context.mounted) return;
    final profile = await showModalBottomSheet<MorphProfileId>(
      context: context,
      backgroundColor: p.panel,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: MorphProfileId.values
            .map(
              (id) => ListTile(
                leading: Icon(id.icon, color: p.accentSecondary),
                title: Text(id.label, style: TextStyle(color: p.ink)),
                onTap: () => Navigator.pop(ctx, id),
              ),
            )
            .toList(),
      ),
    );
    if (profile != null) {
      await c.setAppRule(AppMorphRule(appId: app.id, profileId: profile));
    }
  }

  Future<void> _editEnvironment(
    BuildContext context,
    MorphController c,
    MorphEnvironment env,
  ) async {
    // Quick: cycle theme on long-press for now.
    final themes = MorphThemeId.values;
    final i = themes.indexOf(env.themeId);
    final next = env.copyWith(themeId: themes[(i + 1) % themes.length]);
    await c.updateEnvironment(next);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${env.profileId.label} theme → ${next.themeId.label}',
          ),
        ),
      );
    }
  }
}
