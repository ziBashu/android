/// Morph notification-bar / control-center tiles. Pure — tests page + state.
library;

import 'smart_island.dart';

/// Essential set. First screen holds 8–10; the rest wait behind expand.
enum ShadeTileId {
  wifi,
  mobile,
  bluetooth,
  airplane,
  flashlight,
  location,
  hotspot,
  sound,
  autoRotate,
  cast,
  batterySaver,
  dnd,
}

extension ShadeTileIdX on ShadeTileId {
  String get label => switch (this) {
        ShadeTileId.wifi => 'Wi-Fi',
        ShadeTileId.mobile => 'Mobile data',
        ShadeTileId.bluetooth => 'Bluetooth',
        ShadeTileId.airplane => 'Airplane',
        ShadeTileId.flashlight => 'Flashlight',
        ShadeTileId.location => 'Location',
        ShadeTileId.hotspot => 'Hotspot',
        ShadeTileId.sound => 'Sound',
        ShadeTileId.autoRotate => 'Auto-rotate',
        ShadeTileId.cast => 'Cast',
        ShadeTileId.batterySaver => 'Battery Saver',
        ShadeTileId.dnd => 'Do Not Disturb',
      };

  String get shortLabel => switch (this) {
        ShadeTileId.wifi => 'Wi-Fi',
        ShadeTileId.mobile => 'Mobile',
        ShadeTileId.bluetooth => 'Bluetooth',
        ShadeTileId.airplane => 'Airplane',
        ShadeTileId.flashlight => 'Flash',
        ShadeTileId.location => 'Location',
        ShadeTileId.hotspot => 'Hotspot',
        ShadeTileId.sound => 'Sound',
        ShadeTileId.autoRotate => 'Auto-rotate',
        ShadeTileId.cast => 'Cast',
        ShadeTileId.batterySaver => 'Battery Saver',
        ShadeTileId.dnd => 'DND',
      };
}

/// Paging of the essential set. First page is 8–10 tiles.
class ShadeLayout {
  ShadeLayout._();

  static const firstPageCount = 10;

  static const List<ShadeTileId> essentials = [
    ShadeTileId.wifi,
    ShadeTileId.mobile,
    ShadeTileId.bluetooth,
    ShadeTileId.airplane,
    ShadeTileId.flashlight,
    ShadeTileId.location,
    ShadeTileId.hotspot,
    ShadeTileId.sound,
    ShadeTileId.autoRotate,
    ShadeTileId.batterySaver,
    ShadeTileId.cast,
    ShadeTileId.dnd,
  ];

  static List<ShadeTileId> firstPage({int count = firstPageCount}) {
    final n = count.clamp(8, 10);
    return essentials.take(n).toList(growable: false);
  }

  static List<ShadeTileId> expandedPage({int firstCount = firstPageCount}) {
    final n = firstCount.clamp(8, 10);
    return essentials.skip(n).toList(growable: false);
  }
}

class ShadeTileView {
  const ShadeTileView({
    required this.id,
    required this.on,
    this.detail = '',
  });

  final ShadeTileId id;
  final bool on;
  final String detail;

  String get stateLabel => on ? 'ON' : 'OFF';

  String get subtitle {
    if (detail.isNotEmpty) return detail;
    return stateLabel;
  }

  ShadeTileView copyWith({bool? on, String? detail}) {
    return ShadeTileView(
      id: id,
      on: on ?? this.on,
      detail: detail ?? this.detail,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id.name,
        'on': on,
        'detail': detail,
      };

  static ShadeTileView? fromJson(Map<String, dynamic> m) {
    final name = '${m['id'] ?? ''}';
    ShadeTileId? id;
    for (final t in ShadeTileId.values) {
      if (t.name == name) id = t;
    }
    if (id == null) return null;
    return ShadeTileView(
      id: id,
      on: m['on'] as bool? ?? false,
      detail: '${m['detail'] ?? ''}',
    );
  }
}

class ShadeMedia {
  const ShadeMedia({
    required this.title,
    this.artist = '',
    this.playing = false,
    this.progress = 0,
  });

  final String title;
  final String artist;
  final bool playing;
  final double progress;

  /// Shade media row always offers play/pause/prev/next (+ seek when known).
  bool get hasTransport => true;

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'playing': playing,
        'progress': progress,
      };

