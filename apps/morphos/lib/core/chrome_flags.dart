/// Independent Morph chrome layers. Off = use system UI again.
/// Pure — tests flip flags directly.
library;

enum MorphChromeLayer {
  sidebar,
  notificationBar,
  smartIsland,
}

class MorphChromeFlags {
  const MorphChromeFlags({
    this.sidebar = true,
    this.notificationBar = true,
    this.smartIsland = true,
  });

  final bool sidebar;
  final bool notificationBar;
  final bool smartIsland;

  bool get usesSystemSidebar => !sidebar;
  bool get usesSystemNotificationBar => !notificationBar;
  bool get usesSystemIsland => !smartIsland;

  bool isEnabled(MorphChromeLayer layer) => switch (layer) {
        MorphChromeLayer.sidebar => sidebar,
        MorphChromeLayer.notificationBar => notificationBar,
        MorphChromeLayer.smartIsland => smartIsland,
      };

  MorphChromeFlags setEnabled(MorphChromeLayer layer, bool on) {
    return switch (layer) {
      MorphChromeLayer.sidebar => copyWith(sidebar: on),
      MorphChromeLayer.notificationBar => copyWith(notificationBar: on),
      MorphChromeLayer.smartIsland => copyWith(smartIsland: on),
    };
  }

  MorphChromeFlags copyWith({
    bool? sidebar,
    bool? notificationBar,
    bool? smartIsland,
  }) {
    return MorphChromeFlags(
      sidebar: sidebar ?? this.sidebar,
      notificationBar: notificationBar ?? this.notificationBar,
      smartIsland: smartIsland ?? this.smartIsland,
    );
  }

  Map<String, dynamic> toJson() => {
        'sidebar': sidebar,
        'notificationBar': notificationBar,
        'smartIsland': smartIsland,
      };

  static MorphChromeFlags fromJson(Map<String, dynamic>? m) {
    if (m == null) return const MorphChromeFlags();
    return MorphChromeFlags(
      sidebar: m['sidebar'] as bool? ?? true,
      notificationBar: m['notificationBar'] as bool? ?? true,
      smartIsland: m['smartIsland'] as bool? ?? true,
    );
  }
}

/// Edge shortcut strip. Quick-enters the tapped app.
class SidebarStrip {
  const SidebarStrip({this.shortcutIds = const []});

  static const maxShortcuts = 10;

  final List<String> shortcutIds;

  SidebarStrip add(String id) {
    if (id.isEmpty || shortcutIds.contains(id)) return this;
    if (shortcutIds.length >= maxShortcuts) return this;
    return SidebarStrip(shortcutIds: [...shortcutIds, id]);
  }

  SidebarStrip remove(String id) {
    return SidebarStrip(
      shortcutIds: shortcutIds.where((x) => x != id).toList(growable: false),
    );
  }

  SidebarStrip move(int from, int to) {
    if (from < 0 ||
        to < 0 ||
        from >= shortcutIds.length ||
        to >= shortcutIds.length ||
        from == to) {
      return this;
    }
    final next = List<String>.from(shortcutIds);
    final item = next.removeAt(from);
    next.insert(to, item);
    return SidebarStrip(shortcutIds: next);
  }

  Map<String, dynamic> toJson() => {'shortcutIds': shortcutIds};

  static SidebarStrip fromJson(Map<String, dynamic>? m) {
    if (m == null) return const SidebarStrip();
    final ids = (m['shortcutIds'] as List?)?.map((e) => '$e').toList() ??
        const <String>[];
    return SidebarStrip(
      shortcutIds: ids.take(maxShortcuts).toList(growable: false),
    );
  }
}
