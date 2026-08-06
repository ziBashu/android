import 'package:flutter/services.dart';

import '../storage/app_settings.dart';

class SoundService {
  SoundService();

  bool enabled = true;

  void syncFrom(AppSettings s) => enabled = s.sound;

  Future<void> click() async {
    if (!enabled) return;
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.selectionClick();
  }

  Future<void> modeChange() async {
    if (!enabled) return;
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.lightImpact();
  }

  Future<void> bootTick() async {
    if (!enabled) return;
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> bootComplete() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> alarmPulse() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> timerDone() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }
}