  static ShadeMedia? fromJson(Map<String, dynamic>? m) {
    if (m == null) return null;
    final title = '${m['title'] ?? ''}';
    final artist = '${m['artist'] ?? m['subtitle'] ?? ''}';
    final playing = m['playing'] as bool? ?? false;
    final progress = (m['progress'] as num?)?.toDouble() ?? 0;
    if (title.isEmpty && artist.isEmpty && !playing && progress <= 0) {
      return null;
    }
    return ShadeMedia(
      title: title.isEmpty ? (playing ? 'Now playing' : 'Music') : title,
      artist: artist,
      playing: playing,
      progress: progress,
    );
  }

  static ShadeMedia? fromActivity(IslandActivity activity) {
    if (!activity.isMusic) return null;
    return ShadeMedia(
      title: activity.title.isEmpty
          ? (activity.playing ? 'Now playing' : 'Music')
          : activity.title,
      artist: activity.subtitle,
      playing: activity.playing,
      progress: activity.progress,
    );
  }
}

class ShadeNotification {
  const ShadeNotification({
    required this.packageName,
    required this.title,
    this.body = '',
    this.key = '',
  });

  final String packageName;
  final String title;
  final String body;
  final String key;
}

class ShadeSnapshot {
  const ShadeSnapshot({
    required this.now,
    required this.batteryPercent,
    required this.tiles,
    this.brightness = 0.5,
    this.media,
    this.notifications = const [],
    this.expanded = false,
  });

  final DateTime now;
  final int batteryPercent;
  final List<ShadeTileView> tiles;
  final double brightness;
  final ShadeMedia? media;
  final List<ShadeNotification> notifications;
  final bool expanded;

  List<ShadeTileView> get firstPageTiles {
    final order = ShadeLayout.firstPage();
    return [
      for (final id in order)
        tiles.cast<ShadeTileView?>().firstWhere(
              (t) => t!.id == id,
              orElse: () => ShadeTileView(id: id, on: false),
            )!,
    ];
  }

  List<ShadeTileView> get extraTiles {
    final order = ShadeLayout.expandedPage();
    return [
      for (final id in order)
        tiles.cast<ShadeTileView?>().firstWhere(
              (t) => t!.id == id,
              orElse: () => ShadeTileView(id: id, on: false),
            )!,
    ];
  }

  ShadeSnapshot expand() => copyWith(expanded: true);
  ShadeSnapshot collapse() => copyWith(expanded: false);

  ShadeSnapshot withTile(ShadeTileView tile) {
    final next = [
      for (final t in tiles)
        if (t.id == tile.id) tile else t,
    ];
    if (!next.any((t) => t.id == tile.id)) next.add(tile);
    return copyWith(tiles: next);
  }

  ShadeSnapshot copyWith({
    DateTime? now,
    int? batteryPercent,
    List<ShadeTileView>? tiles,
    double? brightness,
    ShadeMedia? media,
    List<ShadeNotification>? notifications,
    bool? expanded,
    bool clearMedia = false,
  }) {
    return ShadeSnapshot(
      now: now ?? this.now,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      tiles: tiles ?? this.tiles,
      brightness: brightness ?? this.brightness,
      media: clearMedia ? null : (media ?? this.media),
      notifications: notifications ?? this.notifications,
      expanded: expanded ?? this.expanded,
    );
  }

  /// Build from native `{wifi: {on, detail}, ...}` plus clock/battery.
  static ShadeSnapshot fromNative(
    Map<String, dynamic> raw, {
    DateTime? now,
    int batteryPercent = 0,
  }) {
    final tiles = <ShadeTileView>[];
    for (final id in ShadeTileId.values) {
      final block = raw[id.name];
      if (block is Map) {
        tiles.add(
          ShadeTileView(
            id: id,
            on: block['on'] == true,
            detail: '${block['detail'] ?? ''}',
          ),
        );
      } else {
        tiles.add(ShadeTileView(id: id, on: false));
      }
    }
    final mediaRaw = raw['media'];
    final notesRaw = raw['notifications'];
    final notes = <ShadeNotification>[];
    if (notesRaw is List) {
      for (final e in notesRaw) {
        if (e is! Map) continue;
        notes.add(
          ShadeNotification(
            packageName: '${e['packageName'] ?? ''}',
            title: '${e['title'] ?? ''}',
            body: '${e['body'] ?? ''}',
            key: '${e['key'] ?? ''}',
          ),
        );
      }
    }
    return ShadeSnapshot(
      now: now ?? DateTime.now(),
      batteryPercent: (raw['batteryPercent'] as num?)?.toInt() ?? batteryPercent,
      tiles: tiles,
      brightness: (raw['brightness'] as num?)?.toDouble() ?? 0.5,
      media: ShadeMedia.fromJson(
        mediaRaw is Map ? Map<String, dynamic>.from(mediaRaw) : null,
      ),
      notifications: notes,
    );
  }
}
