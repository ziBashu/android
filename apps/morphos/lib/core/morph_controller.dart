import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_appearance.dart';
import 'chrome_flags.dart';
import 'home_occupancy.dart';
import 'image_customize.dart';
import 'models.dart';
import 'morph_pack.dart';
import 'morph_palette.dart';
import 'platform_chrome.dart';
import 'productivity.dart';
import 'system_morph_bridge.dart';

/// Central MorphOS state — personal adaptive environment layer.
///
/// Product contract: Android gives apps; MorphOS gives environments.
/// See docs/morphos-product-vision.md.
class MorphController extends ChangeNotifier {
  MorphController();

  static const _prefsKey = 'morphos_state_v2';
  static const _prefsKeyLegacy = 'morphos_state_v1';

  bool ready = false;
  bool onboardingDone = false;
  String setupFocus = 'entertainment';

  /// Manual / auto profile currently applied.
  MorphProfileId profileId = MorphProfileId.phone;

  /// How MorphOS decides to change environments.
  IntelligenceMode intelligenceMode = IntelligenceMode.beginner;

  /// Pending Ask-mode proposal (cleared on accept / dismiss).
  MorphSuggestion? pendingSuggestion;

  /// Advanced IF/THEN context rules.
  List<MorphContextRule> contextRules = kDefaultContextRules();

  /// Live visual state (mirrors active environment; editable in settings).
  MorphThemeId themeId = MorphThemeId.neon;
  MorphLayoutId layoutId = MorphLayoutId.grid;
  IconStyleId iconStyle = IconStyleId.squircle;
  WallpaperId wallpaperId = WallpaperId.verdantEmerald;
  bool showLabels = true;
  double iconScale = 1.0;
  int gridColumns = 4;
  bool quietMode = false;
  bool largeTargets = false;

  /// MorphOS-only display names (does not rename apps on the OS).
  Map<String, String> renames = {};

  /// MorphOS-only custom icons (base64 PNG/JPEG). Does not change system icons.
  Map<String, String> iconOverridesB64 = {};

  /// User-picked portrait wallpaper (base64 JPEG/PNG). Null = use [wallpaperId] gradient.
  String? customWallpaperPortraitB64;

  /// User-picked landscape wallpaper (base64 JPEG/PNG).
  String? customWallpaperLandscapeB64;

  /// Last wallpaper signature pushed to WallpaperManager (breaks restart loops).
  String? lastPushedWallpaperSig;

  /// One-shot: undo leftover USER_ROTATION from older MorphOS builds.
  bool clearedForcedLauncherRotation = false;

  /// User dismissed the “set as default home” banner (until next reinstall/reset).
  bool launcherSetupDismissed = false;

  /// One-shot: factory home wallpaper → Verdant Emerald.
  bool migratedVerdantWallpaper = false;

  List<String> dockIds = List<String>.from(HomeOccupancy.defaultDemoDock);
  List<String> homeIds = List<String>.from(HomeOccupancy.defaultDemoHome);
  bool dockVisible = true;
  bool occupancySeeded = false;
  List<HomeWidgetKind> homeWidgets = const [];
  bool autoArrange = false;
  List<String> hiddenIds = const [];
  List<HomeFolder> folders = const [];
  MorphChromeFlags chromeFlags = const MorphChromeFlags();
  SidebarStrip sidebar = const SidebarStrip();
  AppAppearanceStore appearances = const AppAppearanceStore();
  List<String> starredAppIds = const [];
  Map<String, int> launchCounts = {};
  RotationAction rotationAction = RotationAction.sensor;
  bool rotationLocked = false;

  /// Last mode actually sent to [SystemMorphBridge.applyGlobalOrientationNow].
  /// Includes `sensor` so Auto restores accelerometer rotation.
  String? lastAppliedOrientationMode;

  /// Phase 2: environment packs keyed by profile.
  final Map<MorphProfileId, MorphEnvironment> environments = {
    for (final p in MorphProfileId.values) p: MorphEnvironment.defaultsFor(p),
  };

  /// Phase 2: per-app morph rules.
  List<AppMorphRule> appRules = kDefaultAppMorphRules();

  /// Phase 2: time-based auto morph (off by default).
  bool timeBasedMorph = false;

  /// Phase 2: apply per-app rules when opening apps.
  bool perAppMorphEnabled = true;

  /// Phase 3: charging → Desktop Morph (dock mode).
  bool chargeMorphEnabled = true;

  /// Phase 3: use category heuristics for real packages without explicit rules.
  bool categoryMorphEnabled = true;

  /// Phase 2+: push orientation system-wide via Accessibility + WRITE_SETTINGS.
  bool systemMorphEnabled = false;

  /// Phase 4: force desktop shell when profile is Desktop or external display.
  bool desktopModeEnabled = true;

  /// Phase 4: floating task panels on desktop workspace.
  bool floatingWindowsEnabled = true;

  /// Phase 5: installed / created morph packs (Morph Store + Creator).
  List<MorphPack> packLibrary = [];

  /// Phase 5: last applied store/creator pack id.
  String? activePackId;

  /// Phase 6: platform control plane (immersive chrome, desktop keep-awake, boot pref).
  bool platformModeEnabled = false;
  bool immersiveChrome = false;
  bool keepAwakeDesktop = true;
  bool bootRestoreEnabled = true;

  /// Phase 3 runtime flags (not all persisted).
  bool isCharging = false;
  MorphProfileId? profileBeforeCharge;

  /// Phase 2+/4 runtime status from native (not fully persisted).
  SystemMorphStatus systemStatus = SystemMorphStatus.unsupported;
  DisplayInfo displayInfo = const DisplayInfo(
    displayCount: 1,
    hasExternalDisplay: false,
    displays: [],
  );
  bool pointerConnected = false;
  bool keyboardConnected = false;

  /// Phase 2: last transition label for UI.
  String? lastMorphReason;

  /// Load failure message (null if OK).
  String? loadError;

  /// Transition tick for AnimatedSwitcher / overlays.
  int morphGeneration = 0;

  /// Landscape / multi-orientation only after first valid home frame (avoids width=0 black screen).
  bool orientationUnlocked = false;

  MorphPalette get palette => MorphPalette.forTheme(themeId);

  MorphEnvironment get activeEnvironment =>
      environments[profileId] ?? MorphEnvironment.defaultsFor(profileId);

  String labelFor(MorphAppItem app) {
    final fromStore = appearances.displayName(app.id, '');
    if (fromStore.isNotEmpty) return fromStore;
    final pkg = app.packageName ?? '';
    if (pkg.isNotEmpty) {
      final alt = appearances.displayName(pkg, '');
      if (alt.isNotEmpty) return alt;
    }
    return renames[app.id] ?? renames[pkg] ?? app.label;
  }

  bool hideNameFor(String id, {String? packageName}) =>
      appearances.hideName(id) ||
      (packageName != null && appearances.hideName(packageName));

  double sizeScaleFor(String id, {String? packageName}) {
    final a = appearances.of(id);
    if (a.sizeScale != 1.0) return a.sizeScale;
    if (packageName != null) return appearances.sizeScale(packageName);
    return 1.0;
  }

  /// Display app with MorphOS rename + custom icon (phone connection layer).
  MorphAppItem displayApp(MorphAppItem app) {
    final key = app.packageName ?? app.id;
    final rename = renames[app.id] ?? renames[key];
    List<int>? overrideBytes;
    final b64 = iconOverridesB64[app.id] ?? iconOverridesB64[key];
    if (b64 != null && b64.isNotEmpty) {
      try {
        overrideBytes = base64Decode(b64);
      } catch (_) {}
    }
    return app.copyWith(
      label: rename ?? app.label,
      iconBytes: overrideBytes ?? app.iconBytes,
    );
  }

