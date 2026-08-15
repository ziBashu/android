import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphos/core/app_library.dart';
import 'package:morphos/core/app_search.dart';
import 'package:morphos/core/home_occupancy.dart';
import 'package:morphos/core/launcher_listing.dart';
import 'package:morphos/core/models.dart';
import 'package:morphos/core/morph_controller.dart';
import 'package:morphos/core/notes_store.dart';
import 'package:morphos/core/productivity.dart';
import 'package:morphos/core/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('battery extras', () {
    test('ACTION_BATTERY_CHANGED extras map every required field', () {
      final charging = BatterySnapshot.fromBatteryChangedExtras({
        'level': 80,
        'scale': 100,
        'status': 2, // charging
        'plugged': 1, // AC
        'temperature': 314,
        'health': 2,
        'voltage': 4120,
        'technology': 'Li-ion',
      });
      expect(charging.level, 80);
      expect(charging.status, 'charging');
      expect(charging.statusLabel, 'charging');
      expect(charging.powerSource, 'ac');
      expect(charging.powerSourceLabel, 'AC');
      expect(charging.temperatureC, 31.4);
      expect(charging.health, 'good');
      expect(charging.voltageMv, 4120);
      expect(charging.technology, 'Li-ion');
      expect(charging.visualKey, 'charging');
      expect(charging.colorKey, 'teal');

      final usbDischarging = BatterySnapshot.fromBatteryChangedExtras({
        'level': 12,
        'scale': 100,
        'status': 3, // discharging
        'plugged': 2, // USB
        'temperature': 280,
        'health': 2,
        'voltage': 3800,
        'technology': 'Li-ion',
      });
      expect(usbDischarging.status, 'discharging');
      expect(usbDischarging.statusLabel, 'discharging');
      expect(usbDischarging.powerSourceLabel, 'USB');
      expect(usbDischarging.level, 12);
      expect(usbDischarging.visualKey, 'alert');
      expect(usbDischarging.colorKey, 'red');
      expect(usbDischarging.visualKey, isNot(charging.visualKey));
      expect(usbDischarging.colorKey, isNot(charging.colorKey));

      final mid = BatterySnapshot.fromBatteryChangedExtras({
        'level': 50,
        'scale': 100,
        'status': 3,
        'plugged': 0,
        'temperature': 300,
        'health': 2,
        'voltage': 3900,
        'technology': 'Li-polymer',
      });
      expect(mid.visualKey, 'mid');
      expect(mid.colorKey, 'amber');
      expect(mid.visualKey, isNot(usbDischarging.visualKey));
    });

    test('live EventChannel extras update snapshot on each delivery', () {
      final first = BatterySnapshot.applyChangedEvent({
        'level': 88,
        'scale': 100,
        'status': 2,
        'plugged': 1,
        'temperature': 310,
        'health': 2,
        'voltage': 4100,
        'technology': 'Li-ion',
      });
      expect(first.level, 88);
      expect(first.status, 'charging');
      expect(first.powerSourceLabel, 'AC');

      final second = BatterySnapshot.applyChangedEvent({
        'level': 40,
        'scale': 100,
        'status': 3,
        'plugged': 2,
        'temperature': 295,
        'health': 2,
        'voltage': 3850,
        'technology': 'Li-ion',
      });
      expect(second.level, 40);
      expect(second.status, 'discharging');
      expect(second.powerSourceLabel, 'USB');
      expect(second.level, isNot(first.level));
      expect(second.status, isNot(first.status));
      expect(second.visualKey, isNot(first.visualKey));

      final home = File('lib/features/home/home_screen.dart').readAsStringSync();
      expect(home.contains('batteryEventStream'), isTrue);
      expect(home.contains('applyChangedEvent'), isTrue);
      expect(
        File('lib/core/system_morph_bridge.dart')
            .readAsStringSync()
            .contains("EventChannel('com.zibashu.morphos/battery')"),
        isTrue,
      );
      expect(
        File(
          'android/app/src/main/kotlin/com/zibashu/morphos/MorphBatteryStream.kt',
        ).readAsStringSync().contains('ACTION_BATTERY_CHANGED'),
        isTrue,
      );
    });
  });

  group('rotation + lock', () {
    test('accepts auto portrait landscape reverse portrait reverse landscape', () {
      expect(RotationActionX.fromMode('sensor'), RotationAction.sensor);
      expect(RotationActionX.fromMode('portrait'), RotationAction.portrait);
      expect(RotationActionX.fromMode('landscape'), RotationAction.landscape);
      expect(
        RotationActionX.fromMode('reversePortrait'),
        RotationAction.reversePortrait,
      );
      expect(
        RotationActionX.fromMode('reverseLandscape'),
        RotationAction.reverseLandscape,
      );
      expect(RotationAction.sensor.mode, 'sensor');
      expect(RotationAction.reversePortrait.mode, 'reversePortrait');
    });

    test('lock flag blocks a subsequent slide-rotate', () {
      var control = const RotationControl(action: RotationAction.portrait);
      control = control.slideRotate();
      expect(control.action, RotationAction.landscape);
      expect(control.canSlideRotate, isTrue);
      control = control.lock();
      expect(control.locked, isTrue);
      final blocked = control.slideRotate();
      expect(blocked.action, RotationAction.landscape);
      expect(blocked.locked, isTrue);
      expect(identical(blocked.action, control.action), isTrue);
    });

    test('setRotationControl always applies sensor so Auto restores system rotate',
        () async {
      expect(
        RotationControl.systemModeToApply(
          const RotationControl(action: RotationAction.sensor),
        ),
        'sensor',
      );
      expect(
        RotationControl.systemModeToApply(
          const RotationControl(action: RotationAction.landscape),
        ),
        'landscape',
      );

      final c = MorphController();
      await c.load();
      await c.setRotationControl(
        const RotationControl(action: RotationAction.landscape),
      );
      expect(c.rotationAction, RotationAction.landscape);
      expect(c.lastAppliedOrientationMode, 'landscape');

      await c.setRotationControl(
        const RotationControl(action: RotationAction.sensor),
      );
      expect(c.rotationAction, RotationAction.sensor);
      expect(c.lastAppliedOrientationMode, 'sensor');
      expect(
        RotationControl.systemModeToApply(
          RotationControl(action: c.rotationAction, locked: c.rotationLocked),
        ),
        'sensor',
      );
    });

    test('home launcher never landscape-locks from a morph profile', () async {
      final c = MorphController();
      await c.load();
      await c.completeOnboarding('gaming');
      expect(c.profileId, MorphProfileId.gaming);
      expect(c.profileId.prefersLandscape, isTrue);
      expect(c.orientationUnlocked, isFalse);
      expect(
        c.launcherPreferredOrientations(),
        [DeviceOrientation.portraitUp],
      );
      await c.unlockOrientationAfterFirstFrame();
      expect(c.orientationUnlocked, isTrue);
      expect(
        c.launcherPreferredOrientations(),
        DeviceOrientation.values,
      );
      expect(c.lastAppliedOrientationMode, isNull);
      await c.applyProfile(MorphProfileId.desktop, reason: 'test');
      expect(
        c.launcherPreferredOrientations(),
        DeviceOrientation.values,
      );
      expect(c.lastAppliedOrientationMode, isNull);
    });
  });

  group('search index + stars', () {
    const brave = MorphAppItem(
      id: 'com.brave.browser',
      label: 'Brave',
      icon: Icons.public,
      packageName: 'com.brave.browser',
    );
    const chrome = MorphAppItem(
      id: 'com.android.chrome',
      label: 'Chrome',
      icon: Icons.public,
      packageName: 'com.android.chrome',
    );
    const wechat = MorphAppItem(
      id: 'com.tencent.mm',
      label: '微信',
      icon: Icons.chat,
      packageName: 'com.tencent.mm',
    );
    const notes = MorphAppItem(
      id: 'notes',
      label: 'Notes',
      icon: Icons.note,
    );

    test('Latin initials A-Z and non-Latin under *', () {
      expect(AppSearch.indexBucket('Brave'), 'B');
      expect(AppSearch.indexBucket('chrome'), 'C');
      expect(AppSearch.indexBucket('微信'), '*');
      expect(AppSearch.indexBucket('ノート'), '*');
      expect(AppSearch.indexBucket(''), '*');
      final buckets = AppSearch.bucketByIndex([brave, chrome, wechat, notes]);
      expect(buckets['B']!.single.label, 'Brave');
      expect(buckets['C']!.single.label, 'Chrome');
      expect(buckets['N']!.single.label, 'Notes');
      expect(buckets['*']!.single.label, '微信');
      expect(buckets.keys.first, '*');
    });

    test('starred ids sort above the rest', () {
      final ranked = AppSearch.rank(
        [chrome, wechat, brave],
        '',
        starredIds: ['com.tencent.mm'],
      );
      expect(ranked.first.label, '微信');
      expect(ranked.map((a) => a.label).toList(), ['微信', 'Brave', 'Chrome']);
    });
  });

  group('notes persist', () {
    test('exposes a writing path so notes are not launcher-owned', () {
      final store = NotesStore();
      expect(store.writingPath, contains('morphos_notes_v1'));
      expect(store.pathHelp.toLowerCase(), contains('home'));
      expect(store.pathHelp.toLowerCase(), contains('path'));
    });

    test('create edit list delete persist across a fresh load', () async {
      final store = NotesStore();
      await store.load();
      expect(store.notes, isEmpty);

      final created = await store.create(title: 'Buy milk', body: 'two litres');
      expect(store.notes, isNotEmpty);
      expect(store.notes.first.listLine, 'Buy milk');

      await store.edit(created.id, body: 'two litres + bread');
      expect(store.byId(created.id)!.body, 'two litres + bread');

      final untitled = await store.create(body: 'first line\nmore');
      expect(untitled.listLine, 'first line');

      final reload = NotesStore();
      await reload.load();
      expect(reload.notes.length, 2);
      expect(reload.byId(created.id)!.body, 'two litres + bread');
      expect(reload.byId(untitled.id)!.listLine, 'first line');

      expect(await reload.delete(created.id), isTrue);
      expect(reload.byId(created.id), isNull);

      final again = NotesStore();
      await again.load();
      expect(again.byId(created.id), isNull);
      expect(again.notes.single.id, untitled.id);
    });
  });

  group('occupancy', () {
    test('default occupancy is a small commonly-used set, not full catalog', () {
      final catalog = List<String>.generate(40, (i) => 'com.vendor.app$i');
      catalog.addAll([
        'com.android.chrome',
        'com.whatsapp',
        'com.google.android.apps.maps',
        'com.android.camera',
      ]);
      final occ = HomeOccupancy.seedCommon(
        catalogIds: catalog,
        labels: {
          'com.android.chrome': 'Chrome',
          'com.whatsapp': 'WhatsApp',
          'com.google.android.apps.maps': 'Maps',
          'com.android.camera': 'Camera',
        },
        packages: {for (final id in catalog) id: id},
      );
      expect(occ.homeIds.length, lessThanOrEqualTo(HomeOccupancy.maxDefaultHome));
      expect(occ.dockIds.length, lessThanOrEqualTo(HomeOccupancy.maxDefaultDock));
      expect(
        occ.homeIds.length + occ.dockIds.length,
        lessThan(catalog.length),
      );
      expect(occ.widgets, isEmpty);
      expect(HomeWidgetKind.values, contains(HomeWidgetKind.clock));
      expect(HomeWidgetKind.values, contains(HomeWidgetKind.webSearch));
      expect(HomeWidgetKind.values, contains(HomeWidgetKind.weather));
      final placed = {...occ.homeIds, ...occ.dockIds};
      expect(placed.length, lessThanOrEqualTo(10));
      expect(catalog.every(placed.contains), isFalse);

      final withMorph = HomeOccupancy.seedCommon(
        catalogIds: [...catalog, 'com.zibashu.morphos'],
        labels: {
          'com.android.chrome': 'Chrome',
          'com.zibashu.morphos': 'MorphOS',
        },
        packages: {
          for (final id in catalog) id: id,
          'com.zibashu.morphos': 'com.zibashu.morphos',
        },
      );
      expect(withMorph.dockIds.first, 'com.zibashu.morphos');
    });

    test('addToHome places an unused catalog id on the page', () async {
      const occ = HomeOccupancy(
        homeIds: ['mail'],
        dockIds: ['chrome'],
        seeded: true,
      );
      final added = occ.addToHome('maps');
      expect(added.homeIds, containsAll(['mail', 'maps']));
      expect(added.dockIds, ['chrome']);
      expect(occ.addToHome('mail').homeIds, ['mail']);

      final c = MorphController();
      await c.load();
      await c.applyOccupancy(
        const HomeOccupancy(homeIds: ['mail'], dockIds: ['chrome'], seeded: true),
      );
      expect(await c.addToHome('maps'), isTrue);
      expect(c.homeIds, contains('maps'));
      expect(await c.addToHome('chrome'), isFalse);
    });

    test('delete all removes occupancy without uninstalling', () {
      const occ = HomeOccupancy(
        homeIds: ['a', 'b', 'c'],
        dockIds: ['d'],
        seeded: true,
      );
      final cleared = occ.deleteAllOnPage();
      expect(cleared.homeIds, isEmpty);
      expect(cleared.dockIds, ['d']);
      // No uninstall side-channel — packages stay installed.
      expect(cleared.toJson().containsKey('uninstalled'), isFalse);
    });

    test('dock hide returns those ids to the home page', () {
      const occ = HomeOccupancy(
        homeIds: ['mail'],
        dockIds: ['chrome', 'camera'],
        dockVisible: true,
        seeded: true,
      );
      final hidden = occ.hideDock();
      expect(hidden.dockVisible, isFalse);
      expect(hidden.dockIds, isEmpty);
      expect(hidden.homeIds, containsAll(['chrome', 'camera', 'mail']));
      expect(hidden.homeIds.first, 'chrome');
    });

    test('minus-menu choices distinguish home-remove vs uninstall', () {
      expect(IconMinusMenu.choices, [
        'Delete from Home screen',
        'Delete application',
        'Cancel',
      ]);
      expect(IconMinusMenu.isHomeRemove(IconMinusMenu.deleteFromHomeScreen),
          isTrue);
      expect(IconMinusMenu.isUninstall(IconMinusMenu.deleteApplication), isTrue);
      expect(IconMinusMenu.isCancel(IconMinusMenu.cancel), isTrue);
      expect(IconMinusMenu.isUninstall(IconMinusMenu.deleteFromHomeScreen),
          isFalse);
      expect(IconMinusMenu.isHomeRemove(IconMinusMenu.deleteApplication),
          isFalse);
    });

    test('minus Delete from Home drops dock icon without moving it to home',
        () async {
      const occ = HomeOccupancy(
        homeIds: ['mail'],
        dockIds: ['chrome', 'camera'],
        dockVisible: true,
        seeded: true,
      );
      final gone = occ.removeFromLauncher('chrome');
      expect(gone.dockIds, ['camera']);
      expect(gone.homeIds, ['mail']);
      expect(gone.homeIds.contains('chrome'), isFalse);
      expect(gone.dockIds.contains('chrome'), isFalse);

      final viaMinus = HomeMinusAction.apply(
        occupancy: occ,
        choice: IconMinusMenu.deleteFromHomeScreen,
        id: 'chrome',
        packageName: 'com.android.chrome',
      );
      expect(viaMinus.homeIds.contains('chrome'), isFalse);
      expect(viaMinus.dockIds.contains('chrome'), isFalse);
      expect(viaMinus.homeIds, ['mail']);

      final c = MorphController();
      await c.load();
      await c.applyOccupancy(
        const HomeOccupancy(
          homeIds: ['mail'],
          dockIds: ['chrome', 'camera'],
          seeded: true,
        ),
      );
      await c.applyMinusChoice(
        IconMinusMenu.deleteFromHomeScreen,
        'chrome',
        packageName: 'com.android.chrome',
      );
      expect(c.dockIds.contains('chrome'), isFalse);
      expect(c.homeIds.contains('chrome'), isFalse);
      expect(c.homeIds, ['mail']);
      expect(c.dockIds, ['camera']);

      final home =
          File('lib/features/home/home_screen.dart').readAsStringSync();
      expect(home.contains('applyMinusChoice'), isTrue);
      expect(
        home.contains('await c.removeFromDock(app.id)'),
        isFalse,
      );
    });
  });

  group('controller occupancy persist', () {
    test('seed + delete-all + dock hide persist on reload', () async {
      final c = MorphController();
      await c.load();
      final catalog = [
        for (var i = 0; i < 30; i++) 'com.vendor.app$i',
        'com.android.chrome',
      ];
      await c.seedOccupancyIfNeeded(
        catalogIds: catalog,
        labels: {'com.android.chrome': 'Chrome'},
        packages: {for (final id in catalog) id: id},
      );
      expect(c.occupancySeeded, isTrue);
      expect(c.homeIds.length + c.dockIds.length, lessThan(catalog.length));
      expect(c.homeWidgets, isEmpty);

      await c.deleteAllHomeApps();
      expect(c.homeIds, isEmpty);

      await c.applyOccupancy(
        HomeOccupancy(
          homeIds: const ['keep'],
          dockIds: const ['dock.a', 'dock.b'],
          dockVisible: true,
          seeded: true,
        ),
      );
      await c.setDockVisible(false);
      expect(c.dockVisible, isFalse);
      expect(c.homeIds, containsAll(['dock.a', 'dock.b', 'keep']));

      final c2 = MorphController();
      await c2.load();
      expect(c2.occupancySeeded, isTrue);
      expect(c2.dockVisible, isFalse);
      expect(c2.homeIds, containsAll(['dock.a', 'dock.b', 'keep']));
      expect(c2.homeWidgets, isEmpty);
    });
  });

  group('launcher listing', () {
    test('keeps non-English labels and MorphOS itself', () {
      final apps = LauncherListing.fromRows([
        {'packageName': 'com.tencent.mm', 'label': '微信'},
        {'packageName': 'jp.naver.line.android', 'label': 'LINE'},
        {'packageName': 'com.android.chrome', 'label': 'Chrome'},
        {'packageName': 'com.hidden.empty', 'label': ''},
      ]);
      expect(apps.any((a) => a.label == '微信'), isTrue);
      expect(apps.any((a) => a.label == 'LINE'), isTrue);
      expect(
        apps.any((a) => a.id == 'com.hidden.empty' && a.label == 'empty'),
        isTrue,
      );
      expect(
        apps.any((a) => a.id == LauncherListing.morphosPackage),
        isTrue,
      );
    });
  });

  group('app library groups', () {
    test('right-page folders include suggestions and categories', () {
      const mail = MorphAppItem(
        id: 'com.google.android.gm',
        label: 'Gmail',
        icon: Icons.mail,
        category: 'work',
      );
      const cam = MorphAppItem(
        id: 'cam',
        label: 'Camera',
        icon: Icons.camera,
        category: 'media',
      );
      final folders = AppLibrary.group(
        [mail, cam],
        starredIds: ['com.google.android.gm'],
      );
      expect(folders.containsKey(AppLibrary.suggestions), isTrue);
      expect(folders[AppLibrary.suggestions]!.first.id, mail.id);
      expect(folders['Productivity'], isNotNull);
      expect(folders['Photos & Images'], isNotNull);
    });
  });

  group('weather parse', () {
    test('Open-Meteo current block maps temperature and WMO code', () {
      final snap = WeatherSnapshot.fromOpenMeteo({
        'latitude': 1.3,
        'longitude': 103.8,
        'current': {
          'temperature_2m': 29.4,
          'weather_code': 61,
          'wind_speed_10m': 12.0,
        },
      }, place: 'Singapore');
      expect(snap, isNotNull);
      expect(snap!.temperatureC, closeTo(29.4, 0.01));
      expect(snap.condition, 'Rain');
      expect(snap.tempLabel, '29°');
      expect(snap.place, 'Singapore');
    });
  });

  test('shipped home / MorphOS app / edit surfaces match the launcher contract',
      () {
    final home = File('lib/features/home/home_screen.dart').readAsStringSync();
    final settings =
        File('lib/features/settings/settings_screen.dart').readAsStringSync();
    final customize =
        File('lib/features/home/customize_home.dart').readAsStringSync();
    final minus =
        File('lib/features/home/icon_minus_sheet.dart').readAsStringSync();
    final library =
        File('lib/features/home/app_library_page.dart').readAsStringSync();

    expect(home.contains('ProductivityStrip'), isFalse);
    expect(home.contains('Adaptive workspace'), isFalse);
    expect(home.contains('Search apps'), isFalse);
    expect(home.contains('cycleProfile'), isFalse);
    expect(home.contains('SmallSearchPill'), isTrue);
    expect(home.contains('AppLibraryPage'), isTrue);
    expect(home.contains('GlassDock'), isTrue);
    expect(home.contains('Add Widget'), isFalse); // menu lives in customize
    expect(home.contains('_buildClock'), isFalse);
    expect(home.contains('fromLibrary: true'), isTrue);
    expect(home.contains('showAddAppSheet'), isTrue);
    expect(home.contains('ClockHomeWidget'), isFalse);

    expect(customize.contains('Add Widget'), isTrue);
    expect(customize.contains('Add App'), isTrue);
    expect(customize.contains('Customize Theme'), isTrue);
    expect(customize.contains('Edit Wallpaper'), isTrue);
    expect(customize.contains('Browser search'), isFalse); // labels via enum
    expect(File('lib/widgets/home_widgets.dart').readAsStringSync(),
        contains('ClockHomeWidget'));
    expect(File('lib/widgets/home_widgets.dart').readAsStringSync(),
        contains('WebSearchHomeWidget'));
    expect(File('lib/widgets/home_widgets.dart').readAsStringSync(),
        contains('WeatherHomeWidget'));

    expect(minus.contains('IconMinusMenu.deleteFromHomeScreen'), isTrue);
    expect(minus.contains('IconMinusMenu.deleteApplication'), isTrue);
    expect(minus.contains('IconMinusMenu.cancel'), isTrue);

    expect(settings.contains('Home widgets'), isTrue);
    expect(settings.contains('HomeWidgetKind.values'), isTrue);
    expect(settings.contains('toggleHomeWidget'), isTrue);

    expect(library.contains('App Library'), isTrue);
    expect(library.contains('onOpenApp'), isTrue);
    expect(library.contains('_minusOn'), isFalse);
    expect(library.contains('fromLibrary'), isFalse);
    expect(home.contains('setSystemWallpaper'), isFalse);
    expect(
      File('lib/core/morph_controller.dart').readAsStringSync().contains(
            'pushSystemWallpaper',
          ),
      isTrue,
    );
  });
}
