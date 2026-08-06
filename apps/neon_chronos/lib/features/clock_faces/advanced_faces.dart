import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/clock_engine/clock_format.dart';
import '../../core/engine/clock_face_config.dart';
import '../../core/storage/app_settings.dart';
import '../../core/theme_engine/neon_theme.dart';

/// Renders Digital HUD / Orbital / Quantum / Custom faces from [ClockFaceConfig].
class AdvancedClockFace extends StatefulWidget {
  const AdvancedClockFace({
    super.key,
    required this.now,
    required this.settings,
    required this.face,
  });

  final DateTime now;
  final AppSettings settings;
  final ClockFaceConfig face;

  @override
  State<AdvancedClockFace> createState() => _AdvancedClockFaceState();
}

class _AdvancedClockFaceState extends State<AdvancedClockFace>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    final speed = 0.4 + widget.face.animSpeed * 1.4;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (8000 / speed).round()),
    );
    if (widget.settings.animation) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant AdvancedClockFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.face.animSpeed != widget.face.animSpeed) {
      final speed = 0.4 + widget.face.animSpeed * 1.4;
      _ctrl.duration = Duration(milliseconds: (8000 / speed).round());
      if (widget.settings.animation && !_ctrl.isAnimating) _ctrl.repeat();
    }
    if (widget.settings.animation && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.settings.animation && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final f = widget.face;
    final primary = s.accent.primary;
    final secondary = s.accent.secondary;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, c) {
            final side = math.min(c.maxWidth, c.maxHeight);
            return SizedBox(
              width: side,
              height: side,
              child: CustomPaint(
                painter: _FacePainter(
                  now: widget.now,
                  progress: widget.settings.animation ? _ctrl.value : 0.25,
                  primary: primary,
                  secondary: secondary,
                  face: f,
                  hour24: s.hour24,
                  intensity: f.glow * s.glow,
                ),
                child: _overlayLabel(side, primary, secondary),
              ),
            );
          },
        );
      },
    );
  }

  Widget? _overlayLabel(double side, Color primary, Color secondary) {
    final f = widget.face;
    final now = widget.now;
    final s = widget.settings;

    if (f.kind == FaceKind.digitalHud || f.kind == FaceKind.custom) {
      final dayOfYear = now.difference(DateTime(now.year)).inDays + 1;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TIME CORE',
              style: TextStyle(
                color: secondary.withValues(alpha: 0.9),
                fontSize: side * 0.04,
                letterSpacing: 3,
              ),
            ),
            Text(
              'ACTIVE',
              style: TextStyle(
                color: NeonColors.ok,
                fontSize: side * 0.032,
                letterSpacing: 2,
                shadows: neonGlow(NeonColors.ok, blur: 8, intensity: f.glow),
              ),
            ),
            SizedBox(height: side * 0.03),
            Text(
              ClockFormat.timeHms(now, hour24: s.hour24),
              style: TextStyle(
                color: primary,
                fontSize: side * 0.16,
                fontWeight: FontWeight.w200,
                letterSpacing: 2,
                fontFeatures: const [FontFeature.tabularFigures()],
                shadows: neonGlow(primary, blur: 18, intensity: f.glow),
              ),
            ),
            SizedBox(height: side * 0.03),
            Text(
              'UTC${now.timeZoneOffset.isNegative ? '' : '+'}'
              '${now.timeZoneOffset.inHours}  ·  DAY $dayOfYear',
              style: TextStyle(
                color: NeonColors.textSecondary,
                fontSize: side * 0.035,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              ClockFormat.weekday(now).toUpperCase(),
              style: TextStyle(
                color: NeonColors.textPrimary.withValues(alpha: 0.85),
                fontSize: side * 0.04,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    if (f.kind == FaceKind.orbital) {
      return Center(
        child: Text(
          ClockFormat.timeHm(now, hour24: s.hour24),
          style: TextStyle(
            color: primary,
            fontSize: side * 0.09,
            fontWeight: FontWeight.w300,
            shadows: neonGlow(primary, blur: 12, intensity: f.glow),
          ),
        ),
      );
    }

    // Quantum — abstract, label bottom
    return Align(
      alignment: const Alignment(0, 0.72),
      child: Text(
        ClockFormat.timeHms(now, hour24: s.hour24),
        style: TextStyle(
          color: primary.withValues(alpha: 0.95),
          fontSize: side * 0.08,
          fontWeight: FontWeight.w200,
          letterSpacing: 3,
          fontFeatures: const [FontFeature.tabularFigures()],
          shadows: neonGlow(primary, blur: 14, intensity: f.glow),
        ),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter({
    required this.now,
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.face,
    required this.hour24,
    required this.intensity,
  });

  final DateTime now;
  final double progress;
  final Color primary;
  final Color secondary;
  final ClockFaceConfig face;
  final bool hour24;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 * 0.92;

    _drawFrame(canvas, c, r);

    switch (face.kind) {
      case FaceKind.digitalHud:
      case FaceKind.custom:
        _drawHudRings(canvas, c, r);
      case FaceKind.orbital:
        _drawOrbital(canvas, c, r);
      case FaceKind.quantum:
        _drawQuantum(canvas, c, r);
    }

    _drawParticles(canvas, size);
  }

  void _drawFrame(Canvas canvas, Offset c, double r) {
    final paint = Paint()
      ..color = primary.withValues(alpha: 0.2 + intensity * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    switch (face.shape) {
      case FaceShape.circle:
        canvas.drawCircle(c, r, paint);
      case FaceShape.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: r * 1.7, height: r * 1.7),
            const Radius.circular(12),
          ),
          paint,
        );
      case FaceShape.hexagon:
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final a = (i / 6) * math.pi * 2 - math.pi / 2;
          final p = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
    }
  }

  void _drawHudRings(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r * 0.88,
      Paint()
        ..color = secondary.withValues(alpha: 0.15 * intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.95),
      progress * math.pi * 2,
      math.pi * 0.5,
      false,
      Paint()
        ..color = primary.withValues(alpha: 0.7 * intensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawOrbital(Canvas canvas, Offset c, double r) {
    // Orbit rings
    for (final f in [0.45, 0.65, 0.85]) {
      canvas.drawCircle(
        c,
        r * f,
        Paint()
          ..color = primary.withValues(alpha: 0.15 + f * 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Sun
    canvas.drawCircle(
      c,
      6,
      Paint()
        ..color = NeonColors.warn
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Planet = hour hand position
    final hour = (now.hour % 12) + now.minute / 60;
    final min = now.minute + now.second / 60;
    final sec = now.second + now.millisecond / 1000;

    void body(double unit, double orbit, Color col, double size) {
      final a = unit * math.pi * 2 - math.pi / 2;
      final p = Offset(
        c.dx + math.cos(a) * r * orbit,
        c.dy + math.sin(a) * r * orbit,
      );
      canvas.drawCircle(
        p,
        size + 3,
        Paint()
          ..color = col.withValues(alpha: 0.35 * intensity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(p, size, Paint()..color = col);
    }

    body(hour / 12, 0.45, primary, 7);
    body(min / 60, 0.65, secondary, 5);
    body(sec / 60, 0.85, NeonColors.magenta, 3.5);

    if (face.showNumbers) {
      final tp = TextPainter(textDirection: TextDirection.ltr);
      for (final n in [12, 3, 6, 9]) {
        final i = n == 12 ? 0 : n ~/ 3;
        final a = (i / 4) * math.pi * 2 - math.pi / 2;
        tp.text = TextSpan(
          text: '$n',
          style: TextStyle(
            color: secondary.withValues(alpha: 0.8),
            fontSize: r * 0.12,
          ),
        );
        tp.layout();
        tp.paint(
          canvas,
          Offset(
            c.dx + math.cos(a) * r * 0.95 - tp.width / 2,
            c.dy + math.sin(a) * r * 0.95 - tp.height / 2,
          ),
        );
      }
    }
  }

  void _drawQuantum(Canvas canvas, Offset c, double r) {
    // Energy field waves
    for (var i = 0; i < 5; i++) {
      final phase = progress * math.pi * 2 + i * 0.8;
      final rr = r * (0.3 + i * 0.12 + 0.05 * math.sin(phase));
      canvas.drawCircle(
        c,
        rr,
        Paint()
          ..color = (i.isEven ? primary : secondary)
              .withValues(alpha: 0.12 + 0.08 * intensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Rotating arcs
    for (var i = 0; i < 3; i++) {
      final start = progress * math.pi * 2 + i * 2;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * (0.55 + i * 0.12)),
        start,
        math.pi * 0.6,
        false,
        Paint()
          ..color = primary.withValues(alpha: 0.55 * intensity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    // Center pulse
    final pulse = 8 + 6 * math.sin(progress * math.pi * 2);
    canvas.drawCircle(
      c,
      pulse,
      Paint()
        ..color = secondary.withValues(alpha: 0.5 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  void _drawParticles(Canvas canvas, Size size) {
    final n = (20 * face.particles).round();
    if (n <= 0) return;
    final rng = math.Random(3);
    final p = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < n; i++) {
      final ang = progress * math.pi * 2 + i * 0.7;
      final rad = size.width * (0.15 + rng.nextDouble() * 0.35);
      final o = Offset(
        size.width / 2 + math.cos(ang) * rad,
        size.height / 2 + math.sin(ang * 1.3) * rad,
      );
      p.color = (i.isEven ? primary : secondary).withValues(
        alpha: 0.2 + 0.4 * intensity * ((math.sin(ang) + 1) / 2),
      );
      canvas.drawCircle(o, 1.2 + rng.nextDouble() * 1.8, p);
    }
  }

  @override
  bool shouldRepaint(covariant _FacePainter old) =>
      old.now != now ||
      old.progress != progress ||
      old.primary != primary ||
      old.face != face ||
      old.intensity != intensity;
}
