import 'package:uuid/uuid.dart';

enum AlarmMode {
  gentleRise,
  cyberPulse,
  sharpAlert,
}

extension AlarmModeX on AlarmMode {
  String get label {
    switch (this) {
      case AlarmMode.gentleRise:
        return 'Gentle Rise';
      case AlarmMode.cyberPulse:
        return 'Cyber Pulse';
      case AlarmMode.sharpAlert:
        return 'Sharp Alert';
    }
  }

  static AlarmMode fromName(String? n) {
    return AlarmMode.values.firstWhere(
      (m) => m.name == n,
      orElse: () => AlarmMode.cyberPulse,
    );
  }
}

class ChronosAlarm {
  ChronosAlarm({
    String? id,
    required this.hour,
    required this.minute,
    this.label = 'Wake Event',
    this.enabled = true,
    this.mode = AlarmMode.cyberPulse,
    this.intensity = 0.7,
    this.vibrate = true,
    this.snoozeMinutes = 5,
    List<int>? weekdays,
  })  : id = id ?? const Uuid().v4(),
        weekdays = weekdays ?? [1, 2, 3, 4, 5, 6, 7];

  final String id;
  final int hour;
  final int minute;
  final String label;
  final bool enabled;
  final AlarmMode mode;
  final double intensity;
  final bool vibrate;
  final int snoozeMinutes;

  /// ISO weekdays 1=Mon … 7=Sun. Empty = once (next match only handled as daily).
  final List<int> weekdays;

  ChronosAlarm copyWith({
    int? hour,
    int? minute,
    String? label,
    bool? enabled,
    AlarmMode? mode,
    double? intensity,
    bool? vibrate,
    int? snoozeMinutes,
    List<int>? weekdays,
  }) {
    return ChronosAlarm(
      id: id,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      intensity: intensity ?? this.intensity,
      vibrate: vibrate ?? this.vibrate,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      weekdays: weekdays ?? this.weekdays,
    );
  }

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Map<String, Object?> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'enabled': enabled,
        'mode': mode.name,
        'intensity': intensity,
        'vibrate': vibrate,
        'snoozeMinutes': snoozeMinutes,
        'weekdays': weekdays.join(','),
      };

  factory ChronosAlarm.fromJson(Map<String, Object?> j) {
    final wd = (j['weekdays'] as String?)
            ?.split(',')
            .where((e) => e.isNotEmpty)
            .map(int.parse)
            .toList() ??
        [1, 2, 3, 4, 5, 6, 7];
    return ChronosAlarm(
      id: j['id'] as String?,
      hour: j['hour'] as int? ?? 6,
      minute: j['minute'] as int? ?? 30,
      label: j['label'] as String? ?? 'Wake Event',
      enabled: j['enabled'] as bool? ?? true,
      mode: AlarmModeX.fromName(j['mode'] as String?),
      intensity: (j['intensity'] as num?)?.toDouble() ?? 0.7,
      vibrate: j['vibrate'] as bool? ?? true,
      snoozeMinutes: j['snoozeMinutes'] as int? ?? 5,
      weekdays: wd,
    );
  }

  /// Next fire time after [from] (local).
  DateTime? nextFire(DateTime from) {
    if (!enabled) return null;
    final days = weekdays.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : weekdays;
    for (var i = 0; i < 8; i++) {
      final candidate = DateTime(
        from.year,
        from.month,
        from.day,
        hour,
        minute,
      ).add(Duration(days: i));
      if (!days.contains(candidate.weekday)) continue;
      if (candidate.isAfter(from)) return candidate;
    }
    return null;
  }
}
