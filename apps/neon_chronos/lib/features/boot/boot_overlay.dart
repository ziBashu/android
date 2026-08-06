import 'package:flutter/material.dart';

import '../../core/sound/sound_service.dart';
import '../../core/theme_engine/neon_theme.dart';

class BootOverlay extends StatefulWidget {
  const BootOverlay({
    super.key,
    required this.primary,
    required this.secondary,
    required this.sound,
    required this.onComplete,
  });

  final Color primary;
  final Color secondary;
  final SoundService sound;
  final VoidCallback onComplete;

  @override
  State<BootOverlay> createState() => _BootOverlayState();
}

class _BootOverlayState extends State<BootOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _pulse;
  int _phase = 0;

  static const _lines = [
    'NEON CHRONOS',
    'Initializing Temporal OS…',
    'TIME ENGINE',
    'ENERGY CORE ONLINE',
    'TIME SYNCHRONIZED',
    'Welcome back.',
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..addListener(() {
        final next =
            (_ctrl.value * _lines.length).floor().clamp(0, _lines.length - 1);
        if (next != _phase) {
          setState(() => _phase = next);
          widget.sound.bootTick();
        }
      });
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.sound.bootComplete();
        widget.onComplete();
      }
    });
    _ctrl.forward();
    widget.sound.bootTick();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engineProgress = Curves.easeInOut.transform(
      (_ctrl.value * 1.15).clamp(0.0, 1.0),
    );

    return Material(
      color: NeonColors.background,
      child: AnimatedBuilder(
        animation: Listenable.merge([_ctrl, _pulse]),
        builder: (context, _) {
          final glow = 0.55 + _pulse.value * 0.45;
          return SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.primary.withValues(alpha: 0.35 * glow),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.primary.withValues(alpha: 0.2 * glow),
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: widget.primary.withValues(alpha: 0.9),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'NEON CHRONOS',
                      style: TextStyle(
                        color: widget.primary,
                        fontSize: 24,
                        letterSpacing: 5.5,
                        fontWeight: FontWeight.w800,
                        shadows: neonGlow(
                          widget.primary,
                          blur: 20,
                          intensity: glow,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TEMPORAL OS  ·  v3.0',
                      style: TextStyle(
                        color: widget.secondary.withValues(alpha: 0.7),
                        fontSize: 11,
                        letterSpacing: 2.8,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'TIME ENGINE',
                      style: TextStyle(
                        color: NeonColors.textSecondary.withValues(alpha: 0.85),
                        fontSize: 10,
                        letterSpacing: 2.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 260,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: engineProgress,
                          minHeight: 4,
                          backgroundColor:
                              widget.primary.withValues(alpha: 0.1),
                          color: widget.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) {
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.12),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        _lines[_phase],
                        key: ValueKey(_phase),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _phase >= _lines.length - 2
                              ? NeonColors.ok
                              : NeonColors.textSecondary,
                          fontSize: 14,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w500,
                          shadows: _phase >= _lines.length - 2
                              ? neonGlow(NeonColors.ok, blur: 12, spread: 0)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
