import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/adaptive_engine.dart';
import '../../core/app_catalog.dart';
import '../../core/home_gestures.dart';
import '../../core/home_nav.dart';
import '../../core/home_occupancy.dart';
import '../../core/launcher_listing.dart';
import '../../core/models.dart';
import '../../core/morph_controller.dart';
import '../../core/notes_store.dart';
import '../../core/productivity.dart';
import '../../core/shade_tiles.dart';
import '../../core/smart_island.dart';
import '../../core/system_morph_bridge.dart';
import '../../core/weather_service.dart';
import '../../widgets/app_icon_tile.dart';
import '../../widgets/glass_dock.dart';
import '../../widgets/home_mixed_grid.dart';
import '../../widgets/home_widgets.dart';
import '../../widgets/launcher_setup_banner.dart';
import '../../widgets/morph_background.dart';
import '../../widgets/sidebar_edge.dart';
import '../../widgets/smart_island_pill.dart';
import '../drawer/app_search_sheet.dart';
import '../morph/morph_shade.dart';
import '../notes/notes_screen.dart';
import '../settings/settings_screen.dart';
import 'app_library_page.dart';
import 'customize_home.dart';
import 'icon_action_sheet.dart';
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
  bool _selecting = false;
  final Set<String> _selectedIds = {};
  Timer? _islandTick;
  IslandActivity _island = IslandActivity.idle;
  StreamSubscription<Map<String, dynamic>>? _batteryLiveSub;
  StreamSubscription<Map<String, dynamic>>? _chromeSub;
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
    _listenChrome();
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
      unawaited(SystemMorphBridge.setHomeVisible(true));
      unawaited(_refreshIsland());
      _islandTick?.cancel();
      _islandTick = Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(_refreshIsland());
      });
    });
  }

  @override
  void dispose() {
    _islandTick?.cancel();
    _batteryLiveSub?.cancel();
    _chromeSub?.cancel();
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
      unawaited(SystemMorphBridge.setHomeVisible(true));
      c.refreshSystemStatus().then((_) {
        if (mounted) setState(() {});
      });
      unawaited(_refreshBattery());
      unawaited(_refreshIsland());
      if (c.homeWidgets.contains(HomeWidgetKind.weather)) {
        unawaited(_refreshWeather());
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(SystemMorphBridge.setHomeVisible(false));
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

  void _listenChrome() {
    _chromeSub?.cancel();
    _chromeSub = SystemMorphBridge.chromeEventStream().listen((event) {
      final type = '${event['type'] ?? ''}';
      if (type == 'shade' && c.chromeFlags.notificationBar) {
        unawaited(_openShade());
      } else if (type == 'island') {
        unawaited(_refreshIsland());
      }
    });
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

  List<MorphAppItem> get _allApps => _catalog.apps
      .where((a) => !c.hiddenIds.contains(a.id) &&
          !(a.packageName != null && c.hiddenIds.contains(a.packageName)))
      .map(c.displayApp)
      .toList(growable: false);

  List<MorphAppItem> get _allAppsIncludingHidden =>
      _catalog.apps.map(c.displayApp).toList(growable: false);

  MorphAppItem? _resolve(String id) {
    for (final a in _allApps) {
      if (a.id == id || a.packageName == id) return a;
    }
    final raw = _catalog.byId(id);
    return raw == null ? null : c.displayApp(raw);
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
    if (_selecting && !fromLibrary) {
      setState(() {
        if (_selectedIds.contains(app.id)) {
          _selectedIds.remove(app.id);
        } else {
          _selectedIds.add(app.id);
        }
      });
      return;
    }
    if (_editing && !fromLibrary) {
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
    final choice = await showIconActionSheet(
      context: context,
      controller: c,
      app: app,
    );
    if (choice == null) return;
    if (IconActionMenu.isAppInfo(choice)) {
      final pkg = app.packageName ?? (app.id.contains('.') ? app.id : '');
      if (pkg.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No system app info for this icon')),
          );
        }
        return;
      }
      await SystemMorphBridge.openAppInfo(pkg);
      return;
    }
    if (IconActionMenu.isSelect(choice)) {
      setState(() {
        _selecting = true;
        _selectedIds
          ..clear()
          ..add(app.id);
      });
      return;
    }
    if (IconActionMenu.isHide(choice)) {
      await c.hideApp(app.id);
      if (mounted) setState(() {});
      return;
    }
    if (IconActionMenu.isRemove(choice)) {
      await _removeCascade(app);
      return;
    }
    if (IconActionMenu.isEditHomescreen(choice)) {
      await _enterEdit();
      return;
    }
    await SystemMorphBridge.runShortcut(
      choice,
      packageName: app.packageName ?? app.id,
    );
  }

  Future<void> _removeCascade(MorphAppItem app) async {
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
    if (mounted) setState(() {});
  }

  Future<void> _toggleRotateLock() async {
    await c.setRotationControl(
      RotationControl(
        action: c.rotationAction,
        locked: !c.rotationLocked,
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _enterEdit() async {
    setState(() => _editing = true);
    await showCustomizeMenu(
      context: context,
      controller: c,
      onAddSidebar: () => showSidebarAppSheet(
        context: context,
        controller: c,
        apps: _allAppsIncludingHidden,
      ),
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
        if (_selecting) {
          setState(() {
            _selecting = false;
            _selectedIds.clear();
          });
          return;
        }
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
              onLongPress: HomeGestures.parentWallpaperLongPress(
                editing: _editing,
                selecting: _selecting,
              )
                  ? _enterEdit
                  : null,
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
    final slots = c.homeIds;
    final dock = _dockApps;
    return SafeArea(
      top: false,
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top,
                ),
                child: _topChrome(),
              ),
              if (_selecting)
                _selectBar()
              else if (_editing)
                CustomizeTopBar(
                  onEdit: _enterEdit,
                  onDone: () => setState(() => _editing = false),
                ),
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: HomeMixedGrid(
                    slots: slots,
                    columns: c.gridColumns.clamp(3, 5),
                    aspect: c.showLabels ? 0.78 : 1.0,
                    editing: _editing,
                    onMove: (from, to) => c.moveHomeSlot(from, to),
                    trailing: _editing ? _addAppTile() : null,
                    itemBuilder: (id, i) => _homeSlot(id, i),
                  ),
                ),
              ),
              SmallSearchPill(
                onTap: _openQuickSearch,
                dockVisible: c.dockVisible,
              ),
              const SizedBox(height: 10),
              if (c.dockVisible) _buildDock(dock),
              const SizedBox(height: 8),
            ],
          ),
          if (c.chromeFlags.notificationBar)
            Positioned(
              top: HomeGestures.statusBarBandHeight,
              left: 0,
              right: 0,
              height: HomeGestures.morphShadeBandHeight,
              child: _MorphShadePull(
                notificationBar: c.chromeFlags.notificationBar,
                onMorph: () => unawaited(_openShade()),
              ),
            ),
          if (c.chromeFlags.sidebar)
            SidebarEdge(
              controller: c,
              apps: _allAppsIncludingHidden,
              onOpen: (app) => _launchApp(app, fromLibrary: true),
              onAdd: () => showSidebarAppSheet(
                context: context,
                controller: c,
                apps: _allAppsIncludingHidden,
              ),
            ),
        ],
      ),
    );
  }

  Widget _topChrome() {
    if (c.chromeFlags.smartIsland && HomeGestures.islandDrawn(_island)) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: SmartIslandPill(
          activity: _island,
          onTap: _toggleIsland,
          onPullDown: c.chromeFlags.notificationBar
              ? () => unawaited(_openShade())
              : null,
          onOpenShade: c.chromeFlags.notificationBar
              ? () => unawaited(_openShade())
              : null,
          onSeek: (v) {
            setState(() => _island = _island.copyWith(progress: v));
            unawaited(SystemMorphBridge.islandCommand('seek:$v'));
          },
          onPrevious: () =>
              unawaited(SystemMorphBridge.islandCommand('previous')),
          onPause: () => unawaited(SystemMorphBridge.islandCommand('pause')),
          onNext: () => unawaited(SystemMorphBridge.islandCommand('next')),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _selectBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          Text(
            '${_selectedIds.length} selected',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _selectedIds.length < 2 ? null : _createFolderFromSelection,
            child: const Text('New folder'),
          ),
          TextButton(
            onPressed: _selectedIds.isEmpty
                ? null
                : () async {
                    await c.removeSelection(_selectedIds.toList());
                    if (mounted) {
                      setState(() {
                        _selecting = false;
                        _selectedIds.clear();
                      });
                    }
                  },
            child: const Text('Remove'),
          ),
          TextButton(
            onPressed: () => setState(() {
              _selecting = false;
              _selectedIds.clear();
            }),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _homeSlot(String raw, int index) {
    final widgetKind = HomeWidgetKindX.ofSlot(raw);
    if (widgetKind != null) {
      return _widgetCell(widgetKind);
    }
    if (raw.isEmpty) {
      final voidCell = const SizedBox.expand();
      if (!_editing) return voidCell;
      return DragTarget<int>(
        onAcceptWithDetails: (d) => c.moveHomeSlot(d.data, index),
        builder: (_, __, ___) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
        ),
      );
    }
    final folder = c.occupancy.folderForSlot(raw);
    if (folder != null) {
      return _folderTile(folder, index);
    }
    final app = _resolve(raw);
    if (app == null) {
      return const SizedBox.shrink();
    }
    final tile = AppIconTile(
      app: app,
      controller: c,
      showMinus: _editing,
      selected: _selectedIds.contains(app.id),
      ignoreInnerGestures: _editing,
      onTap: () => _launchApp(app),
      onLongPress: HomeGestures.iconLongPressEnabled(editing: _editing)
          ? () => _minusOn(app)
          : null,
      onMinus: () => _minusOn(app),
    );
    if (!_editing) return tile;
    return LongPressDraggable<int>(
      data: index,
      feedback: Material(color: Colors.transparent, child: tile),
      childWhenDragging: Opacity(opacity: 0.25, child: tile),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (d) => d.data != index,
        onAcceptWithDetails: (d) => c.moveHomeSlot(d.data, index),
        builder: (_, __, ___) => tile,
      ),
    );
  }

  Widget _folderTile(HomeFolder folder, int index) {
    final p = c.palette;
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openFolder(folder),
        onLongPress: HomeGestures.iconLongPressEnabled(editing: _editing)
            ? () => _enterEdit()
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.folder, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.ink, fontSize: 11),
            ),
          ],
        ),
      ),
    );
    if (!_editing) return child;
    return LongPressDraggable<int>(
      data: index,
      feedback: Material(color: Colors.transparent, child: child),
      childWhenDragging: Opacity(opacity: 0.25, child: child),
      child: DragTarget<int>(
        onAcceptWithDetails: (d) => c.moveHomeSlot(d.data, index),
        builder: (_, __, ___) => child,
      ),
    );
  }

  Future<void> _openFolder(HomeFolder folder) async {
    final p = c.palette;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  folder.name,
                  style: TextStyle(
                    color: p.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final id in folder.appIds)
                      if (_resolve(id) != null)
                        SizedBox(
                          width: 72,
                          child: AppIconTile(
                            app: _resolve(id)!,
                            controller: c,
                            onTap: () {
                              Navigator.pop(ctx);
                              _launchApp(_resolve(id)!, fromLibrary: true);
                            },
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createFolderFromSelection() async {
    final nameCtrl = TextEditingController(text: 'Folder');
    final p = c.palette;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.panel,
        title: Text('Folder name', style: TextStyle(color: p.ink)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: TextStyle(color: p.ink),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    if (name == null) return;
    await c.foldSelection(_selectedIds.toList(), name);
    if (mounted) {
      setState(() {
        _selecting = false;
        _selectedIds.clear();
      });
    }
  }

  Future<void> _openShade() async {
    var snap = shadeSnapshotFallback(battery: _batterySnap);
    try {
      final raw = await SystemMorphBridge.getShadeSnapshot();
      if (raw.isNotEmpty) {
        snap = ShadeSnapshot.fromNative(
          raw,
          now: DateTime.now(),
          batteryPercent: _batterySnap.unknown ? 0 : _batterySnap.level,
        );
      }
    } catch (_) {}
    if (snap.media == null) {
      snap = snap.copyWith(media: ShadeMedia.fromActivity(_island));
    }
    if (!mounted) return;
    await showMorphShade(
      context,
      c,
      snapshot: snap,
      refresh: () async {
        try {
          final raw = await SystemMorphBridge.getShadeSnapshot();
          if (raw.isNotEmpty) {
            var next = ShadeSnapshot.fromNative(
              raw,
              now: DateTime.now(),
              batteryPercent: _batterySnap.unknown ? 0 : _batterySnap.level,
            );
            next = next.copyWith(
              media: next.media ?? ShadeMedia.fromActivity(_island),
            );
            return next;
          }
        } catch (_) {}
        return shadeSnapshotFallback(battery: _batterySnap).copyWith(
          media: ShadeMedia.fromActivity(_island),
        );
      },
      onToggle: (id) async {
        await SystemMorphBridge.toggleShadeTile(id.name);
      },
      onBrightness: (v) async {
        await SystemMorphBridge.setBrightness(v);
      },
      onMediaCommand: (cmd) async {
        await SystemMorphBridge.islandCommand(cmd);
      },
    );
  }

  Future<void> _refreshIsland() async {
    try {
      final raw = await SystemMorphBridge.getIslandSnapshot();
      if (raw.isEmpty) return;
      final next = IslandActivity.fromNativeSnapshot(raw);
      if (mounted) {
        setState(() {
          _island = next.isIdle
              ? IslandActivity.idle
              : next.copyWith(expanded: _island.expanded && !next.isIdle);
        });
      }
    } catch (_) {}
  }

  void _toggleIsland() {
    if (!HomeGestures.islandDrawn(_island)) return;
    setState(() {
      _island = _island.expanded ? _island.compact() : _island.expand();
    });
  }

  Widget _widgetCell(HomeWidgetKind kind) {
    final child = switch (kind) {
      HomeWidgetKind.clock => const ClockHomeWidget(),
      HomeWidgetKind.battery => BatteryHomeWidget(
          snapshot: _batterySnap,
          onTap: () {},
        ),
      HomeWidgetKind.rotate => RotateHomeWidget(
          control: RotationControl(
            action: c.rotationAction,
            locked: c.rotationLocked,
          ),
          onCycle: _cycleRotation,
          onLock: _toggleRotateLock,
        ),
      HomeWidgetKind.search => SearchHomeWidget(onTap: _openQuickSearch),
      HomeWidgetKind.notes => NotesHomeWidget(
          store: _notes,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NotesScreen(controller: c, store: _notes),
              ),
            );
          },
        ),
      HomeWidgetKind.webSearch => WebSearchHomeWidget(
          browserLabel: _browserLabel,
          onSubmit: _webSearch,
        ),
      HomeWidgetKind.weather => WeatherHomeWidget(
          snapshot: _weather,
          busy: _weatherBusy,
          onTap: _refreshWeather,
        ),
    };
    return Stack(
      children: [
        Positioned.fill(
          child: FittedBox(fit: BoxFit.contain, alignment: Alignment.centerLeft, child: child),
        ),
        if (_editing)
          Positioned(
            left: 0,
            top: 0,
            child: GestureDetector(
              onTap: () => c.removeHomeWidget(kind),
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFB0B8C4),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '-',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
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

/// Lower-upper pull only. Upmost / status-bar Y is left to the system shade.
class _MorphShadePull extends StatefulWidget {
  const _MorphShadePull({
    required this.notificationBar,
    required this.onMorph,
  });

  final bool notificationBar;
  final VoidCallback onMorph;

  @override
  State<_MorphShadePull> createState() => _MorphShadePullState();
}

class _MorphShadePullState extends State<_MorphShadePull> {
  double _startY = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (d) => _startY = d.globalPosition.dy,
      onVerticalDragEnd: (d) {
        if (HomeGestures.shadeOwnerForPull(
              notificationBar: widget.notificationBar,
              startY: _startY,
              primaryVelocity: d.primaryVelocity ?? 0,
            ) ==
            ShadeOwner.morph) {
          widget.onMorph();
        }
      },
    );
  }
}
