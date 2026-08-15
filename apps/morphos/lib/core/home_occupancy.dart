/// Home / dock occupancy + minus-menu strings. Pure — tests drive this.
library;

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
}

/// Verbatim minus-menu strings shown on a home icon.
class IconMinusMenu {
  IconMinusMenu._();

  static const deleteFromHomeScreen = 'Delete from Home screen';
  static const deleteApplication = 'Delete application';
  static const cancel = 'Cancel';

  static const List<String> choices = [
    deleteFromHomeScreen,
    deleteApplication,
    cancel,
  ];

  static bool isHomeRemove(String choice) => choice == deleteFromHomeScreen;

  static bool isUninstall(String choice) => choice == deleteApplication;

  static bool isCancel(String choice) => choice == cancel;
}

/// Sparse home occupancy. Never auto-places the full catalog.
class HomeOccupancy {
  const HomeOccupancy({
    required this.homeIds,
    required this.dockIds,
    this.dockVisible = true,
    this.widgets = const [],
    this.seeded = false,
  });

  final List<String> homeIds;
  final List<String> dockIds;
  final bool dockVisible;
  final List<HomeWidgetKind> widgets;
  final bool seeded;

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
  }) {
    return HomeOccupancy(
      homeIds: homeIds ?? this.homeIds,
      dockIds: dockIds ?? this.dockIds,
      dockVisible: dockVisible ?? this.dockVisible,
      widgets: widgets ?? this.widgets,
      seeded: seeded ?? this.seeded,
    );
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
    );
  }

  /// Remove every app on the current page. Does **not** uninstall.
  HomeOccupancy deleteAllOnPage() {
    return copyWith(homeIds: const []);
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
    return copyWith(
      homeIds: homeIds.where((x) => x != id).toList(growable: false),
    );
  }

  HomeOccupancy addToHome(String id) {
    if (homeIds.contains(id) || dockIds.contains(id)) return this;
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
  HomeOccupancy removeFromLauncher(String id, {String? also}) {
    bool drop(String x) => x == id || (also != null && also.isNotEmpty && x == also);
    return copyWith(
      homeIds: homeIds.where((x) => !drop(x)).toList(growable: false),
      dockIds: dockIds.where((x) => !drop(x)).toList(growable: false),
    );
  }

  HomeOccupancy addWidget(HomeWidgetKind kind) {
    if (widgets.contains(kind)) return this;
    return copyWith(widgets: [...widgets, kind]);
  }

  HomeOccupancy removeWidget(HomeWidgetKind kind) {
    return copyWith(
      widgets: widgets.where((w) => w != kind).toList(growable: false),
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
      };

  static HomeOccupancy fromJson(Map<String, dynamic> m) {
    final widgetNames = (m['widgets'] as List?)?.map((e) => '$e') ?? const [];
    final kinds = <HomeWidgetKind>[];
    for (final name in widgetNames) {
      for (final k in HomeWidgetKind.values) {
        if (k.name == name) kinds.add(k);
      }
    }
    return HomeOccupancy(
      homeIds: List<String>.from(m['homeIds'] as List? ?? const []),
      dockIds: List<String>.from(m['dockIds'] as List? ?? const []),
      dockVisible: m['dockVisible'] as bool? ?? true,
      widgets: kinds,
      seeded: m['seeded'] as bool? ?? false,
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
