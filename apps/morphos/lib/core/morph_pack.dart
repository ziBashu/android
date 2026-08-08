import 'models.dart';

/// Phase 5 — shareable Morph pack (theme + layout + wallpaper + mode shell).
/// Format: morphpack/v1 — offline Store + Creator + community clipboard share.
class MorphPack {
  const MorphPack({
    required this.id,
    required this.name,
    required this.author,
    required this.description,
    required this.category,
    required this.themeId,
    required this.wallpaperId,
    required this.layoutPortrait,
    required this.layoutLandscape,
    required this.iconStyle,
    required this.targetProfile,
    this.showLabels = true,
    this.iconScale = 1.0,
    this.gridColumns = 4,
    this.dockIds = const [],
    this.homeIds = const [],
    this.quietMode = false,
    this.largeTargets = false,
    this.tags = const [],
    this.version = 1,
    this.builtIn = false,
    this.createdAtMs,
  });

  final String id;
  final String name;
  final String author;
  final String description;

  /// Store shelf: theme | layout | mode | community
  final String category;

  final MorphThemeId themeId;
  final WallpaperId wallpaperId;
  final MorphLayoutId layoutPortrait;
  final MorphLayoutId layoutLandscape;
  final IconStyleId iconStyle;
  final MorphProfileId targetProfile;
  final bool showLabels;
  final double iconScale;
  final int gridColumns;
  final List<String> dockIds;
  final List<String> homeIds;
  final bool quietMode;
  final bool largeTargets;
  final List<String> tags;
  final int version;
  final bool builtIn;
  final int? createdAtMs;

  MorphEnvironment toEnvironment() {
    return MorphEnvironment(
      profileId: targetProfile,
      themeId: themeId,
      wallpaperId: wallpaperId,
      layoutPortrait: layoutPortrait,
      layoutLandscape: layoutLandscape,
      iconStyle: iconStyle,
      showLabels: showLabels,
      iconScale: iconScale,
      gridColumns: gridColumns,
      dockIds: dockIds.isEmpty
          ? MorphEnvironment.defaultsFor(targetProfile).dockIds
          : dockIds,
      homeIds: homeIds.isEmpty
          ? MorphEnvironment.defaultsFor(targetProfile).homeIds
          : homeIds,
      quietMode: quietMode,
      largeTargets: largeTargets,
    );
  }

  Map<String, dynamic> toJson() => {
        'format': 'morphpack/v1',
        'id': id,
        'name': name,
        'author': author,
        'description': description,
        'category': category,
        'themeId': themeId.name,
        'wallpaperId': wallpaperId.name,
        'layoutPortrait': layoutPortrait.name,
        'layoutLandscape': layoutLandscape.name,
        'iconStyle': iconStyle.name,
        'targetProfile': targetProfile.name,
        'showLabels': showLabels,
        'iconScale': iconScale,
        'gridColumns': gridColumns,
        'dockIds': dockIds,
        'homeIds': homeIds,
        'quietMode': quietMode,
        'largeTargets': largeTargets,
        'tags': tags,
        'version': version,
        'builtIn': builtIn,
        if (createdAtMs != null) 'createdAtMs': createdAtMs,
      };

  static MorphPack? tryFromJson(Map<String, dynamic> m) {
    try {
      return fromJson(m);
    } catch (_) {
      return null;
    }
  }

  static MorphPack fromJson(Map<String, dynamic> m) {
    T byName<T extends Enum>(List<T> values, String? name, T fallback) {
      if (name == null) return fallback;
      for (final v in values) {
        if (v.name == name) return v;
      }
      return fallback;
    }

    return MorphPack(
      id: m['id'] as String? ??
          'pack_${DateTime.now().millisecondsSinceEpoch}',
      name: m['name'] as String? ?? 'Untitled pack',
      author: m['author'] as String? ?? 'unknown',
      description: m['description'] as String? ?? '',
      category: m['category'] as String? ?? 'community',
      themeId: byName(
        MorphThemeId.values,
        m['themeId'] as String?,
        MorphThemeId.neon,
      ),
      wallpaperId: byName(
        WallpaperId.values,
        m['wallpaperId'] as String?,
        WallpaperId.cyberpunk,
      ),
      layoutPortrait: byName(
        MorphLayoutId.values,
        m['layoutPortrait'] as String?,
        MorphLayoutId.grid,
      ),
      layoutLandscape: byName(
        MorphLayoutId.values,
        m['layoutLandscape'] as String?,
        MorphLayoutId.grid,
      ),
      iconStyle: byName(
        IconStyleId.values,
        m['iconStyle'] as String?,
        IconStyleId.squircle,
      ),
      targetProfile: byName(
        MorphProfileId.values,
        m['targetProfile'] as String?,
        MorphProfileId.phone,
      ),
      showLabels: m['showLabels'] as bool? ?? true,
      iconScale: (m['iconScale'] as num?)?.toDouble() ?? 1.0,
      gridColumns: m['gridColumns'] as int? ?? 4,
      dockIds: List<String>.from(m['dockIds'] as List? ?? const []),
      homeIds: List<String>.from(m['homeIds'] as List? ?? const []),
      quietMode: m['quietMode'] as bool? ?? false,
      largeTargets: m['largeTargets'] as bool? ?? false,
      tags: List<String>.from(m['tags'] as List? ?? const []),
      version: m['version'] as int? ?? 1,
      builtIn: m['builtIn'] as bool? ?? false,
      createdAtMs: m['createdAtMs'] as int?,
    );
  }

