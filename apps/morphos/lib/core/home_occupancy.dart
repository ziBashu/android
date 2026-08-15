/// Home / dock occupancy + minus-menu strings. Pure — tests drive this.
library;

import 'icon_action_menu.dart';

export 'icon_action_menu.dart';

/// Widgets the user may pin on the Morph home (none by default).
enum HomeWidgetKind {
  clock,
  battery,
  rotate,
  search,
  notes,
  webSearch,
  weather,
}

extension HomeWidgetKindX on HomeWidgetKind {
  String get label => switch (this) {
        HomeWidgetKind.clock => 'Clock',
        HomeWidgetKind.battery => 'Battery',
        HomeWidgetKind.rotate => 'Rotate',
        HomeWidgetKind.search => 'App search',
        HomeWidgetKind.notes => 'Notes',
        HomeWidgetKind.webSearch => 'Browser search',
        HomeWidgetKind.weather => 'Weather',
      };

  String get blurb => switch (this) {
        HomeWidgetKind.clock => 'Large time on the home page',
        HomeWidgetKind.battery => 'Live battery ring and extras',
        HomeWidgetKind.rotate => 'Cycle and lock rotation',
        HomeWidgetKind.search => 'Jump to the MorphOS app list',
        HomeWidgetKind.notes => 'Latest note preview',
        HomeWidgetKind.webSearch => 'Search the web in the default browser',
        HomeWidgetKind.weather => 'Local temperature and condition',
      };

  bool get isWide =>
      this == HomeWidgetKind.clock || this == HomeWidgetKind.webSearch;

  static const slotPrefix = 'widget:';

  String get slotId => '$slotPrefix$name';

  /// How many app-icon cells this widget occupies.
  int get colSpan => switch (this) {
        HomeWidgetKind.clock => 4,
        HomeWidgetKind.webSearch => 4,
        HomeWidgetKind.weather => 2,
        HomeWidgetKind.battery => 2,
        HomeWidgetKind.notes => 2,
        HomeWidgetKind.rotate => 1,
        HomeWidgetKind.search => 1,
      };

  int get rowSpan => switch (this) {
        HomeWidgetKind.clock => 2,
        HomeWidgetKind.weather => 2,
        _ => 1,
      };

  static bool isSlot(String raw) => raw.startsWith(slotPrefix);

  static HomeWidgetKind? ofSlot(String raw) {
    if (!isSlot(raw)) return null;
    final name = raw.substring(slotPrefix.length);
    for (final k in HomeWidgetKind.values) {
      if (k.name == name) return k;
    }
    return null;
  }
}

/// Named folder occupying one home slot (`folder:<id>`).
class HomeFolder {
  const HomeFolder({
    required this.id,
    required this.name,
    this.appIds = const [],
  });

  static const prefix = 'folder:';

  final String id;
  final String name;
  final List<String> appIds;

  static String slotId(String id) => '$prefix$id';
  static bool isSlot(String raw) => raw.startsWith(prefix);
  static String? idOf(String raw) =>
      isSlot(raw) ? raw.substring(prefix.length) : null;

  HomeFolder copyWith({String? name, List<String>? appIds}) {
    return HomeFolder(
      id: id,
      name: name ?? this.name,
      appIds: appIds ?? this.appIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'appIds': appIds,
      };

  static HomeFolder fromJson(Map<String, dynamic> m) {
    return HomeFolder(
      id: '${m['id'] ?? ''}',
      name: '${m['name'] ?? 'Folder'}',
      appIds: List<String>.from(m['appIds'] as List? ?? const []),
    );
  }
}

/// Sparse home occupancy. Never auto-places the full catalog.
class HomeOccupancy {
  const HomeOccupancy({
    required this.homeIds,
    required this.dockIds,
    this.dockVisible = true,
    this.widgets = const [],
    this.seeded = false,
    this.autoArrange = false,
    this.hiddenIds = const [],
    this.folders = const [],
  });

  /// Empty string = void grid slot (auto-arrange off leaves these).
  static const voidSlot = '';

  final List<String> homeIds;
  final List<String> dockIds;
  final bool dockVisible;
  final List<HomeWidgetKind> widgets;
  final bool seeded;

  /// Default **off**. Off: remove leaves a void. On: compact the row.
  final bool autoArrange;
  final List<String> hiddenIds;
  final List<HomeFolder> folders;

  static const maxDefaultHome = 6;
  static const maxDefaultDock = 4;

