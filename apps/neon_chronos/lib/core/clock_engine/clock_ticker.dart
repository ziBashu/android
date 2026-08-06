import 'dart:async';

import 'package:flutter/foundation.dart';

/// Second-aligned wall clock + high-res tick for stopwatch/timer UI.
class ClockTicker extends ChangeNotifier {
  ClockTicker();

  DateTime _now = DateTime.now();
  Timer? _alignTimer;
  Timer? _periodic;
  Timer? _hiRes;
  bool _disposed = false;
  bool _hiResOn = false;

  DateTime get now => _now;

  void start() {
    if (_disposed) return;
    _cancelSeconds();
    _now = DateTime.now();
    notifyListeners();

    final ms = 1000 - _now.millisecond;
    _alignTimer = Timer(Duration(milliseconds: ms.clamp(1, 1000)), () {
      if (_disposed) return;
      _now = DateTime.now();
      notifyListeners();
      _periodic = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_disposed) return;
        _now = DateTime.now();
        notifyListeners();
      });
    });
  }

  /// ~30–60 FPS tick for stopwatch / countdown smoothness.
  void enableHiRes(bool on) {
    if (_hiResOn == on) return;
    _hiResOn = on;
    _hiRes?.cancel();
    _hiRes = null;
    if (on && !_disposed) {
      _hiRes = Timer.periodic(const Duration(milliseconds: 32), (_) {
        if (_disposed) return;
        _now = DateTime.now();
        notifyListeners();
      });
    }
  }

  void stop() {
    _cancelSeconds();
    _hiRes?.cancel();
    _hiRes = null;
    _hiResOn = false;
  }

  void _cancelSeconds() {
    _alignTimer?.cancel();
    _alignTimer = null;
    _periodic?.cancel();
    _periodic = null;
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}
