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
    expect(morph, MorphProfileId.car);
    expect(c.profileId, MorphProfileId.car);
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
      inferAppCategory(name: 'Maps', packageName: 'com.google.android.apps.maps'),
      'nav',
    );
    expect(
      inferAppCategory(name: 'Kindle', packageName: 'com.amazon.kindle'),
      'read',
    );
  });

  test('MorphEnvironment defaults cover all profiles', () {
    for (final p in MorphProfileId.values) {
      final e = MorphEnvironment.defaultsFor(p);
      expect(e.profileId, p);
      expect(e.dockIds, isNotEmpty);
    }
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
}
