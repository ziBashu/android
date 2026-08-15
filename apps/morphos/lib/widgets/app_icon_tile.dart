import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/morph_controller.dart';
import '../core/morph_palette.dart';

class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    required this.app,
    required this.controller,
    required this.onTap,
    this.onLongPress,
    this.compact = false,
    this.showLabel,
    this.showMinus = false,
    this.onMinus,
    this.selected = false,
    this.sizeOverride,
    this.forceHideLabel = false,
    this.ignoreInnerGestures = false,
  });

  final MorphAppItem app;
  final MorphController controller;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool compact;
  final bool? showLabel;
  final bool showMinus;
  final VoidCallback? onMinus;
  final bool selected;
  final double? sizeOverride;
  final bool forceHideLabel;
  final bool ignoreInnerGestures;

  MorphPalette get p => controller.palette;

  BorderRadius get _radius {
    final s = controller.iconStyle;
    return switch (s) {
      IconStyleId.circle => BorderRadius.circular(999),
      IconStyleId.square => BorderRadius.circular(8),
      IconStyleId.rounded => BorderRadius.circular(14),
      IconStyleId.squircle => BorderRadius.circular(18),
      IconStyleId.neon => BorderRadius.circular(16),
    };
  }

  @override
  Widget build(BuildContext context) {
    final scale = controller.iconScale.clamp(0.75, 1.25) *
        (sizeOverride ??
            controller.sizeScaleFor(app.id, packageName: app.packageName));
    final size = (compact ? 44.0 : 52.0) * scale;
    final label = controller.labelFor(app);
    final neon = controller.iconStyle == IconStyleId.neon;
    final labels = forceHideLabel ||
            controller.hideNameFor(app.id, packageName: app.packageName)
        ? false
        : (showLabel ?? controller.showLabels);
    final bytes = app.iconBytes;

    Widget iconChild;
    if (bytes != null && bytes.isNotEmpty) {
      iconChild = ClipRRect(
        borderRadius: _radius,
        child: Image.memory(
          Uint8List.fromList(bytes),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            app.icon,
            color: Colors.white,
            size: size * 0.46,
          ),
        ),
      );
    } else {
      iconChild = Icon(app.icon, color: Colors.white, size: size * 0.46);
    }

    final visual = Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 2,
            vertical: compact ? 2 : 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
              Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: _radius,
                  gradient: bytes == null
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            app.color,
                            Color.lerp(app.color, Colors.black, 0.28)!,
                          ],
                        )
                      : null,
                  color: bytes != null ? Colors.black26 : null,
                  border: neon
                      ? Border.all(color: p.accentSecondary, width: 1.2)
                      : Border.all(color: p.panelBorder),
                  boxShadow: [
                    BoxShadow(
                      color: (neon ? p.accentSecondary : app.color)
                          .withValues(alpha: 0.3),
                      blurRadius: neon ? 12 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: iconChild,
              ),
              if (selected)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
              if (showMinus)
                Positioned(
                  left: -6,
                  top: -6,
                  child: GestureDetector(
                    onTap: onMinus ?? onLongPress,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB0B8C4),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '-',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                ],
              ),
              if (labels) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: p.ink,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    shadows: p.isDark
                        ? const [
                            Shadow(blurRadius: 6, color: Colors.black54),
                          ]
                        : null,
                  ),
                ),
              ],
            ],
          ),
        );

    if (ignoreInnerGestures) return visual;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: visual,
      ),
    );
  }
}
