import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../brand.dart';

/// Persistent “from ziBashu” mark for About screens and footers.
class FromZiBashuBadge extends StatelessWidget {
  const FromZiBashuBadge({
    super.key,
    this.compact = false,
    this.openWebsite = true,
  });

  final bool compact;
  final bool openWebsite;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 8 : 10,
          height: compact ? 8 : 10,
          decoration: const BoxDecoration(
            color: ZiBashuBrand.forest,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: compact ? 6 : 8),
        Text(
          ZiBashuBrand.fromLine,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: ZiBashuBrand.ink.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
        ),
      ],
    );

    if (!openWebsite) return child;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        launchUrl(
          Uri.parse(ZiBashuBrand.website),
          mode: LaunchMode.externalApplication,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: child,
      ),
    );
  }
}
