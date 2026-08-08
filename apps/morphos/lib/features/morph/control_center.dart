import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../widgets/glass_panel.dart';

/// Quick morph switcher (Launcher OS Control Center analogue).
Future<void> showMorphControlCenter(
  BuildContext context,
  MorphController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final c = controller;
          final p = c.palette;
          final maxH = MediaQuery.sizeOf(context).height * 0.72;
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Material(
              color: Colors.transparent,
              child: GlassPanel(
                palette: p,
                radius: 28,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxH),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: p.muted.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        Text(
                          'Morph Control',
                          style: TextStyle(
                            color: p.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Active: ${c.profileId.label}'
                          '${c.lastMorphReason != null ? ' · ${c.lastMorphReason}' : ''}',
                          style: TextStyle(color: p.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: MorphProfileId.values.map((profile) {
                            final sel = c.profileId == profile;
                            return ActionChip(
                              avatar: Icon(profile.icon, size: 16),
                              label: Text(
                                profile.label.replaceAll(' Morph', ''),
                              ),
                              backgroundColor: sel
                                  ? p.accent.withValues(alpha: 0.35)
                                  : p.scaffoldTint.withValues(alpha: 0.3),
                              side: BorderSide(
                                color: sel ? p.accent : p.panelBorder,
                              ),
                              labelStyle:
                                  TextStyle(color: p.ink, fontSize: 12),
                              onPressed: () async {
                                await c.applyProfile(
                                  profile,
                                  reason: 'control center',
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Per-app morph',
                            style: TextStyle(color: p.ink),
                          ),
                          subtitle: Text(
                            'Rules fire when opening apps',
                            style: TextStyle(color: p.muted, fontSize: 12),
                          ),
                          value: c.perAppMorphEnabled,
                          onChanged: c.setPerAppMorphEnabled,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Time-based morph',
                            style: TextStyle(color: p.ink),
                          ),
                          subtitle: Text(
                            'Work morning · Phone day · Relax evening · Reading night',
                            style: TextStyle(color: p.muted, fontSize: 12),
                          ),
                          value: c.timeBasedMorph,
                          onChanged: c.setTimeBasedMorph,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Charge → Desktop Morph',
                            style: TextStyle(color: p.ink),
                          ),
                          subtitle: Text(
                            c.isCharging
                                ? 'Charging now'
                                : 'Dock mode when plugged in',
                            style: TextStyle(color: p.muted, fontSize: 12),
                          ),
                          value: c.chargeMorphEnabled,
                          onChanged: c.setChargeMorphEnabled,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Category adaptive morph',
                            style: TextStyle(color: p.ink),
                          ),
                          subtitle: Text(
                            'Games/nav/media/work infer morph packs',
                            style: TextStyle(color: p.muted, fontSize: 12),
                          ),
                          value: c.categoryMorphEnabled,
                          onChanged: c.setCategoryMorphEnabled,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'System morph (orientation)',
                            style: TextStyle(color: p.ink),
                          ),
                          subtitle: Text(
                            c.systemStatus.readyForSystemMorph
                                ? 'Accessibility + write ready'
                                : 'Needs Accessibility + WRITE_SETTINGS',
                            style: TextStyle(color: p.muted, fontSize: 12),
                          ),
                          value: c.systemMorphEnabled,
                          onChanged: c.setSystemMorphEnabled,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Desktop shell',
                            style: TextStyle(color: p.ink),
                          ),
                          subtitle: Text(
                            c.showDesktopShell
                                ? 'Desktop UI active'
                                : 'When Desktop Morph / external display',
                            style: TextStyle(color: p.muted, fontSize: 12),
                          ),
                          value: c.desktopModeEnabled,
                          onChanged: c.setDesktopModeEnabled,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
