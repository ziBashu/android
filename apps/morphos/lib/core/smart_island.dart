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
  IslandActivity expand() {
    if (kind == IslandKind.idle) return this;
    return copyWith(expanded: true);
  }

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
      title: title,
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
      subtitle: '${m['subtitle'] ?? ''}',
      expanded: m['expanded'] as bool? ?? false,
      progress: (m['progress'] as num?)?.toDouble() ?? 0,
      playing: m['playing'] as bool? ?? false,
      elapsedLabel: '${m['elapsedLabel'] ?? ''}',
    );
  }
}
