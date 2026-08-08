import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/morph_palette.dart';

class MorphBackground extends StatelessWidget {
  const MorphBackground({
    super.key,
    required this.wallpaperId,
    required this.palette,
    this.child,
  });

  final WallpaperId wallpaperId;
  final MorphPalette palette;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = MorphPalette.wallpaperColors(wallpaperId);
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
          child: child == null
              ? null
              : ColoredBox(
                  color: Colors.black.withValues(
                    alpha: palette.isDark ? 0.25 : 0.06,
                  ),
                  child: child,
                ),
        ),
      ),
    );
  }
}
