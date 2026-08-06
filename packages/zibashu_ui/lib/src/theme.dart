import 'package:flutter/material.dart';

import 'brand.dart';

ThemeData buildZiBashuTheme({Color? seed}) {
  final seedColor = seed ?? ZiBashuBrand.forest;
  final scheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
    surface: ZiBashuBrand.cream,
  ).copyWith(
    primary: seedColor,
    onPrimary: Colors.white,
    onSurface: ZiBashuBrand.ink,
    surfaceContainerLowest: ZiBashuBrand.cream,
    surfaceContainerLow: ZiBashuBrand.mist,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: ZiBashuBrand.cream,
    appBarTheme: AppBarTheme(
      backgroundColor: ZiBashuBrand.cream,
      foregroundColor: ZiBashuBrand.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        color: ZiBashuBrand.ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.72),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ZiBashuBrand.ink.withValues(alpha: 0.08)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ZiBashuBrand.ink.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ZiBashuBrand.ink.withValues(alpha: 0.12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: ZiBashuBrand.ink,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w700,
        color: ZiBashuBrand.ink,
      ),
      bodyLarge: TextStyle(color: ZiBashuBrand.ink, height: 1.4),
      bodyMedium: TextStyle(color: ZiBashuBrand.ink, height: 1.4),
    ),
  );
}
