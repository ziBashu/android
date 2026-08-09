import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

import '../../core/app_catalog.dart';
import '../../core/image_customize.dart';
import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../core/system_morph_bridge.dart';
import '../../widgets/app_icon_tile.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/morph_background.dart';

/// Hardens MorphOS ↔ phone: detect apps (name/icon) + system-wide rotation.
class PhoneConnectionScreen extends StatefulWidget {
  const PhoneConnectionScreen({
    super.key,
    required this.controller,
    this.catalog,
  });

  final MorphController controller;
  final AppCatalog? catalog;

  @override
  State<PhoneConnectionScreen> createState() => _PhoneConnectionScreenState();
}

class _PhoneConnectionScreenState extends State<PhoneConnectionScreen>
    with WidgetsBindingObserver {
  MorphController get c => widget.controller;
  late final AppCatalog _catalog = widget.catalog ?? AppCatalog();
  bool _busy = false;
  String? _statusLine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResume();
    }
  }

  Future<void> _bootstrap() async {
    setState(() => _busy = true);
    await c.refreshSystemStatus();
    if (!_catalog.usingDeviceApps || _catalog.apps.length <= kDemoApps.length) {
      await _catalog.refresh(loadIcons: true);
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _statusLine = _catalog.usingDeviceApps
            ? 'Detected ${_catalog.deviceAppCount} device apps'
            : 'Using demo apps (grant QUERY / open on device)';
      });
    }
  }

  Future<void> _onResume() async {
    await c.refreshSystemStatus();
    // If user left Settings after granting, try to arm system morph.
    if (c.systemMorphEnabled ||
        c.systemStatus.canWriteSettings ||
        c.systemStatus.a11yOk) {
      if (c.systemStatus.readyForSystemMorph && c.systemMorphEnabled) {
        await c.triggerSystemOrientationNow();
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _enableSystemMorph() async {
    setState(() => _busy = true);
    final msg = await c.ensureSystemMorphReady(openMissing: true);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _statusLine = msg;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _testRotation() async {
    setState(() => _busy = true);
    final msg = await c.testSystemRotation();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _statusLine = msg;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _applyNow() async {
    setState(() => _busy = true);
    final ok = await c.triggerSystemOrientationNow();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _statusLine = ok
          ? 'Applied ${c.profileId.systemOrientationMode} device-wide'
          : 'Apply failed — check Modify system settings';
    });
  }

  Future<void> _refreshApps({bool system = false}) async {
    setState(() => _busy = true);
    _catalog.includeSystemApps = system;
    await _catalog.refresh(loadIcons: true);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _statusLine = _catalog.usingDeviceApps
          ? 'Detected ${_catalog.deviceAppCount} apps'
          : (_catalog.lastError ?? 'No device apps');
    });
  }

  Future<void> _editApp(MorphAppItem raw) async {
    final app = c.displayApp(raw);
    final nameCtrl = TextEditingController(text: c.labelFor(raw));
    final p = c.palette;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit in MorphOS',
                style: TextStyle(
                  color: p.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Name & icon change only inside MorphOS — not the system app list.',
                style: TextStyle(color: p.muted, fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  AppIconTile(
                    app: app,
                    controller: c,
                    compact: true,
                    showLabel: false,
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      raw.packageName ?? raw.id,
                      style: TextStyle(color: p.muted, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: p.ink),
                decoration: InputDecoration(
                  labelText: 'Display name',
                  labelStyle: TextStyle(color: p.muted),
                  hintText: raw.label,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      await c.renameApp(raw.id, nameCtrl.text);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.drive_file_rename_outline, size: 18),
                    label: const Text('Save name'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      try {
                        final picker = ImagePicker();
                        final file = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 92,
                        );
                        if (file == null) return;
                        final bytes = await file.readAsBytes();
                        final cropped =
                            ImageCustomize.cropIconSquare(bytes, maxSize: 192);
                        if (cropped != null) {
                          await c.setAppIconOverride(raw.id, cropped);
                          _statusLine = 'Custom icon from photo';
                        }
                      } catch (e) {
                        _statusLine = 'Icon pick failed: $e';
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.crop, size: 18),
                    label: const Text('Icon from photo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final pkg = raw.packageName ?? raw.id;
                      final bytes = await _catalog.loadDeviceIcon(pkg);
                      if (bytes != null) {
                        await c.setAppIconOverride(raw.id, bytes);
                        _statusLine = 'Icon loaded from phone';
                      } else {
                        _statusLine = 'No device icon for $pkg';
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('Use phone icon'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await c.clearAppIconOverride(raw.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) setState(() {});
                    },
                    child: const Text('Clear custom icon'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await c.renameApp(raw.id, '');
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) setState(() {});
                    },
                    child: const Text('Reset name'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = c.palette;
    final s = c.systemStatus;
    final deviceApps = _catalog.apps
        .where((a) => a.id != 'settings')
        .take(40)
        .map(c.displayApp)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MorphBackground(
        wallpaperId: c.wallpaperId,
        palette: p,
        customPortraitBytes: c.customWallpaperPortraitBytes,
        customLandscapeBytes: c.customWallpaperLandscapeBytes,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Phone connection'),
            actions: [
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
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
                      'MorphOS ↔ phone',
                      style: TextStyle(
                        color: p.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '1) Detect installed apps — rename & restyle icons inside MorphOS.\n'
                      '2) System-wide rotation — Accessibility + Modify system settings.',
                      style: TextStyle(color: p.muted, height: 1.4, fontSize: 13),
                    ),
                    if (_statusLine != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _statusLine!,
                        style: TextStyle(
                          color: p.accentSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'System-wide rotation',
                style: TextStyle(
                  color: p.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              GlassPanel(
                palette: p,
                child: Column(
                  children: [
                    _permRow(
                      p,
                      ok: s.canWriteSettings,
                      title: 'Modify system settings',
                      subtitle: s.canWriteSettings
                          ? 'WRITE_SETTINGS granted'
                          : 'Required to lock rotation for whole phone',
                      onTap: () async {
                        await SystemMorphBridge.openWriteSettings();
                      },
                    ),
                    _permRow(
                      p,
                      ok: s.a11yOk,
                      title: 'Accessibility · MorphOS System Morph',
                      subtitle: s.accessibilityRunning
                          ? 'Service running'
                          : (s.accessibilityEnabled
                              ? 'Enabled in settings (connecting…)'
                              : 'Required to watch which app is open'),
                      onTap: () async {
                        await SystemMorphBridge.openAccessibilitySettings();
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.readyForSystemMorph
                          ? 'Ready — MorphOS can rotate the whole device.'
                          : 'Not ready — grant both permissions above.',
                      style: TextStyle(
                        color: s.readyForSystemMorph
                            ? p.accentSecondary
                            : p.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (s.lastForegroundPackage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Last foreground: ${s.lastForegroundPackage}\n'
                        'Mode: ${s.lastAppliedMode ?? s.globalOrientation}',
                        style: TextStyle(color: p.muted, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _busy ? null : _enableSystemMorph,
                          icon: const Icon(Icons.screen_rotation, size: 18),
                          label: Text(
                            c.systemMorphEnabled && s.readyForSystemMorph
                                ? 'Re-arm system morph'
                                : 'Enable system morph',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _testRotation,
                          icon: const Icon(Icons.science_outlined, size: 18),
                          label: const Text('Test rotate'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _applyNow,
                          icon: const Icon(Icons.bolt_outlined, size: 18),
                          label: Text('Apply ${c.profileId.systemOrientationMode}'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await c.refreshSystemStatus();
                            if (mounted) setState(() {});
                          },
                          child: const Text('Refresh status'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Installed apps',
                style: TextStyle(
                  color: p.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to edit name / icon inside MorphOS. Long-press same.',
                style: TextStyle(color: p.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _refreshApps(system: false),
                    icon: const Icon(Icons.apps, size: 18),
                    label: const Text('Scan user apps'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _refreshApps(system: true),
                    icon: const Icon(Icons.phonelink_setup, size: 18),
                    label: const Text('Include system apps'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (deviceApps.isEmpty)
                Text(
                  'No device apps yet — run Scan on a real phone / emulator.',
                  style: TextStyle(color: p.muted),
                )
              else
                ...deviceApps.map((app) {
                  final raw = _catalog.byId(app.id) ?? app;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: SizedBox(
                      width: 48,
                      child: AppIconTile(
                        app: app,
                        controller: c,
                        compact: true,
                        showLabel: false,
                        onTap: () => _editApp(raw),
                      ),
                    ),
                    title: Text(app.label, style: TextStyle(color: p.ink)),
                    subtitle: Text(
                      app.packageName ?? app.id,
                      style: TextStyle(color: p.muted, fontSize: 11),
                    ),
                    trailing: Icon(Icons.edit_outlined, color: p.accentSecondary),
                    onTap: () => _editApp(raw),
                    onLongPress: () => _editApp(raw),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _permRow(
    dynamic p, {
    required bool ok,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        ok ? Icons.check_circle : Icons.error_outline,
        color: ok ? const Color(0xFF66BB6A) : p.accentSecondary,
      ),
      title: Text(title, style: TextStyle(color: p.ink, fontSize: 14)),
      subtitle: Text(subtitle, style: TextStyle(color: p.muted, fontSize: 11)),
      trailing: Icon(Icons.open_in_new, color: p.muted, size: 18),
      onTap: onTap,
    );
  }
}
