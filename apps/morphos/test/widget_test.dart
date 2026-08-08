import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphos/core/models.dart';
import 'package:morphos/core/morph_controller.dart';
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
}
