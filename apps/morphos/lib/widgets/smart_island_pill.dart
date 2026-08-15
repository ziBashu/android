import 'package:flutter/material.dart';

import '../core/smart_island.dart';

class SmartIslandPill extends StatelessWidget {
  const SmartIslandPill({
    super.key,
    required this.activity,
    required this.onTap,
    this.onSeek,
    this.onPrevious,
    this.onPause,
    this.onNext,
  });

  final IslandActivity activity;
  final VoidCallback onTap;
  final ValueChanged<double>? onSeek;
  final VoidCallback? onPrevious;
  final VoidCallback? onPause;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (activity.isIdle && !activity.expanded) {
      return GestureDetector(
        onTap: onTap,
        child: Center(
          child: Container(
            width: 72,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.circle, size: 6, color: Colors.white54),
              ),
            ),
          ),
        ),
      );
    }

    if (!activity.expanded) {
      return GestureDetector(
        onTap: onTap,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                activity.compactLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activity.title.isEmpty ? activity.compactLabel : activity.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (activity.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    activity.subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
                if (activity.isMusic) ...[
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                    ),
                    child: Slider(
                      value: activity.progress.clamp(0, 1),
                      onChanged: onSeek,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: onPrevious,
                        icon: const Icon(Icons.skip_previous, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: onPause,
                        icon: Icon(
                          activity.playing ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      IconButton(
                        onPressed: onNext,
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                      ),
                    ],
                  ),
                ] else if (activity.elapsedLabel.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    activity.elapsedLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
