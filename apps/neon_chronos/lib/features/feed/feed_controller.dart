import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Local-only chronos feed events (no cloud).
class FeedEvent {
  FeedEvent({
    String? id,
    required this.hour,
    required this.minute,
    required this.title,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final int hour;
  final int minute;
  final String title;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Map<String, Object?> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'title': title,
      };

  factory FeedEvent.fromJson(Map<String, Object?> j) => FeedEvent(
        id: j['id'] as String?,
        hour: j['hour'] as int? ?? 0,
        minute: j['minute'] as int? ?? 0,
        title: j['title'] as String? ?? '',
      );
}

class FeedController extends ChangeNotifier {
  FeedController();

  static const _key = 'nc2.feed';

  List<FeedEvent> _events = [];
  bool _ready = false;

  bool get ready => _ready;
  List<FeedEvent> get events {
    final list = List<FeedEvent>.of(_events);
    list.sort((a, b) {
      final am = a.hour * 60 + a.minute;
      final bm = b.hour * 60 + b.minute;
      return am.compareTo(bm);
    });
    return list;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null || raw.isEmpty) {
      _events = [
        FeedEvent(hour: 8, minute: 0, title: 'Meeting'),
        FeedEvent(hour: 12, minute: 30, title: 'Lunch'),
        FeedEvent(hour: 18, minute: 0, title: 'Workout'),
      ];
      await _save();
    } else {
      _events = raw.map((e) {
        final m = jsonDecode(e) as Map<String, dynamic>;
        return FeedEvent.fromJson(m.cast<String, Object?>());
      }).toList();
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      _events.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> add(FeedEvent e) async {
    _events = [..._events, e];
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _events = _events.where((e) => e.id != id).toList();
    notifyListeners();
    await _save();
  }
}
