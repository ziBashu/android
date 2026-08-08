import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../core/system_morph_bridge.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/morph_background.dart';
import '../ecosystem/morph_creator_screen.dart';
import '../ecosystem/morph_store_screen.dart';
import '../platform/platform_screen.dart';

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
            _section(c, 'Morph Engine · Adaptive', [
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
            _section(c, 'System Morph · Phase 2+', [
              Text(
                'Applies morph orientation system-wide (Rotation-style). '
                'Requires Accessibility + Modify system settings. '
                'MorphOS only uses foreground package + orientation — no password reading.',
                style: TextStyle(color: p.muted, fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('System-wide morph orientation',
                    style: TextStyle(color: p.ink)),
                subtitle: Text(
                  _systemMorphSubtitle(c),
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                value: c.systemMorphEnabled,
                onChanged: (v) async {
                  if (v) {
                    await c.refreshSystemStatus();
                    if (!c.systemStatus.accessibilityRunning) {
                      await SystemMorphBridge.openAccessibilitySettings();
                    }
                    if (!c.systemStatus.canWriteSettings) {
                      await SystemMorphBridge.openWriteSettings();
                    }
                  }
                  await c.setSystemMorphEnabled(v);
                  await c.refreshSystemStatus();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.accessibility_new, color: p.accentSecondary),
                title: Text('Open Accessibility settings',
                    style: TextStyle(color: p.ink)),
                subtitle: Text(
                  c.systemStatus.accessibilityRunning
                      ? 'Service running'
                      : 'Enable “MorphOS System Morph”',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                onTap: () async {
                  await SystemMorphBridge.openAccessibilitySettings();
                  await Future<void>.delayed(const Duration(seconds: 1));
                  await c.refreshSystemStatus();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.settings_suggest_outlined,
                    color: p.accentSecondary),
                title: Text('Allow modify system settings',
                    style: TextStyle(color: p.ink)),
                subtitle: Text(
                  c.systemStatus.canWriteSettings
                      ? 'WRITE_SETTINGS granted'
                      : 'Needed to lock rotation',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                onTap: () async {
                  await SystemMorphBridge.openWriteSettings();
                  await Future<void>.delayed(const Duration(seconds: 1));
                  await c.refreshSystemStatus();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.refresh, color: p.accentSecondary),
                title: Text('Refresh system status',
                    style: TextStyle(color: p.ink)),
                onTap: () async {
                  await c.refreshSystemStatus();
                  await c.syncSystemMorph();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'a11y=${c.systemStatus.accessibilityRunning} '
                          'write=${c.systemStatus.canWriteSettings} '
                          'displays=${c.displayInfo.displayCount}',
                        ),
                      ),
                    );
                  }
                },
              ),
            ]),
            _section(c, 'Desktop Mode · Phase 4', [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Desktop shell', style: TextStyle(color: p.ink)),
                subtitle: Text(
                  c.showDesktopShell
                      ? 'Active now (Desktop Morph or external display)'
                      : 'Shows when Desktop Morph or external display',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                value: c.desktopModeEnabled,
                onChanged: c.setDesktopModeEnabled,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title:
                    Text('Floating task windows', style: TextStyle(color: p.ink)),
                subtitle: Text(
                  'Long-press / Ctrl+tap apps on desktop workspace',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                value: c.floatingWindowsEnabled,
                onChanged: c.setFloatingWindowsEnabled,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.cast_connected, color: p.accentSecondary),
                title: Text('Displays', style: TextStyle(color: p.ink)),
                subtitle: Text(
                  '${c.displayInfo.displayCount} display(s)'
                  '${c.displayInfo.hasExternalDisplay ? ' · external connected' : ' · phone only'}'
                  '${c.pointerConnected ? ' · mouse' : ''}'
                  '${c.keyboardConnected ? ' · keyboard' : ''}',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                onTap: () async {
                  await c.refreshSystemStatus();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          c.displayInfo.hasExternalDisplay
                              ? 'External display detected'
                              : 'No external display (HDMI/wireless dock later)',
                        ),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    Icon(Icons.desktop_windows_outlined, color: p.accentSecondary),
                title: Text('Enter Desktop Morph', style: TextStyle(color: p.ink)),
                onTap: () => c.applyProfile(
                  MorphProfileId.desktop,
                  reason: 'settings:desktop',
                ),
              ),
            ]),
            _section(c, 'Platform · Phase 6', [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.developer_board, color: p.accentSecondary),
                title:
                    Text('Platform Control', style: TextStyle(color: p.ink)),
                subtitle: Text(
                  'Home · a11y · battery · QS tile · readiness '
                  '${c.systemStatus.platformScore}/5'
                  '${c.platformModeEnabled ? ' · ON' : ''}',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ListenableBuilder(
                        listenable: c,
                        builder: (_, __) => PlatformScreen(controller: c),
                      ),
                    ),
                  );
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Platform mode', style: TextStyle(color: p.ink)),
                value: c.platformModeEnabled,
                onChanged: c.setPlatformModeEnabled,
              ),
            ]),
            _section(c, 'Ecosystem · Phase 5', [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    Icon(Icons.storefront_outlined, color: p.accentSecondary),
                title: Text('Morph Store', style: TextStyle(color: p.ink)),
                subtitle: Text(
                  '${c.storeCatalog.length} shelf packs · '
                  '${c.packLibrary.length} installed',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ListenableBuilder(
                        listenable: c,
                        builder: (_, __) => MorphStoreScreen(controller: c),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    Icon(Icons.design_services_outlined, color: p.accentSecondary),
                title: Text('Morph Creator', style: TextStyle(color: p.ink)),
                subtitle: Text(
                  'Save current look as a shareable mode',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ListenableBuilder(
                        listenable: c,
                        builder: (_, __) => MorphCreatorScreen(controller: c),
                      ),
                    ),
                  );
                },
              ),
              if (c.activePackId != null)
                Text(
                  'Active pack: ${c.packById(c.activePackId!)?.name ?? c.activePackId}',
                  style: TextStyle(color: p.accentSecondary, fontSize: 12),
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
                'MorphOS 0.6.0 — Phase 6 Platform Layer.\n'
                'Default home · QS tile · boot restore · system chrome.\n'
                'Store · Creator · desktop · adaptive · system morph.\n'
                'Custom ROM remains long-term. from ziBashu.',
                style: TextStyle(color: p.muted, height: 1.4, fontSize: 13),
              ),
            ]),
          ],
        ),
      ),
      ),
    );
  }

  String _systemMorphSubtitle(MorphController c) {
    final s = c.systemStatus;
    if (!s.supported) return 'Android only';
    final bits = <String>[
      if (s.accessibilityRunning) 'a11y on' else 'a11y off',
      if (s.canWriteSettings) 'write ok' else 'need write',
      'mode ${c.profileId.systemOrientationMode}',
    ];
    return bits.join(' · ');
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
