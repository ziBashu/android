/// Per-app MorphOS look: name, icon, size, hide name. Pure — tests drive this.
library;

class AppAppearance {
  const AppAppearance({
    this.customName,
    this.iconB64,
    this.sizeScale = 1.0,
    this.hideName = false,
  });

  final String? customName;
  final String? iconB64;
  final double sizeScale;
  final bool hideName;

  bool get isDefault =>
      (customName == null || customName!.isEmpty) &&
      (iconB64 == null || iconB64!.isEmpty) &&
      sizeScale == 1.0 &&
      !hideName;

  AppAppearance copyWith({
    String? customName,
    String? iconB64,
    double? sizeScale,
    bool? hideName,
    bool clearName = false,
    bool clearIcon = false,
  }) {
    return AppAppearance(
      customName: clearName ? null : (customName ?? this.customName),
      iconB64: clearIcon ? null : (iconB64 ?? this.iconB64),
      sizeScale: sizeScale ?? this.sizeScale,
      hideName: hideName ?? this.hideName,
    );
  }

  Map<String, dynamic> toJson() => {
        if (customName != null && customName!.isNotEmpty) 'customName': customName,
        if (iconB64 != null && iconB64!.isNotEmpty) 'iconB64': iconB64,
        if (sizeScale != 1.0) 'sizeScale': sizeScale,
        if (hideName) 'hideName': hideName,
      };

  static AppAppearance fromJson(Map<String, dynamic>? m) {
    if (m == null) return const AppAppearance();
    return AppAppearance(
      customName: m['customName'] as String?,
      iconB64: m['iconB64'] as String?,
      sizeScale: (m['sizeScale'] as num?)?.toDouble() ?? 1.0,
      hideName: m['hideName'] as bool? ?? false,
    );
  }
}

class AppAppearanceStore {
  const AppAppearanceStore({this.byId = const {}});

  final Map<String, AppAppearance> byId;

  AppAppearance of(String id) => byId[id] ?? const AppAppearance();

  String displayName(String id, String fallback) {
    final n = of(id).customName?.trim();
    if (n == null || n.isEmpty) return fallback;
    return n;
  }

  bool hideName(String id) => of(id).hideName;

  double sizeScale(String id) => of(id).sizeScale.clamp(0.7, 1.6);

  AppAppearanceStore _put(String id, AppAppearance next) {
    final map = Map<String, AppAppearance>.from(byId);
    if (next.isDefault) {
      map.remove(id);
    } else {
      map[id] = next;
    }
    return AppAppearanceStore(byId: map);
  }

  AppAppearanceStore setName(String id, String name) {
    final t = name.trim();
    return _put(id, of(id).copyWith(customName: t, clearName: t.isEmpty));
  }

  AppAppearanceStore setIcon(String id, String? b64) {
    return _put(
      id,
      of(id).copyWith(iconB64: b64, clearIcon: b64 == null || b64.isEmpty),
    );
  }

  AppAppearanceStore setSize(String id, double scale) {
    return _put(id, of(id).copyWith(sizeScale: scale.clamp(0.7, 1.6)));
  }

  AppAppearanceStore setHideName(String id, bool hide) {
    return _put(id, of(id).copyWith(hideName: hide));
  }

  Map<String, dynamic> toJson() => {
        for (final e in byId.entries) e.key: e.value.toJson(),
      };

  static AppAppearanceStore fromJson(Map<String, dynamic>? m) {
    if (m == null) return const AppAppearanceStore();
    final out = <String, AppAppearance>{};
    for (final e in m.entries) {
      if (e.value is Map) {
        out[e.key] = AppAppearance.fromJson(
          Map<String, dynamic>.from(e.value as Map),
        );
      }
    }
    return AppAppearanceStore(byId: out);
  }

  /// Merge existing controller rename/icon maps (upgrade path).
  static AppAppearanceStore fromLegacy({
    Map<String, String> names = const {},
    Map<String, String> icons = const {},
    Map<String, double> sizes = const {},
    List<String> hideNames = const [],
  }) {
    var store = const AppAppearanceStore();
    final ids = <String>{
      ...names.keys,
      ...icons.keys,
      ...sizes.keys,
      ...hideNames,
    };
    for (final id in ids) {
      store = store._put(
        id,
        AppAppearance(
          customName: names[id],
          iconB64: icons[id],
          sizeScale: sizes[id] ?? 1.0,
          hideName: hideNames.contains(id),
        ),
      );
    }
    return store;
  }
}
