import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_module.dart';

class HomeLayoutController extends ChangeNotifier {
  HomeLayoutController();

  static const _key = 'nc3.home_modules';

  List<HomeModule> _modules = List.of(kDefaultHomeModules);
  bool _ready = false;

  List<HomeModule> get modules => List.unmodifiable(_modules);
  bool get ready => _ready;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw != null && raw.isNotEmpty) {
      _modules = raw.map(HomeModuleX.fromName).toList();
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _modules.map((m) => m.name).toList());
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final list = List<HomeModule>.of(_modules);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _modules = list;
    notifyListeners();
    await _save();
  }

  Future<void> toggle(HomeModule m) async {
    if (_modules.contains(m)) {
      if (_modules.length <= 2) return;
      _modules = _modules.where((e) => e != m).toList();
    } else {
      _modules = [..._modules, m];
    }
    notifyListeners();
    await _save();
  }

  Future<void> reset() async {
    _modules = List.of(kDefaultHomeModules);
    notifyListeners();
    await _save();
  }
}
