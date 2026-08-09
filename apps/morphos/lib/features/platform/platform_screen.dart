import 'package:flutter/material.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

import '../../core/morph_controller.dart';
import '../../core/system_morph_bridge.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/morph_background.dart';

/// Phase 6 — Platform Control: deep system hooks toward MorphOS environment.
class PlatformScreen extends StatefulWidget {
  const PlatformScreen({super.key, required this.controller});

  final MorphController controller;

  @override
  State<PlatformScreen> createState() => _PlatformScreenState();
}

class _PlatformScreenState extends State<PlatformScreen> {
  MorphController get c => widget.controller;
  PlatformInfo _info = PlatformInfo.unsupported;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await c.refreshSystemStatus();
    final info = await SystemMorphBridge.getPlatformInfo();
    if (!mounted) return;
    setState(() {
      _info = info;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = c.palette;
    final s = c.systemStatus;
    final score = s.platformScore;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MorphBackground(
        wallpaperId: c.wallpaperId,
        palette: p,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Platform Control'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: _refresh,
                icon: Icon(Icons.refresh, color: p.accentSecondary),
              ),
              const Padding(
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
                      'MorphOS Platform Layer',
                      style: TextStyle(
                        color: p.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Deep system control without a custom ROM yet. '
                      'Enable hooks to make MorphOS the living environment — '
                      'home, orientation engine, boot restore, QS tile, battery.',
                      style: TextStyle(color: p.muted, height: 1.4, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Readiness',
                          style: TextStyle(color: p.muted, fontSize: 12),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: score / 5.0,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(99),
                            color: p.accent,
                            backgroundColor: p.panelBorder,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$score / 5',
                          style: TextStyle(
                            color: p.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(minHeight: 2),
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
                      'Device',
                      style: TextStyle(
                        color: p.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _kv(p, 'Android',
                        'API ${s.sdkInt > 0 ? s.sdkInt : _info.sdkInt} · ${_info.release}'),
                    _kv(
                      p,
                      'Hardware',
                      '${s.manufacturer.isNotEmpty ? s.manufacturer : _info.manufacturer} '
                      '${s.model.isNotEmpty ? s.model : _info.model}',
                    ),
                    _kv(p, 'Layer', _info.platformLayer),
                    _kv(p, 'App', _info.versionLabel.isEmpty ? 'MorphOS' : _info.versionLabel),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionTitle(p, 'Platform mode'),
              GlassPanel(
                palette: p,
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Platform mode',
                          style: TextStyle(color: p.ink)),
                      subtitle: Text(
                        'Immersive chrome · keep-awake on Desktop · boot restore preference',
                        style: TextStyle(color: p.muted, fontSize: 12),
                      ),
                      value: c.platformModeEnabled,
                      onChanged: (v) async {
                        await c.setPlatformModeEnabled(v);
                        await _refresh();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Immersive system UI',
                          style: TextStyle(color: p.ink)),
                      subtitle: Text(
                        'Edge-to-edge status / nav chrome',
                        style: TextStyle(color: p.muted, fontSize: 12),
                      ),
                      value: c.immersiveChrome,
                      onChanged: c.setImmersiveChrome,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Keep screen on in Desktop Morph',
                          style: TextStyle(color: p.ink)),
                      value: c.keepAwakeDesktop,
                      onChanged: c.setKeepAwakeDesktop,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Boot restore system morph',
                          style: TextStyle(color: p.ink)),
                      subtitle: Text(
                        'Native receiver reapplies orientation after reboot '
                        '(requires System Morph on)',
                        style: TextStyle(color: p.muted, fontSize: 12),
                      ),
                      value: c.bootRestoreEnabled,
                      onChanged: c.setBootRestoreEnabled,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionTitle(p, 'System hooks'),
              GlassPanel(
                palette: p,
                child: Column(
                  children: [
                    _hookTile(
                      p,
                      title: 'Default home launcher',
                      ok: s.isDefaultHome,
                      detail: s.isDefaultHome
                          ? 'MorphOS is home'
                          : (s.isHomeCandidate
                              ? 'Registered as Home — choose it in system UI'
                              : 'Not a Home candidate (reinstall APK)'),
                      action: 'Set home',
                      onTap: () async {
                        final r = await SystemMorphBridge.requestHomeRole();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(r.message)),
                          );
                        }
                        await Future<void>.delayed(const Duration(seconds: 1));
                        await _refresh();
                      },
                    ),
                    _hookTile(
                      p,
                      title: 'Accessibility orientation',
                      ok: s.accessibilityRunning,
                      detail: s.accessibilityRunning
                          ? 'MorphOS System Morph running'
                          : 'Enable MorphOS System Morph',
                      action: 'Open',
                      onTap: () async {
                        await SystemMorphBridge.openAccessibilitySettings();
                        await Future<void>.delayed(const Duration(seconds: 1));
                        await _refresh();
                      },
                    ),
                    _hookTile(
                      p,
                      title: 'Write system settings',
                      ok: s.canWriteSettings,
                      detail: s.canWriteSettings
                          ? 'Rotation lock allowed'
                          : 'Needed for forced orientation',
                      action: 'Allow',
                      onTap: () async {
                        await SystemMorphBridge.openWriteSettings();
                        await Future<void>.delayed(const Duration(seconds: 1));
                        await _refresh();
                      },
                    ),
                    _hookTile(
                      p,
                      title: 'Battery unrestricted',
                      ok: s.ignoringBatteryOptimizations,
                      detail: s.ignoringBatteryOptimizations
                          ? 'Not optimized'
                          : 'Helps boot restore + a11y survival',
                      action: 'Request',
                      onTap: () async {
                        await SystemMorphBridge
                            .openBatteryOptimizationSettings();
                        await Future<void>.delayed(const Duration(seconds: 1));
                        await _refresh();
                      },
                    ),
                    _hookTile(
                      p,
                      title: 'Display overlay (reserved)',
                      ok: s.canDrawOverlays,
                      detail: s.canDrawOverlays
                          ? 'Granted'
                          : 'Optional for future HUD overlays',
                      action: 'Open',
                      onTap: () async {
                        await SystemMorphBridge.openOverlaySettings();
                        await Future<void>.delayed(const Duration(seconds: 1));
                        await _refresh();
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.screen_rotation,
                          color: p.accentSecondary),
                      title: Text('Cycle system orientation',
                          style: TextStyle(color: p.ink)),
                      subtitle: Text(
                        'Current: ${s.globalOrientation}',
                        style: TextStyle(color: p.muted, fontSize: 12),
                      ),
                      onTap: () async {
                        final mode =
                            await SystemMorphBridge.cycleOrientationMode();
                        await c.refreshSystemStatus();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                mode == null
                                    ? 'Cycle failed'
                                    : 'Orientation → $mode',
                              ),
                            ),
                          );
                        }
                        setState(() {});
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.info_outline,
                          color: p.accentSecondary),
                      title: Text('App details',
                          style: TextStyle(color: p.ink)),
                      onTap: SystemMorphBridge.openAppDetails,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _sectionTitle(p, 'Native features'),
              GlassPanel(
                palette: p,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• Quick Settings tile: MorphOS Morph (cycle orientation)\n'
                      '• Boot receiver: restore system morph after reboot\n'
                      '• Accessibility MorphOrientationService\n'
                      '• Morph palette drives status / nav chrome',
                      style: TextStyle(color: p.muted, height: 1.45, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Custom Android ROM (MorphOS as OS core) remains the '
                      'long-term Phase 6 vision. This release is the platform '
                      'control plane on stock Android.',
                      style: TextStyle(
                        color: p.accentSecondary,
                        height: 1.4,
                        fontSize: 12,
                      ),
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

  Widget _sectionTitle(dynamic p, String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: TextStyle(
          color: p.ink,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _kv(dynamic p, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(k, style: TextStyle(color: p.muted, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              v.trim().isEmpty ? '—' : v,
              style: TextStyle(color: p.ink, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hookTile(
    dynamic p, {
    required String title,
    required bool ok,
    required String detail,
    required String action,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        ok ? Icons.check_circle : Icons.radio_button_unchecked,
        color: ok ? p.accentSecondary : p.muted,
      ),
      title: Text(title, style: TextStyle(color: p.ink)),
      subtitle: Text(detail, style: TextStyle(color: p.muted, fontSize: 12)),
      trailing: TextButton(onPressed: onTap, child: Text(action)),
    );
  }
}