  MorphAppItem? appById(String id) {
    for (final a in kDemoApps) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> load() async {
    loadError = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      var raw = prefs.getString(_prefsKey);
      raw ??= prefs.getString(_prefsKeyLegacy);
      if (raw != null) {
        try {
          final m = jsonDecode(raw) as Map<String, dynamic>;
          onboardingDone = m['onboardingDone'] as bool? ?? false;
          setupFocus = m['setupFocus'] as String? ?? 'entertainment';
          profileId = _enumByName(
            MorphProfileId.values,
            m['profileId'] as String?,
            MorphProfileId.phone,
          );
          themeId = _enumByName(
            MorphThemeId.values,
            m['themeId'] as String?,
            MorphThemeId.neon,
          );
          layoutId = _enumByName(
            MorphLayoutId.values,
            m['layoutId'] as String?,
            MorphLayoutId.grid,
          );
          iconStyle = _enumByName(
            IconStyleId.values,
            m['iconStyle'] as String?,
            IconStyleId.squircle,
          );
          wallpaperId = _enumByName(
            WallpaperId.values,
            m['wallpaperId'] as String?,
            WallpaperId.verdantEmerald,
          );
          showLabels = m['showLabels'] as bool? ?? true;
          iconScale = (m['iconScale'] as num?)?.toDouble() ?? 1.0;
          gridColumns = m['gridColumns'] as int? ?? 4;
          quietMode = m['quietMode'] as bool? ?? false;
          largeTargets = m['largeTargets'] as bool? ?? false;
          renames = Map<String, String>.from(
            (m['renames'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? {},
          );
          iconOverridesB64 = Map<String, String>.from(
            (m['iconOverridesB64'] as Map?)
                    ?.map((k, v) => MapEntry('$k', '$v')) ??
                {},
          );
          customWallpaperPortraitB64 =
              m['customWallpaperPortraitB64'] as String?;
          customWallpaperLandscapeB64 =
              m['customWallpaperLandscapeB64'] as String?;
          lastPushedWallpaperSig = m['lastPushedWallpaperSig'] as String?;
          clearedForcedLauncherRotation =
              m['clearedForcedLauncherRotation'] as bool? ?? false;
          launcherSetupDismissed =
              m['launcherSetupDismissed'] as bool? ?? false;
          migratedVerdantWallpaper =
              m['migratedVerdantWallpaper'] as bool? ?? false;
          dockIds = List<String>.from(m['dockIds'] as List? ?? dockIds);
          homeIds = List<String>.from(m['homeIds'] as List? ?? homeIds);
          dockVisible = m['dockVisible'] as bool? ?? true;
          occupancySeeded = m['occupancySeeded'] as bool? ?? false;
          homeWidgets = _widgetsFrom(m['homeWidgets']);
          autoArrange = m['autoArrange'] as bool? ?? false;
          hiddenIds = List<String>.from(m['hiddenIds'] as List? ?? const []);
          folders = _foldersFrom(m['folders']);
          chromeFlags = MorphChromeFlags.fromJson(
            (m['chromeFlags'] as Map?)?.cast<String, dynamic>(),
          );
          sidebar = SidebarStrip.fromJson(
            (m['sidebar'] as Map?)?.cast<String, dynamic>(),
          );
          appearances = AppAppearanceStore.fromJson(
            (m['appearances'] as Map?)?.cast<String, dynamic>(),
          );
          if (appearances.byId.isEmpty &&
              (renames.isNotEmpty || iconOverridesB64.isNotEmpty)) {
            appearances = AppAppearanceStore.fromLegacy(
              names: renames,
              icons: iconOverridesB64,
            );
          }
          starredAppIds =
              List<String>.from(m['starredAppIds'] as List? ?? const []);
          launchCounts = (m['launchCounts'] as Map?)?.map(
                (k, v) => MapEntry('$k', (v as num?)?.toInt() ?? 0),
              ) ??
              {};
          rotationAction =
              RotationActionX.fromMode(m['rotationAction'] as String?);
          rotationLocked = m['rotationLocked'] as bool? ?? false;
          timeBasedMorph = m['timeBasedMorph'] as bool? ?? false;
          perAppMorphEnabled = m['perAppMorphEnabled'] as bool? ?? true;
          chargeMorphEnabled = m['chargeMorphEnabled'] as bool? ?? true;
          categoryMorphEnabled = m['categoryMorphEnabled'] as bool? ?? true;
          systemMorphEnabled = m['systemMorphEnabled'] as bool? ?? false;
          desktopModeEnabled = m['desktopModeEnabled'] as bool? ?? true;
          floatingWindowsEnabled =
              m['floatingWindowsEnabled'] as bool? ?? true;
          activePackId = m['activePackId'] as String?;
          platformModeEnabled = m['platformModeEnabled'] as bool? ?? false;
          immersiveChrome = m['immersiveChrome'] as bool? ?? false;
          keepAwakeDesktop = m['keepAwakeDesktop'] as bool? ?? true;
          bootRestoreEnabled = m['bootRestoreEnabled'] as bool? ?? true;
          intelligenceMode = _enumByName(
            IntelligenceMode.values,
            m['intelligenceMode'] as String?,
            IntelligenceMode.beginner,
          );

          final envMap = m['environments'] as Map?;
          if (envMap != null) {
            for (final e in envMap.entries) {
              try {
                final pid = MorphProfileId.values.byName(e.key as String);
                environments[pid] = MorphEnvironment.fromJson(
                  Map<String, dynamic>.from(e.value as Map),
                );
              } catch (_) {
                // Skip corrupt pack entry.
              }
            }
          }

          final rules = m['appRules'] as List?;
          if (rules != null) {
            appRules = rules
                .map((e) {
                  try {
                    return AppMorphRule.fromJson(
                      Map<String, dynamic>.from(e as Map),
                    );
                  } catch (_) {
                    return null;
                  }
                })
                .whereType<AppMorphRule>()
                .toList();
          }

          final ctxRules = m['contextRules'] as List?;
          if (ctxRules != null) {
            contextRules = ctxRules
                .map((e) {
                  try {
                    return MorphContextRule.fromJson(
                      Map<String, dynamic>.from(e as Map),
                    );
                  } catch (_) {
                    return null;
                  }
                })
                .whereType<MorphContextRule>()
                .toList();
          }

          final packs = m['packLibrary'] as List?;
          if (packs != null) {
            packLibrary = packs
                .map((e) {
                  try {
                    return MorphPack.fromJson(
                      Map<String, dynamic>.from(e as Map),
                    );
                  } catch (_) {
                    return null;
                  }
                })
                .whereType<MorphPack>()
                .toList();
          }
        } catch (e) {
          loadError = 'Prefs reset ($e)';
          // Corrupt prefs — keep defaults.
        }
      }

      await _migrateFactoryWallpaperIfNeeded();

      if (timeBasedMorph) {
        try {
          await _applyTimeBasedMorph(
            reason: 'time schedule on load',
            persist: false,
          );
        } catch (_) {}
      }

      // Stay portrait until HomeScreen unlocks (prevents width=0 black frame).
      orientationUnlocked = false;
      await applyOrientation(force: false);
    } catch (e) {
      loadError = 'Load failed: $e';
    } finally {
      ready = true;
      notifyListeners();
    }

    // Native bridge after UI is ready — never block first paint.
    // Do not apply system-wide orientation on every boot (restarts the launcher).
    Future<void>.microtask(() async {
      try {
        await refreshSystemStatus();
        await applyPlatformChrome();
        await _syncKeepAwake();
        await _clearStaleForcedRotationOnce();
        await SystemMorphBridge.syncChrome({
          ...chromeFlags.toJson(),
          'shortcuts': sidebar.shortcutIds,
        });
      } catch (_) {}
    });
  }

  /// Older installs defaulted to a gradient. This launch uses Verdant Emerald.
  Future<void> _migrateFactoryWallpaperIfNeeded() async {
    if (migratedVerdantWallpaper) return;
    migratedVerdantWallpaper = true;
    final noCustom =
        (customWallpaperPortraitB64 == null ||
            customWallpaperPortraitB64!.isEmpty) &&
        (customWallpaperLandscapeB64 == null ||
            customWallpaperLandscapeB64!.isEmpty);
    final factoryLook =
        wallpaperId == WallpaperId.cyberpunk ||
        wallpaperId == WallpaperId.nightCity;
    if (noCustom && factoryLook && profileId == MorphProfileId.phone) {
      wallpaperId = WallpaperId.verdantEmerald;
    }
    try {
      await _persist();
    } catch (_) {}
  }

  /// Older builds wrote landscape USER_ROTATION on every home paint.
  /// Reset to sensor exactly once so the phone is not stuck rotating.
  Future<void> _clearStaleForcedRotationOnce() async {
    if (clearedForcedLauncherRotation) return;
    if (!SystemMorphBridge.isAndroid) {
      clearedForcedLauncherRotation = true;
      return;
    }
    clearedForcedLauncherRotation = true;
    try {
      await _persist();
    } catch (_) {}
    try {
      await SystemMorphBridge.applyGlobalOrientationNow('sensor');
    } catch (_) {}
  }

  static List<HomeWidgetKind> _widgetsFrom(dynamic raw) {
    if (raw is! List) return const [];
    final out = <HomeWidgetKind>[];
    for (final e in raw) {
      for (final k in HomeWidgetKind.values) {
        if (k.name == '$e') out.add(k);
      }
    }
    return out;
  }

  static List<HomeFolder> _foldersFrom(dynamic raw) {
    if (raw is! List) return const [];
    final out = <HomeFolder>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(HomeFolder.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    return out;
  }

  HomeOccupancy get occupancy => HomeOccupancy(
        homeIds: homeIds,
        dockIds: dockIds,
        dockVisible: dockVisible,
        widgets: homeWidgets,
        seeded: occupancySeeded,
        autoArrange: autoArrange,
        hiddenIds: hiddenIds,
        folders: folders,
      );

  Future<void> applyOccupancy(HomeOccupancy next) async {
    homeIds = List<String>.from(next.homeIds);
    dockIds = List<String>.from(next.dockIds);
    dockVisible = next.dockVisible;
    homeWidgets = List<HomeWidgetKind>.from(next.widgets);
    occupancySeeded = next.seeded;
    autoArrange = next.autoArrange;
    hiddenIds = List<String>.from(next.hiddenIds);
    folders = List<HomeFolder>.from(next.folders);
    await _persist();
    notifyListeners();
  }

  /// First-run only: commonly used apps, never the full catalog.
  Future<void> seedOccupancyIfNeeded({
    required List<String> catalogIds,
    Map<String, String> labels = const {},
    Map<String, String?> packages = const {},
  }) async {
    if (occupancySeeded) return;
    if (catalogIds.isEmpty) {
      occupancySeeded = true;
      await _persist();
      notifyListeners();
      return;
    }
    final looksLikePackages = catalogIds.any((id) => id.contains('.'));
    final homeLooksDemo =
        homeIds.isEmpty || homeIds.every((id) => !id.contains('.'));
    if (!looksLikePackages && !homeLooksDemo) {
      occupancySeeded = true;
      await _persist();
      notifyListeners();
      return;
    }
    final seeded = HomeOccupancy.seedCommon(
      catalogIds: catalogIds,
      launchCounts: launchCounts,
      labels: labels,
      packages: packages,
    );
    await applyOccupancy(seeded);
    if (sidebar.shortcutIds.isEmpty && seeded.dockIds.isNotEmpty) {
      var strip = const SidebarStrip();
      for (final id in seeded.dockIds) {
        strip = strip.add(id);
      }
      await setSidebar(strip);
    }
  }

  Future<void> deleteAllHomeApps() =>
      applyOccupancy(occupancy.deleteAllOnPage().copyWith(seeded: true));

  Future<void> setDockVisible(bool visible) async {
    if (visible) {
      await applyOccupancy(occupancy.showDock().copyWith(seeded: true));
    } else {
      await applyOccupancy(occupancy.hideDock().copyWith(seeded: true));
    }
  }

  Future<void> removeFromHome(String id) =>
      applyOccupancy(occupancy.removeFromHome(id).copyWith(seeded: true));

  Future<bool> addToHome(String id) async {
    if (id.isEmpty) return false;
    if (occupancy.isOnHome(id) || dockIds.contains(id)) return false;
    await applyOccupancy(occupancy.addToHome(id).copyWith(seeded: true));
    return occupancy.isOnHome(id);
  }

  Future<void> addToDock(String id) =>
      applyOccupancy(occupancy.addToDock(id).copyWith(seeded: true));

  Future<void> removeFromDock(String id) =>
      applyOccupancy(occupancy.removeFromDock(id).copyWith(seeded: true));

  /// Drop [id] from home and dock with no transfer (minus → Delete from Home).
  Future<void> removeFromLauncher(String id, {String? also}) =>
      applyOccupancy(
        occupancy.removeFromLauncher(id, also: also).copyWith(seeded: true),
      );

  /// Minus-menu apply path used by the home surface.
  Future<void> applyMinusChoice(
    String choice,
    String id, {
    String? packageName,
  }) async {
    final next = HomeMinusAction.apply(
      occupancy: occupancy,
      choice: choice,
      id: id,
      packageName: packageName,
    );
    await applyOccupancy(next.copyWith(seeded: true));
  }

  Future<void> hideApp(String id) =>
      applyOccupancy(occupancy.hideApp(id).copyWith(seeded: true));

  Future<void> unhideApp(String id) =>
      applyOccupancy(occupancy.unhideApp(id).copyWith(seeded: true));

  Future<void> setAutoArrange(bool on) =>
      applyOccupancy(occupancy.setAutoArrange(on).copyWith(seeded: true));

  Future<void> removeSelection(List<String> ids) =>
      applyOccupancy(occupancy.removeSelection(ids).copyWith(seeded: true));

  Future<void> foldSelection(List<String> ids, String name) =>
      applyOccupancy(
        occupancy.foldSelection(ids, name).copyWith(seeded: true),
      );

  Future<void> renameFolder(String folderId, String name) =>
      applyOccupancy(
        occupancy.renameFolder(folderId, name).copyWith(seeded: true),
      );

  Future<void> moveHomeSlot(int from, int to) =>
      applyOccupancy(occupancy.moveHomeSlot(from, to).copyWith(seeded: true));

  Future<void> moveHomeWidget(int from, int to) =>
      applyOccupancy(occupancy.moveWidget(from, to).copyWith(seeded: true));

  Future<void> setChromeFlags(MorphChromeFlags flags) async {
    chromeFlags = flags;
    await _persist();
    notifyListeners();
    unawaited(SystemMorphBridge.syncChrome(flags.toJson()));
  }

  Future<void> setChromeLayer(MorphChromeLayer layer, bool on) =>
      setChromeFlags(chromeFlags.setEnabled(layer, on));

  Future<void> setSidebar(SidebarStrip next) async {
    sidebar = next;
    await _persist();
    notifyListeners();
    unawaited(
      SystemMorphBridge.syncChrome({
        ...chromeFlags.toJson(),
        'shortcuts': next.shortcutIds,
      }),
    );
  }

  Future<void> applyAppearance(AppAppearanceStore next) async {
    appearances = next;
    // Keep legacy maps in sync so older screens still work.
    final names = <String, String>{};
    final icons = <String, String>{};
    for (final e in next.byId.entries) {
      final n = e.value.customName?.trim();
      if (n != null && n.isNotEmpty) names[e.key] = n;
      final ic = e.value.iconB64;
      if (ic != null && ic.isNotEmpty) icons[e.key] = ic;
    }
    renames = names;
    iconOverridesB64 = icons;
    await _persist();
    notifyListeners();
  }

  Future<void> setAppHideName(String id, bool hide) =>
      applyAppearance(appearances.setHideName(id, hide));

  Future<void> setAppSizeScale(String id, double scale) =>
      applyAppearance(appearances.setSize(id, scale));

  Future<void> toggleHomeWidget(HomeWidgetKind kind) =>
      applyOccupancy(occupancy.toggleWidget(kind).copyWith(seeded: true));

  Future<void> addHomeWidget(HomeWidgetKind kind) =>
      applyOccupancy(occupancy.addWidget(kind).copyWith(seeded: true));

  Future<void> removeHomeWidget(HomeWidgetKind kind) =>
      applyOccupancy(occupancy.removeWidget(kind).copyWith(seeded: true));

  Future<void> recordLaunch(String id) async {
    final next = Map<String, int>.from(launchCounts);
    next[id] = (next[id] ?? 0) + 1;
    launchCounts = next;
    await _persist();
    notifyListeners();
  }

  Future<void> toggleStar(String id) async {
    if (starredAppIds.contains(id)) {
      starredAppIds = starredAppIds.where((x) => x != id).toList();
    } else {
      starredAppIds = [...starredAppIds, id];
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setStarred(List<String> ids) async {
    starredAppIds = List<String>.from(ids);
    await _persist();
    notifyListeners();
  }

  Future<void> setRotationControl(RotationControl control) async {
    rotationAction = control.action;
    rotationLocked = control.locked;
    await applyOrientation(force: true);
    // Always write the mode, including sensor — otherwise Auto never
    // re-enables ACCELEROMETER_ROTATION after a forced USER_ROTATION.
    final mode = RotationControl.systemModeToApply(control);
    lastAppliedOrientationMode = mode;
    try {
      await SystemMorphBridge.applyGlobalOrientationNow(mode);
    } catch (_) {}
    await _persist();
    notifyListeners();
  }

  Future<void> setRotationLocked(bool locked) async {
    rotationLocked = locked;
    await _persist();
    notifyListeners();
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    if (name == null || name.isEmpty) return fallback;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, exportJson());
  }

  Map<String, dynamic> _stateMap() => {
        'onboardingDone': onboardingDone,
        'setupFocus': setupFocus,
        'profileId': profileId.name,
        'themeId': themeId.name,
        'layoutId': layoutId.name,
        'iconStyle': iconStyle.name,
        'wallpaperId': wallpaperId.name,
        'showLabels': showLabels,
        'iconScale': iconScale,
        'gridColumns': gridColumns,
        'quietMode': quietMode,
        'largeTargets': largeTargets,
        'renames': renames,
        'iconOverridesB64': iconOverridesB64,
        'customWallpaperPortraitB64': customWallpaperPortraitB64,
        'customWallpaperLandscapeB64': customWallpaperLandscapeB64,
        'lastPushedWallpaperSig': lastPushedWallpaperSig,
        'clearedForcedLauncherRotation': clearedForcedLauncherRotation,
        'launcherSetupDismissed': launcherSetupDismissed,
        'migratedVerdantWallpaper': migratedVerdantWallpaper,
        'dockIds': dockIds,
        'homeIds': homeIds,
        'dockVisible': dockVisible,
        'occupancySeeded': occupancySeeded,
        'homeWidgets': homeWidgets.map((w) => w.name).toList(),
        'autoArrange': autoArrange,
        'hiddenIds': hiddenIds,
        'folders': folders.map((f) => f.toJson()).toList(),
        'chromeFlags': chromeFlags.toJson(),
        'sidebar': sidebar.toJson(),
        'appearances': appearances.toJson(),
        'starredAppIds': starredAppIds,
        'launchCounts': launchCounts,
        'rotationAction': rotationAction.mode,
        'rotationLocked': rotationLocked,
        'timeBasedMorph': timeBasedMorph,
        'perAppMorphEnabled': perAppMorphEnabled,
        'chargeMorphEnabled': chargeMorphEnabled,
        'categoryMorphEnabled': categoryMorphEnabled,
        'systemMorphEnabled': systemMorphEnabled,
        'desktopModeEnabled': desktopModeEnabled,
        'floatingWindowsEnabled': floatingWindowsEnabled,
        'activePackId': activePackId,
        'platformModeEnabled': platformModeEnabled,
        'immersiveChrome': immersiveChrome,
        'keepAwakeDesktop': keepAwakeDesktop,
        'bootRestoreEnabled': bootRestoreEnabled,
        'intelligenceMode': intelligenceMode.name,
        'environments': {
          for (final e in environments.entries) e.key.name: e.value.toJson(),
        },
        'appRules': appRules.map((r) => r.toJson()).toList(),
        'contextRules': contextRules.map((r) => r.toJson()).toList(),
        'packLibrary': packLibrary.map((p) => p.toJson()).toList(),
      };

  /// Built-in store shelf (not all installed).
  List<MorphPack> get storeCatalog => kBuiltInMorphStore();

  bool isPackInstalled(String id) =>
      packLibrary.any((p) => p.id == id);

  MorphPack? packById(String id) {
    for (final p in packLibrary) {
      if (p.id == id) return p;
    }
    for (final p in storeCatalog) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Desktop shell when Desktop Morph active, or external display + toggle.
  bool get showDesktopShell {
    if (!desktopModeEnabled) return false;
    if (profileId == MorphProfileId.desktop) return true;
    if (displayInfo.hasExternalDisplay) return true;
    return false;
  }

  Future<void> completeOnboarding(String focus) async {
    setupFocus = focus;
    onboardingDone = true;
    final MorphProfileId seed = switch (focus) {
      'gaming' => MorphProfileId.gaming,
      'productivity' => MorphProfileId.work,
      'minimal' => MorphProfileId.phone,
      'creative' => MorphProfileId.desktop,
      _ => MorphProfileId.phone,
    };
    // Reset environments to defaults then apply seed.
    for (final p in MorphProfileId.values) {
      environments[p] = MorphEnvironment.defaultsFor(p);
    }
    if (focus == 'minimal') {
      environments[MorphProfileId.phone] =
          MorphEnvironment.defaultsFor(MorphProfileId.phone).copyWith(
        themeId: MorphThemeId.dark,
        wallpaperId: WallpaperId.voidBlack,
        layoutPortrait: MorphLayoutId.minimal,
      );
    }
    await applyProfile(seed, reason: 'onboarding:$focus');
  }

  /// Apply a full morph profile environment (Phase 2 heart).
  Future<void> applyProfile(
    MorphProfileId id, {
    String reason = 'manual',
    bool persist = true,
  }) async {
    profileId = id;
    final env = environments[id] ?? MorphEnvironment.defaultsFor(id);
    themeId = env.themeId;
    wallpaperId = env.wallpaperId;
    iconStyle = env.iconStyle;
    showLabels = env.showLabels;
    iconScale = env.iconScale;
    gridColumns = env.gridColumns;
    if (!occupancySeeded) {
      dockIds = List<String>.from(env.dockIds);
      homeIds = List<String>.from(env.homeIds);
    }
    quietMode = env.quietMode;
    largeTargets = env.largeTargets;
    // Layout resolved live via [layoutForSize]; seed portrait default.
    layoutId = env.layoutPortrait;
    lastMorphReason = reason;
    morphGeneration++;
    // Home activity stays sensor/portrait. Never push wallpaper or
    // system rotation here — those restart the launcher on MIUI.
    await applyOrientation(force: false);
    unawaited(applyPlatformChrome());
    unawaited(_syncKeepAwake());
    if (persist) await _persist();
    notifyListeners();
  }

  Future<void> setPlatformModeEnabled(bool v) async {
    platformModeEnabled = v;
    if (v) {
      immersiveChrome = true;
      bootRestoreEnabled = true;
      // Encourage system morph when platform mode is on.
      if (!systemMorphEnabled) {
        systemMorphEnabled = true;
        systemStatus = await SystemMorphBridge.setSystemMorphEnabled(true);
      }
    }
    await applyPlatformChrome();
    await _syncKeepAwake();
    await syncSystemMorph();
    await _persist();
    notifyListeners();
  }

  Future<void> setImmersiveChrome(bool v) async {
    immersiveChrome = v;
    await applyPlatformChrome();
    await _persist();
    notifyListeners();
  }

  Future<void> setKeepAwakeDesktop(bool v) async {
    keepAwakeDesktop = v;
    await _syncKeepAwake();
    await _persist();
    notifyListeners();
  }

  Future<void> setBootRestoreEnabled(bool v) async {
    bootRestoreEnabled = v;
    // Boot receiver always registered; only reapplies when system morph enabled.
    // Persist preference for UI honesty + future native gate.
    await _persist();
    notifyListeners();
  }

  Future<void> applyPlatformChrome() async {
    final immersive = immersiveChrome || platformModeEnabled;
    await PlatformChrome.apply(
      palette: palette,
      immersive: immersive,
      quietMode: quietMode,
    );
  }

  Future<void> _syncKeepAwake() async {
    final keep = keepAwakeDesktop &&
        (profileId == MorphProfileId.desktop ||
            (platformModeEnabled && displayInfo.hasExternalDisplay));
    await SystemMorphBridge.setKeepScreenOn(keep);
  }

  MorphLayoutId layoutForSize(Size size) {
    final env = activeEnvironment;
    final landscape = size.width > size.height;
    return env.layoutFor(landscape: landscape);
  }

  Future<void> cycleProfile({int delta = 1}) async {
    final values = MorphProfileId.values;
    final i = values.indexOf(profileId);
    final next = values[(i + delta) % values.length];
    await applyProfile(next, reason: delta > 0 ? 'gesture:next' : 'gesture:prev');
  }

  Future<void> setProfile(MorphProfileId id) =>
      applyProfile(id, reason: 'manual');

  /// Propose a morph for an app without applying (Ask mode / UI).
  MorphSuggestion? suggestMorphForApp(
    String appId, {
    MorphAppItem? app,
  }) {
    if (!perAppMorphEnabled) return null;

    // Explicit per-app rules first.
    for (final r in appRules) {
      if (!r.enabled) continue;
      if (r.appId == appId ||
          (app?.packageName != null && r.appId == app!.packageName)) {
        if (r.profileId == profileId) return null;
        return MorphSuggestion(
          profileId: r.profileId,
          reason: 'app-rule:${app?.label ?? appId}',
          prompt: r.profileId.askPrompt,
          trigger: MorphTriggerKind.appRule,
          appId: appId,
        );
      }
    }

    // Advanced: category only via context rules, not silent heuristics.
    if (intelligenceMode == IntelligenceMode.advanced) {
      final cat = app?.category ??
          inferAppCategory(name: app?.label ?? appId, packageName: appId);
      for (final r in contextRules) {
        if (!r.enabled) continue;
        if (r.trigger != MorphTriggerKind.category) continue;
        if (r.matchValue != cat) continue;
        if (r.profileId == profileId) return null;
        return MorphSuggestion(
          profileId: r.profileId,
          reason: r.label ?? 'context:category $cat',
          prompt: r.profileId.askPrompt,
          trigger: MorphTriggerKind.contextRule,
          appId: appId,
        );
      }
      return null;
    }

    // Beginner / Ask: category heuristics.
    if (categoryMorphEnabled) {
      final cat = app?.category ??
          inferAppCategory(name: app?.label ?? appId, packageName: appId);
      final next = profileForCategory(cat);
      if (next != null && next != profileId) {
        return MorphSuggestion(
          profileId: next,
          reason: 'adaptive:category $cat → ${next.label}',
          prompt: next.askPrompt,
          trigger: MorphTriggerKind.category,
          appId: appId,
        );
      }
    }
    return null;
  }

  /// Opening an app may switch morph (rules + category + intelligence mode).
  ///
  /// In [IntelligenceMode.ask], stores [pendingSuggestion] and does not apply
  /// until [acceptPendingSuggestion] (UI dialog).
  Future<MorphProfileId?> morphForAppLaunch(
    String appId, {
    MorphAppItem? app,
  }) async {
    final suggestion = suggestMorphForApp(appId, app: app);
    if (suggestion == null) return null;

    if (intelligenceMode == IntelligenceMode.ask) {
      pendingSuggestion = suggestion;
      notifyListeners();
      return null;
    }

    await applyProfile(
      suggestion.profileId,
      reason: suggestion.reason,
    );
    return suggestion.profileId;
  }

  Future<void> acceptPendingSuggestion() async {
    final s = pendingSuggestion;
    if (s == null) return;
    pendingSuggestion = null;
    await applyProfile(s.profileId, reason: 'ask-accept:${s.reason}');
  }

  void dismissPendingSuggestion() {
    if (pendingSuggestion == null) return;
    pendingSuggestion = null;
    notifyListeners();
  }

  Future<void> setIntelligenceMode(IntelligenceMode mode) async {
    intelligenceMode = mode;
    if (mode != IntelligenceMode.ask) {
      pendingSuggestion = null;
    }
    // Beginner turns adaptive helpers on; Advanced leaves toggles to user.
    if (mode == IntelligenceMode.beginner) {
      perAppMorphEnabled = true;
      categoryMorphEnabled = true;
    } else if (mode == IntelligenceMode.advanced) {
      // Explicit rules only for category path; keep per-app on.
      categoryMorphEnabled = false;
      perAppMorphEnabled = true;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setContextRule(MorphContextRule rule) async {
    contextRules = [
      ...contextRules.where((r) => r.id != rule.id),
      rule,
    ];
    await _persist();
    notifyListeners();
  }

  Future<void> removeContextRule(String id) async {
    contextRules = contextRules.where((r) => r.id != id).toList();
    await _persist();
    notifyListeners();
  }

  /// Evaluate non-app context (keyboard, external display) for Advanced/Beginner.
  Future<MorphProfileId?> evaluateAccessoryContext({
    bool? keyboard,
    bool? externalDisplay,
  }) async {
    final kb = keyboard ?? keyboardConnected;
    final ext = externalDisplay ?? displayInfo.hasExternalDisplay;

    MorphSuggestion? pick(MorphTriggerKind kind) {
      for (final r in contextRules) {
        if (!r.enabled || r.trigger != kind) continue;
        if (r.profileId == profileId) continue;
        return MorphSuggestion(
          profileId: r.profileId,
          reason: r.label ?? 'context:${kind.name}',
          prompt: r.profileId.askPrompt,
          trigger: kind,
        );
      }
      return null;
    }

    MorphSuggestion? suggestion;
    if (kb) suggestion = pick(MorphTriggerKind.keyboard);
    suggestion ??= ext ? pick(MorphTriggerKind.externalDisplay) : null;
    if (suggestion == null) return null;

    if (intelligenceMode == IntelligenceMode.ask) {
      pendingSuggestion = suggestion;
      notifyListeners();
      return null;
    }
    // Advanced and beginner both apply accessory context rules when enabled.
    if (intelligenceMode == IntelligenceMode.advanced ||
        intelligenceMode == IntelligenceMode.beginner) {
      await applyProfile(suggestion.profileId, reason: suggestion.reason);
      return suggestion.profileId;
    }
    return null;
  }

  Future<void> setChargeMorphEnabled(bool v) async {
    chargeMorphEnabled = v;
    await _persist();
    notifyListeners();
  }

  Future<void> setCategoryMorphEnabled(bool v) async {
    categoryMorphEnabled = v;
    await _persist();
    notifyListeners();
  }

  Future<void> setSystemMorphEnabled(bool v) async {
    if (v) {
      final msg = await ensureSystemMorphReady(openMissing: true);
      lastMorphReason = msg;
      return;
    }
    systemMorphEnabled = false;
    systemStatus = await SystemMorphBridge.setSystemMorphEnabled(false);
    await _persist();
    notifyListeners();
  }

  Future<void> setDesktopModeEnabled(bool v) async {
    desktopModeEnabled = v;
    await _persist();
    notifyListeners();
  }

  Future<void> setFloatingWindowsEnabled(bool v) async {
    floatingWindowsEnabled = v;
    await _persist();
    notifyListeners();
  }

  void setPointerConnected(bool v) {
    if (pointerConnected == v) return;
    pointerConnected = v;
    notifyListeners();
  }

  void setKeyboardConnected(bool v) {
    if (keyboardConnected == v) return;
    keyboardConnected = v;
    if (v) {
      unawaited(evaluateAccessoryContext(keyboard: true));
    }
    notifyListeners();
  }

  Future<void> refreshSystemStatus() async {
    systemStatus = await SystemMorphBridge.getStatus();
    displayInfo = await SystemMorphBridge.getDisplayInfo();
    // Prefer status fields when bridge bundles them.
    if (systemStatus.displayCount > 0) {
      displayInfo = DisplayInfo(
        displayCount: systemStatus.displayCount,
        hasExternalDisplay: systemStatus.hasExternalDisplay,
        displays: displayInfo.displays,
      );
    }
    notifyListeners();
  }

  /// Push per-app orientation rules only. Does **not** write a global
  /// USER_ROTATION — that rotates (and often kills) the home activity.
  Future<void> syncSystemMorph() async {
    if (!SystemMorphBridge.isAndroid) return;
    try {
      if (systemMorphEnabled) {
        await SystemMorphBridge.syncPackageRules(
          SystemMorphBridge.rulesFromAppMorph(appRules),
        );
      }
    } catch (_) {}
  }

  void notifyAdaptiveOnly() => notifyListeners();

  Future<void> setAppRule(AppMorphRule rule) async {
    appRules = [
      ...appRules.where((r) => r.appId != rule.appId),
      rule,
    ];
    await syncSystemMorph();
    await _persist();
    notifyListeners();
  }

  Future<void> removeAppRule(String appId) async {
    appRules = appRules.where((r) => r.appId != appId).toList();
    await syncSystemMorph();
    await _persist();
    notifyListeners();
  }

  Future<void> setPerAppMorphEnabled(bool v) async {
    perAppMorphEnabled = v;
    await _persist();
    notifyListeners();
  }

  Future<void> setTimeBasedMorph(bool v) async {
    timeBasedMorph = v;
    if (v) {
      await _applyTimeBasedMorph(reason: 'time schedule enabled');
    } else {
      await _persist();
      notifyListeners();
    }
  }

  Future<void> refreshTimeBasedMorph() async {
    if (!timeBasedMorph) return;
    await _applyTimeBasedMorph(reason: 'time schedule tick');
  }

  Future<void> _applyTimeBasedMorph({
    required String reason,
    bool persist = true,
  }) async {
    final hour = DateTime.now().hour;
    final MorphProfileId next;
    if (hour >= 6 && hour < 12) {
      next = MorphProfileId.work;
    } else if (hour >= 12 && hour < 18) {
      next = MorphProfileId.phone;
    } else if (hour >= 18 && hour < 22) {
      next = MorphProfileId.relax;
    } else {
      next = MorphProfileId.reading;
    }
    if (next != profileId) {
      await applyProfile(next, reason: reason, persist: persist);
    } else if (persist) {
      await _persist();
      notifyListeners();
    }
  }

  /// Save current visuals into the active profile pack.
  Future<void> saveCurrentIntoActiveEnvironment() async {
    final cur = activeEnvironment;
    environments[profileId] = cur.copyWith(
      themeId: themeId,
      wallpaperId: wallpaperId,
      layoutPortrait: layoutId,
      // Keep landscape unless cards/desktop force.
      layoutLandscape: cur.layoutLandscape,
      iconStyle: iconStyle,
      showLabels: showLabels,
      iconScale: iconScale,
      gridColumns: gridColumns,
      dockIds: List<String>.from(dockIds),
      homeIds: List<String>.from(homeIds),
      quietMode: quietMode,
      largeTargets: largeTargets,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> updateEnvironment(MorphEnvironment env) async {
    environments[env.profileId] = env;
    if (env.profileId == profileId) {
      await applyProfile(env.profileId, reason: 'env edit');
    } else {
      await _persist();
      notifyListeners();
    }
  }

  Future<void> setTheme(MorphThemeId id) async {
    themeId = id;
    await _persist();
    notifyListeners();
  }

  Future<void> setLayout(MorphLayoutId id) async {
    layoutId = id;
    await _persist();
    notifyListeners();
  }

  Future<void> setIconStyle(IconStyleId id) async {
    iconStyle = id;
    await _persist();
    notifyListeners();
  }

  Future<void> setWallpaper(WallpaperId id) async {
    wallpaperId = id;
    await _persist();
    notifyListeners();
    unawaited(pushSystemWallpaper(force: true));
  }

  /// Custom portrait/landscape wallpapers from user media (MorphOS home only).
  /// Pass null for a slot to clear it. Empty list clears that orientation.
  Future<void> setCustomWallpapers({
    List<int>? portraitBytes,
    List<int>? landscapeBytes,
    bool clearPortrait = false,
    bool clearLandscape = false,
  }) async {
    if (clearPortrait) {
      customWallpaperPortraitB64 = null;
    } else if (portraitBytes != null) {
      if (portraitBytes.isEmpty) {
        customWallpaperPortraitB64 = null;
      } else if (portraitBytes.length <= 900 * 1024) {
        customWallpaperPortraitB64 = base64Encode(portraitBytes);
      }
    }
    if (clearLandscape) {
      customWallpaperLandscapeB64 = null;
    } else if (landscapeBytes != null) {
      if (landscapeBytes.isEmpty) {
        customWallpaperLandscapeB64 = null;
      } else if (landscapeBytes.length <= 900 * 1024) {
        customWallpaperLandscapeB64 = base64Encode(landscapeBytes);
      }
    }
    await _persist();
    notifyListeners();
    unawaited(pushSystemWallpaper(force: true));
  }

  Future<void> clearCustomWallpapers() async {
    customWallpaperPortraitB64 = null;
    customWallpaperLandscapeB64 = null;
    await _persist();
    notifyListeners();
    unawaited(pushSystemWallpaper(force: true));
  }

  bool systemWallpaperPushed = false;

  /// Push MorphOS wallpaper to the system so recents uses it (not OEM home).
  /// Once per process unless [force] — setBitmap restarts the launcher on MIUI.
  Future<bool> pushSystemWallpaper({
    bool landscape = false,
    bool force = false,
  }) async {
    if (!SystemMorphBridge.isAndroid) return false;
    final sig =
        '${wallpaperId.name}|${customWallpaperPortraitB64?.length ?? 0}|${customWallpaperLandscapeB64?.length ?? 0}';
    if (!force &&
        (systemWallpaperPushed || lastPushedWallpaperSig == sig)) {
      systemWallpaperPushed = true;
      return true;
    }
    // Persist first so a MIUI activity-kill cannot loop setBitmap forever.
    lastPushedWallpaperSig = sig;
    systemWallpaperPushed = true;
    try {
      await _persist();
    } catch (_) {}
    try {
      final custom = customWallpaperFor(landscape: landscape);
      if (custom != null && custom.isNotEmpty) {
        return SystemMorphBridge.setSystemWallpaper(custom);
      }
      final colors = MorphPalette.wallpaperColors(wallpaperId);
      final bytes = ImageCustomize.gradientJpeg(
        topArgb: colors.first.toARGB32(),
        bottomArgb: colors.last.toARGB32(),
        width: 540,
        height: 960,
      );
      return SystemMorphBridge.setSystemWallpaper(bytes);
    } catch (_) {
      return false;
    }
  }

  List<int>? get customWallpaperPortraitBytes {
    final b64 = customWallpaperPortraitB64;
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  List<int>? get customWallpaperLandscapeBytes {
    final b64 = customWallpaperLandscapeB64;
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  /// Resolve custom wallpaper bytes for the given orientation.
  List<int>? customWallpaperFor({required bool landscape}) {
    if (landscape) {
      return customWallpaperLandscapeBytes ?? customWallpaperPortraitBytes;
    }
    return customWallpaperPortraitBytes ?? customWallpaperLandscapeBytes;
  }

  Future<void> dismissLauncherSetup() async {
    launcherSetupDismissed = true;
    await _persist();
    notifyListeners();
  }

  Future<void> setShowLabels(bool v) async {
    showLabels = v;
    await _persist();
    notifyListeners();
  }

  Future<void> setIconScale(double v) async {
    iconScale = v.clamp(0.75, 1.4);
    await _persist();
    notifyListeners();
  }

  Future<void> setGridColumns(int v) async {
    gridColumns = v.clamp(3, 6);
    await _persist();
    notifyListeners();
  }

  Future<void> renameApp(String id, String name) async {
    await applyAppearance(appearances.setName(id, name));
  }

  /// Store a MorphOS-only custom icon (base64). Empty clears override.
  Future<void> setAppIconOverride(String id, List<int>? bytes) async {
    if (bytes == null || bytes.isEmpty) {
      await applyAppearance(appearances.setIcon(id, null));
      return;
    }
    if (bytes.length > 200 * 1024) return;
    await applyAppearance(appearances.setIcon(id, base64Encode(bytes)));
  }

  Future<void> clearAppIconOverride(String id) async {
    await applyAppearance(appearances.setIcon(id, null));
  }

  /// Guided enable for system-wide rotation (Accessibility + WRITE_SETTINGS).
  ///
  /// Opens missing settings screens, then enables morph when both grants exist.
  /// Returns a short status string for UI snackbars.
  Future<String> ensureSystemMorphReady({bool openMissing = true}) async {
    await refreshSystemStatus();
    var s = systemStatus;
    if (!s.supported) {
      return 'System morph is Android-only.';
    }

    if (!s.canWriteSettings && openMissing) {
      await SystemMorphBridge.openWriteSettings();
      // Caller should re-invoke after resume; still continue status.
      await refreshSystemStatus();
      s = systemStatus;
    }
    if (!s.accessibilityRunning &&
        !(s.accessibilityEnabled) &&
        openMissing) {
      await SystemMorphBridge.openAccessibilitySettings();
      await refreshSystemStatus();
      s = systemStatus;
    }

    if (!s.canWriteSettings) {
      systemMorphEnabled = true; // user intent remembered
      await _persist();
      notifyListeners();
      return 'Grant “Modify system settings” for MorphOS, then return.';
    }
    if (!s.accessibilityRunning && !s.accessibilityEnabled) {
      systemMorphEnabled = true;
      await _persist();
      notifyListeners();
      return 'Enable “MorphOS System Morph” in Accessibility, then return.';
    }

    systemStatus = await SystemMorphBridge.setSystemMorphEnabled(true);
    systemMorphEnabled = true;
    await applyOrientation(force: true);
    await syncSystemMorph();
    await _persist();
    notifyListeners();

    final applied = await SystemMorphBridge.applyGlobalOrientationNow(
      profileId.systemOrientationMode,
    );
    if (applied) {
      return 'System morph ON · ${profileId.label} → '
          '${profileId.systemOrientationMode} (device-wide).';
    }
    return 'System morph enabled — waiting for WRITE_SETTINGS apply.';
  }

  /// Force current profile orientation onto the phone (if permissions ready).
  Future<bool> triggerSystemOrientationNow() async {
    await refreshSystemStatus();
    if (!systemStatus.canWriteSettings) return false;
    if (!systemMorphEnabled) {
      systemStatus = await SystemMorphBridge.setSystemMorphEnabled(true);
      systemMorphEnabled = true;
    }
    final ok = await SystemMorphBridge.applyGlobalOrientationNow(
      profileId.systemOrientationMode,
    );
    await syncSystemMorph();
    await refreshSystemStatus();
    notifyListeners();
    return ok;
  }

  /// Brief landscape pulse so the user can feel system rotation working.
  Future<String> testSystemRotation() async {
    await refreshSystemStatus();
    if (!systemStatus.canWriteSettings) {
      await SystemMorphBridge.openWriteSettings();
      return 'Need Modify system settings first.';
    }
    if (!systemStatus.accessibilityRunning &&
        !systemStatus.accessibilityEnabled) {
      await SystemMorphBridge.openAccessibilitySettings();
      return 'Enable MorphOS Accessibility service first.';
    }
    systemStatus = await SystemMorphBridge.setSystemMorphEnabled(true);
    systemMorphEnabled = true;
    final mode = await SystemMorphBridge.testRotationPulse();
    await refreshSystemStatus();
    await _persist();
    notifyListeners();
    return mode == null
        ? 'Test failed — check permissions.'
        : 'Test applied: $mode (device-wide).';
  }

  // ── Phase 5: Morph Store / Creator / community packs ──

  /// Install a store or community pack into the local library.
  Future<void> installPack(MorphPack pack) async {
    packLibrary = [
      ...packLibrary.where((p) => p.id != pack.id),
      pack,
    ];
    await _persist();
    notifyListeners();
  }

  Future<void> uninstallPack(String id) async {
    packLibrary = packLibrary.where((p) => p.id != id).toList();
    if (activePackId == id) activePackId = null;
    await _persist();
    notifyListeners();
  }

  /// Apply pack look onto its target profile and switch to that profile.
  Future<void> applyPack(
    MorphPack pack, {
    String reason = 'pack apply',
  }) async {
    environments[pack.targetProfile] = pack.toEnvironment();
    activePackId = pack.id;
    if (!isPackInstalled(pack.id)) {
      packLibrary = [...packLibrary, pack];
    }
    await applyProfile(pack.targetProfile, reason: '$reason:${pack.name}');
  }

  /// Morph Creator — capture current look as a new library pack.
  Future<MorphPack> createPackFromCurrent({
    required String name,
    String description = '',
    String author = 'me',
    List<String> tags = const [],
    MorphProfileId? bindProfile,
  }) async {
    final profile = bindProfile ?? profileId;
    final id =
        'user.${DateTime.now().millisecondsSinceEpoch}.${name.hashCode.abs()}';
    final pack = MorphPack(
      id: id,
      name: name.trim().isEmpty ? 'My Morph' : name.trim(),
      author: author.trim().isEmpty ? 'me' : author.trim(),
      description: description.trim(),
      category: 'community',
      themeId: themeId,
      wallpaperId: wallpaperId,
      layoutPortrait: layoutId,
      layoutLandscape: activeEnvironment.layoutLandscape,
      iconStyle: iconStyle,
      targetProfile: profile,
      showLabels: showLabels,
      iconScale: iconScale,
      gridColumns: gridColumns,
      dockIds: List<String>.from(dockIds),
      homeIds: List<String>.from(homeIds),
      quietMode: quietMode,
      largeTargets: largeTargets,
      tags: tags,
      version: 1,
      builtIn: false,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await installPack(pack);
    activePackId = pack.id;
    await _persist();
    notifyListeners();
    return pack;
  }

  /// Export one pack as shareable morphpack/v1 JSON.
  String exportPackJson(MorphPack pack) =>
      const JsonEncoder.withIndent('  ').convert(pack.toJson());

  /// Import pack from clipboard / community JSON.
  Future<MorphPack?> importPackJson(String raw) async {
    try {
      final decoded = jsonDecode(raw);
      Map<String, dynamic> map;
      if (decoded is Map) {
        map = Map<String, dynamic>.from(decoded);
      } else {
        return null;
      }
      // Allow wrapping: { "pack": { ... } }
      if (map['pack'] is Map) {
        map = Map<String, dynamic>.from(map['pack'] as Map);
      }
      final pack = MorphPack.fromJson({
        ...map,
        'builtIn': false,
        'category': map['category'] as String? ?? 'community',
        'id': map['id'] as String? ??
            'imported.${DateTime.now().millisecondsSinceEpoch}',
      });
      await installPack(pack);
      return pack;
    } catch (_) {
      return null;
    }
  }

  /// Unlock after first home frame. Launcher stays sensor — never landscape-lock.
  Future<void> unlockOrientationAfterFirstFrame() async {
    if (orientationUnlocked) return;
    orientationUnlocked = true;
    await applyOrientation(force: true);
  }

  /// Orientations for the MorphOS **home activity**.
  ///
  /// Profiles may prefer landscape, but applying that to the launcher
  /// flips the phone on every boot and restarts the activity (Loading…).
  List<DeviceOrientation> launcherPreferredOrientations() {
    if (!orientationUnlocked || !onboardingDone) {
      return const [DeviceOrientation.portraitUp];
    }
    if (rotationLocked || rotationAction != RotationAction.sensor) {
      return _orientationsFor(rotationAction);
    }
    return DeviceOrientation.values;
  }

  /// Apply orientation for the home activity only (not system USER_ROTATION).
  Future<void> applyOrientation({bool force = false}) async {
    try {
      if (!force && !onboardingDone) return;
      await SystemChrome.setPreferredOrientations(
        launcherPreferredOrientations(),
      );
    } catch (_) {
      // Ignore in unit tests / headless environments.
    }
  }

  static List<DeviceOrientation> _orientationsFor(RotationAction action) {
    return switch (action) {
      RotationAction.sensor => DeviceOrientation.values,
      RotationAction.portrait => const [DeviceOrientation.portraitUp],
      RotationAction.landscape => const [DeviceOrientation.landscapeLeft],
      RotationAction.reversePortrait => const [DeviceOrientation.portraitDown],
      RotationAction.reverseLandscape => const [
          DeviceOrientation.landscapeRight,
        ],
    };
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_prefsKeyLegacy);
    onboardingDone = false;
    setupFocus = 'entertainment';
    profileId = MorphProfileId.phone;
    for (final p in MorphProfileId.values) {
      environments[p] = MorphEnvironment.defaultsFor(p);
    }
    appRules = kDefaultAppMorphRules();
    contextRules = kDefaultContextRules();
    intelligenceMode = IntelligenceMode.beginner;
    pendingSuggestion = null;
    timeBasedMorph = false;
    perAppMorphEnabled = true;
    chargeMorphEnabled = true;
    categoryMorphEnabled = true;
    systemMorphEnabled = false;
    desktopModeEnabled = true;
    floatingWindowsEnabled = true;
    packLibrary = [];
    activePackId = null;
    platformModeEnabled = false;
    immersiveChrome = false;
    keepAwakeDesktop = true;
    bootRestoreEnabled = true;
    isCharging = false;
    profileBeforeCharge = null;
    lastMorphReason = null;
    loadError = null;
    morphGeneration = 0;
    orientationUnlocked = false;
    pointerConnected = false;
    keyboardConnected = false;
    final env = MorphEnvironment.defaultsFor(MorphProfileId.phone);
    themeId = env.themeId;
    layoutId = env.layoutPortrait;
    iconStyle = env.iconStyle;
    wallpaperId = env.wallpaperId;
    showLabels = env.showLabels;
    iconScale = env.iconScale;
    gridColumns = env.gridColumns;
    quietMode = env.quietMode;
    largeTargets = env.largeTargets;
    renames = {};
    iconOverridesB64 = {};
    customWallpaperPortraitB64 = null;
    customWallpaperLandscapeB64 = null;
    launcherSetupDismissed = false;
    migratedVerdantWallpaper = true;
    wallpaperId = WallpaperId.verdantEmerald;
    dockIds = List<String>.from(HomeOccupancy.defaultDemoDock);
    homeIds = List<String>.from(HomeOccupancy.defaultDemoHome);
    dockVisible = true;
    occupancySeeded = false;
    homeWidgets = const [];
    autoArrange = false;
    hiddenIds = const [];
    folders = const [];
    chromeFlags = const MorphChromeFlags();
    sidebar = const SidebarStrip();
    appearances = const AppAppearanceStore();
    starredAppIds = const [];
    launchCounts = {};
    rotationAction = RotationAction.sensor;
    rotationLocked = false;
    await applyOrientation();
    notifyListeners();
  }

  String exportJson() =>
      const JsonEncoder.withIndent('  ').convert(_stateMap());

  Future<bool> importJson(String raw) async {
    try {
      jsonDecode(raw); // validate JSON before overwriting prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, raw);
      ready = false;
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}
