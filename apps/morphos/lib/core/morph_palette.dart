import 'package:flutter/material.dart';

import 'models.dart';

class MorphPalette {
  const MorphPalette({
    required this.brightness,
    required this.accent,
    required this.accentSecondary,
    required this.ink,
    required this.muted,
    required this.panel,
    required this.panelBorder,
    required this.scaffoldTint,
    required this.glow,
  });

  final Brightness brightness;
  final Color accent;
  final Color accentSecondary;
  final Color ink;
  final Color muted;
  final Color panel;
  final Color panelBorder;
  final Color scaffoldTint;
  final Color glow;

  bool get isDark => brightness == Brightness.dark;

  static MorphPalette forTheme(MorphThemeId id) {
    switch (id) {
      case MorphThemeId.neon:
        return const MorphPalette(
          brightness: Brightness.dark,
          accent: Color(0xFF7C4DFF),
          accentSecondary: Color(0xFF00E5FF),
          ink: Color(0xFFF2F4FF),
          muted: Color(0xFF9AA3C7),
          panel: Color(0xCC14182B),
          panelBorder: Color(0x447C4DFF),
          scaffoldTint: Color(0xFF070A14),
          glow: Color(0x667C4DFF),
        );
      case MorphThemeId.glass:
        return const MorphPalette(
          brightness: Brightness.dark,
          accent: Color(0xFF80DEEA),
          accentSecondary: Color(0xFFB39DDB),
          ink: Color(0xFFF8FBFF),
          muted: Color(0xFFB0BEC5),
          panel: Color(0x66FFFFFF),
          panelBorder: Color(0x55FFFFFF),
          scaffoldTint: Color(0xFF0D1B2A),
          glow: Color(0x4480DEEA),
        );
      case MorphThemeId.dark:
        return const MorphPalette(
          brightness: Brightness.dark,
          accent: Color(0xFF90CAF9),
          accentSecondary: Color(0xFFCE93D8),
          ink: Color(0xFFECEFF1),
          muted: Color(0xFF90A4AE),
          panel: Color(0xEE1A1D21),
          panelBorder: Color(0x33FFFFFF),
          scaffoldTint: Color(0xFF0A0B0D),
          glow: Color(0x2290CAF9),
        );
      case MorphThemeId.light:
        return const MorphPalette(
          brightness: Brightness.light,
          accent: Color(0xFF5E35B1),
          accentSecondary: Color(0xFF00897B),
          ink: Color(0xFF1A1C22),
          muted: Color(0xFF5F6368),
          panel: Color(0xF2FFFFFF),
          panelBorder: Color(0x22000000),
          scaffoldTint: Color(0xFFF4F1FA),
          glow: Color(0x225E35B1),
        );
      case MorphThemeId.material:
        return const MorphPalette(
          brightness: Brightness.light,
          accent: Color(0xFF6750A4),
          accentSecondary: Color(0xFF625B71),
          ink: Color(0xFF1C1B1F),
          muted: Color(0xFF49454F),
          panel: Color(0xFFFFFBFE),
          panelBorder: Color(0x1A000000),
          scaffoldTint: Color(0xFFFEF7FF),
          glow: Color(0x1A6750A4),
        );
    }
  }

  static List<Color> wallpaperColors(WallpaperId id) {
    switch (id) {
      case WallpaperId.dawn:
        return const [Color(0xFF87CEEB), Color(0xFFFFE4B5), Color(0xFFFFB347)];
      case WallpaperId.nightCity:
        return const [Color(0xFF0B1026), Color(0xFF1A237E), Color(0xFF4A148C)];
      case WallpaperId.cyberpunk:
        return const [Color(0xFF050510), Color(0xFF2A0845), Color(0xFF00F5D4)];
      case WallpaperId.ocean:
        return const [Color(0xFF001F3F), Color(0xFF0077B6), Color(0xFF00B4D8)];
      case WallpaperId.forest:
        return const [Color(0xFF0B1F14), Color(0xFF1B4332), Color(0xFF40916C)];
      case WallpaperId.aurora:
        return const [Color(0xFF0A0F1C), Color(0xFF1B4332), Color(0xFF7B2CBF)];
      case WallpaperId.voidBlack:
        return const [Color(0xFF000000), Color(0xFF0D0D12), Color(0xFF1A1030)];
    }
  }

  ThemeData toThemeData() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      secondary: accentSecondary,
      onSurface: ink,
      surface: panel,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldTint,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: ink, height: 1.35),
        bodyMedium: TextStyle(color: ink, height: 1.35),
        labelLarge: TextStyle(color: ink, fontWeight: FontWeight.w600),
        bodySmall: TextStyle(color: muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: isDark ? Colors.white : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: panel,
        selectedColor: accent.withValues(alpha: 0.28),
        labelStyle: TextStyle(color: ink),
        side: BorderSide(color: panelBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
