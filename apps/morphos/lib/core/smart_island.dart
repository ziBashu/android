/// Smart Island — "what is happening right now", not a notification center.
/// Pure compact / expand units. Tests drive these.
library;

enum IslandKind {
  idle,
  music,
  timer,
  download,
  navigation,
  call,
  recording,
}

class IslandActivity {
  const IslandActivity({
    required this.kind,
    this.title = '',
    this.subtitle = '',
    this.expanded = false,
    this.progress = 0,
    this.playing = false,
    this.elapsedLabel = '',
  });

  final IslandKind kind;
  final String title;
  final String subtitle;
  final bool expanded;
  final double progress;
  final bool playing;
  final String elapsedLabel;

  bool get isIdle => kind == IslandKind.idle;
  bool get isMusic => kind == IslandKind.music;

  /// Generic fallbacks must stay compact — they must not sit on the OEM island.
  bool get hasSpecificTitle => IslandCopy.isSpecificTitle(title);

  static const musicTransport = ['seek', 'previous', 'pause', 'next'];

  List<String> get expandControls {
    if (kind == IslandKind.music) return musicTransport;
    return const [];
  }

  String get compactLabel {
    return switch (kind) {
      IslandKind.idle => '',
      IslandKind.music => title.isEmpty ? 'Music' : title,
      IslandKind.timer => elapsedLabel.isEmpty ? 'Timer' : elapsedLabel,
      IslandKind.download => progress <= 0
          ? 'Download'
          : 'Download ${(progress * 100).round()}%',
      IslandKind.navigation =>
        subtitle.isEmpty ? title : '$title  $subtitle',
      IslandKind.call =>
        elapsedLabel.isEmpty ? title : '$title  $elapsedLabel',
      IslandKind.recording =>
        elapsedLabel.isEmpty ? 'Recording' : 'Recording  $elapsedLabel',
    };
  }

  IslandActivity compact() => copyWith(expanded: false);

  /// Idle stays idle — expanding it must not create occupying chrome.
  IslandActivity expand() => isIdle ? this : copyWith(expanded: true);

  IslandActivity copyWith({
    IslandKind? kind,
    String? title,
    String? subtitle,
    bool? expanded,
    double? progress,
    bool? playing,
    String? elapsedLabel,
  }) {
    return IslandActivity(
      kind: kind ?? this.kind,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      expanded: expanded ?? this.expanded,
      progress: progress ?? this.progress,
      playing: playing ?? this.playing,
      elapsedLabel: elapsedLabel ?? this.elapsedLabel,
    );
  }

  static const idle = IslandActivity(kind: IslandKind.idle);

  static IslandActivity music({
    required String title,
    String artist = '',
    bool playing = true,
    double progress = 0,
    bool expanded = false,
  }) {
    return IslandActivity(
      kind: IslandKind.music,
      title: title.isEmpty ? (playing ? 'Now playing' : 'Music') : title,
      subtitle: artist,
      playing: playing,
      progress: progress.clamp(0, 1),
      expanded: expanded,
    );
  }

  static IslandActivity timer({
    required String remaining,
    bool expanded = false,
  }) {
    return IslandActivity(
      kind: IslandKind.timer,
      title: 'Timer',
      elapsedLabel: remaining,
      expanded: expanded,
    );
  }

  static IslandActivity download({
    required double progress,
    String title = 'Download',
    bool expanded = false,
  }) {
    return IslandActivity(
      kind: IslandKind.download,
      title: title,
      progress: progress.clamp(0, 1),
      expanded: expanded,
    );
  }

  static IslandActivity navigation({
    required String instruction,
    String distance = '',
    bool expanded = false,
  }) {
    return IslandActivity(
      kind: IslandKind.navigation,
      title: instruction,
      subtitle: distance,
      expanded: expanded,
    );
  }

  static IslandActivity call({
    required String name,
    String elapsed = '',
    bool expanded = false,
  }) {
    return IslandActivity(
      kind: IslandKind.call,
      title: name,
      elapsedLabel: elapsed,
      expanded: expanded,
    );
  }

