import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

import '../../core/chrome_flags.dart';
import '../../core/home_occupancy.dart';
import '../../core/image_customize.dart';
import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../core/productivity.dart';
import '../../core/system_morph_bridge.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/morph_background.dart';
import '../ecosystem/morph_creator_screen.dart';
import '../ecosystem/morph_store_screen.dart';
import '../connection/phone_connection_screen.dart';
import '../platform/platform_screen.dart';
import 'apps_customize_screen.dart';
import '../vision/vision_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final MorphController controller;

  Future<void> _pickWallpaper(
    BuildContext context, {
    required bool landscape,
  }) async {
    final c = controller;
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );
      if (file == null) return;
      final raw = await file.readAsBytes();
      final prepared = ImageCustomize.prepareWallpaper(raw);
      if (prepared == null ||
          !ImageCustomize.isReasonableWallpaperPayload(prepared)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not use that image')),
          );
        }
        return;
      }
      if (landscape) {
        await c.setCustomWallpapers(landscapeBytes: prepared);
      } else {
        await c.setCustomWallpapers(portraitBytes: prepared);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              landscape
                  ? 'Landscape wallpaper set'
                  : 'Portrait wallpaper set',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wallpaper pick unavailable: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final p = c.palette;

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
            _section(c, 'What MorphOS is', [
              Text(
                'Personal adaptive environment layer — Android gives apps, '
                'MorphOS gives environments.',
                style: TextStyle(color: p.muted, fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.auto_awesome, color: p.accentSecondary),
                title: Text('Product vision · 12 questions',
                    style: TextStyle(color: p.ink)),
                subtitle: Text(
                  'Active: ${c.profileId.shape.label} · ${c.intelligenceMode.label}',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right, color: p.muted),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ListenableBuilder(
                        listenable: c,
                        builder: (_, __) => VisionScreen(controller: c),
                      ),
                    ),
                  );
                },
              ),
            ]),
            _section(c, 'Intelligence', [
              Text(
                c.intelligenceMode.blurb,
                style: TextStyle(color: p.muted, fontSize: 12, height: 1.35),
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
            ]),
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
              Text(
                'Built-in gradients, plus your own portrait & landscape photos.',
                style: TextStyle(color: p.muted, fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.crop_portrait, color: p.accentSecondary),
                title: Text('Portrait wallpaper', style: TextStyle(color: p.ink)),
                subtitle: Text(
                  c.customWallpaperPortraitB64 != null
                      ? 'Custom photo set'
                      : 'Pick from gallery',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                trailing: Icon(Icons.photo_library_outlined, color: p.muted),
                onTap: () => _pickWallpaper(context, landscape: false),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.crop_landscape, color: p.accentSecondary),
                title:
                    Text('Landscape wallpaper', style: TextStyle(color: p.ink)),
                subtitle: Text(
                  c.customWallpaperLandscapeB64 != null
                      ? 'Custom photo set'
                      : 'Pick from gallery',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                trailing: Icon(Icons.photo_library_outlined, color: p.muted),
                onTap: () => _pickWallpaper(context, landscape: true),
              ),
              if (c.customWallpaperPortraitB64 != null ||
                  c.customWallpaperLandscapeB64 != null)
                TextButton.icon(
                  onPressed: () => c.clearCustomWallpapers(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear custom wallpapers'),
                ),
            ]),
            _section(c, 'Default home launcher', [
              Text(
                c.systemStatus.isDefaultHome
                    ? 'MorphOS is your default Home. Pressing Home returns here.'
                    : 'Third-party launcher (Nova-style): MorphOS declares MAIN+HOME+DEFAULT. '
                        'Android requires you to choose it once — no app can take over silently.',
                style: TextStyle(color: p.muted, fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 6),
              Text(
                c.systemStatus.isHomeCandidate
                    ? 'Status: registered as Home candidate on this device.'
                    : 'Status: not seen as Home candidate — reinstall the APK.',
                style: TextStyle(
                  color: c.systemStatus.isHomeCandidate
                      ? p.accentSecondary
                      : const Color(0xFFFF8A80),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  final r = await SystemMorphBridge.requestHomeRole();
                  await c.refreshSystemStatus();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(r.message)),
                    );
                  }
                },
                icon: const Icon(Icons.home_filled),
                label: Text(
                  c.systemStatus.isDefaultHome
                      ? 'Open Home settings'
                      : 'Choose MorphOS as Home',
                ),
              ),
              TextButton(
                onPressed: () async {
                  await SystemMorphBridge.openHomeSettings();
                  await c.refreshSystemStatus();
                },
                child: const Text('Open system Home settings'),
              ),
            ]),
            _section(c, 'Home widgets', [
              Text(
                'Widgets stay off the home screen until you add them here '
                'or from Edit on the home wallpaper.',
                style: TextStyle(color: p.muted, fontSize: 12, height: 1.35),
              ),
              for (final kind in HomeWidgetKind.values)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(kind.label, style: TextStyle(color: p.ink)),
                  subtitle: Text(
                    kind.blurb,
                    style: TextStyle(color: p.muted, fontSize: 12),
                  ),
                  value: c.homeWidgets.contains(kind),
                  onChanged: (_) => c.toggleHomeWidget(kind),
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Glass dock', style: TextStyle(color: p.ink)),
                subtitle: Text(
                  'Off: dock apps return to the home page',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                value: c.dockVisible,
                onChanged: c.setDockVisible,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Auto-arrange', style: TextStyle(color: p.ink)),
                subtitle: Text(
                  'Off (default): remove leaves a void grid slot',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                value: c.autoArrange,
                onChanged: c.setAutoArrange,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.cleaning_services_outlined, color: p.accent),
                title: Text(
                  'Clear all apps on the home page',
                  style: TextStyle(color: p.ink),
                ),
                subtitle: Text(
                  'Does not uninstall anything',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                onTap: () => c.deleteAllHomeApps(),
              ),
            ]),
            _section(c, 'All apps', [
              Text(
                'Change an app’s name, icon, size, or hide its name. '
                'This stays in MorphOS and does not rename the system app.',
                style: TextStyle(color: p.muted, fontSize: 12, height: 1.35),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.apps, color: p.accentSecondary),
                title: Text('View all apps', style: TextStyle(color: p.ink)),
                subtitle: Text(
                  'Name · icon · size · hide name',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right, color: p.muted),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ListenableBuilder(
                        listenable: c,
                        builder: (_, __) =>
                            AppsCustomizeScreen(controller: c),
                      ),
                    ),
                  );
                },
              ),
            ]),
            _section(c, 'Morph chrome', [
              Text(
                'Turn a layer off to use the system UI again.',
                style: TextStyle(color: p.muted, fontSize: 12, height: 1.35),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Sidebar', style: TextStyle(color: p.ink)),
                subtitle: Text(
                  c.chromeFlags.sidebar
                      ? 'Rim nub — tap or swipe inward to open'
                      : 'System — Morph sidebar off',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                value: c.chromeFlags.sidebar,
                onChanged: (v) =>
                    c.setChromeLayer(MorphChromeLayer.sidebar, v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Notification bar', style: TextStyle(color: p.ink)),
                subtitle: Text(
                  c.chromeFlags.notificationBar
                      ? 'Pull just below the status bar for Morph shade. The very top edge stays the system shade.'
                      : 'System — Morph notification bar off',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                value: c.chromeFlags.notificationBar,
                onChanged: (v) =>
                    c.setChromeLayer(MorphChromeLayer.notificationBar, v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Smart Island', style: TextStyle(color: p.ink)),
                subtitle: Text(
                  c.chromeFlags.smartIsland
                      ? 'Sits below the system island. Needs Notification access for Brave / YouTube titles.'
                      : 'System — Morph island off',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                value: c.chromeFlags.smartIsland,
                onChanged: (v) =>
                    c.setChromeLayer(MorphChromeLayer.smartIsland, v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Notification access',
                  style: TextStyle(color: p.ink),
                ),
                subtitle: Text(
                  'Needed for live tiles, media, and island activities',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                onTap: SystemMorphBridge.openNotificationListenerSettings,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Draw over other apps',
                  style: TextStyle(color: p.ink),
                ),
                subtitle: Text(
                  c.systemStatus.canDrawOverlays
                      ? 'Granted — chrome can sit above other apps'
                      : 'Grant overlay so chrome works outside MorphOS',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                onTap: SystemMorphBridge.openOverlaySettings,
              ),
            ]),
            _section(c, 'Rotation', [
              Text(
                'Auto follows the system. Lock stops slide-to-rotate on the clock.',
                style: TextStyle(color: p.muted, fontSize: 12, height: 1.35),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RotationAction.values.map((a) {
                  return ChoiceChip(
                    label: Text(a.label),
                    selected: c.rotationAction == a,
                    onSelected: (_) => c.setRotationControl(
                      RotationControl(action: a, locked: c.rotationLocked),
                    ),
                  );
                }).toList(),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Lock rotation', style: TextStyle(color: p.ink)),
                value: c.rotationLocked,
                onChanged: c.setRotationLocked,
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
            _section(c, 'Phone connection', [
              Text(
                'Detect installed apps (rename + icons in MorphOS) and '
                'system-wide rotation (Accessibility + WRITE_SETTINGS).',
                style: TextStyle(color: p.muted, fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.phonelink_setup, color: p.accentSecondary),
                title: Text('Open phone connection', style: TextStyle(color: p.ink)),
                subtitle: Text(
                  c.systemStatus.readyForSystemMorph
                      ? 'System morph ready · ${c.systemStatus.lastAppliedMode ?? c.systemStatus.globalOrientation}'
                      : 'Permissions needed for whole-device rotation',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right, color: p.muted),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ListenableBuilder(
                        listenable: c,
                        builder: (_, __) =>
                            PhoneConnectionScreen(controller: c),
                      ),
                    ),
                  );
                },
              ),
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
                  await c.setSystemMorphEnabled(v);
                  await c.refreshSystemStatus();
                  if (context.mounted && c.lastMorphReason != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(c.lastMorphReason!)),
                    );
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.science_outlined, color: p.accentSecondary),
                title: Text('Test device rotation', style: TextStyle(color: p.ink)),
                subtitle: Text(
                  'Forces landscape system-wide (needs permissions)',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                onTap: () async {
                  final msg = await c.testSystemRotation();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.bolt_outlined, color: p.accentSecondary),
                title: Text(
                  'Apply ${c.profileId.systemOrientationMode} now',
                  style: TextStyle(color: p.ink),
                ),
                onTap: () async {
                  final ok = await c.triggerSystemOrientationNow();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Applied device-wide'
                              : 'Failed — open Phone connection for permissions',
                        ),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.accessibility_new, color: p.accentSecondary),
                title: Text('Accessibility settings',
                    style: TextStyle(color: p.ink)),
                subtitle: Text(
                  c.systemStatus.a11yOk
                      ? (c.systemStatus.accessibilityRunning
                          ? 'Service running'
                          : 'Enabled in settings')
                      : 'Enable “MorphOS System Morph”',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                onTap: () async {
                  await SystemMorphBridge.openAccessibilitySettings();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.settings_suggest_outlined,
                    color: p.accentSecondary),
                title: Text('Modify system settings',
                    style: TextStyle(color: p.ink)),
                subtitle: Text(
                  c.systemStatus.canWriteSettings
                      ? 'WRITE_SETTINGS granted'
                      : 'Needed to lock rotation for whole phone',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                onTap: () async {
                  await SystemMorphBridge.openWriteSettings();
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/brand/morphos_launcher_1024.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.smartphone,
                        size: 48,
                        color: p.accentSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MorphOS',
                          style: TextStyle(
                            color: p.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const FromZiBashuBadge(
                          compact: true,
                          openWebsite: true,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'v0.7.0 · personal adaptive environment',
                          style: TextStyle(color: p.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Custom launcher icon: morphing phones in ziBashu forest + cream, '
                'with the green brand mark.\n'
                'No cleartext · no backup leak · gated system services.\n'
                'Custom ROM remains long-term.',
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
      if (s.a11yOk) 'a11y on' else 'a11y off',
      if (s.canWriteSettings) 'write ok' else 'need write',
      if (s.readyForSystemMorph) 'ready' else 'setup needed',
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