  static const defaultDemoHome = [
    'browser',
    'music',
    'notes',
    'maps',
  ];

  static const defaultDemoDock = [
    'messages',
    'camera',
    'settings',
  ];

  /// Package / label needles for “commonly used” (no usage-stats permission).
  static const commonNeedles = [
    'chrome',
    'brave',
    'firefox',
    'browser',
    'opera',
    'edge',
    'mms',
    'messaging',
    'sms',
    'messages',
    'whatsapp',
    'wechat',
    'telegram',
    'qq',
    'line',
    'kakao',
    'camera',
    'gallery',
    'photos',
    'maps',
    'waze',
    'gmail',
    'mail',
    'outlook',
    'clock',
    'deskclock',
    'music',
    'spotify',
    'youtube',
    'phone',
    'dialer',
    'contacts',
    'calendar',
    'settings',
    'morphos',
    'zibashu',
  ];

  HomeOccupancy copyWith({
    List<String>? homeIds,
    List<String>? dockIds,
    bool? dockVisible,
    List<HomeWidgetKind>? widgets,
    bool? seeded,
    bool? autoArrange,
    List<String>? hiddenIds,
    List<HomeFolder>? folders,
  }) {
    return HomeOccupancy(
      homeIds: homeIds ?? this.homeIds,
      dockIds: dockIds ?? this.dockIds,
      dockVisible: dockVisible ?? this.dockVisible,
      widgets: widgets ?? this.widgets,
      seeded: seeded ?? this.seeded,
      autoArrange: autoArrange ?? this.autoArrange,
      hiddenIds: hiddenIds ?? this.hiddenIds,
      folders: folders ?? this.folders,
    );
  }

  bool isVoidSlot(String id) => id.isEmpty;

  HomeFolder? folderForSlot(String raw) {
    final fid = HomeFolder.idOf(raw);
    if (fid == null) return null;
    for (final f in folders) {
      if (f.id == fid) return f;
    }
    return null;
  }

  bool isOnHome(String id) {
    if (homeIds.contains(id)) return true;
    for (final f in folders) {
      if (f.appIds.contains(id) &&
          homeIds.contains(HomeFolder.slotId(f.id))) {
        return true;
      }
    }
    return false;
  }

  /// Pick a small commonly-used set. Never returns the full catalog when it
  /// is larger than [maxDefaultHome] + [maxDefaultDock].
  static HomeOccupancy seedCommon({
    required List<String> catalogIds,
    Map<String, int> launchCounts = const {},
    Map<String, String> labels = const {},
    Map<String, String?> packages = const {},
  }) {
    if (catalogIds.isEmpty) {
      return const HomeOccupancy(
        homeIds: defaultDemoHome,
        dockIds: defaultDemoDock,
        dockVisible: true,
        widgets: [],
        seeded: true,
      );
    }

    int score(String id) {
      var s = (launchCounts[id] ?? 0) * 12;
      final hay =
          '${id.toLowerCase()} ${(labels[id] ?? '').toLowerCase()} ${(packages[id] ?? '').toLowerCase()}';
      for (var i = 0; i < commonNeedles.length; i++) {
        if (hay.contains(commonNeedles[i])) {
          s += 200 - i;
          break;
        }
      }
      return s;
    }

    final ranked = List<String>.from(catalogIds)
      ..sort((a, b) {
        final d = score(b).compareTo(score(a));
        if (d != 0) return d;
        return a.compareTo(b);
      });

    final cap = maxDefaultHome + maxDefaultDock;
    final morphos = ranked.where((id) {
      final hay =
          '${id.toLowerCase()} ${(labels[id] ?? '').toLowerCase()} ${(packages[id] ?? '').toLowerCase()}';
      return hay.contains('morphos') || hay.contains('zibashu.morphos');
    }).toList();
    final take = [
      ...morphos,
      ...ranked.where((id) => !morphos.contains(id)),
    ].take(cap).toList(growable: false);
    final dockTake =
        take.length < 3 ? take.length : maxDefaultDock.clamp(0, take.length);
    final dock = take.take(dockTake).toList(growable: false);
    final home = take.skip(dock.length).toList(growable: false);

    return HomeOccupancy(
      homeIds: home,
      dockIds: dock,
      dockVisible: true,
      widgets: const [],
      seeded: true,
      autoArrange: false,
    );
  }

  /// Remove every app on the current page. Does **not** uninstall.
  HomeOccupancy deleteAllOnPage() {
    return copyWith(homeIds: const [], folders: const []);
  }

