import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'morph_pack.dart';
import 'morph_palette.dart';
import 'system_morph_bridge.dart';

/// Central MorphOS state — Phase 0–5 Morph Engine + ecosystem packs.
class MorphController extends ChangeNotifier {
  MorphController();

  static const _prefsKey = 'morphos_state_v2';
  static const _prefsKeyLegacy = 'morphos_state_v1';

  bool ready = false;
  bool onboardingDone = false;
  String setupFocus = 'entertainment';

  /// Manual / auto profile currently applied.
  MorphProfileId profileId = MorphProfileId.phone;

  /// Live visual state (mirrors active environment; editable in settings).
  MorphThemeId themeId = MorphThemeId.neon;
  MorphLayoutId layoutId = MorphLayoutId.grid;
  IconStyleId iconStyle = IconStyleId.squircle;
  WallpaperId wallpaperId = WallpaperId.cyberpunk;
  bool showLabels = true;
  double iconScale = 1.0;
  int gridColumns = 4;
  bool quietMode = false;
  bool largeTargets = false;

  Map<String, String> renames = {};
  List<String> dockIds = const [
    'browser',
    'messages',
    'music',
    'camera',
    'settings',
  ];
  List<String> homeIds = const [
    'browser',
    'music',
    'notes',
    'maps',
    'gallery',
    'mail',
    'clock',
    'store',
  ];

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

  String labelFor(MorphAppItem app) => renames[app.id] ?? app.label;

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
            WallpaperId.cyberpunk,
          );
          showLabels = m['showLabels'] as bool? ?? true;
          iconScale = (m['iconScale'] as num?)?.toDouble() ?? 1.0;
          gridColumns = m['gridColumns'] as int? ?? 4;
          quietMode = m['quietMode'] as bool? ?? false;
          largeTargets = m['largeTargets'] as bool? ?? false;
          renames = Map<String, String>.from(
            (m['renames'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? {},
          );
          dockIds = List<String>.from(m['dockIds'] as List? ?? dockIds);
          homeIds = List<String>.from(m['homeIds'] as List? ?? homeIds);
          timeBasedMorph = m['timeBasedMorph'] as bool? ?? false;
          perAppMorphEnabled = m['perAppMorphEnabled'] as bool? ?? true;
          chargeMorphEnabled = m['chargeMorphEnabled'] as bool? ?? true;
          categoryMorphEnabled = m['categoryMorphEnabled'] as bool? ?? true;
          systemMorphEnabled = m['systemMorphEnabled'] as bool? ?? false;
          desktopModeEnabled = m['desktopModeEnabled'] as bool? ?? true;
          floatingWindowsEnabled =
              m['floatingWindowsEnabled'] as bool? ?? true;
          activePackId = m['activePackId'] as String?;

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
    Future<void>.microtask(() async {
      try {
        await refreshSystemStatus();
        await syncSystemMorph();
      } catch (_) {}
    });
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
        'dockIds': dockIds,
        'homeIds': homeIds,
        'timeBasedMorph': timeBasedMorph,
        'perAppMorphEnabled': perAppMorphEnabled,
        'chargeMorphEnabled': chargeMorphEnabled,
        'categoryMorphEnabled': categoryMorphEnabled,
        'systemMorphEnabled': systemMorphEnabled,
        'desktopModeEnabled': desktopModeEnabled,
        'floatingWindowsEnabled': floatingWindowsEnabled,
        'activePackId': activePackId,
        'environments': {
          for (final e in environments.entries) e.key.name: e.value.toJson(),
        },
        'appRules': appRules.map((r) => r.toJson()).toList(),
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
    dockIds = List<String>.from(env.dockIds);
    homeIds = List<String>.from(env.homeIds);
    quietMode = env.quietMode;
    largeTargets = env.largeTargets;
    // Layout resolved live via [layoutForSize]; seed portrait default.
    layoutId = env.layoutPortrait;
    lastMorphReason = reason;
    morphGeneration++;
    // Only rotate when home has painted once (avoids black / width=0).
    await applyOrientation(force: false);
    if (orientationUnlocked) {
      unawaited(syncSystemMorph());
    }
    if (persist) await _persist();
    notifyListeners();
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

  /// Opening an app may switch morph (Phase 2 rules + Phase 3 category).
  Future<MorphProfileId?> morphForAppLaunch(
    String appId, {
    MorphAppItem? app,
  }) async {
    if (!perAppMorphEnabled) return null;

    // Explicit rules first (id or package).
    for (final r in appRules) {
      if (!r.enabled) continue;
      if (r.appId == appId ||
          (app?.packageName != null && r.appId == app!.packageName)) {
        if (r.profileId != profileId) {
          await applyProfile(
            r.profileId,
            reason: 'app-rule:${app?.label ?? appId}',
          );
        }
        return r.profileId;
      }
    }

    // Category heuristics for real / demo apps.
    if (categoryMorphEnabled) {
      final cat = app?.category ??
          inferAppCategory(name: app?.label ?? appId, packageName: appId);
      final next = profileForCategory(cat);
      if (next != null && next != profileId) {
        await applyProfile(
          next,
          reason: 'adaptive:category $cat → ${next.label}',
        );
        return next;
      }
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
    systemMorphEnabled = v;
    systemStatus = await SystemMorphBridge.setSystemMorphEnabled(v);
    await syncSystemMorph();
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

  /// Push active profile orientation + per-app rules to native layer.
  Future<void> syncSystemMorph() async {
    if (!SystemMorphBridge.isAndroid) return;
    try {
      if (systemMorphEnabled) {
        await SystemMorphBridge.setGlobalOrientation(
          profileId.systemOrientationMode,
        );
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
    final t = name.trim();
    if (t.isEmpty) {
      renames.remove(id);
    } else {
      renames[id] = t;
    }
    await _persist();
    notifyListeners();
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

  /// Unlock multi-orientation after first home frame with a valid size.
  Future<void> unlockOrientationAfterFirstFrame() async {
    if (orientationUnlocked) return;
    orientationUnlocked = true;
    await applyOrientation(force: true);
    unawaited(syncSystemMorph());
  }

  /// Apply orientation for active morph.
  /// Until [orientationUnlocked], always portrait (prevents black width=0 screen).
  Future<void> applyOrientation({bool force = false}) async {
    try {
      if (!orientationUnlocked || !onboardingDone) {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
        ]);
        return;
      }
      if (!force && !onboardingDone) return;
      await SystemChrome.setPreferredOrientations(profileId.orientations);
    } catch (_) {
      // Ignore in unit tests / headless environments.
    }
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
    timeBasedMorph = false;
    perAppMorphEnabled = true;
    chargeMorphEnabled = true;
    categoryMorphEnabled = true;
    systemMorphEnabled = false;
    desktopModeEnabled = true;
    floatingWindowsEnabled = true;
    packLibrary = [];
    activePackId = null;
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
    dockIds = List<String>.from(env.dockIds);
    homeIds = List<String>.from(env.homeIds);
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
