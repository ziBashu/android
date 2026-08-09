import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/morph_palette.dart';

class MorphBackground extends StatelessWidget {
  const MorphBackground({
    super.key,
    required this.wallpaperId,
    required this.palette,
    this.child,
    this.customPortraitBytes,
    this.customLandscapeBytes,
  });

  final WallpaperId wallpaperId;
  final MorphPalette palette;
  final Widget? child;

  /// User-picked portrait wallpaper image bytes (JPEG/PNG).
  final List<int>? customPortraitBytes;

  /// User-picked landscape wallpaper image bytes (JPEG/PNG).
  final List<int>? customLandscapeBytes;

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final custom = landscape
        ? (customLandscapeBytes ?? customPortraitBytes)
        : (customPortraitBytes ?? customLandscapeBytes);
    final colors = MorphPalette.wallpaperColors(wallpaperId);

    Widget? content = child == null
        ? null
        : ColoredBox(
            color: Colors.black.withValues(
              alpha: palette.isDark ? 0.25 : 0.06,
            ),
            child: child,
          );

    if (custom != null && custom.isNotEmpty) {
      return Material(
        color: colors.last,
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                Uint8List.fromList(custom),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                  ),
                ),
              ),
              if (content != null) content,
            ],
          ),
        ),
      );
    }

    return Material(
      color: colors.last,
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
