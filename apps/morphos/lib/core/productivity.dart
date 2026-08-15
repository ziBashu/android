/// Pure productivity helpers — battery mapping + rotation cycle state.
/// No platform channels here so unit tests drive real logic.
library;

/// Battery status snapshot for home widgets.
class BatterySnapshot {
  const BatterySnapshot({
    required this.level,
    required this.charging,
    required this.unknown,
    this.status = 'unknown',
    this.powerSource = 'none',
    this.temperatureC,
    this.health = 'unknown',
    this.voltageMv,
    this.technology = '',
  });

  /// 0–100 when known; -1 when unknown.
  final int level;
  final bool charging;
  final bool unknown;

  /// charging | discharging | full | not_charging | unknown
  final String status;

  /// ac | usb | wireless | none
  final String powerSource;

  /// Degrees Celsius when known.
  final double? temperatureC;

  /// good | overheat | dead | over_voltage | cold | unspecified | unknown
  final String health;

  /// Millivolts when known.
  final int? voltageMv;

  /// e.g. Li-ion
  final String technology;

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

  /// Color-coded visual that changes with level and charge.
  String get visualKey => iconKey;

  /// Named color token for the ring / icon.
  String get colorKey {
    switch (visualKey) {
      case 'charging':
        return 'teal';
      case 'alert':
        return 'red';
      case 'low':
        return 'orange';
      case 'mid':
        return 'amber';
      case 'full':
        return 'green';
      default:
        return 'gray';
    }
  }

  bool get isLow => !unknown && level >= 0 && level <= 15 && !charging;

  String get statusLabel {
    switch (status) {
      case 'charging':
        return 'charging';
      case 'discharging':
        return 'discharging';
      case 'full':
        return 'full';
      case 'not_charging':
        return 'not charging';
      default:
        return charging ? 'charging' : 'discharging';
    }
  }

  String get powerSourceLabel {
    switch (powerSource) {
      case 'ac':
        return 'AC';
      case 'usb':
        return 'USB';
      case 'wireless':
        return 'Wireless';
      default:
        return 'none';
    }
  }

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
    final status = isCharging
        ? (s == 'full' ? 'full' : 'charging')
        : (s.isEmpty ? 'discharging' : s);
    if (level == null) {
      return BatterySnapshot(
        level: -1,
        charging: isCharging,
        unknown: true,
        status: status,
      );
    }
    return BatterySnapshot(
      level: level.clamp(0, 100),
      charging: isCharging,
      unknown: false,
      status: status,
    );
  }

  /// Map Android `Intent.ACTION_BATTERY_CHANGED` extras.
  ///
  /// Keys: level, scale, status, plugged, temperature, health, voltage,
  /// technology — ints as Android sends them (temp tenths °C, voltage mV).
  static BatterySnapshot fromBatteryChangedExtras(Map<dynamic, dynamic> extras) {
    int? asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.round();
      return int.tryParse('$v');
    }

    final rawLevel = asInt(extras['level']);
    final scale = asInt(extras['scale']) ?? 100;
    final statusCode = asInt(extras['status']) ?? 1;
    final plugged = asInt(extras['plugged']) ?? 0;
    final tempTenths = asInt(extras['temperature']);
    final healthCode = asInt(extras['health']) ?? 1;
    final voltage = asInt(extras['voltage']);
    final tech = '${extras['technology'] ?? ''}'.trim();

    int level = -1;
    var unknown = true;
    if (rawLevel != null && rawLevel >= 0 && scale > 0) {
      level = ((rawLevel * 100) / scale).round().clamp(0, 100);
      unknown = false;
    }

    // BatteryManager.BATTERY_STATUS_*
    final status = switch (statusCode) {
      2 => 'charging',
      3 => 'discharging',
      4 => 'not_charging',
      5 => 'full',
      _ => 'unknown',
    };
    final charging = status == 'charging' || status == 'full';

    // BatteryManager.BATTERY_PLUGGED_*
    final powerSource = switch (plugged) {
      1 => 'ac',
      2 => 'usb',
      4 => 'wireless',
      _ => 'none',
    };

    // BatteryManager.BATTERY_HEALTH_*
    final health = switch (healthCode) {
      2 => 'good',
      3 => 'overheat',
      4 => 'dead',
      5 => 'over_voltage',
      6 => 'unspecified',
      7 => 'cold',
      _ => 'unknown',
    };

    return BatterySnapshot(
      level: level,
      charging: charging,
      unknown: unknown,
      status: status,
      powerSource: powerSource,
      temperatureC: tempTenths == null ? null : tempTenths / 10.0,
      health: health,
      voltageMv: voltage,
      technology: tech,
    );
  }

  /// One live `ACTION_BATTERY_CHANGED` EventChannel item → snapshot.
  /// Home applies this on every extras delivery, not only init/resume.
  static BatterySnapshot applyChangedEvent(Object? event) {
    if (event is! Map) {
      return const BatterySnapshot(
        level: -1,
        charging: false,
        unknown: true,
      );
    }
    return fromBatteryChangedExtras(event);
  }
}

