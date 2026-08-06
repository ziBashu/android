import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme_engine/accent.dart';
import 'app_settings.dart';

class SettingsController extends ChangeNotifier {
  SettingsController();

  static const _p = 'nc2.';

  AppSettings _settings = AppSettings.defaults;
  bool _ready = false;

  AppSettings get settings => _settings;
  bool get ready => _ready;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _settings = AppSettings.fromMap({
      'mode': prefs.getString('${_p}mode'),
      'hour24': prefs.getBool('${_p}hour24'),
      'glow': prefs.getDouble('${_p}glow'),
      'animation': prefs.getBool('${_p}animation'),
      'accent': prefs.getString('${_p}accent'),
      'sound': prefs.getBool('${_p}sound'),
      'background': prefs.getString('${_p}background'),
      'particleAmount': prefs.getDouble('${_p}particleAmount'),
      'gridSpeed': prefs.getDouble('${_p}gridSpeed'),
      'animationLevel': prefs.getDouble('${_p}animationLevel'),
    });
    _ready = true;
    notifyListeners();
  }

  Future<void> update(AppSettings next) async {
    _settings = next;
    notifyListeners();
    await _persist(next);
  }

  Future<void> _persist(AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_p}mode', s.mode.name);
    await prefs.setBool('${_p}hour24', s.hour24);
    await prefs.setDouble('${_p}glow', s.glow);
    await prefs.setBool('${_p}animation', s.animation);
    await prefs.setString('${_p}accent', s.accent.name);
    await prefs.setBool('${_p}sound', s.sound);
    await prefs.setString('${_p}background', s.background.name);
    await prefs.setDouble('${_p}particleAmount', s.particleAmount);
    await prefs.setDouble('${_p}gridSpeed', s.gridSpeed);
    await prefs.setDouble('${_p}animationLevel', s.animationLevel);
  }

  Future<void> setMode(ClockMode mode) => update(_settings.copyWith(mode: mode));

  Future<void> cycleMode() {
    final next = _settings.mode.next;
    _settings = _settings.copyWith(mode: next);
    notifyListeners();
    return _persist(_settings);
  }

  Future<void> setHour24(bool v) => update(_settings.copyWith(hour24: v));
  Future<void> setGlow(double v) =>
      update(_settings.copyWith(glow: v.clamp(0.0, 1.0)));
  Future<void> setAnimation(bool v) => update(_settings.copyWith(animation: v));
  Future<void> setAccent(NeonAccent a) => update(_settings.copyWith(accent: a));
  Future<void> setSound(bool v) => update(_settings.copyWith(sound: v));
  Future<void> setBackground(BackgroundMode b) =>
      update(_settings.copyWith(background: b));
  Future<void> setParticleAmount(double v) =>
      update(_settings.copyWith(particleAmount: v.clamp(0.0, 1.0)));
  Future<void> setGridSpeed(double v) =>
      update(_settings.copyWith(gridSpeed: v.clamp(0.0, 1.0)));
  Future<void> setAnimationLevel(double v) =>
      update(_settings.copyWith(animationLevel: v.clamp(0.0, 1.0)));
}
