import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/adaptive_engine.dart';
import '../../core/app_catalog.dart';
import '../../core/home_nav.dart';
import '../../core/home_occupancy.dart';
import '../../core/launcher_listing.dart';
import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../core/notes_store.dart';
import '../../core/productivity.dart';
import '../../core/system_morph_bridge.dart';
import '../../core/weather_service.dart';
import '../../widgets/app_icon_tile.dart';
import '../../widgets/glass_dock.dart';
import '../../widgets/home_widgets.dart';
import '../../widgets/launcher_setup_banner.dart';
import '../../widgets/morph_background.dart';
import '../drawer/app_search_sheet.dart';
import '../morph/control_center.dart';
import '../settings/settings_screen.dart';
import 'app_library_page.dart';
import 'customize_home.dart';
import 'icon_minus_sheet.dart';
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
  final NotesStore _notes = NotesStore();
  final PageController _pages = PageController();
  bool _catalogReady = false;
  bool _editing = false;
  bool _showRotateLock = false;
  StreamSubscription<Map<String, dynamic>>? _batteryLiveSub;
  BatterySnapshot _batterySnap = const BatterySnapshot(
    level: -1,
    charging: false,
    unknown: true,
  );
  WeatherSnapshot? _weather;
  bool _weatherBusy = false;
  String? _browserLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKey);
    c.addListener(_onController);
    _listenBattery();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final size = MediaQuery.sizeOf(context);
      if (size.width > 32 && size.height > 32) {
        await c.unlockOrientationAfterFirstFrame();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await c.unlockOrientationAfterFirstFrame();
        });
      }
      try {
        await c.refreshSystemStatus();
        await c.applyPlatformChrome();
      } catch (_) {}
      try {
        await _catalog.refresh();
        await _seedAndDecorate();
      } catch (_) {}
      try {
        if (SystemMorphBridge.isAndroid) {
          await _adaptive.start();
        }
      } catch (_) {}
      await _notes.load();
      await _refreshBattery();
      await _loadBrowserLabel();
      if (mounted) setState(() => _catalogReady = true);
      unawaited(_loadRemainingIcons());
      if (c.homeWidgets.contains(HomeWidgetKind.weather)) {
        unawaited(_refreshWeather());
      }
    });
  }

  @override
  void dispose() {
    _batteryLiveSub?.cancel();
    c.removeListener(_onController);
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_onKey);
    _pages.dispose();
    _adaptive.stop();
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      c.refreshSystemStatus().then((_) {
        if (mounted) setState(() {});
      });
      unawaited(_refreshBattery());
      if (c.homeWidgets.contains(HomeWidgetKind.weather)) {
        unawaited(_refreshWeather());
      }
    }
  }

  Future<void> _loadRemainingIcons() async {
    final pkgs = _catalog.apps
        .where(
          (a) =>
              !a.isSystemDemo &&
              a.packageName != null &&
              (a.iconBytes == null || a.iconBytes!.isEmpty),
        )
        .map((a) => a.packageName!)
        .toList();
    if (pkgs.isEmpty) return;
    await _catalog.loadIconsForPackages(pkgs);
    if (mounted) setState(() {});
  }

  Future<void> _loadBrowserLabel() async {
    try {
      final info = await SystemMorphBridge.getDefaultBrowser();
      final label = info['label']?.trim();
      if (mounted && label != null && label.isNotEmpty) {
        setState(() => _browserLabel = label);
      }
    } catch (_) {}
  }

  Future<void> _refreshWeather() async {
    if (_weatherBusy) return;
    setState(() => _weatherBusy = true);
    try {
      var loc = await SystemMorphBridge.getLastLocation();
      if (loc['needPermission'] == true) {
        await SystemMorphBridge.requestLocationPermission();
        await Future<void>.delayed(const Duration(milliseconds: 400));
        loc = await SystemMorphBridge.getLastLocation();
      }
      final lat = (loc['latitude'] as num?)?.toDouble();
      final lon = (loc['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null) {
        if (mounted) setState(() => _weatherBusy = false);
        return;
      }
      final snap = await WeatherService.fetch(latitude: lat, longitude: lon);
      if (mounted) setState(() => _weather = snap);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _weatherBusy = false);
    }
  }

  Future<void> _seedAndDecorate() async {
    await c.seedOccupancyIfNeeded(
      catalogIds: _catalog.apps.map((a) => a.id).toList(),
      labels: {for (final a in _catalog.apps) a.id: a.label},
      packages: {for (final a in _catalog.apps) a.id: a.packageName},
    );
    final want = <String>{...c.homeIds, ...c.dockIds};
    await _catalog.loadIconsForPackages(
      want
          .map((id) => _catalog.byId(id)?.packageName ?? id)
          .where((id) => id.contains('.'))
          .take(24)
          .toList(),
    );
  }

  void _listenBattery() {
    _batteryLiveSub?.cancel();
    _batteryLiveSub = SystemMorphBridge.batteryEventStream().listen((extras) {
      if (extras.isEmpty) return;
      final snap = BatterySnapshot.applyChangedEvent(extras);
      if (mounted) setState(() => _batterySnap = snap);
    });
  }

  Future<void> _refreshBattery() async {
    try {
      final extras = await SystemMorphBridge.getBatteryExtras();
      if (extras.isNotEmpty) {
        final snap = BatterySnapshot.applyChangedEvent(extras);
        if (mounted) setState(() => _batterySnap = snap);
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _batterySnap = BatterySnapshot.fromRaw(
          charging: c.isCharging,
          stateName: c.isCharging ? 'charging' : null,
        );
      });
    }
  }

  Future<void> _openQuickSearch() async {
    await showAppSearchSheet(
      context: context,
      controller: c,
      apps: _allApps,
      onOpenApp: (app) => _launchApp(app, fromLibrary: true),
      onLongPress: _placeApp,
    );
  }

  Future<void> _requestHomeRole() async {
    await showSetHomeSheet(context: context, controller: c);
    await c.refreshSystemStatus();
    if (mounted) setState(() {});
  }

  bool _onKey(KeyEvent event) {
    c.setKeyboardConnected(true);
    return false;
  }

  List<MorphAppItem> get _allApps =>
      _catalog.apps.map(c.displayApp).toList(growable: false);

  MorphAppItem? _resolve(String id) {
    for (final a in _allApps) {
      if (a.id == id || a.packageName == id) return a;
    }
    final raw = _catalog.byId(id);
    return raw == null ? null : c.displayApp(raw);
  }

  List<MorphAppItem> get _homeApps {
    return c.homeIds.map(_resolve).whereType<MorphAppItem>().toList();
  }

  List<MorphAppItem> get _dockApps {
    return c.dockIds.map(_resolve).whereType<MorphAppItem>().toList();
  }

  Future<void> _placeApp(MorphAppItem app) async {
    final choice = await showAppPlacementSheet(
      context: context,
      controller: c,
      app: app,
    );
    if (choice == null || choice == 'cancel') return;
    if (choice == 'open') {
      await _launchApp(app, fromLibrary: true);
      return;
    }
    if (choice == 'star') {
      await _starOrRename(app);
      return;
    }
    if (choice == 'dock') {
      await c.addToDock(app.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${c.labelFor(app)} to the dock')),
        );
        setState(() {});
      }
      return;
    }
    if (choice == 'home') {
      await _addAppToHome(app);
    }
  }

  Future<void> _addAppToHome(MorphAppItem app) async {
    final id = app.id;
    final added = await c.addToHome(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? 'Added ${c.labelFor(app)} to Home'
              : '${c.labelFor(app)} is already on Home or the dock',
        ),
        duration: const Duration(milliseconds: 1200),
      ),
    );
    setState(() {});
    unawaited(
      _catalog.loadIconsForPackages(
        [app.packageName ?? id].where((p) => p.contains('.')).toList(),
      ).then((_) {
        if (mounted) setState(() {});
      }),
    );
  }

  Future<void> _launchApp(MorphAppItem app, {bool fromLibrary = false}) async {
    if (_editing && !fromLibrary) {
      await _minusOn(app);
      return;
    }
    if (app.id == 'settings' ||
        app.id == LauncherListing.morphosPackage ||
        app.packageName == LauncherListing.morphosPackage ||
        app.label.contains('MorphOS')) {
      _openSettings();
      return;
    }
    final before = c.profileId;
    final applied = await c.morphForAppLaunch(app.id, app: app);
    if (!mounted) return;

    if (c.intelligenceMode == IntelligenceMode.ask &&
        c.pendingSuggestion != null) {
      await _promptPendingMorph();
    }
    if (!mounted) return;
    HapticFeedback.selectionClick();
    unawaited(c.recordLaunch(app.id));

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

  Future<void> _minusOn(MorphAppItem app) async {
    final choice = await showIconMinusSheet(
      context: context,
      controller: c,
      app: app,
    );
    if (choice == null || IconMinusMenu.isCancel(choice)) return;
    if (IconMinusMenu.isHomeRemove(choice)) {
      await c.applyMinusChoice(
        choice,
        app.id,
        packageName: app.packageName,
      );
      if (mounted) setState(() {});
      return;
    }
    if (IconMinusMenu.isUninstall(choice)) {
      final pkg = app.packageName ?? (app.id.contains('.') ? app.id : '');
      if (pkg.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This demo app cannot be uninstalled')),
          );
        }
        return;
      }
      await SystemMorphBridge.requestUninstall(pkg);
    }
  }

  Future<void> _starOrRename(MorphAppItem app) async {
    await c.toggleStar(app.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            c.starredAppIds.contains(app.id)
                ? 'Starred ${c.labelFor(app)}'
                : 'Unstarred ${c.labelFor(app)}',
          ),
          duration: const Duration(milliseconds: 900),
        ),
      );
      setState(() {});
    }
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

  Future<void> _cycleRotation() async {
    var control = RotationControl(
      action: c.rotationAction,
      locked: c.rotationLocked,
    );
    if (control.locked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rotation is locked')),
        );
      }
      return;
    }
    control = control.slideRotate();
    await c.setRotationControl(control);
    if (mounted) {
      setState(() => _showRotateLock = true);
    }
  }

  Future<void> _toggleRotateLock() async {
    await c.setRotationControl(
      RotationControl(
        action: c.rotationAction,
        locked: !c.rotationLocked,
      ),
    );
    if (mounted) setState(() => _showRotateLock = c.rotationLocked);
  }

  Future<void> _enterEdit() async {
    setState(() => _editing = true);
    await showCustomizeMenu(
      context: context,
      controller: c,
      onAddApp: () => showAddAppSheet(
        context: context,
        controller: c,
        apps: _allApps,
        onAddHome: _addAppToHome,
        onAddDock: (app) async {
          await c.addToDock(app.id);
          if (mounted) setState(() {});
        },
      ),
      onAddWidget: () async {
        await showAddWidgetSheet(context: context, controller: c);
        if (c.homeWidgets.contains(HomeWidgetKind.weather)) {
          unawaited(_refreshWeather());
        }
      },
      onClearPage: () async {
        await c.deleteAllHomeApps();
        if (mounted) setState(() {});
      },
      onToggleDock: () async {
        await c.setDockVisible(!c.dockVisible);
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _webSearch(String query) async {
    final ok = await SystemMorphBridge.openWebSearch(query);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the default browser')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = c.palette;
    final showLauncherCta =
        !c.launcherSetupDismissed && !c.systemStatus.isDefaultHome;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_editing) {
          setState(() => _editing = false);
          return;
        }
        if (_pages.hasClients && (_pages.page ?? 0) > 0.5) {
          await _pages.animateToPage(
            0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
          return;
        }
        final nav = Navigator.of(context);
        final moveBack = HomeNav.shouldMoveTaskToBack(
          navigatorCanPop: nav.canPop(),
          atMorphHomeRoot: true,
        );
        if (moveBack || !nav.canPop()) {
          await SystemMorphBridge.moveTaskToBack();
        } else {
          nav.pop();
        }
      },
      child: Scaffold(
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
              onLongPress: _enterEdit,
              onVerticalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v > 500) {
                  showMorphControlCenter(context, c);
                } else if (v < -500) {
                  _openQuickSearch();
                }
              },
              child: PageView(
                controller: _pages,
                children: [
                  _buildHomePage(showLauncherCta),
                  AppLibraryPage(
                    controller: c,
                    apps: _allApps,
                    onOpenApp: (app) => _launchApp(app, fromLibrary: true),
                    onPlaceApp: _placeApp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomePage(bool showLauncherCta) {
    final homeApps = _homeApps;
    final dock = _dockApps;
    return SafeArea(
      child: Column(
        children: [
          if (_editing)
            CustomizeTopBar(
              onEdit: _enterEdit,
              onDone: () => setState(() => _editing = false),
            )
          else
            const SizedBox(height: 8),
          if (showLauncherCta)
            LauncherSetupBanner(
              palette: c.palette,
              isDefaultHome: c.systemStatus.isDefaultHome,
              onSetHome: _requestHomeRole,
              onDismiss: () => c.dismissLauncherSetup(),
            ),
          if (!_catalogReady)
            const SizedBox(
              height: 2,
              width: double.infinity,
              child: ColoredBox(color: Color(0x33FFFFFF)),
            ),
          if (c.homeWidgets.isNotEmpty)
            HomeWidgetStrip(
              controller: c,
              kinds: c.homeWidgets,
              battery: _batterySnap,
              notes: _notes,
              onSearch: _openQuickSearch,
              onRotate: _cycleRotation,
              onLockRotate: _toggleRotateLock,
              onWebSearch: _webSearch,
              weather: _weather,
              weatherBusy: _weatherBusy,
              browserLabel: _browserLabel,
              onRefreshWeather: _refreshWeather,
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: c.gridColumns.clamp(3, 5),
                mainAxisSpacing: 10,
                crossAxisSpacing: 8,
                childAspectRatio: c.showLabels ? 0.78 : 1.0,
              ),
              itemCount: homeApps.length + (_editing ? 1 : 0),
              itemBuilder: (context, i) {
                if (_editing && i == homeApps.length) {
                  return _addAppTile();
                }
                final app = homeApps[i];
                return AppIconTile(
                  app: app,
                  controller: c,
                  showMinus: _editing,
                  onTap: () => _launchApp(app),
                  onLongPress: () => _minusOn(app),
                  onMinus: () => _minusOn(app),
                );
              },
            ),
          ),
          if (_showRotateLock || c.rotationLocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: _toggleRotateLock,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          c.rotationLocked ? Icons.lock : Icons.lock_open,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          c.rotationLocked
                              ? 'Rotation locked'
                              : 'Lock rotation',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SmallSearchPill(onTap: _openQuickSearch),
          const SizedBox(height: 10),
          if (c.dockVisible) _buildDock(dock),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _addAppTile() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showAddAppSheet(
          context: context,
          controller: c,
          apps: _allApps,
          onAddHome: _addAppToHome,
          onAddDock: (app) async {
            await c.addToDock(app.id);
            if (mounted) setState(() {});
          },
        ),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white54, width: 1.4),
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDock(List<MorphAppItem> dock) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
      child: GlassDock(
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
                    showMinus: _editing,
                    onTap: () => _launchApp(app),
                    onLongPress: () => _minusOn(app),
                    onMinus: () => _minusOn(app),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
