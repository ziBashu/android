import 'package:flutter/material.dart';

/// Named visual themes for Neon Chronos v2.
enum NeonAccent {
  cyanMatrix(
    label: 'CYAN MATRIX',
    shortLabel: 'Cyan',
    primary: Color(0xFF00E5FF),
    secondary: Color(0xFFB14CFF),
  ),
  purpleVoid(
    label: 'PURPLE VOID',
    shortLabel: 'Purple',
    primary: Color(0xFFB14CFF),
    secondary: Color(0xFF00E5FF),
  ),
  redWarning(
    label: 'RED WARNING',
    shortLabel: 'Red',
    primary: Color(0xFFFF2D55),
    secondary: Color(0xFFFF8A00),
  ),
  greenTerminal(
    label: 'GREEN TERMINAL',
    shortLabel: 'Green',
    primary: Color(0xFF39FF14),
    secondary: Color(0xFF00E5FF),
  ),
  whiteFuture(
    label: 'WHITE FUTURE',
    shortLabel: 'White',
    primary: Color(0xFFE8F7FF),
    secondary: Color(0xFF7AD7FF),
  );

  const NeonAccent({
    required this.label,
    required this.shortLabel,
    required this.primary,
    required this.secondary,
  });

  final String label;
  final String shortLabel;
  final Color primary;
  final Color secondary;

  static NeonAccent fromName(String? name) {
    switch (name) {
      case 'cyan':
        return NeonAccent.cyanMatrix;
      case 'purple':
        return NeonAccent.purpleVoid;
      case 'red':
        return NeonAccent.redWarning;
      default:
        return NeonAccent.values.firstWhere(
          (a) => a.name == name,
          orElse: () => NeonAccent.cyanMatrix,
        );
    }
  }
}

enum BackgroundMode {
  cyberGrid('Cyber Grid'),
  spaceMode('Space'),
  digitalRain('Digital Rain');

  const BackgroundMode(this.label);
  final String label;

  static BackgroundMode fromName(String? name) {
    return BackgroundMode.values.firstWhere(
      (b) => b.name == name,
      orElse: () => BackgroundMode.cyberGrid,
    );
  }
}

enum ClockMode {
  digital('DIGITAL', 'Digital'),
  analog('ANALOG', 'Analog'),
  minimal('MINIMAL', 'Minimal');

  const ClockMode(this.label, this.shortLabel);
  final String label;
  final String shortLabel;

  ClockMode get next {
    final values = ClockMode.values;
    return values[(index + 1) % values.length];
  }

  static ClockMode fromName(String? name) {
    return ClockMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ClockMode.digital,
    );
  }
}
