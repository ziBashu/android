import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'morph_palette.dart';

/// Phase 6 — system UI chrome follows active morph palette / quiet mode.
class PlatformChrome {
  PlatformChrome._();

  static Future<void> apply({
    required MorphPalette palette,
    required bool immersive,
    required bool quietMode,
  }) async {
    final lightIcons = palette.isDark;
    final nav = immersive
        ? Colors.transparent
        : palette.scaffoldTint.withValues(alpha: 0.92);

    final style = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          lightIcons ? Brightness.light : Brightness.dark,
      statusBarBrightness: lightIcons ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: nav,
      systemNavigationBarIconBrightness:
          lightIcons ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: !immersive,
    );

    try {
      SystemChrome.setSystemUIOverlayStyle(style);
      if (immersive) {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
        );
      } else {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      }
    } catch (_) {}
  }
}
