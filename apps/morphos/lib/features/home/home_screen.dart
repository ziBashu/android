import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zibashu_ui/zibashu_ui.dart';

import '../../core/adaptive_engine.dart';
import '../../core/app_catalog.dart';
import '../../core/home_nav.dart';
import '../../core/image_customize.dart';
import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../core/productivity.dart';
import '../../core/system_morph_bridge.dart';
import '../../widgets/app_icon_tile.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/launcher_setup_banner.dart';
import '../../widgets/morph_background.dart';
import '../../widgets/productivity_strip.dart';
import '../connection/phone_connection_screen.dart';
import '../desktop/desktop_shell.dart';
import '../drawer/app_drawer.dart';
import '../drawer/app_search_sheet.dart';
import '../ecosystem/morph_store_screen.dart';
import '../morph/control_center.dart';
import '../morph/morph_hub_screen.dart';
import '../platform/platform_screen.dart';
import '../settings/settings_screen.dart';
import 'set_home_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final MorphController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  MorphController get c => widget.controller;
  final AppCatalog _catalog = AppCatalog();
  late final AdaptiveEngine _adaptive = AdaptiveEngine(c);
  final Battery _battery = Battery();
  bool _catalogReady = false;
  BatterySnapshot _batterySnap = const BatterySnapshot(
    level: -1,
    charging: false,
    unknown: true,
  );
  RotationAction _rotation = RotationAction.sensor;
  Timer? _batteryTimer;
  StreamSubscription<BatteryState>? _battSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKey);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Wait until Flutter has a real size — prevents black width=0 frame.
      final size = MediaQuery.sizeOf(context);
      if (size.width > 32 && size.height > 32) {
        await c.unlockOrientationAfterFirstFrame();
      } else {
        // Retry next frame if still zero-sized.
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await c.unlockOrientationAfterFirstFrame();
        });
      }
      try {
        await c.refreshSystemStatus();
        await c.syncSystemMorph();
        await c.applyPlatformChrome();
      } catch (_) {}
      try {
        await _catalog.refresh();
      } catch (_) {}
      try {
        await _adaptive.start();
      } catch (_) {}
      await _refreshBattery();
      _syncRotationFromStatus();
      try {
        _battSub = _battery.onBatteryStateChanged.listen((_) {
          unawaited(_refreshBattery());
        });
      } catch (_) {}
      _batteryTimer = Timer.periodic(const Duration(seconds: 45), (_) {
        unawaited(_refreshBattery());
      });
      if (mounted) setState(() => _catalogReady = true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_onKey);
    _batteryTimer?.cancel();
    unawaited(_battSub?.cancel() ?? Future<void>.value());
    _adaptive.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      c.refreshSystemStatus().then((_) {
        if (mounted) {
          _syncRotationFromStatus();
          setState(() {});
        }
      });
      c.syncSystemMorph();
      unawaited(_refreshBattery());
    }
  }

  Future<void> _refreshBattery() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final snap = BatterySnapshot.fromRaw(
        level: level,
        charging: state == BatteryState.charging || state == BatteryState.full,
        stateName: state.name,
      );
      if (mounted) setState(() => _batterySnap = snap);
    } catch (_) {
      if (mounted) {
        setState(() {
          _batterySnap = BatterySnapshot.fromRaw(
            charging: c.isCharging,
            stateName: c.isCharging ? 'charging' : null,
          );
        });
      }
    }
  }

  void _syncRotationFromStatus() {
    _rotation =
        RotationActionX.fromMode(c.systemStatus.globalOrientation);
  }

  Future<void> _cycleRotation() async {
    final next = _rotation.next;
    setState(() => _rotation = next);
    try {
      final ok = await SystemMorphBridge.applyGlobalOrientationNow(next.mode);
      if (!mounted) return;
      await c.refreshSystemStatus();
      if (!mounted) return;
      _syncRotationFromStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Rotation → ${next.label}'
                : 'Rotation set in MorphOS · grant system settings for device-wide',
          ),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rotation → ${next.label} (local)'),
          duration: const Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openQuickSearch() async {
    await showAppSearchSheet(
      context: context,
      controller: c,
      apps: _allApps,
      onOpenApp: _launchApp,
      onLongPress: _renameApp,
    );
  }

  Future<void> _requestHomeRole() async {
    await showSetHomeSheet(context: context, controller: c);
    await c.refreshSystemStatus();
    if (mounted) setState(() {});
  }

  bool _onKey(KeyEvent event) {
    // Phase 4: keyboard presence for desktop chrome.
    c.setKeyboardConnected(true);
    return false;
  }

  List<MorphAppItem> get _allApps =>
      _catalog.apps.map(c.displayApp).toList(growable: false);

  List<MorphAppItem> get _homeApps {
    if (_catalog.usingDeviceApps) {
      return _allApps
          .where((a) => a.id != 'settings')
          .take(16)
          .toList(growable: false);
    }
    return c.homeIds
        .map(_catalog.byId)
        .whereType<MorphAppItem>()
        .map(c.displayApp)
        .toList(growable: false);
  }

  List<MorphAppItem> get _dockApps {
    if (_catalog.usingDeviceApps) {
      final list = _allApps
          .where((a) => a.id != 'settings')
          .take(4)
          .toList(growable: true);
      final settings = _catalog.byId('settings');
      if (settings != null) list.add(c.displayApp(settings));
      return list;
    }
    return c.dockIds
        .map(_catalog.byId)
        .whereType<MorphAppItem>()
        .map(c.displayApp)
        .take(5)
        .toList(growable: false);
  }

  Future<void> _openDrawer() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppDrawerSheet(
        controller: c,
        apps: _allApps,
        onOpenApp: _launchApp,
        onRename: _renameApp,
        onRefresh: () async {
          await _catalog.refresh();
          if (mounted) setState(() {});
        },
        usingDeviceApps: _catalog.usingDeviceApps,
      ),
    );
  }

  Future<void> _launchApp(MorphAppItem app) async {
    if (app.id == 'settings' || app.label.contains('MorphOS Settings')) {
      _openSettings();
      return;
    }
    final before = c.profileId;
    final applied = await c.morphForAppLaunch(app.id, app: app);
    if (!mounted) return;

    // Ask-first intelligence: propose environment change before/with launch.
    if (c.intelligenceMode == IntelligenceMode.ask &&
        c.pendingSuggestion != null) {
      await _promptPendingMorph();
    }

    if (!mounted) return;
    HapticFeedback.selectionClick();

    final launched = await _catalog.launch(app);
    if (!mounted) return;

    final after = c.profileId;
    final morphNote = after != before ? ' · ${after.label}' : '';
    final msg = launched
        ? 'Launch ${c.labelFor(app)}$morphNote'
        : (applied != null && applied != before
            ? '${c.labelFor(app)} → ${applied.label}'
            : 'Open ${c.labelFor(app)} (demo shell)$morphNote');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1100),
        behavior: SnackBarBehavior.floating,
      ),
    );
    setState(() {});
  }

  Future<void> _promptPendingMorph() async {
    final s = c.pendingSuggestion;
    if (s == null) return;
    final p = c.palette;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.panel,
        title: Text(s.prompt, style: TextStyle(color: p.ink)),
        content: Text(
          '${s.profileId.label}\n${s.profileId.shape.blurb}\n\n${s.reason}',
          style: TextStyle(color: p.muted, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.profileId.label),
          ),
        ],
      ),
    );
    if (go == true) {
      await c.acceptPendingSuggestion();
    } else {
      c.dismissPendingSuggestion();
    }
  }

  Future<void> _renameApp(MorphAppItem app) async {
    // Full edit sheet: rename + custom icon from picture (crop square).
    final raw = _catalog.byId(app.id) ?? app;
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
                'Edit app in MorphOS',
                style: TextStyle(
                  color: p.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Name + icon stay in MorphOS. Cut a square icon from any photo.',
                style: TextStyle(color: p.muted, fontSize: 12, height: 1.35),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                autofocus: true,
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
                  FilledButton(
                    onPressed: () async {
                      await c.renameApp(raw.id, nameCtrl.text);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) setState(() {});
                    },
                    child: const Text('Save name'),
                  ),
                  FilledButton.tonal(
                    onPressed: () async {
                      final ok = await _pickCustomIcon(raw.id);
                      if (ok && ctx.mounted) Navigator.pop(ctx);
                      if (mounted) setState(() {});
                    },
                    child: const Text('Icon from photo'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      final pkg = raw.packageName ?? raw.id;
                      final bytes = await _catalog.loadDeviceIcon(pkg);
                      if (bytes != null) {
                        await c.setAppIconOverride(raw.id, bytes);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) setState(() {});
                    },
                    child: const Text('Use phone icon'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await c.clearAppIconOverride(raw.id);
                      await c.renameApp(raw.id, '');
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) setState(() {});
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _pickCustomIcon(String appId) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 92,
      );
      if (file == null) return false;
      final raw = await file.readAsBytes();
      final cropped = ImageCustomize.cropIconSquare(raw, maxSize: 192);
      if (cropped == null || !ImageCustomize.isReasonableIconPayload(cropped)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not crop that image')),
          );
        }
        return false;
      }
      await c.setAppIconOverride(appId, cropped);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Icon pick unavailable: $e')),
        );
      }
      return false;
    }
  }

  void _openPhoneConnection() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListenableBuilder(
          listenable: c,
          builder: (_, __) => PhoneConnectionScreen(
            controller: c,
            catalog: _catalog,
          ),
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListenableBuilder(
          listenable: c,
          builder: (_, __) => SettingsScreen(controller: c),
        ),
      ),
    );
  }

  void _openMorphHub() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListenableBuilder(
          listenable: c,
          builder: (_, __) => MorphHubScreen(controller: c),
        ),
      ),
    );
  }

  void _openMorphStore() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListenableBuilder(
          listenable: c,
          builder: (_, __) => MorphStoreScreen(controller: c),
        ),
      ),
    );
  }

  void _openPlatform() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListenableBuilder(
          listenable: c,
          builder: (_, __) => PlatformScreen(controller: c),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = c.palette;
    final now = TimeOfDay.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final size = MediaQuery.sizeOf(context);
    final layout = c.layoutForSize(size);

    final useDesktop = c.showDesktopShell || layout == MorphLayoutId.desktop;

    final showLauncherCta =
        !c.launcherSetupDismissed && !c.systemStatus.isDefaultHome;

    // Launcher root: system Back never finishes MorphOS — it backgrounds.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        final moveBack = HomeNav.shouldMoveTaskToBack(
          navigatorCanPop: nav.canPop(),
          atMorphHomeRoot: true,
        );
        if (moveBack) {
          await SystemMorphBridge.moveTaskToBack();
        } else if (nav.canPop()) {
          nav.pop();
        } else {
          await SystemMorphBridge.moveTaskToBack();
        }
      },
      child: Scaffold(
      // Opaque fallback so a failed child never shows pure black emptiness.
      backgroundColor: p.scaffoldTint,
      body: MorphBackground(
        wallpaperId: c.wallpaperId,
        palette: p,
        customPortraitBytes: c.customWallpaperPortraitBytes,
        customLandscapeBytes: c.customWallpaperLandscapeBytes,
        child: Listener(
          onPointerHover: (_) => c.setPointerConnected(true),
          onPointerDown: (e) {
            if (e.kind == PointerDeviceKind.mouse ||
                e.kind == PointerDeviceKind.trackpad) {
              c.setPointerConnected(true);
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v > 500) {
                showMorphControlCenter(context, c);
              } else if (v < -500) {
                _openDrawer();
              }
            },
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v < -500) {
                c.cycleProfile(delta: 1);
                HapticFeedback.lightImpact();
              } else if (v > 500) {
                c.cycleProfile(delta: -1);
                HapticFeedback.lightImpact();
              }
            },
            child: SafeArea(
              child: useDesktop
                  ? Column(
                      children: [
                        _buildHeader(p, time, MorphLayoutId.desktop),
                        if (showLauncherCta)
                          LauncherSetupBanner(
                            palette: p,
                            isDefaultHome: c.systemStatus.isDefaultHome,
                            onSetHome: _requestHomeRole,
                            onDismiss: () => c.dismissLauncherSetup(),
                          ),
                        ProductivityStrip(
                          palette: p,
                          battery: _batterySnap,
                          rotation: _rotation,
                          onSearch: _openQuickSearch,
                          onCycleRotation: _cycleRotation,
                        ),
                        if (!_catalogReady)
                          const LinearProgressIndicator(minHeight: 2),
                        Expanded(
                          child: DesktopShell(
                            controller: c,
                            apps: _allApps,
                            dockApps: _dockApps,
                            onOpenApp: _launchApp,
                            onRename: _renameApp,
                            onOpenDrawer: _openDrawer,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildHeader(p, time, layout),
                        if (showLauncherCta)
                          LauncherSetupBanner(
                            palette: p,
                            isDefaultHome: c.systemStatus.isDefaultHome,
                            onSetHome: _requestHomeRole,
                            onDismiss: () => c.dismissLauncherSetup(),
                          ),
                        ProductivityStrip(
                          palette: p,
                          battery: _batterySnap,
                          rotation: _rotation,
                          onSearch: _openQuickSearch,
                          onCycleRotation: _cycleRotation,
                        ),
                        if (!_catalogReady)
                          const LinearProgressIndicator(minHeight: 2),
                        Expanded(child: _buildLayout(layout)),
                        _buildDock(p),
                      ],
                    ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(dynamic p, String time, MorphLayoutId layout) {
    final adaptiveBits = <String>[
      if (c.timeBasedMorph) 'Time',
      if (c.chargeMorphEnabled) 'Charge',
      if (c.categoryMorphEnabled) 'Category',
      if (c.systemMorphEnabled) 'System',
      if (c.showDesktopShell) 'Desktop',
      if (c.activePackId != null) 'Pack',
      if (c.platformModeEnabled) 'Platform',
      if (c.isCharging) '⚡',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: p.ink,
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                    height: 1.05,
                    shadows: const [
                      Shadow(blurRadius: 12, color: Colors.black45),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${c.profileId.label} · ${layout.label}'
                  '${c.quietMode ? ' · Quiet' : ''}'
                  '${c.systemStatus.isDefaultHome ? ' · Home' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.ink.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    shadows: const [
                      Shadow(blurRadius: 8, color: Colors.black38),
                    ],
                  ),
                ),
                Text(
                  [
                    if (_catalog.usingDeviceApps)
                      '${_allApps.length} apps'
                    else
                      'Demo catalog',
                    if (adaptiveBits.isNotEmpty)
                      'Adaptive: ${adaptiveBits.join(' · ')}',
                    if (c.lastMorphReason != null) c.lastMorphReason!,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const FromZiBashuBadge(compact: true, openWebsite: false),
          IconButton(
            tooltip: 'Control center',
            visualDensity: VisualDensity.compact,
            onPressed: () => showMorphControlCenter(context, c),
            icon: Icon(Icons.tune, color: p.accentSecondary),
          ),
          IconButton(
            tooltip: 'Morph Engine',
            visualDensity: VisualDensity.compact,
            onPressed: _openMorphHub,
            icon: Icon(Icons.auto_awesome, color: p.accentSecondary),
          ),
          IconButton(
            tooltip: 'Morph Store',
            visualDensity: VisualDensity.compact,
            onPressed: _openMorphStore,
            icon: Icon(Icons.storefront_outlined, color: p.accentSecondary),
          ),
          IconButton(
            tooltip: 'Platform',
            visualDensity: VisualDensity.compact,
            onPressed: _openPlatform,
            icon: Icon(Icons.developer_board, color: p.accentSecondary),
          ),
          IconButton(
            tooltip: 'Phone connection',
            visualDensity: VisualDensity.compact,
            onPressed: _openPhoneConnection,
            icon: Icon(Icons.phonelink_setup, color: p.accentSecondary),
          ),
          IconButton(
            tooltip: 'Settings',
            visualDensity: VisualDensity.compact,
            onPressed: _openSettings,
            icon: Icon(Icons.settings_outlined, color: p.ink),
          ),
        ],
      ),
    );
  }

  Widget _buildDock(dynamic p) {
    final dock = _dockApps;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: GlassPanel(
        palette: p,
        radius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final app in dock)
                Expanded(
                  child: AppIconTile(
                    app: app,
                    controller: c,
                    compact: true,
                    showLabel: false,
                    onTap: () => _launchApp(app),
                    onLongPress: () => _renameApp(app),
                  ),
                ),
              Expanded(
                child: Center(
                  child: IconButton(
                    tooltip: 'All apps',
                    onPressed: _openDrawer,
                    icon: Icon(Icons.apps_rounded, color: p.ink, size: 28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayout(MorphLayoutId layoutId) {
    final homeApps = _homeApps;

    switch (layoutId) {
      case MorphLayoutId.minimal:
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.profileId.label,
                  style: TextStyle(
                    color: c.palette.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Swipe ↓ control · ↑ apps · ←→ morph · search in strip',
                  style: TextStyle(color: c.palette.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: homeApps.take(4).map((a) {
                    return AppIconTile(
                      app: a,
                      controller: c,
                      onTap: () => _launchApp(a),
                      onLongPress: () => _renameApp(a),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      case MorphLayoutId.spatial:
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  for (var i = 0; i < homeApps.length && i < 9; i++)
                    Positioned(
                      left: ((i % 3) / 3) * (w - 88) + 12,
                      top: ((i ~/ 3) / 3.0) * (h - 100).clamp(80, h) +
                          (i % 2) * 18 +
                          8,
                      width: 88,
                      height: 96,
                      child: AppIconTile(
                        app: homeApps[i],
                        controller: c,
                        onTap: () => _launchApp(homeApps[i]),
                        onLongPress: () => _renameApp(homeApps[i]),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      case MorphLayoutId.cards:
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          itemCount: homeApps.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassPanel(
                  palette: c.palette,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Adaptive workspace',
                        style: TextStyle(
                          color: c.palette.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Morphs react to apps, time, and charging.',
                        style: TextStyle(
                          color: c.palette.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final a = homeApps[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassPanel(
                palette: c.palette,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: a.color,
                    child: Icon(a.icon, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    c.labelFor(a),
                    style: TextStyle(
                      color: c.palette.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    a.category,
                    style: TextStyle(color: c.palette.muted, fontSize: 12),
                  ),
                  onTap: () => _launchApp(a),
                  onLongPress: () => _renameApp(a),
                ),
              ),
            );
          },
        );
      case MorphLayoutId.grid:
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          gridDelegate: aSliver(c),
          itemCount: homeApps.length,
          itemBuilder: (context, i) {
            final app = homeApps[i];
            return AppIconTile(
              app: app,
              controller: c,
              onTap: () => _launchApp(app),
              onLongPress: () => _renameApp(app),
            );
          },
        );
      case MorphLayoutId.desktop:
        // Desktop shell is rendered by HomeScreen when this layout is active.
        return DesktopShell(
          controller: c,
          apps: _allApps,
          dockApps: _dockApps,
          onOpenApp: _launchApp,
          onRename: _renameApp,
          onOpenDrawer: _openDrawer,
        );
    }
  }
}

SliverGridDelegateWithFixedCrossAxisCount aSliver(MorphController c) {
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: c.gridColumns.clamp(3, 5),
    mainAxisSpacing: 8,
    crossAxisSpacing: 6,
    childAspectRatio: c.showLabels ? 0.78 : 1.0,
  );
}