  MorphPack copyWith({
    String? name,
    String? description,
    String? category,
    List<String>? tags,
  }) {
    return MorphPack(
      id: id,
      name: name ?? this.name,
      author: author,
      description: description ?? this.description,
      category: category ?? this.category,
      themeId: themeId,
      wallpaperId: wallpaperId,
      layoutPortrait: layoutPortrait,
      layoutLandscape: layoutLandscape,
      iconStyle: iconStyle,
      targetProfile: targetProfile,
      showLabels: showLabels,
      iconScale: iconScale,
      gridColumns: gridColumns,
      dockIds: dockIds,
      homeIds: homeIds,
      quietMode: quietMode,
      largeTargets: largeTargets,
      tags: tags ?? this.tags,
      version: version,
      builtIn: builtIn,
      createdAtMs: createdAtMs,
    );
  }
}

/// Offline Morph Store shelf (Phase 5). Remote store later — same pack schema.
List<MorphPack> kBuiltInMorphStore() {
  return const [
    MorphPack(
      id: 'store.cyberpunk_night',
      name: 'Cyberpunk Night',
      author: 'ziBashu',
      description: 'Neon HUD, cyber skyline, spatial gaming energy.',
      category: 'mode',
      themeId: MorphThemeId.neon,
      wallpaperId: WallpaperId.cyberpunk,
      layoutPortrait: MorphLayoutId.spatial,
      layoutLandscape: MorphLayoutId.spatial,
      iconStyle: IconStyleId.neon,
      targetProfile: MorphProfileId.gaming,
      showLabels: false,
      iconScale: 1.15,
      gridColumns: 4,
      dockIds: ['store', 'browser', 'music', 'settings'],
      homeIds: ['store', 'browser', 'music', 'gallery', 'files'],
      quietMode: true,
      tags: ['neon', 'gaming', 'night'],
      builtIn: true,
    ),
    MorphPack(
      id: 'store.zen_study',
      name: 'Zen Study',
      author: 'ziBashu',
      description: 'Quiet forest reading desk — warm, minimal, focused.',
      category: 'mode',
      themeId: MorphThemeId.dark,
      wallpaperId: WallpaperId.forest,
      layoutPortrait: MorphLayoutId.minimal,
      layoutLandscape: MorphLayoutId.cards,
      iconStyle: IconStyleId.circle,
      targetProfile: MorphProfileId.reading,
      showLabels: true,
      iconScale: 1.05,
      gridColumns: 3,
      dockIds: ['notes', 'browser', 'music', 'settings'],
      homeIds: ['notes', 'browser', 'clock', 'music'],
      quietMode: true,
      tags: ['study', 'reading', 'quiet'],
      builtIn: true,
    ),
    MorphPack(
      id: 'store.dock_workstation',
      name: 'Dock Workstation',
      author: 'ziBashu',
      description: 'Glass desktop shell for docked / productivity days.',
      category: 'layout',
      themeId: MorphThemeId.glass,
      wallpaperId: WallpaperId.aurora,
      layoutPortrait: MorphLayoutId.desktop,
      layoutLandscape: MorphLayoutId.desktop,
      iconStyle: IconStyleId.squircle,
      targetProfile: MorphProfileId.desktop,
      showLabels: true,
      iconScale: 1.0,
      gridColumns: 5,
      dockIds: ['browser', 'files', 'notes', 'mail', 'settings'],
      homeIds: ['browser', 'files', 'notes', 'mail', 'gallery', 'clock'],
      tags: ['desktop', 'work', 'dock'],
      builtIn: true,
    ),
    MorphPack(
      id: 'store.road_trip',
      name: 'Road Trip',
      author: 'ziBashu',
      description: 'Large targets, landscape car mode, nav-first dock.',
      category: 'mode',
      themeId: MorphThemeId.dark,
      wallpaperId: WallpaperId.voidBlack,
      layoutPortrait: MorphLayoutId.grid,
      layoutLandscape: MorphLayoutId.grid,
      iconStyle: IconStyleId.rounded,
      targetProfile: MorphProfileId.car,
      showLabels: true,
      iconScale: 1.3,
      gridColumns: 3,
      dockIds: ['maps', 'music', 'messages', 'settings'],
      homeIds: ['maps', 'music', 'messages', 'browser', 'clock'],
      largeTargets: true,
      tags: ['car', 'nav', 'travel'],
      builtIn: true,
    ),
    MorphPack(
      id: 'store.night_cinema',
      name: 'Night Cinema',
      author: 'ziBashu',
      description: 'Ocean dusk relax mode for streaming and wind-down.',
      category: 'theme',
      themeId: MorphThemeId.glass,
      wallpaperId: WallpaperId.ocean,
      layoutPortrait: MorphLayoutId.cards,
      layoutLandscape: MorphLayoutId.spatial,
      iconStyle: IconStyleId.circle,
      targetProfile: MorphProfileId.relax,
      showLabels: true,
      iconScale: 1.1,
      gridColumns: 3,
      dockIds: ['music', 'gallery', 'notes', 'settings'],
      homeIds: ['music', 'gallery', 'notes', 'clock', 'browser'],
      quietMode: true,
      tags: ['media', 'relax', 'night'],
      builtIn: true,
    ),
    MorphPack(
      id: 'store.pure_focus',
      name: 'Pure Focus',
      author: 'ziBashu',
      description: 'Clean light Material grid for deep work mornings.',
      category: 'theme',
      themeId: MorphThemeId.material,
      wallpaperId: WallpaperId.dawn,
      layoutPortrait: MorphLayoutId.cards,
      layoutLandscape: MorphLayoutId.cards,
      iconStyle: IconStyleId.rounded,
      targetProfile: MorphProfileId.work,
      showLabels: true,
      iconScale: 1.0,
      gridColumns: 5,
      dockIds: ['mail', 'browser', 'notes', 'settings'],
      homeIds: ['mail', 'browser', 'notes', 'files', 'maps', 'clock'],
      tags: ['work', 'light', 'focus'],
      builtIn: true,
    ),
    MorphPack(
      id: 'store.void_minimal',
      name: 'Void Minimal',
      author: 'ziBashu',
      description: 'Almost nothing. OLED black, one quiet page of apps.',
      category: 'layout',
      themeId: MorphThemeId.dark,
      wallpaperId: WallpaperId.voidBlack,
      layoutPortrait: MorphLayoutId.minimal,
      layoutLandscape: MorphLayoutId.minimal,
      iconStyle: IconStyleId.square,
      targetProfile: MorphProfileId.phone,
      showLabels: false,
      iconScale: 0.95,
      gridColumns: 3,
      dockIds: ['browser', 'messages', 'settings'],
      homeIds: ['browser', 'notes', 'clock'],
      quietMode: true,
      tags: ['minimal', 'oled'],
      builtIn: true,
    ),
    MorphPack(
      id: 'store.community_starter',
      name: 'Community Starter Kit',
      author: 'ziBashu Community',
      description:
          'Template pack for sharing — install, remix in Creator, export JSON.',
      category: 'community',
      themeId: MorphThemeId.neon,
      wallpaperId: WallpaperId.nightCity,
      layoutPortrait: MorphLayoutId.grid,
      layoutLandscape: MorphLayoutId.grid,
      iconStyle: IconStyleId.squircle,
      targetProfile: MorphProfileId.phone,
      showLabels: true,
      iconScale: 1.0,
      gridColumns: 4,
      dockIds: ['browser', 'messages', 'music', 'camera', 'settings'],
      homeIds: [
        'browser',
        'music',
        'notes',
        'maps',
        'gallery',
        'mail',
        'clock',
        'store',
      ],
      tags: ['template', 'share'],
      builtIn: true,
    ),
  ];
}

const kMorphPackCategories = [
  'all',
  'mode',
  'theme',
  'layout',
  'community',
];
