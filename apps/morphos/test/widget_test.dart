import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:morphos/core/app_search.dart';
import 'package:morphos/core/home_nav.dart';
import 'package:morphos/core/image_customize.dart';
import 'package:morphos/core/models.dart';
import 'package:morphos/core/morph_controller.dart';
import 'package:morphos/core/morph_pack.dart';
import 'package:morphos/core/productivity.dart';
import 'package:morphos/core/system_morph_bridge.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('MorphEngine applyProfile switches pack', () async {
    final c = MorphController();
    await c.load();
    await c.applyProfile(MorphProfileId.gaming, reason: 'test');
    expect(c.profileId, MorphProfileId.gaming);
    expect(c.wallpaperId, WallpaperId.cyberpunk);
    expect(c.quietMode, isTrue);
    final morph = await c.morphForAppLaunch('maps');
    expect(morph, MorphProfileId.travel);
    expect(c.profileId, MorphProfileId.travel);
  });

  test('Phase3 category adaptive morph', () async {
    final c = MorphController();
    await c.load();
    c.categoryMorphEnabled = true;
    const app = MorphAppItem(
      id: 'com.example.netflix',
      label: 'Netflix',
      icon: Icons.movie_outlined,
      packageName: 'com.example.netflix',
      category: 'media',
      isSystemDemo: false,
    );
    final morph = await c.morphForAppLaunch(app.id, app: app);
    expect(morph, MorphProfileId.relax);
  });

  test('inferAppCategory heuristics', () {
    expect(
      inferAppCategory(
        name: 'Maps',
        packageName: 'com.google.android.apps.maps',
      ),
      'nav',
    );
    expect(
      inferAppCategory(name: 'Kindle', packageName: 'com.amazon.kindle'),
      'read',
    );
    expect(
      inferAppCategory(name: 'AnkiDroid', packageName: 'com.ichi2.anki'),
      'study',
    );
    expect(
      inferAppCategory(
        name: 'Google Translate',
        packageName: 'com.google.android.apps.translate',
      ),
      'travel',
    );
  });

  test('MorphEnvironment defaults cover all profiles', () {
    for (final p in MorphProfileId.values) {
      final e = MorphEnvironment.defaultsFor(p);
      expect(e.profileId, p);
      expect(e.dockIds, isNotEmpty);
      expect(p.shape.label, isNotEmpty);
    }
  });

  test('Vision: Study and Travel spaces exist', () async {
    final c = MorphController();
    await c.load();
    await c.applyProfile(MorphProfileId.study, reason: 'test');
    expect(c.profileId.shape, DeviceShape.studySpace);
    expect(c.quietMode, isTrue);
    await c.applyProfile(MorphProfileId.travel, reason: 'test');
    expect(c.profileId.shape, DeviceShape.travelSpace);
    expect(c.largeTargets, isTrue);
  });

  test('Intelligence Ask mode queues suggestion', () async {
    final c = MorphController();
    await c.load();
    await c.setIntelligenceMode(IntelligenceMode.ask);
    final applied = await c.morphForAppLaunch('store');
    expect(applied, isNull);
    expect(c.pendingSuggestion, isNotNull);
    expect(c.pendingSuggestion!.profileId, MorphProfileId.gaming);
    await c.acceptPendingSuggestion();
    expect(c.profileId, MorphProfileId.gaming);
    expect(c.pendingSuggestion, isNull);
  });

  test('Intelligence Advanced uses context category rules', () async {
    final c = MorphController();
    await c.load();
    await c.setIntelligenceMode(IntelligenceMode.advanced);
    await c.removeAppRule('store');
    const app = MorphAppItem(
      id: 'com.example.game',
      label: 'Some Game',
      icon: Icons.sports_esports,
      packageName: 'com.example.game',
      category: 'game',
      isSystemDemo: false,
    );
    final morph = await c.morphForAppLaunch(app.id, app: app);
    expect(morph, MorphProfileId.gaming);
  });

  test('Pocket Morph is default phone shape', () {
    expect(MorphProfileId.phone.label, 'Pocket Morph');
    expect(MorphProfileId.phone.shape, DeviceShape.pocket);
    expect(MorphProfileId.desktop.askPrompt, contains('desktop'));
  });

  test('Onboarding completes and seeds profile', () async {
    final c = MorphController();
    await c.load();
    await c.completeOnboarding('gaming');
    expect(c.onboardingDone, isTrue);
    expect(c.profileId, MorphProfileId.gaming);
  });

  test('Phase2+ system orientation modes map from profiles', () {
    expect(MorphProfileId.gaming.systemOrientationMode, 'landscape');
    expect(MorphProfileId.reading.systemOrientationMode, 'portrait');
    expect(MorphProfileId.phone.systemOrientationMode, 'sensor');
    expect(MorphProfileId.travel.systemOrientationMode, 'landscape');
    expect(MorphProfileId.study.systemOrientationMode, 'sensor');
  });

  test('Phase4 desktop shell flag and layout default', () async {
    final c = MorphController();
    await c.load();
    expect(c.desktopModeEnabled, isTrue);
    await c.applyProfile(MorphProfileId.desktop, reason: 'test');
    expect(c.showDesktopShell, isTrue);
    expect(
      MorphEnvironment.defaultsFor(MorphProfileId.desktop).layoutLandscape,
      MorphLayoutId.desktop,
    );
  });

  test('SystemMorphBridge rules skip demo ids', () {
    final rules = SystemMorphBridge.rulesFromAppMorph([
      const AppMorphRule(appId: 'maps', profileId: MorphProfileId.car),
      const AppMorphRule(
        appId: 'com.google.android.apps.maps',
        profileId: MorphProfileId.car,
      ),
    ]);
    expect(rules.containsKey('maps'), isFalse);
    expect(rules['com.google.android.apps.maps'], 'landscape');
  });

  test('Phase5 store catalog and applyPack', () async {
    final c = MorphController();
    await c.load();
    expect(c.storeCatalog, isNotEmpty);
    final pack = c.storeCatalog.first;
    await c.applyPack(pack, reason: 'test');
    expect(c.activePackId, pack.id);
    expect(c.isPackInstalled(pack.id), isTrue);
    expect(c.profileId, pack.targetProfile);
    expect(c.themeId, pack.themeId);
  });

  test('Phase5 creator + morphpack import export', () async {
    final c = MorphController();
    await c.load();
    await c.setTheme(MorphThemeId.light);
    final created = await c.createPackFromCurrent(
      name: 'My Study Mode',
      description: 'test',
      tags: ['study'],
      bindProfile: MorphProfileId.reading,
    );
    expect(created.name, 'My Study Mode');
    expect(c.packLibrary.any((p) => p.id == created.id), isTrue);
    final json = c.exportPackJson(created);
    expect(json, contains('morphpack/v1'));
    await c.uninstallPack(created.id);
    final imported = await c.importPackJson(json);
    expect(imported, isNotNull);
    expect(imported!.name, 'My Study Mode');
  });

  test('MorphPack fromJson is tolerant', () {
    final p = MorphPack.fromJson({
      'format': 'morphpack/v1',
      'id': 'x',
      'name': 'X',
      'author': 'a',
      'description': 'd',
      'category': 'mode',
      'themeId': 'neon',
      'wallpaperId': 'cyberpunk',
      'layoutPortrait': 'grid',
      'layoutLandscape': 'grid',
      'iconStyle': 'squircle',
      'targetProfile': 'phone',
    });
    expect(p.id, 'x');
    expect(p.toEnvironment().themeId, MorphThemeId.neon);
  });

  test('Phase6 platform mode flags persist defaults', () async {
    final c = MorphController();
    await c.load();
    expect(c.platformModeEnabled, isFalse);
    expect(c.bootRestoreEnabled, isTrue);
    expect(c.keepAwakeDesktop, isTrue);
    await c.setPlatformModeEnabled(true);
    expect(c.platformModeEnabled, isTrue);
    expect(c.immersiveChrome, isTrue);
    expect(c.systemStatus.platformScore, inInclusiveRange(0, 5));
  });

  test('Phone connection: rename + icon override persist in state', () async {
    final c = MorphController();
    await c.load();
    await c.renameApp('maps', 'Nav');
    expect(c.labelFor(const MorphAppItem(
      id: 'maps',
      label: 'Maps',
      icon: Icons.map,
    )), 'Nav');
    await c.setAppIconOverride('maps', [1, 2, 3, 4]);
    expect(c.iconOverridesB64.containsKey('maps'), isTrue);
    final decorated = c.displayApp(const MorphAppItem(
      id: 'maps',
      label: 'Maps',
      icon: Icons.map,
    ));
    expect(decorated.label, 'Nav');
    expect(decorated.iconBytes, isNotNull);
    await c.clearAppIconOverride('maps');
    expect(c.iconOverridesB64.containsKey('maps'), isFalse);
  });

  test('SystemMorphStatus readyForSystemMorph needs a11y + write', () {
    const notReady = SystemMorphStatus(
      systemMorphEnabled: true,
      accessibilityRunning: false,
      canWriteSettings: true,
      canDrawOverlays: false,
      globalOrientation: 'landscape',
    );
    expect(notReady.readyForSystemMorph, isFalse);
    const ready = SystemMorphStatus(
      systemMorphEnabled: true,
      accessibilityRunning: true,
      accessibilityEnabled: true,
      canWriteSettings: true,
      canDrawOverlays: false,
      globalOrientation: 'landscape',
    );
    expect(ready.readyForSystemMorph, isTrue);
  });

  // ── MorphOS 1.0.0: ranked search, productivity, customization ──

  test('Ranked app search: brave surfaces Brave label first', () {
    const brave = MorphAppItem(
      id: 'com.brave.browser',
      label: 'Brave',
      icon: Icons.public,
      packageName: 'com.brave.browser',
      isSystemDemo: false,
    );
    const chrome = MorphAppItem(
      id: 'com.android.chrome',
      label: 'Chrome',
      icon: Icons.public,
      packageName: 'com.android.chrome',
      isSystemDemo: false,
    );
    const other = MorphAppItem(
      id: 'com.example.bravado',
      label: 'Bravado Notes',
      icon: Icons.note,
      packageName: 'com.example.bravado',
      isSystemDemo: false,
    );
    const noise = MorphAppItem(
      id: 'com.noise.pkgbravehelper',
      label: 'System Helper',
      icon: Icons.settings,
      packageName: 'com.noise.pkgbravehelper',
      isSystemDemo: false,
    );

    final ranked = AppSearch.rank(
      [chrome, other, noise, brave],
      'brave',
    );
    expect(ranked, isNotEmpty);
    expect(ranked.first.label, 'Brave');
    expect(ranked.first.packageName, 'com.brave.browser');
    // Label match beats package-only noise
    expect(AppSearch.scoreApp(brave, 'brave'),
        greaterThan(AppSearch.scoreApp(noise, 'brave')));
  });

  test('Ranked search: empty query sorts A-Z by label', () {
    const a = MorphAppItem(id: 'z', label: 'Zulu', icon: Icons.abc);
    const b = MorphAppItem(id: 'a', label: 'Alpha', icon: Icons.abc);
    final ranked = AppSearch.rank([a, b], '');
    expect(ranked.first.label, 'Alpha');
  });

  test('BatterySnapshot mapping from raw plugin inputs', () {
    final charged = BatterySnapshot.fromRaw(level: 88, charging: true);
    expect(charged.level, 88);
    expect(charged.charging, isTrue);
    expect(charged.label, '⚡ 88%');
    expect(charged.iconKey, 'charging');

    final low = BatterySnapshot.fromRaw(level: 12, charging: false);
    expect(low.isLow, isTrue);
    expect(low.label, '12%');
    expect(low.iconKey, 'alert');

    final fromState = BatterySnapshot.fromRaw(
      level: 50,
      stateName: 'charging',
    );
    expect(fromState.charging, isTrue);

    final unknown = BatterySnapshot.fromRaw(stateName: 'unknown');
    expect(unknown.unknown, isTrue);
  });

  test('RotationAction cycles and maps modes', () {
    expect(RotationAction.sensor.next, RotationAction.portrait);
    expect(RotationAction.portrait.next, RotationAction.landscape);
    expect(RotationAction.landscape.next, RotationAction.reverseLandscape);
    expect(RotationAction.reverseLandscape.next, RotationAction.sensor);
    expect(RotationActionX.fromMode('landscape'), RotationAction.landscape);
    expect(RotationAction.portrait.mode, 'portrait');
    expect(RotationAction.sensor.shortLabel, 'AUTO');
  });

  test('Customization: icon override + dual wallpaper + icon scale persist',
      () async {
    SharedPreferences.setMockInitialValues({});
    final c = MorphController();
    await c.load();

    // Icon override from “cropped” payload
    final iconBytes = List<int>.generate(64, (i) => i % 256);
    await c.setAppIconOverride('com.brave.browser', iconBytes);
    expect(c.iconOverridesB64.containsKey('com.brave.browser'), isTrue);

    // Dual wallpapers
    final portrait = List<int>.generate(120, (i) => (i * 3) % 256);
    final landscape = List<int>.generate(140, (i) => (i * 7) % 256);
    await c.setCustomWallpapers(
      portraitBytes: portrait,
      landscapeBytes: landscape,
    );
    expect(c.customWallpaperPortraitBytes, portrait);
    expect(c.customWallpaperLandscapeBytes, landscape);
    expect(c.customWallpaperFor(landscape: false), portrait);
    expect(c.customWallpaperFor(landscape: true), landscape);

    // Icon size + grid columns
    await c.setIconScale(1.25);
    await c.setGridColumns(5);
    expect(c.iconScale, 1.25);
    expect(c.gridColumns, 5);

    // Reload from prefs — real persistence path
    final c2 = MorphController();
    await c2.load();
    expect(c2.iconOverridesB64['com.brave.browser'], isNotNull);
    expect(base64Decode(c2.iconOverridesB64['com.brave.browser']!), iconBytes);
    expect(c2.customWallpaperPortraitBytes, portrait);
    expect(c2.customWallpaperLandscapeBytes, landscape);
    expect(c2.iconScale, 1.25);
    expect(c2.gridColumns, 5);

    final decorated = c2.displayApp(const MorphAppItem(
      id: 'com.brave.browser',
      label: 'Brave',
      icon: Icons.public,
      packageName: 'com.brave.browser',
    ));
    expect(decorated.iconBytes, iconBytes);
  });

  test('ImageCustomize center-crops square icon from non-square image', () {
    // Build a 40x20 red image, crop to square, resize.
    final src = img.Image(width: 40, height: 20);
    img.fill(src, color: img.ColorRgb8(200, 40, 40));
    final png = img.encodePng(src);
    final out = ImageCustomize.cropIconSquare(png, maxSize: 16);
    expect(out, isNotNull);
    final decoded = img.decodeImage(out!);
    expect(decoded, isNotNull);
    expect(decoded!.width, decoded.height);
    expect(decoded.width, lessThanOrEqualTo(16));
    expect(ImageCustomize.isReasonableIconPayload(out), isTrue);
  });

  test('ImageCustomize prepares wallpaper under size budget', () {
    final src = img.Image(width: 80, height: 120);
    img.fill(src, color: img.ColorRgb8(20, 80, 180));
    final png = Uint8List.fromList(img.encodePng(src));
    final out = ImageCustomize.prepareWallpaper(png, maxLongEdge: 64);
    expect(out, isNotNull);
    expect(ImageCustomize.isReasonableWallpaperPayload(out!), isTrue);
    final decoded = img.decodeImage(out);
    expect(decoded, isNotNull);
    final long =
        decoded!.width > decoded.height ? decoded.width : decoded.height;
    expect(long, lessThanOrEqualTo(64));
  });

  test('Launcher setup dismiss flag persists', () async {
    final c = MorphController();
    await c.load();
    expect(c.launcherSetupDismissed, isFalse);
    await c.dismissLauncherSetup();
    expect(c.launcherSetupDismissed, isTrue);
    final c2 = MorphController();
    await c2.load();
    expect(c2.launcherSetupDismissed, isTrue);
  });

  // ── MorphOS 1.1.0: home-root launcher policy ──

  test('HomeNav: back at root moves task to back, not pop', () {
    expect(
      HomeNav.shouldMoveTaskToBack(
        navigatorCanPop: false,
        atMorphHomeRoot: true,
      ),
      isTrue,
    );
    expect(
      HomeNav.shouldMoveTaskToBack(
        navigatorCanPop: true,
        atMorphHomeRoot: true,
      ),
      isFalse,
    );
    expect(
      HomeNav.shouldMoveTaskToBack(
        navigatorCanPop: false,
        atMorphHomeRoot: false,
      ),
      isFalse,
    );
  });

  test('HomeNav: only HOME events force pop-to-root', () {
    expect(HomeNav.shouldPopToRoot('home'), isTrue);
    expect(HomeNav.shouldPopToRoot('launcher'), isFalse);
    expect(HomeNav.shouldPopToRoot('resume'), isFalse);
    expect(
      HomeNav.isHomeCategories(const [
        'android.intent.category.HOME',
        'android.intent.category.DEFAULT',
      ]),
      isTrue,
    );
    expect(
      HomeNav.isHomeCategories(const ['android.intent.category.LAUNCHER']),
      isFalse,
    );
  });

  test('HomeRoleResult maps system Home picker diagnostics', () {
    final r = HomeRoleResult.fromMap({
      'ok': true,
      'action': 'role_request',
      'message': 'Choose MorphOS',
      'isHomeCandidate': true,
      'isDefaultHome': false,
      'homeCandidateCount': 3,
      'homeCandidates': ['com.zibashu.morphos/.MainActivity'],
      'roleAvailable': true,
      'roleHeld': false,
    });
    expect(r.ok, isTrue);
    expect(r.action, 'role_request');
    expect(r.isHomeCandidate, isTrue);
    expect(r.homeCandidateCount, 3);
    expect(r.homeCandidates.first, contains('morphos'));
  });
}
