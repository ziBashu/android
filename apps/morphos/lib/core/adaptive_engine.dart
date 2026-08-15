import 'dart:async';

import 'package:battery_plus/battery_plus.dart';

import 'models.dart';
import 'morph_controller.dart';

/// Phase 3 — context-aware morph triggers (time + charging).
/// Per-app morph remains in [MorphController.morphForAppLaunch].
class AdaptiveEngine {
  AdaptiveEngine(this.controller);

  final MorphController controller;
  final Battery _battery = Battery();

  StreamSubscription<BatteryState>? _battSub;
  Timer? _timeTimer;
  bool _running = false;

  bool get running => _running;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    await _tickTime();
    await _tickCharge();
    _timeTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      unawaited(_tickTime());
    });
    try {
      _battSub = _battery.onBatteryStateChanged.listen((state) {
        unawaited(_onBattery(state));
      });
    } catch (_) {
      // Plugin may be unavailable in tests.
    }
  }

  Future<void> stop() async {
    _running = false;
    await _battSub?.cancel();
    _battSub = null;
    _timeTimer?.cancel();
    _timeTimer = null;
  }

  Future<void> _tickTime() async {
    if (!controller.timeBasedMorph) return;
    // Don't fight charging dock morph.
    if (controller.chargeMorphEnabled && controller.isCharging) return;
    await controller.refreshTimeBasedMorph();
  }

  Future<void> _tickCharge() async {
    if (!controller.chargeMorphEnabled) return;
    try {
      final state = await _battery.batteryState.timeout(
        const Duration(milliseconds: 80),
        onTimeout: () => BatteryState.unknown,
      );
      await _onBattery(state);
    } catch (_) {}
  }

  Future<void> _onBattery(BatteryState state) async {
    final charging = state == BatteryState.charging ||
        state == BatteryState.full;
    controller.isCharging = charging;
    if (!controller.chargeMorphEnabled) {
      controller.notifyAdaptiveOnly();
      return;
    }
    if (charging) {
      if (controller.profileId != MorphProfileId.desktop) {
        controller.profileBeforeCharge ??= controller.profileId;
        await controller.applyProfile(
          MorphProfileId.desktop,
          reason: 'adaptive:charging → Desktop Morph',
        );
      } else {
        controller.notifyAdaptiveOnly();
      }
    } else if (controller.profileBeforeCharge != null) {
      final restore = controller.profileBeforeCharge!;
      controller.profileBeforeCharge = null;
      await controller.applyProfile(
        restore,
        reason: 'adaptive:unplugged → restore',
      );
    } else {
      controller.notifyAdaptiveOnly();
    }
  }
}
