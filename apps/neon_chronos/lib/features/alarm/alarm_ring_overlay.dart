import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme_engine/neon_theme.dart';
import 'alarm_models.dart';

/// Wake Protocol: phased glow → sound → vibration UI.
class AlarmRingOverlay extends StatefulWidget {
  const AlarmRingOverlay({
    super.key,
    required this.alarm,
    required this.primary,
    required this.onSnooze,
    required this.onDismiss,
  });

  final ChronosAlarm alarm;
  final Color primary;
  final VoidCallback onSnooze;
  final VoidCallback onDismiss;

  @override
  State<AlarmRingOverlay> createState() => _AlarmRingOverlayState();
}

class _AlarmRingOverlayState extends State<AlarmRingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _phase = 1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..addListener(() {
        final p = _ctrl.value;
        final next = p < 0.33 ? 1 : (p < 0.66 ? 2 : 3);
        if (next != _phase) {
          setState(() => _phase = next);
          if (next == 2) {
            SystemSound.play(SystemSoundType.alert);
          }
          if (next == 3 && widget.alarm.vibrate) {
            HapticFeedback.heavyImpact();
          }
        }
      });
    _ctrl.forward();
    // Phase 1: soft glow only
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;
    final glow = 0.3 + _ctrl.value * 0.7 * widget.alarm.intensity;

    return Material(
      color: Colors.black.withValues(alpha: 0.88),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  primary.withValues(alpha: 0.08 + glow * 0.2),
                  Colors.black,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'WAKE SEQUENCE',
                        style: TextStyle(
                          color: primary,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w700,
                          shadows: neonGlow(primary, blur: 14, intensity: glow),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _phaseRow(1, 'Light glow', _phase >= 1, primary),
                      _phaseRow(2, 'Sound', _phase >= 2, primary),
                      _phaseRow(3, 'Vibration', _phase >= 3, primary),
                      const SizedBox(height: 20),
                      Text(
                        widget.alarm.timeLabel,
                        style: TextStyle(
                          color: primary,
                          fontSize: 64,
                          fontWeight: FontWeight.w200,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          shadows:
                              neonGlow(primary, blur: 24, intensity: glow),
                        ),
                      ),
                      Text(
                        widget.alarm.label,
                        style: const TextStyle(
                          color: NeonColors.textSecondary,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.alarm.mode.label.toUpperCase(),
                        style: TextStyle(
                          color: NeonColors.ok,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onSnooze,
                              child: Text(
                                'SNOOZE ${widget.alarm.snoozeMinutes}m',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: widget.onDismiss,
                              child: const Text('DISMISS'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _phaseRow(int n, String label, bool on, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? primary : NeonColors.textSecondary.withValues(alpha: 0.3),
              boxShadow: on
                  ? [BoxShadow(color: primary.withValues(alpha: 0.6), blurRadius: 6)]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Phase $n  $label',
            style: TextStyle(
              color: on ? NeonColors.textPrimary : NeonColors.textSecondary,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
