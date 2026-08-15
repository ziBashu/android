import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Visual theme identity (Phase 1).
enum MorphThemeId {
  neon,
  glass,
  dark,
  light,
  material,
}

/// Home layout modes (Phase 1 + Phase 4 desktop shell).
enum MorphLayoutId {
  minimal,
  grid,
  spatial,
  cards,
  desktop,
}

/// Orientation / personality profiles (Phase 2 core + Vision spaces).
///
/// These are **environments**, not skins — each answers “what is this phone
/// right now?” (pocket, workspace, console, reader, dashboard, …).
enum MorphProfileId {
  /// Pocket device — portrait, one-hand, simple UI.
  phone,
  /// Work Space — calendar, mail, docs, notes.
  work,
  /// Gaming console — landscape, focus, performance feel.
  gaming,
  /// Book reader — portrait, minimal, eye comfort.
  reading,
  /// Dashboard / Car — landscape, large controls, nav + music.
  car,
  /// Mini computer — landscape, multi-window desktop shell.
  desktop,
  /// Relax Space — music, movies, wind-down.
  relax,
  /// Study Space — books, dictionary, timer, notes.
  study,
  /// Travel Space — map, translation, camera, currency.
  travel,
}

/// How MorphOS decides to change environments (product intelligence modes).
enum IntelligenceMode {
  /// Beginner: MorphOS automatically morphs from context.
  beginner,
  /// Ask first: propose a morph (“Switch to desktop?”) before applying.
  ask,
  /// Advanced: only explicit user rules (per-app + context IF/THEN).
  advanced,
}

/// Product “device shape” — phone is not always a phone.
enum DeviceShape {
  pocket,
  gamingConsole,
  miniComputer,
  bookReader,
  dashboard,
  workSpace,
  relaxSpace,
  studySpace,
  travelSpace,
}

/// Why a morph was proposed (orientation / context engine).
enum MorphTriggerKind {
  manual,
  appRule,
  category,
  timeOfDay,
  charging,
  keyboard,
  externalDisplay,
  gesture,
  pack,
  contextRule,
}

/// Pending or applied morph proposal — used by Ask mode + UI copy.
class MorphSuggestion {
  const MorphSuggestion({
    required this.profileId,
    required this.reason,
    required this.prompt,
    required this.trigger,
    this.appId,
  });

  final MorphProfileId profileId;
  final String reason;
  /// User-facing question, e.g. “Open entertainment landscape?”
  final String prompt;
  final MorphTriggerKind trigger;
  final String? appId;
}

/// Advanced IF/THEN context rule (Intelligence · Advanced mode).
class MorphContextRule {
  const MorphContextRule({
    required this.id,
    required this.trigger,
    required this.profileId,
    this.matchValue,
    this.enabled = true,
    this.label,
  });

  final String id;
  final MorphTriggerKind trigger;
  final MorphProfileId profileId;
  /// Optional matcher (e.g. category name, hour band, package id).
  final String? matchValue;
  final bool enabled;
  final String? label;

  Map<String, dynamic> toJson() => {
        'id': id,
        'trigger': trigger.name,
        'profileId': profileId.name,
        if (matchValue != null) 'matchValue': matchValue,
        'enabled': enabled,
        if (label != null) 'label': label,
      };

  static MorphContextRule fromJson(Map<String, dynamic> m) {
    MorphTriggerKind trig = MorphTriggerKind.contextRule;
    final t = m['trigger'] as String?;
    if (t != null) {
      for (final v in MorphTriggerKind.values) {
        if (v.name == t) {
          trig = v;
          break;
        }
      }
    }
    MorphProfileId pid = MorphProfileId.phone;
    final p = m['profileId'] as String?;
    if (p != null) {
      for (final v in MorphProfileId.values) {
        if (v.name == p) {
          pid = v;
          break;
        }
      }
    }
    return MorphContextRule(
      id: m['id'] as String? ??
          'rule_${DateTime.now().millisecondsSinceEpoch}',
      trigger: trig,
      profileId: pid,
      matchValue: m['matchValue'] as String?,
      enabled: m['enabled'] as bool? ?? true,
      label: m['label'] as String?,
    );
  }
}

