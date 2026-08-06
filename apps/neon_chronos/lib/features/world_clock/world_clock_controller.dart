import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'city_catalog.dart';

class WorldClockController extends ChangeNotifier {
  WorldClockController();

  static const _key = 'nc2.world_cities';
  static const _defaultIds = ['tokyo', 'london', 'new_york'];

  List<String> _cityIds = List.of(_defaultIds);
  bool _ready = false;

  bool get ready => _ready;

  List<WorldCity> get cities =>
      _cityIds.map(cityById).whereType<WorldCity>().toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw != null && raw.isNotEmpty) {
      _cityIds = raw;
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _cityIds);
  }

  Future<void> addCity(String id) async {
    if (_cityIds.contains(id)) return;
    if (cityById(id) == null) return;
    _cityIds = [..._cityIds, id];
    notifyListeners();
    await _save();
  }

  Future<void> removeCity(String id) async {
    _cityIds = _cityIds.where((e) => e != id).toList();
    notifyListeners();
    await _save();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final list = List<String>.of(_cityIds);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _cityIds = list;
    notifyListeners();
    await _save();
  }
}
