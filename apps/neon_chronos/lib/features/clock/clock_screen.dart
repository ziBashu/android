import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/clock_engine/clock_ticker.dart';
import '../../core/engine/clock_face_config.dart';
import '../../core/sound/sound_service.dart';
import '../../core/storage/settings_controller.dart';
import '../../core/theme_engine/neon_theme.dart';
import '../../widgets/glass_panel.dart';
import '../alarm/alarm_controller.dart';
import '../clock_faces/advanced_faces.dart';
import '../clock_faces/face_config_controller.dart';

class ClockScreen extends StatelessWidget {
  const ClockScreen({
    super.key,
    required this.ticker,
    required this.settings,
    required this.sound,
    required this.alarms,
    required this.faces,
  });

  final ClockTicker ticker;
  final SettingsController settings;
  final SoundService sound;
  final AlarmController alarms;
  final FaceConfigController faces;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ticker, settings, alarms, faces]),
      builder: (context, _) {
        final s = settings.settings;
        final primary = s.accent.primary;
        final secondary = s.accent.secondary;
        final now = ticker.now;
        final next = alarms.nextFireTime(now);
        final face = faces.config;

        return SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              sound.modeChange();
              final kinds = FaceKind.values;
              final i = kinds.indexOf(face.kind);
              faces.update(face.copyWith(kind: kinds[(i + 1) % kinds.length]));
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'NEON CHRONOS',
                        style: TextStyle(
                          color: primary,
                          fontSize: 12,
                          letterSpacing: 2.2,
                          fontWeight: FontWeight.w700,
                          shadows: neonGlow(primary, blur: 8, spread: 0),
                        ),
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: Container(
                          key: ValueKey(face.kind),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: secondary.withValues(alpha: 0.4),
                            ),
                            color: secondary.withValues(alpha: 0.08),
                          ),
                          child: Text(
                            face.kind.label.toUpperCase(),
                            style: TextStyle(
                              color: secondary,
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GlassPanel(
                          accent: NeonColors.ok,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                          child: const Text(
                            'SYSTEM NORMAL',
                            style: TextStyle(
                              color: NeonColors.ok,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlassPanel(
                          accent: secondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 9,
                          ),
                          child: Text(
                            next == null
                                ? 'NO ALARM'
                                : 'NEXT ${next.hour.toString().padLeft(2, '0')}:${next.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: secondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final side = math.min(c.maxWidth, c.maxHeight) * 0.95;
                        return Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 420),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, anim) {
                              return FadeTransition(
                                opacity: anim,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.94, end: 1)
                                      .animate(anim),
                                  child: child,
                                ),
                              );
                            },
                            child: SizedBox(
                              key: ValueKey(face.kind.name + face.shape.name),
                              width: side,
                              height: side,
                              child: AdvancedClockFace(
                                now: now,
                                settings: s,
                                face: face,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Text(
                    'TAP TO CYCLE FACE  ·  ${face.name}',
                    style: TextStyle(
                      color: NeonColors.textSecondary.withValues(alpha: 0.5),
                      fontSize: 10,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