/// How icons are rendered.
enum IconStyleId {
  rounded,
  squircle,
  circle,
  square,
  neon,
}

/// Wallpaper engine style (static gradients for V1; video later).
enum WallpaperId {
  verdantEmerald,
  dawn,
  nightCity,
  cyberpunk,
  ocean,
  forest,
  aurora,
  voidBlack,
}

extension MorphThemeX on MorphThemeId {
  String get label => switch (this) {
        MorphThemeId.neon => 'Neon',
        MorphThemeId.glass => 'Glass',
        MorphThemeId.dark => 'Dark',
        MorphThemeId.light => 'Light',
        MorphThemeId.material => 'Material',
      };

  String get blurb => switch (this) {
        MorphThemeId.neon => 'Cyber glow, high contrast',
        MorphThemeId.glass => 'Frosted panels, soft light',
        MorphThemeId.dark => 'OLED-friendly deep ink',
        MorphThemeId.light => 'Clean daylight surfaces',
        MorphThemeId.material => 'System Material You feel',
      };
}

extension MorphLayoutX on MorphLayoutId {
  String get label => switch (this) {
        MorphLayoutId.minimal => 'Minimal',
        MorphLayoutId.grid => 'Grid',
        MorphLayoutId.spatial => 'Spatial',
        MorphLayoutId.cards => 'Cards',
        MorphLayoutId.desktop => 'Desktop',
      };

  IconData get icon => switch (this) {
        MorphLayoutId.minimal => Icons.crop_free,
        MorphLayoutId.grid => Icons.grid_view_rounded,
        MorphLayoutId.spatial => Icons.bubble_chart_outlined,
        MorphLayoutId.cards => Icons.view_agenda_outlined,
        MorphLayoutId.desktop => Icons.desktop_windows_outlined,
      };
}

extension IntelligenceModeX on IntelligenceMode {
  String get label => switch (this) {
        IntelligenceMode.beginner => 'Beginner · Auto',
        IntelligenceMode.ask => 'Ask first',
        IntelligenceMode.advanced => 'Advanced · Rules',
      };

  String get blurb => switch (this) {
        IntelligenceMode.beginner =>
          'MorphOS changes the environment for you (open game → Gaming Morph).',
        IntelligenceMode.ask =>
          'MorphOS proposes a change and waits for your yes.',
        IntelligenceMode.advanced =>
          'Only your IF/THEN and per-app rules fire — no silent category morphs.',
      };
}

extension DeviceShapeX on DeviceShape {
  String get label => switch (this) {
        DeviceShape.pocket => 'Pocket device',
        DeviceShape.gamingConsole => 'Gaming console',
        DeviceShape.miniComputer => 'Mini computer',
        DeviceShape.bookReader => 'Book reader',
        DeviceShape.dashboard => 'Dashboard',
        DeviceShape.workSpace => 'Work Space',
        DeviceShape.relaxSpace => 'Relax Space',
        DeviceShape.studySpace => 'Study Space',
        DeviceShape.travelSpace => 'Travel Space',
      };

  String get blurb => switch (this) {
        DeviceShape.pocket => 'Portrait · one hand · simple UI',
        DeviceShape.gamingConsole => 'Landscape · game controls · focus',
        DeviceShape.miniComputer => 'Landscape · multi-window · keyboard',
        DeviceShape.bookReader => 'Portrait · minimal · eye comfort',
        DeviceShape.dashboard => 'Landscape · large controls · nav + music',
        DeviceShape.workSpace => 'Calendar · email · documents · notes',
        DeviceShape.relaxSpace => 'Music · movies · games · wind-down',
        DeviceShape.studySpace => 'Books · dictionary · timer · notes',
        DeviceShape.travelSpace => 'Map · translation · camera · currency',
      };
}

extension MorphProfileX on MorphProfileId {
  String get label => switch (this) {
        MorphProfileId.phone => 'Pocket Morph',
        MorphProfileId.work => 'Work Space',
        MorphProfileId.gaming => 'Gaming Morph',
        MorphProfileId.reading => 'Reading Morph',
        MorphProfileId.car => 'Dashboard Morph',
        MorphProfileId.desktop => 'Desktop Morph',
        MorphProfileId.relax => 'Relax Space',
        MorphProfileId.study => 'Study Space',
        MorphProfileId.travel => 'Travel Space',
      };