  static IslandActivity recording({
    required String elapsed,
    bool expanded = false,
  }) {
    return IslandActivity(
      kind: IslandKind.recording,
      title: 'Recording',
      elapsedLabel: elapsed,
      expanded: expanded,
    );
  }

  /// Pick the most urgent live activity. Notifications feed this, not the island itself.
  static IslandActivity pickPrimary(List<IslandActivity> live) {
    const rank = [
      IslandKind.call,
      IslandKind.recording,
      IslandKind.navigation,
      IslandKind.timer,
      IslandKind.download,
      IslandKind.music,
    ];
    for (final k in rank) {
      for (final a in live) {
        if (a.kind == k) return a;
      }
    }
    return idle;
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'title': title,
        'subtitle': subtitle,
        'expanded': expanded,
        'progress': progress,
        'playing': playing,
        'elapsedLabel': elapsedLabel,
      };

  static IslandActivity fromJson(Map<String, dynamic>? m) {
    if (m == null) return idle;
    IslandKind kind = IslandKind.idle;
    final name = '${m['kind'] ?? ''}';
    for (final k in IslandKind.values) {
      if (k.name == name) kind = k;
    }
    return IslandActivity(
      kind: kind,
      title: '${m['title'] ?? ''}',
      subtitle: '${m['subtitle'] ?? m['artist'] ?? ''}',
      expanded: m['expanded'] as bool? ?? false,
      progress: (m['progress'] as num?)?.toDouble() ?? 0,
      playing: m['playing'] as bool? ?? false,
      elapsedLabel: '${m['elapsedLabel'] ?? ''}',
    );
  }

  /// Native overlay / MediaSession snapshot → live activity.
  /// Music with a blank title still becomes a shown Now playing row.
  /// A snapshot that is playing but forgot `kind` is still music.
  static IslandActivity fromNativeSnapshot(Map<String, dynamic>? m) {
    if (m == null || m.isEmpty) return idle;
    final parsed = fromJson(m);
    final playing = parsed.playing || m['playing'] == true;
    if (parsed.kind == IslandKind.music ||
        (parsed.kind == IslandKind.idle && playing)) {
      return music(
        title: parsed.title,
        artist: parsed.subtitle,
        playing: playing,
        progress: parsed.progress,
        expanded: parsed.expanded,
      );
    }
    return parsed;
  }

  /// Stable identity for "did what is happening change?" — ignores progress.
  String get signature => '${kind.name}|$title|$subtitle|$playing';
}

/// Compact / peek / auto-shrink policy. HomeScreen and tests call this.
class IslandPresenter {
  IslandPresenter._();

  static const autoShrinkMs = 2800;

  static IslandTick apply({
    required IslandActivity previous,
    required IslandActivity incoming,
  }) {
    if (incoming.isIdle) {
      return const IslandTick(activity: IslandActivity.idle, restartShrink: false);
    }
    final changed = previous.signature != incoming.signature;
    if (changed) {
      final peek = incoming.hasSpecificTitle;
      return IslandTick(
        activity: peek ? incoming.expand() : incoming.compact(),
        restartShrink: peek,
      );
    }
    return IslandTick(
      activity: incoming.copyWith(expanded: previous.expanded),
      restartShrink: false,
    );
  }

  static bool shouldAutoShrink({
    required IslandActivity activity,
    required int elapsedMs,
  }) =>
      !activity.isIdle && activity.expanded && elapsedMs >= autoShrinkMs;
}

class IslandTick {
  const IslandTick({
    required this.activity,
    required this.restartShrink,
  });

  final IslandActivity activity;
  final bool restartShrink;
}

/// Titles that are not a real track / video name.
class IslandCopy {
  IslandCopy._();

  static const genericTitles = {
    '',
    'now playing',
    'music',
    'brave',
    'chrome',
    'youtube',
    'youtube music',
    'media',
  };

  static bool isSpecificTitle(String title) {
    final t = title.trim().toLowerCase();
    if (genericTitles.contains(t)) return false;
    if (t.startsWith('com.')) return false;
    return t.length >= 2;
  }
}