  /// Hide the dock and return those ids to the home page.
  HomeOccupancy hideDock() {
    final returned = <String>[
      ...dockIds.where((id) => !homeIds.contains(id)),
      ...homeIds,
    ];
    return copyWith(
      homeIds: returned,
      dockIds: const [],
      dockVisible: false,
    );
  }

  HomeOccupancy showDock({List<String> ids = const []}) {
    final nextDock = ids.isEmpty ? dockIds : ids;
    final nextHome =
        homeIds.where((id) => !nextDock.contains(id)).toList(growable: false);
    return copyWith(
      homeIds: nextHome,
      dockIds: nextDock,
      dockVisible: true,
    );
  }

  HomeOccupancy removeFromHome(String id) {
    if (autoArrange) {
      return copyWith(
        homeIds: homeIds.where((x) => x != id).toList(growable: false),
      );
    }
    return copyWith(
      homeIds: homeIds.map((x) => x == id ? voidSlot : x).toList(growable: false),
    );
  }

  HomeOccupancy addToHome(String id) {
    if (id.isEmpty) return this;
    if (isOnHome(id) || dockIds.contains(id)) return this;
    final voidIdx = homeIds.indexOf(voidSlot);
    if (voidIdx >= 0) {
      final next = List<String>.from(homeIds);
      next[voidIdx] = id;
      return copyWith(homeIds: next);
    }
    return copyWith(homeIds: [...homeIds, id]);
  }

  HomeOccupancy addToDock(String id) {
    final nextDock = dockIds.contains(id) ? dockIds : [...dockIds, id];
    return copyWith(
      dockIds: nextDock,
      homeIds: homeIds.where((x) => x != id).toList(growable: false),
      dockVisible: true,
    );
  }

  HomeOccupancy removeFromDock(String id) {
    final nextDock = dockIds.where((x) => x != id).toList(growable: false);
    final nextHome = homeIds.contains(id) ? homeIds : [...homeIds, id];
    return copyWith(dockIds: nextDock, homeIds: nextHome);
  }

  /// Remove from home **and** dock. Does not move the id onto the other row.
  /// Auto-arrange off: home slot becomes a void instead of compacting.
  HomeOccupancy removeFromLauncher(String id, {String? also}) {
    bool drop(String x) =>
        x == id || (also != null && also.isNotEmpty && x == also);
    final nextHome = autoArrange
        ? homeIds.where((x) => !drop(x)).toList(growable: false)
        : homeIds
            .map((x) => drop(x) ? voidSlot : x)
            .toList(growable: false);
    return copyWith(
      homeIds: nextHome,
      dockIds: dockIds.where((x) => !drop(x)).toList(growable: false),
    );
  }

  HomeOccupancy hideApp(String id) {
    final nextHidden =
        hiddenIds.contains(id) ? hiddenIds : [...hiddenIds, id];
    return removeFromLauncher(id).copyWith(hiddenIds: nextHidden);
  }

  HomeOccupancy unhideApp(String id) {
    return copyWith(
      hiddenIds: hiddenIds.where((x) => x != id).toList(growable: false),
    );
  }

  HomeOccupancy setAutoArrange(bool on) {
    if (on == autoArrange) return this;
    if (!on) return copyWith(autoArrange: false);
    return copyWith(
      autoArrange: true,
      homeIds: homeIds.where((x) => x.isNotEmpty).toList(growable: false),
    );
  }

  /// Select → drop several ids from home/dock (voids if auto-arrange off).
  HomeOccupancy removeSelection(List<String> ids) {
    var next = this;
    for (final id in ids) {
      if (id.isEmpty) continue;
      next = next.removeFromLauncher(id);
    }
    return next;
  }

  /// Select → named folder occupying the first selected slot.
  HomeOccupancy foldSelection(List<String> ids, String name, {String? folderId}) {
    final selected = ids
        .where((id) => id.isNotEmpty && !HomeFolder.isSlot(id))
        .toList(growable: false);
    if (selected.length < 2) return this;
    final fid = (folderId != null && folderId.isNotEmpty)
        ? folderId
        : 'f${selected.join('|').hashCode.abs()}';
    final folder = HomeFolder(
      id: fid,
      name: name.trim().isEmpty ? 'Folder' : name.trim(),
      appIds: selected,
    );
    var placed = false;
    final nextHome = <String>[];
    for (final slot in homeIds) {
      if (selected.contains(slot)) {
        if (!placed) {
          nextHome.add(HomeFolder.slotId(fid));
          placed = true;
        } else if (!autoArrange) {
          nextHome.add(voidSlot);
        }
      } else {
        nextHome.add(slot);
      }
    }
    if (!placed) nextHome.add(HomeFolder.slotId(fid));
    return copyWith(
      homeIds: nextHome,
      dockIds:
          dockIds.where((d) => !selected.contains(d)).toList(growable: false),
      folders: [...folders.where((f) => f.id != fid), folder],
    );
  }

