import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphos/core/models.dart';
import 'package:morphos/core/morph_controller.dart';
import 'package:morphos/core/morph_pack.dart';
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
}