  String get blurb => switch (this) {
        MorphProfileId.phone => 'Pocket device — portrait, one hand, simple UI',
        MorphProfileId.work => 'Work Space — mail, calendar, docs, notes',
        MorphProfileId.gaming => 'Gaming console — landscape lock + focus HUD',
        MorphProfileId.reading => 'Book reader — portrait, warm, quiet',
        MorphProfileId.car => 'Dashboard — large controls, landscape nav',
        MorphProfileId.desktop => 'Mini computer — multi-window workstation',
        MorphProfileId.relax => 'Relax Space — media and night wind-down',
        MorphProfileId.study => 'Study Space — books, dictionary, timer, notes',
        MorphProfileId.travel =>
          'Travel Space — map, translation, camera, currency',
      };

  IconData get icon => switch (this) {
        MorphProfileId.phone => Icons.smartphone,
        MorphProfileId.work => Icons.work_outline,
        MorphProfileId.gaming => Icons.sports_esports_outlined,
        MorphProfileId.reading => Icons.menu_book_outlined,
        MorphProfileId.car => Icons.directions_car_outlined,
        MorphProfileId.desktop => Icons.desktop_windows_outlined,
        MorphProfileId.relax => Icons.nightlight_round,
        MorphProfileId.study => Icons.school_outlined,
        MorphProfileId.travel => Icons.flight_takeoff,
      };

  /// Product shape this morph turns the phone into.
  DeviceShape get shape => switch (this) {
        MorphProfileId.phone => DeviceShape.pocket,
        MorphProfileId.work => DeviceShape.workSpace,
        MorphProfileId.gaming => DeviceShape.gamingConsole,
        MorphProfileId.reading => DeviceShape.bookReader,
        MorphProfileId.car => DeviceShape.dashboard,
        MorphProfileId.desktop => DeviceShape.miniComputer,
        MorphProfileId.relax => DeviceShape.relaxSpace,
        MorphProfileId.study => DeviceShape.studySpace,
        MorphProfileId.travel => DeviceShape.travelSpace,
      };

  /// Preferred orientations when this morph is active (MorphOS activity).
  List<DeviceOrientation> get orientations => switch (this) {
        MorphProfileId.phone || MorphProfileId.study => const [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ],
        MorphProfileId.reading => const [DeviceOrientation.portraitUp],
        MorphProfileId.work ||
        MorphProfileId.gaming ||
        MorphProfileId.car ||
        MorphProfileId.desktop ||
        MorphProfileId.travel =>
          const [
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ],
        MorphProfileId.relax => DeviceOrientation.values,
      };

  bool get prefersLandscape => switch (this) {
        MorphProfileId.work ||
        MorphProfileId.gaming ||
        MorphProfileId.car ||
        MorphProfileId.desktop ||
        MorphProfileId.travel =>
          true,
        _ => false,
      };

  /// Phase 2+ system-wide orientation mode for Settings.System / Accessibility.
  String get systemOrientationMode => switch (this) {
        MorphProfileId.phone || MorphProfileId.study => 'sensor',
        MorphProfileId.reading => 'portrait',
        MorphProfileId.work ||
        MorphProfileId.gaming ||
        MorphProfileId.car ||
        MorphProfileId.desktop ||
        MorphProfileId.travel =>
          'landscape',
        MorphProfileId.relax => 'sensor',
      };

  /// Short Ask-mode prompt when proposing this environment.
  String get askPrompt => switch (this) {
        MorphProfileId.phone => 'Return to pocket mode?',
        MorphProfileId.work => 'Switch to Work Space?',
        MorphProfileId.gaming => 'Enter gaming console mode?',
        MorphProfileId.reading => 'Switch to book reader mode?',
        MorphProfileId.car => 'Switch to dashboard mode?',
        MorphProfileId.desktop => 'Switch to desktop / mini computer?',
        MorphProfileId.relax => 'Enter Relax Space?',
        MorphProfileId.study => 'Enter Study Space?',
        MorphProfileId.travel => 'Enter Travel Space?',
      };
}

