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

  /// Overlay sync payload. Always includes shortcuts so a flag flip
  /// cannot wipe the native sidebar list.
  Map<String, dynamic> toSyncJson(SidebarStrip strip) => {
        ...toJson(),
        'shortcuts': List<String>.from(strip.shortcutIds),
        'rim': strip.placement.rim.name,
        'along': strip.placement.along,
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

enum ScreenRim { left, right, top, bottom }

/// Handle sits on the screen rim and can be dragged around the edge.
class SidebarPlacement {
  const SidebarPlacement({
    this.rim = ScreenRim.right,
    this.along = 0.42,
  });

  final ScreenRim rim;
  final double along;

  SidebarPlacement copyWith({ScreenRim? rim, double? along}) {
    return SidebarPlacement(
      rim: rim ?? this.rim,
      along: (along ?? this.along).clamp(0.08, 0.92),
    );
  }

  /// Snap a pointer to the nearest rim.
  static SidebarPlacement fromPoint(double x, double y, double w, double h) {
    final dl = x;
    final dr = w - x;
    final dt = y;
    final db = h - y;
    final m = [dl, dr, dt, db].reduce((a, b) => a < b ? a : b);
    if (m == dl) {
      return SidebarPlacement(rim: ScreenRim.left, along: (y / h).clamp(0.08, 0.92));
    }
    if (m == dr) {
      return SidebarPlacement(rim: ScreenRim.right, along: (y / h).clamp(0.08, 0.92));
    }
    if (m == dt) {
      return SidebarPlacement(rim: ScreenRim.top, along: (x / w).clamp(0.08, 0.92));
    }
    return SidebarPlacement(rim: ScreenRim.bottom, along: (x / w).clamp(0.08, 0.92));
  }

  Map<String, dynamic> toJson() => {'rim': rim.name, 'along': along};

  static SidebarPlacement fromJson(Map<String, dynamic>? m) {
    if (m == null) return const SidebarPlacement();
    var rim = ScreenRim.right;
    final name = '${m['rim'] ?? ''}';
    for (final r in ScreenRim.values) {
      if (r.name == name) rim = r;
    }
    return SidebarPlacement(
      rim: rim,
      along: (m['along'] as num?)?.toDouble() ?? 0.42,
    );
  }
}

/// Edge shortcut strip. Quick-enters the tapped app.
class SidebarStrip {
  const SidebarStrip({
    this.shortcutIds = const [],
    this.placement = const SidebarPlacement(),
  });

  static const maxShortcuts = 10;

  final List<String> shortcutIds;
  final SidebarPlacement placement;

  SidebarStrip add(String id) {
    if (id.isEmpty || shortcutIds.contains(id)) return this;
    if (shortcutIds.length >= maxShortcuts) return this;
    return SidebarStrip(
      shortcutIds: [...shortcutIds, id],
      placement: placement,
    );
  }

  SidebarStrip remove(String id) {
    return SidebarStrip(
      shortcutIds: shortcutIds.where((x) => x != id).toList(growable: false),
      placement: placement,
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
    return SidebarStrip(shortcutIds: next, placement: placement);
  }

  SidebarStrip withPlacement(SidebarPlacement next) =>
      SidebarStrip(shortcutIds: shortcutIds, placement: next);

  Map<String, dynamic> toJson() => {
        'shortcutIds': shortcutIds,
        'placement': placement.toJson(),
      };

  static SidebarStrip fromJson(Map<String, dynamic>? m) {
    if (m == null) return const SidebarStrip();
    final ids = (m['shortcutIds'] as List?)?.map((e) => '$e').toList() ??
        const <String>[];
    return SidebarStrip(
      shortcutIds: ids.take(maxShortcuts).toList(growable: false),
      placement: SidebarPlacement.fromJson(
        (m['placement'] as Map?)?.cast<String, dynamic>(),
      ),
    );
  }
}
