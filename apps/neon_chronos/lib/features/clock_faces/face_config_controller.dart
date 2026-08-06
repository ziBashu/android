import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/engine/clock_face_config.dart';

class FaceConfigController extends ChangeNotifier {
  FaceConfigController();

  static const _key = 'nc3.face_config';
  static const _savedKey = 'nc3.saved_faces';

  ClockFaceConfig _config = ClockFaceConfig.defaults;
  final List<ClockFaceConfig> _saved = [];
  bool _ready = false;

  ClockFaceConfig get config => _config;
  List<ClockFaceConfig> get saved => List.unmodifiable(_saved);
  bool get ready => _ready;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final imported = ClockFaceConfig.importCode(raw);
      if (imported != null) _config = imported;
    }
    final list = prefs.getStringList(_savedKey) ?? [];
    _saved
      ..clear()
      ..addAll(list.map(ClockFaceConfig.importCode).whereType<ClockFaceConfig>());
    _ready = true;
    notifyListeners();
  }

  Future<void> update(ClockFaceConfig c) async {
    _config = c;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, c.exportCode());
  }

  Future<void> saveCurrent() async {
    _saved.insert(0, _config);
    if (_saved.length > 12) _saved.removeLast();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _savedKey,
      _saved.map((e) => e.exportCode()).toList(),
    );
  }

  Future<void> applySaved(ClockFaceConfig c) => update(c);

  Future<bool> importShareCode(String code) async {
    final c = ClockFaceConfig.importCode(code.trim());
    if (c == null) return false;
    await update(c);
    return true;
  }
}