  HomeOccupancy renameFolder(String folderId, String name) {
    return copyWith(
      folders: [
        for (final f in folders)
          if (f.id == folderId)
            f.copyWith(name: name.trim().isEmpty ? f.name : name.trim())
          else
            f,
      ],
    );
  }

  HomeOccupancy moveHomeSlot(int from, int to) {
    if (from < 0 ||
        to < 0 ||
        from >= homeIds.length ||
        to >= homeIds.length ||
        from == to) {
      return this;
    }
    final next = List<String>.from(homeIds);
    final item = next.removeAt(from);
    next.insert(to, item);
    return copyWith(homeIds: next);
  }

  HomeOccupancy moveWidget(int from, int to) {
    if (from < 0 ||
        to < 0 ||
        from >= widgets.length ||
        to >= widgets.length ||
        from == to) {
      return this;
    }
    final next = List<HomeWidgetKind>.from(widgets);
    final item = next.removeAt(from);
    next.insert(to, item);
    return copyWith(widgets: next);
  }

  HomeOccupancy addWidget(HomeWidgetKind kind) {
    if (widgets.contains(kind) || homeIds.contains(kind.slotId)) return this;
    return copyWith(
      widgets: [...widgets, kind],
      homeIds: [...homeIds, kind.slotId],
    );
  }

  HomeOccupancy removeWidget(HomeWidgetKind kind) {
    return copyWith(
      widgets: widgets.where((w) => w != kind).toList(growable: false),
      homeIds: homeIds
          .where((id) => id != kind.slotId)
          .toList(growable: false),
    );
  }

  HomeOccupancy toggleWidget(HomeWidgetKind kind) {
    return widgets.contains(kind) ? removeWidget(kind) : addWidget(kind);
  }

  Map<String, dynamic> toJson() => {
        'homeIds': homeIds,
        'dockIds': dockIds,
        'dockVisible': dockVisible,
        'widgets': widgets.map((w) => w.name).toList(),
        'seeded': seeded,
        'autoArrange': autoArrange,
        'hiddenIds': hiddenIds,
        'folders': folders.map((f) => f.toJson()).toList(),
      };

  static HomeOccupancy fromJson(Map<String, dynamic> m) {
    final widgetNames = (m['widgets'] as List?)?.map((e) => '$e') ?? const [];
    final kinds = <HomeWidgetKind>[];
    for (final name in widgetNames) {
      for (final k in HomeWidgetKind.values) {
        if (k.name == name) kinds.add(k);
      }
    }
    final folderRaw = (m['folders'] as List?) ?? const [];
    final parsedFolders = <HomeFolder>[];
    for (final e in folderRaw) {
      if (e is Map) {
        parsedFolders.add(HomeFolder.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    var ids = List<String>.from(m['homeIds'] as List? ?? const []);
    for (final k in kinds) {
      if (!ids.contains(k.slotId)) ids = [...ids, k.slotId];
    }
    return HomeOccupancy(
      homeIds: ids,
      dockIds: List<String>.from(m['dockIds'] as List? ?? const []),
      dockVisible: m['dockVisible'] as bool? ?? true,
      widgets: kinds,
      seeded: m['seeded'] as bool? ?? false,
      autoArrange: m['autoArrange'] as bool? ?? false,
      hiddenIds: List<String>.from(m['hiddenIds'] as List? ?? const []),
      folders: parsedFolders,
    );
  }
}

/// Minus-menu mutations used by the home surface (no uninstall here).
class HomeMinusAction {
  HomeMinusAction._();

  static HomeOccupancy apply({
    required HomeOccupancy occupancy,
    required String choice,
    required String id,
    String? packageName,
  }) {
    if (IconMinusMenu.isHomeRemove(choice)) {
      return occupancy.removeFromLauncher(id, also: packageName);
    }
    return occupancy;
  }
}
