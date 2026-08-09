import 'package:flutter/material.dart';

import '../core/morph_palette.dart';
import 'glass_panel.dart';

/// Primary-flow CTA to make MorphOS the global default home launcher.
class LauncherSetupBanner extends StatelessWidget {
  const LauncherSetupBanner({
    super.key,
    required this.palette,
    required this.isDefaultHome,
    required this.onSetHome,
    required this.onDismiss,
  });

  final MorphPalette palette;
  final bool isDefaultHome;
  final VoidCallback onSetHome;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (isDefaultHome) return const SizedBox.shrink();
    final p = palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
      child: GlassPanel(
        palette: p,
        radius: 16,
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Icon(Icons.home_filled, color: p.accentSecondary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use MorphOS as Home',
                    style: TextStyle(
                      color: p.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Set as default launcher — Home returns here, not a nested app.',
                    style: TextStyle(
                      color: p.muted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onSetHome,
              child: const Text('Set home'),
            ),
            IconButton(
              tooltip: 'Dismiss',
              visualDensity: VisualDensity.compact,
              onPressed: onDismiss,
              icon: Icon(Icons.close, size: 18, color: p.muted),
            ),
          ],
        ),
      ),
    );
  }
}
