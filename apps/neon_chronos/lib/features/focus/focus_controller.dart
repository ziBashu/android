import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class FocusSession {
  FocusSession({
    String? id,
    required this.target,
    required this.plannedMinutes,
    required this.startedAt,
    this.endedAt,
    this.completed = false,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String target;
  final int plannedMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool completed;

  Duration get elapsed {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'target': target,
        'plannedMinutes': plannedMinutes,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'completed': completed,
      };

  factory FocusSession.fromJson(Map<String, Object?> j) => FocusSession(
        id: j['id'] as String?,
        target: j['target'] as String? ?? 'Deep Work',
        plannedMinutes: j['plannedMinutes'] as int? ?? 25,
        startedAt: DateTime.tryParse(j['startedAt'] as String? ?? '') ??
            DateTime.now(),
        endedAt: j['endedAt'] != null
            ? DateTime.tryParse(j['endedAt'] as String)
            : null,
        completed: j['completed'] as bool? ?? false,
      );
}

class FocusController extends ChangeNotifier {
  FocusController();

  static const _key = 'nc3.focus_history';
  static const _activeKey = 'nc3.focus_active';

  List<FocusSession> _history = [];
  FocusSession? _active;
  bool _ready = false;

  /// Pomodoro defaults.
  int workMinutes = 25;
  int breakMinutes = 5;
  String target = 'Deep Work';

  void setWorkMinutes(int m) {
    workMinutes = m.clamp(1, 180);
    notifyListeners();
  }

  bool get ready => _ready;
  FocusSession? get active => _active;
  List<FocusSession> get history => List.unmodifiable(_history);
  bool get isActive => _active != null && _active!.endedAt == null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    _history = raw.map((e) {
      final m = jsonDecode(e) as Map<String, dynamic>;
      return FocusSession.fromJson(m.cast<String, Object?>());
    }).toList();
    final activeRaw = prefs.getString(_activeKey);
    if (activeRaw != null) {
      final m = jsonDecode(activeRaw) as Map<String, dynamic>;
      _active = FocusSession.fromJson(m.cast<String, Object?>());
      if (_active!.endedAt != null) _active = null;
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _history.take(50).map((s) => jsonEncode(s.toJson())).toList(),
    );
    if (_active != null && _active!.endedAt == null) {
      await prefs.setString(_activeKey, jsonEncode(_active!.toJson()));
    } else {
      await prefs.remove(_activeKey);
    }
  }

  Future<void> start({String? targetOverride, int? minutes}) async {
    if (isActive) return;
    _active = FocusSession(
      target: targetOverride ?? target,
      plannedMinutes: minutes ?? workMinutes,
      startedAt: DateTime.now(),
    );
    notifyListeners();
    await _save();
  }

  Future<void> stop({bool completed = true}) async {
    if (_active == null) return;
    final done = FocusSession(
      id: _active!.id,
      target: _active!.target,
      plannedMinutes: _active!.plannedMinutes,
      startedAt: _active!.startedAt,
      endedAt: DateTime.now(),
      completed: completed,
    );
    _history = [done, ..._history];
    _active = null;
    notifyListeners();
    await _save();
  }

  Duration remaining(DateTime now) {
    if (_active == null) return Duration.zero;
    final total = Duration(minutes: _active!.plannedMinutes);
    final used = now.difference(_active!.startedAt);
    final left = total - used;
    return left.isNegative ? Duration.zero : left;
  }

  double progress(DateTime now) {
    if (_active == null) return 0;
    final total = _active!.plannedMinutes * 60;
    if (total <= 0) return 1;
    final used = now.difference(_active!.startedAt).inSeconds;
    return (used / total).clamp(0.0, 1.0);
  }

  int totalFocusMinutesToday() {
    final today = DateTime.now();
    var mins = 0;
    for (final s in _history) {
      if (s.startedAt.year == today.year &&
          s.startedAt.month == today.month &&
          s.startedAt.day == today.day) {
        mins += s.elapsed.inMinutes;
      }
    }
    if (isActive) {
      mins += DateTime.now().difference(_active!.startedAt).inMinutes;
    }
    return mins;
  }
}