extension WallpaperX on WallpaperId {
  String get label => switch (this) {
        WallpaperId.verdantEmerald => 'Verdant Emerald',
        WallpaperId.dawn => 'Dawn Sky',
        WallpaperId.nightCity => 'Night City',
        WallpaperId.cyberpunk => 'Cyberpunk',
        WallpaperId.ocean => 'Ocean',
        WallpaperId.forest => 'Forest',
        WallpaperId.aurora => 'Aurora',
        WallpaperId.voidBlack => 'Void',
      };

  /// Bundled photo wallpaper, if this style is not a gradient.
  String? get assetPath => switch (this) {
        WallpaperId.verdantEmerald =>
          'assets/wallpapers/verdant_emerald.jpg',
        _ => null,
      };
}

/// Full environment bundle applied with a morph (Phase 2).
class MorphEnvironment {
  const MorphEnvironment({
    required this.profileId,
    required this.themeId,
    required this.wallpaperId,
    required this.layoutPortrait,
    required this.layoutLandscape,
    required this.iconStyle,
    required this.showLabels,
    required this.iconScale,
    required this.gridColumns,
    required this.dockIds,
    required this.homeIds,
    this.quietMode = false,
    this.largeTargets = false,
  });

  final MorphProfileId profileId;
  final MorphThemeId themeId;
  final WallpaperId wallpaperId;
  final MorphLayoutId layoutPortrait;
  final MorphLayoutId layoutLandscape;
  final IconStyleId iconStyle;
  final bool showLabels;
  final double iconScale;
  final int gridColumns;
  final List<String> dockIds;
  final List<String> homeIds;
  final bool quietMode;
  final bool largeTargets;

  MorphLayoutId layoutFor({required bool landscape}) =>
      landscape ? layoutLandscape : layoutPortrait;

  MorphEnvironment copyWith({
    MorphThemeId? themeId,
    WallpaperId? wallpaperId,
    MorphLayoutId? layoutPortrait,
    MorphLayoutId? layoutLandscape,
    IconStyleId? iconStyle,
    bool? showLabels,
    double? iconScale,
    int? gridColumns,
    List<String>? dockIds,
    List<String>? homeIds,
    bool? quietMode,
    bool? largeTargets,
  }) {
    return MorphEnvironment(
      profileId: profileId,
      themeId: themeId ?? this.themeId,
      wallpaperId: wallpaperId ?? this.wallpaperId,
      layoutPortrait: layoutPortrait ?? this.layoutPortrait,
      layoutLandscape: layoutLandscape ?? this.layoutLandscape,
      iconStyle: iconStyle ?? this.iconStyle,
      showLabels: showLabels ?? this.showLabels,
      iconScale: iconScale ?? this.iconScale,
      gridColumns: gridColumns ?? this.gridColumns,
      dockIds: dockIds ?? this.dockIds,
      homeIds: homeIds ?? this.homeIds,
      quietMode: quietMode ?? this.quietMode,
      largeTargets: largeTargets ?? this.largeTargets,
    );
  }

  Map<String, dynamic> toJson() => {
        'profileId': profileId.name,
        'themeId': themeId.name,
        'wallpaperId': wallpaperId.name,
        'layoutPortrait': layoutPortrait.name,
        'layoutLandscape': layoutLandscape.name,
        'iconStyle': iconStyle.name,
        'showLabels': showLabels,
        'iconScale': iconScale,
        'gridColumns': gridColumns,
        'dockIds': dockIds,
        'homeIds': homeIds,
        'quietMode': quietMode,
        'largeTargets': largeTargets,
      };

