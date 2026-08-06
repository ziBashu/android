import 'package:flutter/foundation.dart';

import '../../core/sound/sound_service.dart';

class CountdownController extends ChangeNotifier {
  CountdownController({required this.sound});

  final SoundService sound;

  Duration _total = const Duration(minutes: 5);
  Duration _remaining = const Duration(minutes: 5);
  DateTime? _endsAt;
  bool _running = false;
  bool _finished = false;

  Duration get total => _total;
  Duration get remaining => _remaining;
  bool get running => _running;
  bool get finished => _finished;
  double get progress {
    if (_total.inMilliseconds == 0) return 0;
    return 1.0 - (_remaining.inMilliseconds / _total.inMilliseconds);
  }

  void setMinutes(int m) {
    if (_running) return;
    _total = Duration(minutes: m.clamp(1, 180));
    _remaining = _total;
    _finished = false;
    notifyListeners();
  }

  void setDuration(Duration d) {
    if (_running) return;
    _total = d;
    _remaining = d;
    _finished = false;
    notifyListeners();
  }

  void start() {
    if (_remaining.inMilliseconds <= 0) {
      _remaining = _total;
    }
    _running = true;
    _finished = false;
    _endsAt = DateTime.now().add(_remaining);
    notifyListeners();
    sound.click();
  }

  void pause() {
    if (!_running) return;
    _tickNow();
    _running = false;
    _endsAt = null;
    notifyListeners();
    sound.click();
  }

  void reset() {
    _running = false;
    _finished = false;
    _endsAt = null;
    _remaining = _total;
    notifyListeners();
    sound.click();
  }

  void tick(DateTime now) {
    if (!_running || _endsAt == null) return;
    final left = _endsAt!.difference(now);
    if (left.inMilliseconds <= 0) {
      _remaining = Duration.zero;
      _running = false;
      _finished = true;
      _endsAt = null;
      notifyListeners();
      sound.timerDone();
    } else {
      _remaining = left;
      notifyListeners();
    }
  }

  void _tickNow() {
    if (_endsAt == null) return;
    final left = _endsAt!.difference(DateTime.now());
    _remaining = left.isNegative ? Duration.zero : left;
  }
}

class ChronosStopwatch extends ChangeNotifier {
  ChronosStopwatch({required this.sound});

  final SoundService sound;

  final List<Duration> laps = [];
  DateTime? _startedAt;
  Duration _accumulated = Duration.zero;
  bool _running = false;

  bool get running => _running;

  Duration elapsed(DateTime now) {
    if (_running && _startedAt != null) {
      return _accumulated + now.difference(_startedAt!);
    }
    return _accumulated;
  }

  void start(DateTime now) {
    if (_running) return;
    _running = true;
    _startedAt = now;
    notifyListeners();
    sound.click();
  }

  void stop(DateTime now) {
    if (!_running) return;
    _accumulated = elapsed(now);
    _running = false;
    _startedAt = null;
    notifyListeners();
    sound.click();
  }

  void reset() {
    _running = false;
    _startedAt = null;
    _accumulated = Duration.zero;
    laps.clear();
    notifyListeners();
    sound.click();
  }

  void lap(DateTime now) {
    if (!_running) return;
    laps.insert(0, elapsed(now));
    if (laps.length > 20) laps.removeLast();
    notifyListeners();
    sound.click();
  }
}
