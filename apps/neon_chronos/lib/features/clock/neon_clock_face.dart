import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/clock_engine/clock_format.dart';
import '../../core/storage/app_settings.dart';
import '../../core/theme_engine/accent.dart';
import '../../core/theme_engine/neon_theme.dart';

class NeonClockFace extends StatefulWidget {
  const NeonClockFace({
    super.key,
    required this.now,
    required this.settings,
  });

  final DateTime now;
  final AppSettings settings;

  @override
  State<NeonClockFace> createState() => _NeonClockFaceState();
}

class _NeonClockFaceState extends State<NeonClockFace>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _ring;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant NeonClockFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.animation != widget.settings.animation ||
        oldWidget.settings.animationLevel != widget.settings.animationLevel) {
      _sync();
    }
  }

  void _sync() {
    final on = widget.settings.animation && widget.settings.animationLevel > 0.05;
    if (on) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
      if (!_ring.isAnimating) _ring.repeat();
    } else {
      _pulse
        ..stop()
        ..value = 0.75;
      _ring
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final primary = s.accent.primary;
    final secondary = s.accent.secondary;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _ring]),
      builder: (context, _) {
        final intensity = s.glow * (0.55 + _pulse.value * 0.45);
        return LayoutBuilder(
          builder: (context, c) {
            final side = math.min(c.maxWidth, c.maxHeight);
            return SizedBox(
              width: side,
              height: side,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(side * 0.94, side * 0.94),
                    painter: _RingPainter(
                      progress: _ring.value,
                      pulse: intensity,
                      primary: primary,
                      secondary: secondary,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: Duration(
                      milliseconds: s.animation ? 320 : 0,
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(s.mode),
                      child: _face(side * 0.72, intensity),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _face(double size, double intensity) {
    final s = widget.settings;
    final primary = s.accent.primary;
    final secondary = s.accent.secondary;
    final now = widget.now;

    switch (s.mode) {
      case ClockMode.digital:
        return SizedBox(
          width: size,
          height: size,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'TIME CORE',
                style: TextStyle(
                  color: secondary.withValues(alpha: 0.9),
                  fontSize: size * 0.042,
                  letterSpacing: 3,
                ),
              ),
              Text(
                'ACTIVE',
                style: TextStyle(
                  color: NeonColors.ok,
                  fontSize: size * 0.034,
                  letterSpacing: 3,
                  shadows: neonGlow(NeonColors.ok, blur: 8, intensity: intensity),
                ),
              ),
              SizedBox(height: size * 0.04),
              FittedBox(
                child: Text(
                  ClockFormat.timeHms(now, hour24: s.hour24),
                  style: TextStyle(
                    color: primary,
                    fontSize: size * 0.18,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    shadows: neonGlow(primary, blur: 18, intensity: intensity),
                  ),
                ),
              ),
              if (!s.hour24)
                Text(
                  ClockFormat.amPm(now),
                  style: TextStyle(color: secondary, fontSize: size * 0.05),
                ),
              SizedBox(height: size * 0.04),
              Text(
                ClockFormat.weekday(now).toUpperCase(),
                style: TextStyle(
                  color: NeonColors.textPrimary,
                  fontSize: size * 0.048,
                  letterSpacing: 2,
                ),
              ),
              Text(
                ClockFormat.dateLine(now),
                style: TextStyle(
                  color: NeonColors.textSecondary,
                  fontSize: size * 0.04,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        );
      case ClockMode.analog:
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _AnalogPainter(
              now: now,
              primary: primary,
              secondary: secondary,
              pulse: intensity,
            ),
            child: Center(
              child: Text(
                ClockFormat.timeHm(now, hour24: s.hour24),
                style: TextStyle(
                  color: primary,
                  fontSize: size * 0.1,
                  fontWeight: FontWeight.w300,
                  shadows: neonGlow(primary, blur: 10, intensity: intensity),
                ),
              ),
            ),
          ),
        );
      case ClockMode.minimal:
        return SizedBox(
          width: size,
          height: size,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                ClockFormat.timeHm(now, hour24: s.hour24),
                style: TextStyle(
                  color: primary,
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 6,
                  shadows: neonGlow(primary, blur: 20, intensity: intensity),
                ),
              ),
              Text(
                ClockFormat.weekday(now),
                style: TextStyle(
                  color: NeonColors.textSecondary,
                  fontSize: size * 0.055,
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.pulse,
    required this.primary,
    required this.secondary,
  });

  final double progress;
  final double pulse;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 * 0.96;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = primary.withValues(alpha: 0.15 + 0.1 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      progress * math.pi * 2,
      math.pi * 0.55,
      false,
      Paint()
        ..shader = SweepGradient(
          colors: [
            primary.withValues(alpha: 0),
            primary.withValues(alpha: 0.85 * pulse),
            secondary.withValues(alpha: 0.9 * pulse),
            primary.withValues(alpha: 0),
          ],
          transform: GradientRotation(progress * math.pi * 2),
        ).createShader(Rect.fromCircle(center: c, radius: r))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.pulse != pulse || old.primary != primary;
}

class _AnalogPainter extends CustomPainter {
  _AnalogPainter({
    required this.now,
    required this.primary,
    required this.secondary,
    required this.pulse,
  });

  final DateTime now;
  final Color primary;
  final Color secondary;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 * 0.88;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < 12; i++) {
      final n = i == 0 ? 12 : i;
      final a = (i / 12) * math.pi * 2 - math.pi / 2;
      canvas.drawLine(
        Offset(c.dx + math.cos(a) * r * 0.82, c.dy + math.sin(a) * r * 0.82),
        Offset(c.dx + math.cos(a) * r * 0.94, c.dy + math.sin(a) * r * 0.94),
        Paint()
          ..color = primary.withValues(alpha: 0.7 * pulse)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
      tp.text = TextSpan(
        text: '$n',
        style: TextStyle(
          color: secondary.withValues(alpha: 0.75),
          fontSize: size.width * 0.045,
        ),
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(
          c.dx + math.cos(a) * r * 0.7 - tp.width / 2,
          c.dy + math.sin(a) * r * 0.7 - tp.height / 2,
        ),
      );
    }

    final sec = now.second + now.millisecond / 1000;
    final min = now.minute + sec / 60;
    final hour = (now.hour % 12) + min / 60;

    void hand(double u, double len, Color col, double w) {
      final a = u * math.pi * 2 - math.pi / 2;
      final end = Offset(c.dx + math.cos(a) * r * len, c.dy + math.sin(a) * r * len);
      canvas.drawLine(
        c,
        end,
        Paint()
          ..color = col.withValues(alpha: 0.4 * pulse)
          ..strokeWidth = w + 4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawLine(
        c,
        end,
        Paint()
          ..color = col
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round,
      );
    }

    hand(hour / 12, 0.48, primary, 3.5);
    hand(min / 60, 0.66, secondary, 2.5);
    hand(sec / 60, 0.76, NeonColors.magenta, 1.3);
    canvas.drawCircle(c, 3.5, Paint()..color = NeonColors.textPrimary);
  }

  @override
  bool shouldRepaint(covariant _AnalogPainter old) =>
      old.now != now || old.primary != primary || old.pulse != pulse;
}
