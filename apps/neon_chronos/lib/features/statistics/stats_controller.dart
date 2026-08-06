import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manual time map (user-entered hours per category).
class TimeStats {
  const TimeStats({
    this.sleep = 8,
    this.work = 6,
    this.focus = 4,
    this.free = 5,
    this.other = 1,
  });

  final double sleep;
  final double work;
  final double focus;
  final double free;
  final double other;

  double get total => sleep + work + focus + free + other;

  TimeStats copyWith({
    double? sleep,
    double? work,
    double? focus,
    double? free,
    double? other,
  }) {
    return TimeStats(
      sleep: sleep ?? this.sleep,
      work: work ?? this.work,
      focus: focus ?? this.focus,
      free: free ?? this.free,
      other: other ?? this.other,
    );
  }

  Map<String, double> get bars => {
        'Sleep': sleep,
        'Work': work,
        'Focus': focus,
        'Free': free,
        'Other': other,
      };
}

class StatsController extends ChangeNotifier {
  StatsController();

  static const _p = 'nc3.stats.';
  TimeStats _stats = const TimeStats();
  bool _ready = false;

  TimeStats get stats => _stats;
  bool get ready => _ready;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _stats = TimeStats(
      sleep: prefs.getDouble('${_p}sleep') ?? 8,
      work: prefs.getDouble('${_p}work') ?? 6,
      focus: prefs.getDouble('${_p}focus') ?? 4,
      free: prefs.getDouble('${_p}free') ?? 5,
      other: prefs.getDouble('${_p}other') ?? 1,
    );
    _ready = true;
    notifyListeners();
  }

  Future<void> update(TimeStats s) async {
    _stats = s;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_p}sleep', s.sleep);
    await prefs.setDouble('${_p}work', s.work);
    await prefs.setDouble('${_p}focus', s.focus);
    await prefs.setDouble('${_p}free', s.free);
    await prefs.setDouble('${_p}other', s.other);
  }
}