  static MorphEnvironment fromJson(Map<String, dynamic> m) {
    T byName<T extends Enum>(List<T> values, String? name, T fallback) {
      if (name == null) return fallback;
      for (final v in values) {
        if (v.name == name) return v;
      }
      return fallback;
    }

    final profileId = byName(
      MorphProfileId.values,
      m['profileId'] as String?,
      MorphProfileId.phone,
    );
    return MorphEnvironment(
      profileId: profileId,
      themeId: byName(
        MorphThemeId.values,
        m['themeId'] as String?,
        MorphThemeId.neon,
      ),
      wallpaperId: byName(
        WallpaperId.values,
        m['wallpaperId'] as String?,
        WallpaperId.verdantEmerald,
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
      showLabels: m['showLabels'] as bool? ?? true,
      iconScale: (m['iconScale'] as num?)?.toDouble() ?? 1.0,
      gridColumns: m['gridColumns'] as int? ?? 4,
      dockIds: List<String>.from(m['dockIds'] as List? ?? const []),
      homeIds: List<String>.from(m['homeIds'] as List? ?? const []),
      quietMode: m['quietMode'] as bool? ?? false,
      largeTargets: m['largeTargets'] as bool? ?? false,
    );
  }

  /// Factory defaults for each morph personality.
  static MorphEnvironment defaultsFor(MorphProfileId id) {
    const dockPhone = ['browser', 'messages', 'music', 'camera', 'settings'];
    const homePhone = [
      'browser',
      'music',
      'notes',
      'maps',
      'gallery',
      'mail',
      'clock',
      'store',
    ];
    switch (id) {
      case MorphProfileId.phone:
        return const MorphEnvironment(
          profileId: MorphProfileId.phone,
          themeId: MorphThemeId.neon,
          wallpaperId: WallpaperId.verdantEmerald,
          layoutPortrait: MorphLayoutId.grid,
          layoutLandscape: MorphLayoutId.grid,
          iconStyle: IconStyleId.squircle,
          showLabels: true,
          iconScale: 1.0,
          gridColumns: 4,
          dockIds: dockPhone,
          homeIds: homePhone,
        );
      case MorphProfileId.work:
        return const MorphEnvironment(
          profileId: MorphProfileId.work,
          themeId: MorphThemeId.material,
          wallpaperId: WallpaperId.dawn,
          layoutPortrait: MorphLayoutId.cards,
          layoutLandscape: MorphLayoutId.cards,
          iconStyle: IconStyleId.rounded,
          showLabels: true,
          iconScale: 1.0,
          gridColumns: 5,
          dockIds: ['mail', 'browser', 'notes', 'calendar_work', 'settings'],
          homeIds: ['mail', 'browser', 'notes', 'files', 'maps', 'clock'],
        );
      case MorphProfileId.gaming:
        return const MorphEnvironment(
          profileId: MorphProfileId.gaming,
          themeId: MorphThemeId.neon,
          wallpaperId: WallpaperId.cyberpunk,
          layoutPortrait: MorphLayoutId.spatial,
          layoutLandscape: MorphLayoutId.spatial,
          iconStyle: IconStyleId.neon,
          showLabels: false,
          iconScale: 1.15,
          gridColumns: 4,
          dockIds: ['store', 'browser', 'music', 'settings'],
          homeIds: ['store', 'browser', 'music', 'gallery', 'files'],
          quietMode: true,
        );
      case MorphProfileId.reading:
        return const MorphEnvironment(
          profileId: MorphProfileId.reading,
          themeId: MorphThemeId.dark,
          wallpaperId: WallpaperId.forest,
          layoutPortrait: MorphLayoutId.minimal,
          layoutLandscape: MorphLayoutId.cards,
          iconStyle: IconStyleId.circle,
          showLabels: true,
          iconScale: 1.05,
          gridColumns: 3,
          dockIds: ['notes', 'browser', 'music', 'settings'],
          homeIds: ['notes', 'browser', 'clock', 'music'],
          quietMode: true,
        );
      case MorphProfileId.car:
        return const MorphEnvironment(
          profileId: MorphProfileId.car,
          themeId: MorphThemeId.dark,
          wallpaperId: WallpaperId.voidBlack,
          layoutPortrait: MorphLayoutId.grid,
          layoutLandscape: MorphLayoutId.grid,
          iconStyle: IconStyleId.rounded,
          showLabels: true,
          iconScale: 1.3,
          gridColumns: 3,
          dockIds: ['maps', 'music', 'messages', 'settings'],
          homeIds: ['maps', 'music', 'messages', 'browser', 'clock'],
          largeTargets: true,
        );
      case MorphProfileId.desktop:
        return const MorphEnvironment(
          profileId: MorphProfileId.desktop,
          themeId: MorphThemeId.glass,
          wallpaperId: WallpaperId.aurora,
          layoutPortrait: MorphLayoutId.desktop,
          layoutLandscape: MorphLayoutId.desktop,
          iconStyle: IconStyleId.squircle,
          showLabels: true,
          iconScale: 1.0,
          gridColumns: 5,
          dockIds: ['browser', 'files', 'notes', 'mail', 'settings'],
          homeIds: [
            'browser',
            'files',
            'notes',
            'mail',
            'gallery',
            'clock',
            'store',
          ],
        );
      case MorphProfileId.relax:
        return const MorphEnvironment(
          profileId: MorphProfileId.relax,
          themeId: MorphThemeId.glass,
          wallpaperId: WallpaperId.ocean,
          layoutPortrait: MorphLayoutId.minimal,
          layoutLandscape: MorphLayoutId.spatial,
          iconStyle: IconStyleId.circle,
          showLabels: true,
          iconScale: 1.1,
          gridColumns: 3,
          dockIds: ['music', 'gallery', 'notes', 'settings'],
          homeIds: ['music', 'gallery', 'notes', 'clock', 'browser', 'video'],
          quietMode: true,
        );
      case MorphProfileId.study:
        return const MorphEnvironment(
          profileId: MorphProfileId.study,
          themeId: MorphThemeId.light,
          wallpaperId: WallpaperId.dawn,
          layoutPortrait: MorphLayoutId.cards,
          layoutLandscape: MorphLayoutId.cards,
          iconStyle: IconStyleId.rounded,
          showLabels: true,
          iconScale: 1.0,
          gridColumns: 3,
          dockIds: ['notes', 'reader', 'timer', 'dictionary', 'settings'],
          homeIds: [
            'notes',
            'reader',
            'dictionary',
            'timer',
            'browser',
            'clock',
          ],
          quietMode: true,
        );
      case MorphProfileId.travel:
        return const MorphEnvironment(
          profileId: MorphProfileId.travel,
          themeId: MorphThemeId.material,
          wallpaperId: WallpaperId.aurora,
          layoutPortrait: MorphLayoutId.grid,
          layoutLandscape: MorphLayoutId.grid,
          iconStyle: IconStyleId.squircle,
          showLabels: true,
          iconScale: 1.15,
          gridColumns: 3,
          dockIds: ['maps', 'translate', 'camera', 'currency', 'settings'],
          homeIds: [
            'maps',
            'translate',
            'camera',
            'currency',
            'browser',
            'messages',
          ],
          largeTargets: true,
        );
    }
  }
}

/// Per-app morph rule (Phase 2) — like Rotation's per-app orientation, but MorphOS environment.
class AppMorphRule {
  const AppMorphRule({
    required this.appId,
    required this.profileId,
    this.enabled = true,
  });

