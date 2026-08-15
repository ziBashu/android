import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphos/core/app_appearance.dart';
import 'package:morphos/core/chrome_flags.dart';
import 'package:morphos/core/home_gestures.dart';
import 'package:morphos/core/home_grid_pack.dart';
import 'package:morphos/core/home_occupancy.dart';
import 'package:morphos/core/morph_controller.dart';
import 'package:morphos/core/shade_tiles.dart';
import 'package:morphos/core/smart_island.dart';
import 'package:morphos/features/home/home_screen.dart';
import 'package:morphos/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('first-level icon menu', () {
    test('core choices are App info / Select / Hide / Remove / Edit Homescreen',
        () {
      final first = IconActionMenu.firstLevel(id: 'maps', label: 'Maps');
      expect(first, containsAll(IconActionMenu.coreChoices));
      expect(first, contains('App info'));
      expect(first, contains('Select'));
      expect(first, contains('Hide'));
      expect(first, contains('Remove'));
      expect(first, contains('Edit Homescreen'));
      expect(IconActionMenu.firstLevelContainsForbidden(first), isFalse);
      expect(first, isNot(contains('Delete')));
      expect(first, isNot(contains('Cancel')));
      expect(first, isNot(contains(IconActionMenu.deleteFromHomeScreen)));
      expect(first, isNot(contains(IconActionMenu.deleteApplication)));
    });

    test('Remove cascade is home-remove vs Delete application vs Cancel', () {
      expect(IconActionMenu.removeCascade, [
        IconActionMenu.deleteFromHomeScreen,
        IconActionMenu.deleteApplication,
        IconActionMenu.cancel,
      ]);
      const occ = HomeOccupancy(
        homeIds: ['mail', 'maps'],
        dockIds: ['chrome'],
        seeded: true,
      );
      final homeDrop = HomeMinusAction.apply(
        occupancy: occ,
        choice: IconActionMenu.deleteFromHomeScreen,
        id: 'maps',
      );
      expect(homeDrop.homeIds.contains('maps'), isFalse);
      expect(homeDrop.dockIds, ['chrome']);
      expect(homeDrop.homeIds, contains('mail'));
      // Home-remove does not uninstall — no side channel.
      expect(homeDrop.toJson().containsKey('uninstalled'), isFalse);

      final cancel = HomeMinusAction.apply(
        occupancy: occ,
        choice: IconActionMenu.cancel,
        id: 'maps',
      );
      expect(cancel.homeIds, occ.homeIds);

      final uninstallChoice = HomeMinusAction.apply(
        occupancy: occ,
        choice: IconActionMenu.deleteApplication,
        id: 'maps',
      );
      expect(uninstallChoice.homeIds, occ.homeIds);
    });

    test('Settings / Browser / Gmail extras', () {
      expect(
        IconActionMenu.extrasFor(
          id: 'settings',
          packageName: 'com.android.settings',
          label: 'Settings',
        ),
        contains('WLAN'),
      );
      expect(
        IconActionMenu.extrasFor(
          id: 'browser',
          packageName: 'com.android.chrome',
          label: 'Chrome',
        ),
        containsAll(['New Tab', 'Private Tab']),
      );
      expect(
        IconActionMenu.extrasFor(
          id: 'com.google.android.gm',
          packageName: 'com.google.android.gm',
          label: 'Gmail',
        ),
        containsAll(['Compose', 'Account']),
      );
      final settings = IconActionMenu.firstLevel(
        id: 'settings',
        packageName: 'com.android.settings',
        label: 'Settings',
      );
      expect(settings, contains('WLAN'));
      expect(IconActionMenu.firstLevelContainsForbidden(settings), isFalse);
    });
  });

  group('select / hide / voids / folders', () {
    test('auto-arrange off (default): remove leaves a void at that index', () {
      const occ = HomeOccupancy(
        homeIds: ['mail', 'maps', 'notes'],
        dockIds: ['chrome'],
        seeded: true,
      );
      expect(occ.autoArrange, isFalse);
      final gone = occ.removeFromHome('maps');
      expect(gone.homeIds, ['mail', HomeOccupancy.voidSlot, 'notes']);
      expect(gone.homeIds[1], isEmpty);
      expect(gone.homeIds.length, 3);

      final compacted = occ.setAutoArrange(true).removeFromHome('maps');
      expect(compacted.autoArrange, isTrue);
      expect(compacted.homeIds, ['mail', 'notes']);
      expect(compacted.homeIds.contains(HomeOccupancy.voidSlot), isFalse);
    });

    test('Select several ids can drop them or fold into a named folder', () {
      const occ = HomeOccupancy(
        homeIds: ['mail', 'maps', 'notes', 'camera'],
        dockIds: [],
        seeded: true,
      );
      final dropped = occ.removeSelection(['mail', 'notes']);
      expect(dropped.homeIds[0], isEmpty);
      expect(dropped.homeIds[2], isEmpty);
      expect(dropped.homeIds.contains('maps'), isTrue);

      final foldered = occ.foldSelection(['mail', 'maps', 'notes'], 'Work');
      expect(foldered.folders, isNotEmpty);
      expect(foldered.folders.single.name, 'Work');
      expect(foldered.folders.single.appIds, ['mail', 'maps', 'notes']);
      expect(HomeFolder.isSlot(foldered.homeIds.first), isTrue);
      expect(foldered.folderForSlot(foldered.homeIds.first)?.name, 'Work');
    });

    test('Hide drops occupancy and records hidden id', () {
      const occ = HomeOccupancy(
        homeIds: ['mail', 'maps'],
        dockIds: ['chrome'],
        seeded: true,
      );
      final hidden = occ.hideApp('maps');
      expect(hidden.hiddenIds, contains('maps'));
      expect(hidden.homeIds.contains('maps'), isFalse);
    });

    test('rearrange moves apps and widgets', () {
      const occ = HomeOccupancy(
        homeIds: ['a', 'b', 'c'],
        dockIds: [],
        widgets: [HomeWidgetKind.clock, HomeWidgetKind.weather],
        seeded: true,
      );
      expect(occ.moveHomeSlot(0, 2).homeIds, ['b', 'c', 'a']);
      expect(
        occ.moveWidget(0, 1).widgets,
        [HomeWidgetKind.weather, HomeWidgetKind.clock],
      );
    });

    test('widgets occupy multiple app cells and live on the board', () {
      expect(HomeWidgetKind.clock.colSpan, greaterThan(1));
      expect(HomeWidgetKind.clock.rowSpan, greaterThan(1));
      expect(HomeWidgetKind.weather.colSpan, 2);
      expect(HomeWidgetKind.weather.rowSpan, 2);
      const empty = HomeOccupancy(homeIds: ['mail'], dockIds: [], seeded: true);
      final withClock = empty.addWidget(HomeWidgetKind.clock);
      expect(withClock.homeIds, contains(HomeWidgetKind.clock.slotId));
      final packed = HomeGridPack.pack(withClock.homeIds, 4);
      final clockCell = packed.firstWhere((c) => c.id == HomeWidgetKind.clock.slotId);
      expect(clockCell.cellCount, greaterThanOrEqualTo(4));
      expect(clockCell.colSpan * clockCell.rowSpan, HomeWidgetKind.clock.colSpan.clamp(1, 4) * HomeWidgetKind.clock.rowSpan);
    });
  });

  group('chrome flags', () {
    test('sidebar / notification bar / island each independently disable', () {
      var flags = const MorphChromeFlags();
      expect(flags.sidebar, isTrue);
      expect(flags.notificationBar, isTrue);
      expect(flags.smartIsland, isTrue);
      flags = flags.setEnabled(MorphChromeLayer.sidebar, false);
      expect(flags.usesSystemSidebar, isTrue);
      expect(flags.notificationBar, isTrue);
      expect(flags.smartIsland, isTrue);
      flags = flags.setEnabled(MorphChromeLayer.notificationBar, false);
      expect(flags.usesSystemNotificationBar, isTrue);
      expect(flags.sidebar, isFalse);
      flags = flags.setEnabled(MorphChromeLayer.smartIsland, false);
      expect(flags.usesSystemIsland, isTrue);
      expect(flags.notificationBar, isFalse);
    });

    test('chrome sync payload keeps shortcuts when a flag flips', () async {
      const strip = SidebarStrip(shortcutIds: ['chrome', 'camera']);
      final payload = const MorphChromeFlags(smartIsland: false).toSyncJson(strip);
      expect(payload['shortcuts'], ['chrome', 'camera']);
      expect(payload['smartIsland'], isFalse);
      expect(payload['sidebar'], isTrue);
      expect(payload['notificationBar'], isTrue);

      final c = MorphController();
      await c.load();
      await c.setSidebar(const SidebarStrip(shortcutIds: ['chrome', 'maps']));
      expect(c.chromeSyncPayload()['shortcuts'], ['chrome', 'maps']);
      await c.setChromeLayer(MorphChromeLayer.notificationBar, false);
      expect(c.chromeFlags.notificationBar, isFalse);
      expect(c.chromeSyncPayload()['shortcuts'], ['chrome', 'maps']);
      expect(c.chromeSyncPayload()['notificationBar'], isFalse);
      expect(
        File('lib/core/morph_controller.dart').readAsStringSync(),
        contains('syncChrome(chromeSyncPayload())'),
      );
      expect(
        File('lib/core/morph_controller.dart').readAsStringSync(),
        isNot(contains('syncChrome(flags.toJson())')),
      );
    });
  });

  group('home gestures', () {
    test('edit mode disables icon long-press so drag can start', () {
      expect(HomeGestures.iconLongPressEnabled(editing: false), isTrue);
      expect(HomeGestures.iconLongPressEnabled(editing: true), isFalse);
      expect(
        HomeGestures.parentWallpaperLongPress(editing: true, selecting: false),
        isFalse,
      );
      expect(
        HomeGestures.gridScrollEnabled(editing: true),
        isFalse,
      );
      final home = File('lib/features/home/home_screen.dart').readAsStringSync();
      expect(home, contains('HomeGestures.iconLongPressEnabled'));
      expect(home, contains('HomeGestures.parentWallpaperLongPress'));
      expect(
        File('lib/widgets/home_mixed_grid.dart').readAsStringSync(),
        contains('NeverScrollableScrollPhysics'),
      );
      expect(home, contains('ignoreInnerGestures'));
      expect(home, contains('HomeMixedGrid'));
      expect(home, isNot(contains('Rotation locked')));
      expect(home, contains('dockVisible: c.dockVisible'));
    });

    test('swipe-down intercepts only when Morph notification bar is on', () {
      expect(
        HomeGestures.interceptSwipeDown(notificationBar: true),
        isTrue,
      );
      expect(
        HomeGestures.interceptSwipeDown(notificationBar: false),
        isFalse,
      );
      expect(
        HomeGestures.openShadeFromTopPull(
          notificationBar: true,
          primaryVelocity: 400,
        ),
        isTrue,
      );
      expect(
        HomeGestures.openShadeFromTopPull(
          notificationBar: false,
          primaryVelocity: 400,
        ),
        isFalse,
      );
      final home = File('lib/features/home/home_screen.dart').readAsStringSync();
      expect(home, contains('HomeGestures.openShadeFromTopPull'));
      expect(home, contains('_topChrome'));
      expect(home, contains('SmartIslandPill'));
      expect(home, isNot(contains('showMorphControlCenter')));
      expect(
        File('lib/features/morph/morph_shade.dart').readAsStringSync(),
        contains('showGeneralDialog'),
      );
      expect(
        File('lib/features/morph/morph_shade.dart').readAsStringSync(),
        contains('Alignment.topCenter'),
      );
    });

    test('sidebar handle is a short line and can add apps', () {
      expect(HomeGestures.sidebarHandleHeight, lessThan(50));
      expect(HomeGestures.sidebarHandleWidth, lessThan(12));
      final snapped = SidebarPlacement.fromPoint(10, 200, 400, 800);
      expect(snapped.rim, ScreenRim.left);
      expect(HomeGestures.islandIdleHeight, greaterThanOrEqualTo(32));
      final side = File('lib/widgets/sidebar_edge.dart').readAsStringSync();
      expect(side, contains('HomeGestures.sidebarHandleHeight'));
      expect(side, contains('onAdd'));
      expect(side, contains('Add app'));
      expect(side, isNot(contains('double.infinity')));
      final home = File('lib/features/home/home_screen.dart').readAsStringSync();
      expect(home, contains('showSidebarAppSheet'));
    });
  });

  group('shade tiles', () {
    test('first page is 8–10 essentials; rest after expand; tiles carry state',
        () {
      final first = ShadeLayout.firstPage();
      expect(first.length, inInclusiveRange(8, 10));
      expect(first.length, 10);
      final extra = ShadeLayout.expandedPage();
      expect(extra, isNotEmpty);
      expect(first.toSet().intersection(extra.toSet()), isEmpty);
      expect(
        {...first, ...extra},
        ShadeLayout.essentials.toSet(),
      );
      for (final id in first) {
        expect(ShadeLayout.essentials, contains(id));
      }
      final snap = ShadeSnapshot(
        now: DateTime(2026, 8, 15, 8, 42),
        batteryPercent: 82,
        tiles: [
          const ShadeTileView(id: ShadeTileId.wifi, on: true, detail: 'Home'),
          const ShadeTileView(id: ShadeTileId.mobile, on: true, detail: '5G'),
          for (final id in ShadeTileId.values)
            if (id != ShadeTileId.wifi && id != ShadeTileId.mobile)
              ShadeTileView(id: id, on: false),
        ],
      );
      expect(snap.firstPageTiles.length, inInclusiveRange(8, 10));
      expect(snap.firstPageTiles.first.id, ShadeTileId.wifi);
      expect(snap.firstPageTiles.first.on, isTrue);
      expect(snap.firstPageTiles.first.stateLabel, 'ON');
      expect(snap.firstPageTiles.first.detail, 'Home');
      expect(snap.extraTiles, isNotEmpty);
      expect(snap.expanded, isFalse);
      expect(snap.expand().expanded, isTrue);
    });
  });

  group('smart island', () {
    test('compact + expand for every live kind; music has seek + transport',
        () {
      final kinds = <IslandActivity>[
        IslandActivity.music(title: 'Midnight City', artist: 'M83'),
        IslandActivity.timer(remaining: '02:41'),
        IslandActivity.download(progress: 0.67),
        IslandActivity.navigation(instruction: 'Turn right', distance: '300 m'),
        IslandActivity.call(name: 'Mom', elapsed: '02:31'),
        IslandActivity.recording(elapsed: '03:12'),
      ];
      for (final a in kinds) {
        expect(a.isIdle, isFalse);
        expect(a.expanded, isFalse);
        final open = a.expand();
        expect(open.expanded, isTrue);
        expect(open.kind, a.kind);
        expect(open.compact().expanded, isFalse);
        expect(open.compactLabel, isNotEmpty);
      }
      final music = IslandActivity.music(title: 'Midnight City').expand();
      expect(music.expandControls, containsAll(['seek', 'previous', 'pause', 'next']));
      expect(IslandActivity.musicTransport, contains('seek'));
      expect(IslandActivity.idle.expand().isIdle, isTrue);
      expect(IslandActivity.idle.expand().expanded, isTrue);
    });
  });

  group('app appearance', () {
    test('name / icon / size / hide name', () {
      var store = const AppAppearanceStore();
      store = store.setName('maps', 'Nav');
      store = store.setSize('maps', 1.3);
      store = store.setHideName('maps', true);
      store = store.setIcon('maps', 'abc');
      expect(store.displayName('maps', 'Maps'), 'Nav');
      expect(store.hideName('maps'), isTrue);
      expect(store.sizeScale('maps'), closeTo(1.3, 0.01));
      expect(store.of('maps').iconB64, 'abc');
    });
  });

  test('controller persists occupancy chrome and auto-arrange default off',
      () async {
    final c = MorphController();
    await c.load();
    expect(c.autoArrange, isFalse);
    expect(c.chromeFlags.sidebar, isTrue);
    await c.applyOccupancy(
      const HomeOccupancy(
        homeIds: ['mail', 'maps', 'notes'],
        dockIds: ['chrome'],
        seeded: true,
      ),
    );
    await c.hideApp('maps');
    expect(c.hiddenIds, contains('maps'));
    expect(c.homeIds.contains('maps'), isFalse);
    await c.setAutoArrange(false);
    await c.applyOccupancy(
      HomeOccupancy(
        homeIds: const ['mail', 'maps'],
        dockIds: [],
        seeded: true,
        autoArrange: false,
      ),
    );
    await c.removeFromHome('maps');
    expect(c.homeIds[1], isEmpty);
    await c.setChromeLayer(MorphChromeLayer.smartIsland, false);
    expect(c.chromeFlags.usesSystemIsland, isTrue);

    final c2 = MorphController();
    await c2.load();
    expect(c2.chromeFlags.smartIsland, isFalse);
    expect(c2.autoArrange, isFalse);
  });

  test('shipped surfaces name the new first-level menu and chrome toggles', () {
    final action =
        File('lib/features/home/icon_action_sheet.dart').readAsStringSync();
    final minus =
        File('lib/features/home/icon_minus_sheet.dart').readAsStringSync();
    final home = File('lib/features/home/home_screen.dart').readAsStringSync();
    final settings =
        File('lib/features/settings/settings_screen.dart').readAsStringSync();
    final appsCustomize =
        File('lib/features/settings/apps_customize_screen.dart')
            .readAsStringSync();
    expect(action, contains('App info'));
    expect(action, contains('Select'));
    expect(action, contains('Hide'));
    expect(action, contains('Remove'));
    expect(action, contains('Edit Homescreen'));
    expect(action.contains('Delete from Home screen'), isFalse);
    expect(action.contains("'Cancel'"), isFalse);
    expect(minus, contains('Delete from Home screen'));
    expect(minus, contains('Delete application'));
    expect(minus, contains('Color(0xFFE53935)'));
    expect(action, contains('0xFFE53935'));
    expect(home, contains('showIconActionSheet'));
    expect(home, contains('_enterEdit'));
    expect(home, contains('moveHomeSlot'));
    expect(home, contains('moveHomeWidget'));
    expect(settings, contains('Auto-arrange'));
    expect(settings, contains('View all apps'));
    expect(settings, contains('Sidebar'));
    expect(settings, contains('Notification bar'));
    expect(settings, contains('Smart Island'));
    expect(appsCustomize, contains('Hide name'));
    expect(settings.toLowerCase(), contains('hide name'));
  });

  testWidgets('MorphOS home surface builds', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final c = MorphController();
    await c.load();
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(controller: c)),
    );
    await tester.pump();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MorphOSApp pumps without error', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MorphOSApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
