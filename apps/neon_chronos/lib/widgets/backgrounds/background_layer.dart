import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme_engine/accent.dart';
import '../../core/theme_engine/neon_theme.dart';
import '../../core/storage/app_settings.dart';

/// Dynamic backgrounds: cyber grid / space / digital rain.
class BackgroundLayer extends StatefulWidget {
  const BackgroundLayer({
    super.key,
    required this.settings,
  });

  final AppSettings settings;

  @override
  State<BackgroundLayer> createState() => _BackgroundLayerState();
}

class _BackgroundLayerState extends State<BackgroundLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    _sync();
  }

  @override
  void didUpdateWidget(covariant BackgroundLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final on = widget.settings.animation && widget.settings.animationLevel > 0.05;
    if (on && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!on && _ctrl.isAnimating) {
      _ctrl.stop();
    }
    final speed = 0.4 + widget.settings.gridSpeed * 1.2;
    _ctrl.duration = Duration(milliseconds: (16000 / speed).round());
    if (on && !_ctrl.isAnimating) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _BgPainter(
            progress: s.animation ? _ctrl.value : 0,
            primary: s.accent.primary,
            secondary: s.accent.secondary,
            glow: s.glow,
            mode: s.background,
            particles: s.particleAmount,
            animLevel: s.animationLevel,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _BgPainter extends CustomPainter {
  _BgPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.glow,
    required this.mode,
    required this.particles,
    required this.animLevel,
  });

  final double progress;
  final Color primary;
  final Color secondary;
  final double glow;
  final BackgroundMode mode;
  final double particles;
  final double animLevel;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = NeonColors.background,
    );

    switch (mode) {
      case BackgroundMode.cyberGrid:
        _paintCyberGrid(canvas, size);
      case BackgroundMode.spaceMode:
        _paintSpace(canvas, size);
      case BackgroundMode.digitalRain:
        _paintRain(canvas, size);
    }
  }

  void _paintCyberGrid(Canvas canvas, Size size) {
    // Perspective horizon grid
    final horizon = size.height * 0.42;
    final vanish = Offset(size.width / 2, horizon);

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          NeonColors.background,
          primary.withValues(alpha: 0.04 * glow),
          NeonColors.background,
        ],
        stops: const [0, 0.45, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, fill);

    final line = Paint()
      ..color = NeonColors.gridLine.withValues(alpha: 0.65)
      ..strokeWidth = 0.9;

    // Horizontal perspective lines
    for (var i = 0; i < 14; i++) {
      final t = i / 13;
      final y = horizon + math.pow(t, 1.6) * (size.height - horizon);
      final alpha = 0.15 + t * 0.45;
      line.color = primary.withValues(alpha: alpha * 0.35);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }

    // Vertical rays from vanish
    for (var i = -10; i <= 10; i++) {
      final edgeX = size.width / 2 + i * (size.width / 9);
      line.color = primary.withValues(alpha: 0.12 + glow * 0.08);
      canvas.drawLine(vanish, Offset(edgeX, size.height), line);
    }

    // Upper grid
    const spacing = 36.0;
    final offset = progress * spacing * animLevel;
    final grid = Paint()
      ..color = NeonColors.gridLine.withValues(alpha: 0.4)
      ..strokeWidth = 0.7;
    for (double x = offset % spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, horizon), grid);
    }
    for (double y = offset % spacing; y < horizon; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    _particles(canvas, size, count: (22 * particles).round());
  }

  void _paintSpace(Canvas canvas, Size size) {
    final nebula = Paint()
      ..shader = RadialGradient(
        center: Alignment(math.sin(progress * math.pi * 2) * 0.3, -0.2),
        radius: 0.9,
        colors: [
          secondary.withValues(alpha: 0.12 * glow),
          primary.withValues(alpha: 0.05 * glow),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, nebula);

    final rng = math.Random(7);
    final star = Paint()..style = PaintingStyle.fill;
    final n = (80 * particles).round().clamp(10, 120);
    for (var i = 0; i < n; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final twinkle =
          0.3 + 0.7 * ((math.sin(progress * math.pi * 2 + i) + 1) / 2);
      star.color = Colors.white.withValues(alpha: 0.25 + twinkle * 0.55 * glow);
      canvas.drawCircle(Offset(x, y), 0.8 + rng.nextDouble() * 1.4, star);
    }

    // Soft planet
    final pc = Offset(size.width * 0.78, size.height * 0.22);
    canvas.drawCircle(
      pc,
      28,
      Paint()
        ..color = primary.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    canvas.drawCircle(
      pc,
      18,
      Paint()
        ..shader = RadialGradient(
          colors: [
            secondary.withValues(alpha: 0.5),
            primary.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: pc, radius: 18)),
    );
  }

  void _paintRain(Canvas canvas, Size size) {
    final rng = math.Random(99);
    final n = (40 * particles).round().clamp(8, 60);
    final paint = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < n; i++) {
      final x = (rng.nextDouble() * size.width + progress * 40 * i) % size.width;
      final speed = 0.4 + rng.nextDouble() * 0.8;
      final len = 12.0 + rng.nextDouble() * 28;
      final y =
          ((progress * size.height * speed * 2) + rng.nextDouble() * size.height) %
              (size.height + len);
      paint.color = (i.isEven ? primary : secondary)
          .withValues(alpha: 0.25 + rng.nextDouble() * 0.4 * glow);
      canvas.drawLine(Offset(x, y - len), Offset(x, y), paint);
    }
  }

  void _particles(Canvas canvas, Size size, {required int count}) {
    final rng = math.Random(42);
    final p = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < count; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final y = (baseY + progress * size.height * (0.3 + rng.nextDouble())) %
          size.height;
      final x = baseX + math.sin((progress + i) * math.pi * 2) * 6 * animLevel;
      p.color = (i.isEven ? primary : secondary).withValues(
        alpha: 0.2 + 0.3 * glow * ((math.sin(progress * math.pi * 2 + i) + 1) / 2),
      );
      canvas.drawCircle(Offset(x, y), 1.2 + rng.nextDouble() * 1.6, p);
    }
  }

  @override
  bool shouldRepaint(covariant _BgPainter old) =>
      old.progress != progress ||
      old.primary != primary ||
      old.mode != mode ||
      old.particles != particles ||
      old.glow != glow;
}