  final String appId;
  final MorphProfileId profileId;
  final bool enabled;

  Map<String, dynamic> toJson() => {
        'appId': appId,
        'profileId': profileId.name,
        'enabled': enabled,
      };

  static AppMorphRule fromJson(Map<String, dynamic> m) => AppMorphRule(
        appId: m['appId'] as String,
        profileId: MorphProfileId.values.byName(m['profileId'] as String),
        enabled: m['enabled'] as bool? ?? true,
      );
}

/// Dock / home shortcut entry.
class MorphAppItem {
  const MorphAppItem({
    required this.id,
    required this.label,
    required this.icon,
    this.packageName,
    this.color = const Color(0xFF7C4DFF),
    this.isSystemDemo = true,
    this.category = 'other',
    this.iconBytes,
  });

  final String id;
  final String label;
  final IconData icon;
  final String? packageName;
  final Color color;
  final bool isSystemDemo;

  /// Hint for default morph rules: media|work|game|read|nav|other
  final String category;

  /// Optional real launcher icon bytes (Phase 3).
  final List<int>? iconBytes;

  MorphAppItem copyWith({
    String? label,
    IconData? icon,
    Color? color,
    List<int>? iconBytes,
  }) {
    return MorphAppItem(
      id: id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      packageName: packageName,
      color: color ?? this.color,
      isSystemDemo: isSystemDemo,
      category: category,
      iconBytes: iconBytes ?? this.iconBytes,
    );
  }
}

/// Infer morph category from package / app name (Phase 3 adaptive).
String inferAppCategory({required String name, String? packageName}) {
  final s = '${name.toLowerCase()} ${(packageName ?? '').toLowerCase()}';
  if (s.contains('game') ||
      s.contains('play') && s.contains('game') ||
      s.contains('epic') ||
      s.contains('steam') ||
      s.contains('roblox') ||
      s.contains('minecraft')) {
    return 'game';
  }
  if (s.contains('map') ||
      s.contains('nav') ||
      s.contains('waze') ||
      s.contains('uber') ||
      s.contains('geo')) {
    return 'nav';
  }
  if (s.contains('dict') ||
      s.contains('anki') ||
      s.contains('quizlet') ||
      s.contains('study') ||
      s.contains('timer') ||
      s.contains('pomodoro')) {
    return 'study';
  }
  if (s.contains('translat') ||
      s.contains('currency') ||
      s.contains('trip') ||
      s.contains('travel') ||
      s.contains('booking') ||
      s.contains('airline')) {
    return 'travel';
  }
  if (s.contains('book') ||
      s.contains('kindle') ||
      s.contains('reader') ||
      s.contains('novel') ||
      s.contains('pdf')) {
    return 'read';
  }
  if (s.contains('mail') ||
      s.contains('outlook') ||
      s.contains('slack') ||
      s.contains('teams') ||
      s.contains('docs') ||
      s.contains('office') ||
      s.contains('calendar') ||
      s.contains('notion')) {
    return 'work';
  }
  if (s.contains('youtube') ||
      s.contains('netflix') ||
      s.contains('spotify') ||
      s.contains('music') ||
      s.contains('video') ||
      s.contains('photo') ||
      s.contains('gallery') ||
      s.contains('tiktok') ||
      s.contains('cinema')) {
    return 'media';
  }
  return 'other';
}

MorphProfileId? profileForCategory(String category) {
  return switch (category) {
    'game' => MorphProfileId.gaming,
    'nav' => MorphProfileId.car,
    'read' => MorphProfileId.reading,
    'work' => MorphProfileId.work,
    'media' => MorphProfileId.relax,
    'study' => MorphProfileId.study,
    'travel' => MorphProfileId.travel,
    _ => null,
  };
}

/// Built-in demo apps for offline / when package query is limited.
const List<MorphAppItem> kDemoApps = [
  MorphAppItem(
    id: 'browser',
    label: 'Browser',
    icon: Icons.language,
    color: Color(0xFF42A5F5),
    category: 'work',
  ),
  MorphAppItem(
    id: 'messages',
    label: 'Messages',
    icon: Icons.chat_bubble_outline,
    color: Color(0xFF66BB6A),
    category: 'other',
  ),
  MorphAppItem(
    id: 'camera',
    label: 'Camera',
    icon: Icons.photo_camera_outlined,
    color: Color(0xFFEF5350),
    category: 'media',
  ),
  MorphAppItem(
    id: 'music',
    label: 'Music Vault',
    icon: Icons.music_note_outlined,
    color: Color(0xFFAB47BC),
    category: 'media',
  ),
  MorphAppItem(
    id: 'gallery',
    label: 'Gallery',
    icon: Icons.photo_outlined,
    color: Color(0xFFFFA726),
    category: 'media',
  ),
  MorphAppItem(
    id: 'maps',
    label: 'Maps',
    icon: Icons.map_outlined,
    color: Color(0xFF26A69A),
    category: 'nav',
  ),
  MorphAppItem(
    id: 'mail',
    label: 'Mail',
    icon: Icons.mail_outline,
    color: Color(0xFF5C6BC0),
    category: 'work',
  ),
  MorphAppItem(
    id: 'notes',
    label: 'Notes',
    icon: Icons.sticky_note_2_outlined,
    color: Color(0xFFFFCA28),
    category: 'read',
  ),
  MorphAppItem(
    id: 'clock',
    label: 'Clock',
    icon: Icons.schedule,
    color: Color(0xFF00E5FF),
    category: 'other',
  ),
  MorphAppItem(
    id: 'settings',
    label: 'System',
    icon: Icons.settings_outlined,
    color: Color(0xFF90A4AE),
    category: 'other',
  ),
  MorphAppItem(
    id: 'store',
    label: 'Game Shelf',
    icon: Icons.sports_esports_outlined,
    color: Color(0xFFEC407A),
    category: 'game',
  ),
  MorphAppItem(
    id: 'files',
    label: 'Files',
    icon: Icons.folder_outlined,
    color: Color(0xFF8D6E63),
    category: 'work',
  ),
  MorphAppItem(
    id: 'calendar_work',
    label: 'Calendar',
    icon: Icons.calendar_month_outlined,
    color: Color(0xFF78909C),
    category: 'work',
  ),
  MorphAppItem(
    id: 'reader',
    label: 'Reader',
    icon: Icons.menu_book_outlined,
    color: Color(0xFFA1887F),
    category: 'read',
  ),
  MorphAppItem(
    id: 'video',
    label: 'Cinema',
    icon: Icons.movie_outlined,
    color: Color(0xFFE53935),
    category: 'media',
  ),
  MorphAppItem(
    id: 'dictionary',
    label: 'Dictionary',
    icon: Icons.menu_book,
    color: Color(0xFF8D6E63),
    category: 'study',
  ),
  MorphAppItem(
    id: 'timer',
    label: 'Focus Timer',
    icon: Icons.timer_outlined,
    color: Color(0xFF43A047),
    category: 'study',
  ),
  MorphAppItem(
    id: 'translate',
    label: 'Translate',
    icon: Icons.translate,
    color: Color(0xFF1E88E5),
    category: 'travel',
  ),
  MorphAppItem(
    id: 'currency',
    label: 'Currency',
    icon: Icons.currency_exchange,
    color: Color(0xFFF9A825),
    category: 'travel',
  ),
];

/// Default per-app morph rules shipped with Phase 2.
List<AppMorphRule> kDefaultAppMorphRules() => [
      const AppMorphRule(appId: 'store', profileId: MorphProfileId.gaming),
      const AppMorphRule(appId: 'video', profileId: MorphProfileId.relax),
      const AppMorphRule(appId: 'reader', profileId: MorphProfileId.reading),
      const AppMorphRule(appId: 'notes', profileId: MorphProfileId.study),
      const AppMorphRule(appId: 'dictionary', profileId: MorphProfileId.study),
      const AppMorphRule(appId: 'timer', profileId: MorphProfileId.study),
      const AppMorphRule(appId: 'mail', profileId: MorphProfileId.work),
      const AppMorphRule(appId: 'calendar_work', profileId: MorphProfileId.work),
      const AppMorphRule(appId: 'files', profileId: MorphProfileId.desktop),
      const AppMorphRule(appId: 'maps', profileId: MorphProfileId.travel),
      const AppMorphRule(appId: 'translate', profileId: MorphProfileId.travel),
      const AppMorphRule(appId: 'currency', profileId: MorphProfileId.travel),
      const AppMorphRule(appId: 'camera', profileId: MorphProfileId.travel),
      const AppMorphRule(appId: 'music', profileId: MorphProfileId.relax),
      const AppMorphRule(appId: 'gallery', profileId: MorphProfileId.relax),
    ];

/// Built-in advanced IF/THEN context rules (user can edit / disable).
List<MorphContextRule> kDefaultContextRules() => [
      const MorphContextRule(
        id: 'ctx.charge.desktop',
        trigger: MorphTriggerKind.charging,
        profileId: MorphProfileId.desktop,
        label: 'IF charging THEN Desktop Morph',
      ),
      const MorphContextRule(
        id: 'ctx.keyboard.desktop',
        trigger: MorphTriggerKind.keyboard,
        profileId: MorphProfileId.desktop,
        label: 'IF keyboard connected THEN Desktop Morph',
      ),
      const MorphContextRule(
        id: 'ctx.external.desktop',
        trigger: MorphTriggerKind.externalDisplay,
        profileId: MorphProfileId.desktop,
        label: 'IF external display THEN Desktop Morph',
      ),
      const MorphContextRule(
        id: 'ctx.category.game',
        trigger: MorphTriggerKind.category,
        matchValue: 'game',
        profileId: MorphProfileId.gaming,
        label: 'IF game app THEN Gaming Morph',
      ),
      const MorphContextRule(
        id: 'ctx.category.media',
        trigger: MorphTriggerKind.category,
        matchValue: 'media',
        profileId: MorphProfileId.relax,
        label: 'IF media app THEN Relax Space',
      ),
    ];