/// Quick rotation modes for the home widget / lock.
enum RotationAction {
  sensor,
  portrait,
  landscape,
  reversePortrait,
  reverseLandscape,
}

extension RotationActionX on RotationAction {
  String get mode => switch (this) {
        RotationAction.sensor => 'sensor',
        RotationAction.portrait => 'portrait',
        RotationAction.landscape => 'landscape',
        RotationAction.reversePortrait => 'reversePortrait',
        RotationAction.reverseLandscape => 'reverseLandscape',
      };

  String get label => switch (this) {
        RotationAction.sensor => 'Auto',
        RotationAction.portrait => 'Portrait',
        RotationAction.landscape => 'Landscape',
        RotationAction.reversePortrait => 'Rev portrait',
        RotationAction.reverseLandscape => 'Rev landscape',
      };

  String get shortLabel => switch (this) {
        RotationAction.sensor => 'AUTO',
        RotationAction.portrait => 'PORT',
        RotationAction.landscape => 'LAND',
        RotationAction.reversePortrait => 'R-PORT',
        RotationAction.reverseLandscape => 'R-LAND',
      };

  static RotationAction fromMode(String? mode) {
    switch ((mode ?? '').toLowerCase().replaceAll('_', '').replaceAll('-', '')) {
      case 'portrait':
        return RotationAction.portrait;
      case 'landscape':
        return RotationAction.landscape;
      case 'reverseportrait':
        return RotationAction.reversePortrait;
      case 'reverselandscape':
        return RotationAction.reverseLandscape;
      default:
        return RotationAction.sensor;
    }
  }

  /// Cycle: auto → portrait → landscape → reverse portrait → reverse landscape.
  RotationAction get next {
    const order = RotationAction.values;
    final i = order.indexOf(this);
    return order[(i + 1) % order.length];
  }
}

/// Slide-to-rotate plus a lock that blocks the next slide.
class RotationControl {
  const RotationControl({
    this.action = RotationAction.sensor,
    this.locked = false,
  });

  final RotationAction action;
  final bool locked;

  bool get canSlideRotate => !locked;

  RotationControl copyWith({
    RotationAction? action,
    bool? locked,
  }) {
    return RotationControl(
      action: action ?? this.action,
      locked: locked ?? this.locked,
    );
  }

  /// Advance one mode. No-op when [locked].
  RotationControl slideRotate() {
    if (locked) return this;
    return RotationControl(action: action.next);
  }

  RotationControl setAction(RotationAction next) =>
      RotationControl(action: next, locked: locked);

  RotationControl lock() => RotationControl(action: action, locked: true);

  RotationControl unlock() => RotationControl(action: action);

  /// Mode string always sent to Settings.System, including `sensor` (auto).
  static String systemModeToApply(RotationControl control) =>
      control.action.mode;
}
