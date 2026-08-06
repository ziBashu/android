import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/sound/sound_service.dart';
import 'alarm_models.dart';

class AlarmController extends ChangeNotifier {
  AlarmController({required this.sound});

  final SoundService sound;
  static const _key = 'nc2.alarms';
  static const _snoozeKey = 'nc2.snooze_until';

  List<ChronosAlarm> _alarms = [];
  ChronosAlarm? _ringing;
  DateTime? _snoozeUntil;
  String? _lastFiredKey;
  bool _ready = false;

  bool get ready => _ready;
  List<ChronosAlarm> get alarms => List.unmodifiable(_alarms);
  ChronosAlarm? get ringing => _ringing;

  ChronosAlarm? get nextAlarm {
    final now = DateTime.now();
    ChronosAlarm? best;
    DateTime? bestTime;
    for (final a in _alarms) {
      final t = a.nextFire(now);
      if (t == null) continue;
      if (bestTime == null || t.isBefore(bestTime)) {
        bestTime = t;
        best = a;
      }
    }
    if (_snoozeUntil != null &&
        _snoozeUntil!.isAfter(now) &&
        (bestTime == null || _snoozeUntil!.isBefore(bestTime))) {
      final base = best ??
          ChronosAlarm(
            hour: _snoozeUntil!.hour,
            minute: _snoozeUntil!.minute,
            label: 'Snoozed',
          );
      return base.copyWith(
        hour: _snoozeUntil!.hour,
        minute: _snoozeUntil!.minute,
        label: 'Snoozed',
      );
    }
    return best;
  }

  DateTime? nextFireTime(DateTime now) {
    if (_snoozeUntil != null && _snoozeUntil!.isAfter(now)) {
      return _snoozeUntil;
    }
    DateTime? best;
    for (final a in _alarms) {
      final t = a.nextFire(now);
      if (t == null) continue;
      if (best == null || t.isBefore(best)) best = t;
    }
    return best;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _alarms = raw.map((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return ChronosAlarm.fromJson(map.cast<String, Object?>());
    }).toList();
    if (_alarms.isEmpty) {
      _alarms = [
        ChronosAlarm(
          hour: 6,
          minute: 30,
          label: 'Morning Rise',
          mode: AlarmMode.gentleRise,
          weekdays: [1, 2, 3, 4, 5],
        ),
      ];
      await _save();
    }
    final snoozeMs = prefs.getInt(_snoozeKey);
    if (snoozeMs != null) {
      _snoozeUntil = DateTime.fromMillisecondsSinceEpoch(snoozeMs);
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _alarms.map((a) => jsonEncode(a.toJson())).toList(),
    );
    if (_snoozeUntil != null) {
      await prefs.setInt(_snoozeKey, _snoozeUntil!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_snoozeKey);
    }
  }

  Future<void> add(ChronosAlarm a) async {
    _alarms = [..._alarms, a];
    notifyListeners();
    await _save();
  }

  Future<void> update(ChronosAlarm a) async {
    _alarms = _alarms.map((e) => e.id == a.id ? a : e).toList();
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _alarms = _alarms.where((e) => e.id != id).toList();
    notifyListeners();
    await _save();
  }

  Future<void> toggle(String id) async {
    _alarms = _alarms
        .map((e) => e.id == id ? e.copyWith(enabled: !e.enabled) : e)
        .toList();
    notifyListeners();
    await _save();
  }

  /// Called each second from the shell.
  void tick(DateTime now) {
    if (_ringing != null) return;

    if (_snoozeUntil != null) {
      final s = _snoozeUntil!;
      if (now.year == s.year &&
          now.month == s.month &&
          now.day == s.day &&
          now.hour == s.hour &&
          now.minute == s.minute &&
          now.second == 0) {
        _snoozeUntil = null;
        _fire(
          ChronosAlarm(
            hour: s.hour,
            minute: s.minute,
            label: 'Snooze',
            mode: AlarmMode.cyberPulse,
          ),
          now,
        );
        return;
      }
    }

    for (final a in _alarms) {
      if (!a.enabled) continue;
      final days = a.weekdays.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : a.weekdays;
      if (!days.contains(now.weekday)) continue;
      if (now.hour == a.hour && now.minute == a.minute && now.second == 0) {
        final key = '${a.id}-${now.year}${now.month}${now.day}${now.hour}${now.minute}';
        if (_lastFiredKey == key) continue;
        _fire(a, now);
        return;
      }
    }
  }

  void _fire(ChronosAlarm a, DateTime now) {
    _lastFiredKey =
        '${a.id}-${now.year}${now.month}${now.day}${now.hour}${now.minute}';
    _ringing = a;
    notifyListeners();
    sound.alarmPulse();
    if (a.vibrate) {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> dismiss() async {
    _ringing = null;
    _snoozeUntil = null;
    notifyListeners();
    await _save();
  }

  Future<void> snooze() async {
    final a = _ringing;
    if (a == null) return;
    final mins = a.snoozeMinutes.clamp(1, 60);
    _snoozeUntil = DateTime.now().add(Duration(minutes: mins));
    _ringing = null;
    notifyListeners();
    await _save();
    await sound.click();
  }
}
