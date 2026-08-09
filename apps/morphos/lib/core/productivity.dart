/// Pure productivity helpers — battery mapping + rotation cycle state.
/// No platform channels here so unit tests drive real logic.
library;

/// Battery status snapshot for home widgets.
class BatterySnapshot {
  const BatterySnapshot({
    required this.level,
    required this.charging,
    required this.unknown,
  });

  /// 0–100 when known; -1 when unknown.
  final int level;
  final bool charging;
  final bool unknown;

  /// Short label for UI chips.
  String get label {
    if (unknown || level < 0) return charging ? '⚡ …' : '…%';
    final pct = level.clamp(0, 100);
    return charging ? '⚡ $pct%' : '$pct%';
  }

  /// Material-style battery icon key.
  String get iconKey {
    if (charging) return 'charging';
    if (unknown || level < 0) return 'unknown';
    if (level <= 15) return 'alert';
    if (level <= 30) return 'low';
    if (level <= 60) return 'mid';
    return 'full';
  }

  bool get isLow => !unknown && level >= 0 && level <= 15 && !charging;

  /// Map plugin-style inputs into a snapshot (the unit under test for UI).
  static BatterySnapshot fromRaw({
    int? level,
    bool? charging,
    String? stateName,
  }) {
    final s = (stateName ?? '').toLowerCase();
    final isCharging = charging == true ||
        s == 'charging' ||
        s == 'full' ||
        s.contains('charg');
    if (level == null) {
      return BatterySnapshot(
        level: -1,
        charging: isCharging,
        unknown: true,
      );
    }
    return BatterySnapshot(
      level: level.clamp(0, 100),
      charging: isCharging,
      unknown: false,
    );
  }
}

/// Quick rotation modes for the home productivity strip.
enum RotationAction {
  sensor,
  portrait,
  landscape,
  reverseLandscape,
}

extension RotationActionX on RotationAction {
  String get mode => switch (this) {
        RotationAction.sensor => 'sensor',
        RotationAction.portrait => 'portrait',
        RotationAction.landscape => 'landscape',
        RotationAction.reverseLandscape => 'reverseLandscape',
      };

  String get label => switch (this) {
        RotationAction.sensor => 'Auto',
        RotationAction.portrait => 'Portrait',
        RotationAction.landscape => 'Landscape',
        RotationAction.reverseLandscape => 'Rev landscape',
      };

  String get shortLabel => switch (this) {
        RotationAction.sensor => 'AUTO',
        RotationAction.portrait => 'PORT',
        RotationAction.landscape => 'LAND',
        RotationAction.reverseLandscape => 'R-LAND',
      };

  static RotationAction fromMode(String? mode) {
    switch ((mode ?? '').toLowerCase()) {
      case 'portrait':
        return RotationAction.portrait;
      case 'landscape':
        return RotationAction.landscape;
      case 'reverselandscape':
      case 'reverse_landscape':
      case 'reverse-landscape':
        return RotationAction.reverseLandscape;
      default:
        return RotationAction.sensor;
    }
  }

  /// Cycle: sensor → portrait → landscape → reverseLandscape → sensor.
  RotationAction get next {
    const order = RotationAction.values;
    final i = order.indexOf(this);
    return order[(i + 1) % order.length];
  }
}
