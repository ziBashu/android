import 'package:flutter/material.dart';

import 'accent.dart';

class NeonColors {
  NeonColors._();

  static const Color background = Color(0xFF05060A);
  static const Color surface = Color(0xFF0C0F18);
  static const Color textPrimary = Color(0xFFE8F7FF);
  static const Color textSecondary = Color(0xFF8AA8B8);
  static const Color gridLine = Color(0xFF1A2A35);
  static const Color ok = Color(0xFF39FF14);
  static const Color danger = Color(0xFFFF4D6A);
  static const Color magenta = Color(0xFFFF2BD6);
  static const Color warn = Color(0xFFFFB020);
}

class NeonPalette {
  const NeonPalette({
    required this.primary,
    required this.secondary,
    required this.glow,
    required this.animation,
    required this.particleAmount,
    required this.gridSpeed,
  });

  final Color primary;
  final Color secondary;
  final double glow;
  final bool animation;
  final double particleAmount; // 0–1
  final double gridSpeed; // 0–1

  factory NeonPalette.from({
    required NeonAccent accent,
    required double glow,
    required bool animation,
    required double particleAmount,
    required double gridSpeed,
  }) {
    return NeonPalette(
      primary: accent.primary,
      secondary: accent.secondary,
      glow: glow,
      animation: animation,
      particleAmount: particleAmount,
      gridSpeed: gridSpeed,
    );
  }
}

ThemeData buildNeonTheme({NeonAccent accent = NeonAccent.cyanMatrix}) {
  final primary = accent.primary;
  final secondary = accent.secondary;
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NeonColors.background,
    colorScheme: ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: NeonColors.surface,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      onSurface: NeonColors.textPrimary,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primary,
      inactiveTrackColor: primary.withValues(alpha: 0.2),
      thumbColor: primary,
      overlayColor: primary.withValues(alpha: 0.15),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primary;
        return NeonColors.textSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary.withValues(alpha: 0.35);
        }
        return NeonColors.surface;
      }),
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: NeonColors.textPrimary,
      displayColor: NeonColors.textPrimary,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: NeonColors.surface,
      contentTextStyle: TextStyle(color: primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary.withValues(alpha: 0.9),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary.withValues(alpha: 0.45)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    ),
  );
}

List<Shadow> neonGlow(
  Color color, {
  double blur = 16,
  double spread = 1,
  double intensity = 1,
}) {
  final i = intensity.clamp(0.0, 1.5);
  return [
    Shadow(color: color.withValues(alpha: 0.9 * i), blurRadius: blur),
    Shadow(color: color.withValues(alpha: 0.45 * i), blurRadius: blur * 2),
    if (spread > 0)
      Shadow(color: color.withValues(alpha: 0.2 * i), blurRadius: blur * 3),
  ];
}
